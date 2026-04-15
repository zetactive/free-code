#!/usr/bin/env bash
# Local install: build ./free-code from this repo and link ~/.local/bin/free-code
# Usage: from repo root — bash install-local.sh
#    or: bash /path/to/free-code/install-local.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

BUN_MIN_VERSION="1.3.11"
LINK_DIR="${HOME}/.local/bin"
BINARY_NAME="free-code"

info()  { printf "${CYAN}[*]${RESET} %s\n" "$*"; }
ok()    { printf "${GREEN}[+]${RESET} %s\n" "$*"; }
warn()  { printf "${YELLOW}[!]${RESET} %s\n" "$*"; }
fail()  { printf "${RED}[x]${RESET} %s\n" "$*"; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

version_gte() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

install_bun() {
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
  export PATH="$BUN_INSTALL/bin:$PATH"
  if ! command -v bun &>/dev/null; then
    fail "bun 安装后仍未在 PATH 中找到。请将下列行加入 shell 配置后重开终端:
      export PATH=\"\$HOME/.bun/bin:\$PATH\""
  fi
  ok "bun: v$(bun --version)（刚安装）"
}

check_bun() {
  if command -v bun &>/dev/null; then
    local ver
    ver="$(bun --version 2>/dev/null || echo "0.0.0")"
    if version_gte "$ver" "$BUN_MIN_VERSION"; then
      ok "bun: v${ver}"
      return
    fi
    warn "当前 bun v${ver}，需要 v${BUN_MIN_VERSION}+，正在安装/升级..."
  else
    info "未找到 bun，正在安装..."
  fi
  install_bun
}

install_deps() {
  info "安装依赖（bun install）..."
  bun install --frozen-lockfile 2>/dev/null || bun install
  ok "依赖已就绪"
}

build_free_code() {
  info "编译 ${BINARY_NAME}（输出: ${REPO_ROOT}/${BINARY_NAME}）..."
  bun run ./scripts/build.ts --outfile="${BINARY_NAME}"
  if [[ ! -x "${REPO_ROOT}/${BINARY_NAME}" ]]; then
    fail "未找到可执行文件: ${REPO_ROOT}/${BINARY_NAME}"
  fi
  ok "已生成: ${REPO_ROOT}/${BINARY_NAME}"
}

link_binary() {
  mkdir -p "$LINK_DIR"
  ln -sf "${REPO_ROOT}/${BINARY_NAME}" "${LINK_DIR}/${BINARY_NAME}"
  ok "已链接: ${LINK_DIR}/${BINARY_NAME} -> ${REPO_ROOT}/${BINARY_NAME}"

  if ! echo "$PATH" | tr ':' '\n' | grep -qx "$LINK_DIR"; then
    warn "${LINK_DIR} 不在当前 PATH 中"
    echo ""
    printf "${YELLOW}  请将下列行加入 ~/.zshrc 或 ~/.bashrc 后执行 source 或重开终端:${RESET}\n"
    printf "${BOLD}    export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}\n"
    echo ""
  fi
}

main() {
  echo ""
  printf "${BOLD}${CYAN}free-code${RESET} ${DIM}本地安装（当前仓库）${RESET}\n"
  printf "${DIM}  ${REPO_ROOT}${RESET}\n"
  echo ""

  case "$(uname -s)" in
    Darwin|Linux) ;;
    *) fail "不支持的操作系统: $(uname -s)，需要 macOS 或 Linux。" ;;
  esac

  check_bun
  echo ""
  install_deps
  echo ""
  build_free_code
  echo ""
  link_binary

  echo ""
  printf "${GREEN}${BOLD}安装完成。${RESET}\n"
  echo ""
  printf "  ${BOLD}运行:${RESET} ${CYAN}${BINARY_NAME}${RESET}\n"
  printf "  ${DIM}二进制位于仓库内；若移动仓库请重新执行本脚本。${RESET}\n"
  echo ""
}

main "$@"
