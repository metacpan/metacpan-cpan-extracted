#!/usr/bin/env bash
# Smoke-test a built karr binary against the pp runtime traps.
# Usage: verify-binary.sh <karr-binary>
# Trap 3 compares against the share/ of the checkout this script lives in, so
# run the copy from the checkout the binary was built from.
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

# Trap 3: karr's own share/, which the binary has only if build-binary.sh packed
# it. Nothing above reads it -- `skill --help` loads the class, not the files --
# so a binary without it passes traps 1 and 2 and dies the first time someone
# runs `karr skill` or `karr init --claude-skill` (k308). Every skill under the
# checkout's share/ has to come back from `skill show` byte for byte, and
# `skill install` has to write each of its files, references included, unchanged.
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skills=()
for f in "$root"/share/*/SKILL.md; do
  if [ -f "$f" ]; then skills+=("$(basename "$(dirname "$f")")"); fi
done
[ "${#skills[@]}" -gt 0 ] || { echo "FAIL: no skills under $root/share" >&2; exit 1; }
hint="is share/ bundled (build-binary.sh -a share)?"
proj=$(mktemp -d)
( cd "$proj" && "$BIN" skill install --agent claude-code >/dev/null ) \
  || { echo "FAIL: skill install -- $hint" >&2; exit 1; }
for s in "${skills[@]}"; do
  "$BIN" skill show "$s" | cmp -s - "$root/share/$s/SKILL.md" \
    || { echo "FAIL: skill show $s -- $hint" >&2; exit 1; }
  while IFS= read -r f; do
    f=${f#./}
    cmp -s "$root/share/$s/$f" "$proj/.claude/skills/$s/$f" \
      || { echo "FAIL: skill install wrote no matching $s/$f -- $hint" >&2; exit 1; }
  done < <(cd "$root/share/$s" && find . -type f -name '*.md')
done
echo "trap3 (bundled skills: ${skills[*]}): OK"
echo "verify: OK"
