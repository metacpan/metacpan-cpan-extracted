#!/usr/bin/env bash
# Smoke-test a built karr binary against both pp runtime traps.
# Usage: verify-binary.sh <karr-binary>
set -euo pipefail
BIN=$(realpath "${1:?usage: verify-binary.sh <karr-binary>}")
export PAR_GLOBAL_TEMP="$(mktemp -d)"

"$BIN" --version
"$BIN" --help >/dev/null

# Trap 1: force every dynamically-loaded Cmd class to load (no side effects).
for cmd in init create list show move edit delete board dashboard pick unlock \
           archive handoff needs metrics log config context agent-name skill \
           materialize import repair sync backup restore destroy \
           set-refs get-refs disable enable completion; do
  "$BIN" "$cmd" --help >/dev/null || { echo "FAIL: subcommand $cmd" >&2; exit 1; }
done
echo "trap1 (subcommand classes): OK"

# Trap 2: a real libgit2/FFI round trip in a throwaway repo, never the checkout.
work=$(mktemp -d)
(
  cd "$work" && git init -q .
  "$BIN" init
  "$BIN" create "smoke test card" >/dev/null
  "$BIN" list --compact
  id=$("$BIN" list --compact | awk 'NR==1{gsub(/#/,"",$1); print $1}')
  "$BIN" move "$id" in-progress --claim smoke
  "$BIN" handoff "$id" --claim smoke --note ok
  "$BIN" backup > board.yaml && test -s board.yaml
  "$BIN" restore --yes --input board.yaml
  "$BIN" list --compact
  "$BIN" destroy --yes
)
echo "trap2 (libgit2 board flow): OK"
echo "verify: OK"
