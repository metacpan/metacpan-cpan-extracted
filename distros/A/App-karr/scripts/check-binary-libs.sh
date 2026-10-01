#!/usr/bin/env bash
# Fail if a packed karr binary needs a shared library on the target beyond the
# documented runtime set.
# Usage: check-binary-libs.sh <karr-binary>
#        check-binary-libs.sh --list    # print the documented runtime set
#
# Every compiled object pp packed is checked, not only libgit2: the loader
# itself, and every .so inside the PAR archive (the binary is a zip after its
# ELF head), extracted and run through ldd. Which libs an XS module links
# against is decided by the build image, not by karr: on a trixie-based
# perl:5.40, whose base carries libthai-dev, Unicode::LineBreak links
# libthai.so.0, and the binary dies at startup on every target without libthai0
# (k315). A check of libgit2 alone (k293) could not see that, and neither can
# verify-binary.sh, which runs in the build container where the lib is present.
# This compares names against the list below, so it works in that container.
set -euo pipefail

# The documented runtime set: what a target must have installed for the
# binary to run. The one place it is listed -- the release workflow prints it
# into each tarball's README with --list. README.md ("Binary (no Perl
# needed)") names the same libs in prose; change the two together.
RUNTIME_LIBS=(libssl libcrypto libssh2 libz libzstd)

# Never worth documenting: glibc and the toolchain runtime every Linux target
# has, and libperl, which pp's boot loader carries itself when perl was built
# with a shared libperl (the perl:*-bookworm images link it statically).
BASE_LIBS=(libc libm libpthread libdl librt libgcc_s ld-linux-.* linux-vdso libperl)

if [ "${1:-}" = "--list" ]; then
  echo "${RUNTIME_LIBS[*]}"
  exit 0
fi

BIN=$(realpath "${1:?usage: check-binary-libs.sh <karr-binary> | --list}")
# Checked here because nothing below would notice: unzip quietly falls back to
# "$BIN.zip", and ldd's failure on the loader is ignored like any other.
[ -f "$BIN" ] || { echo "FAIL: no such file: $BIN" >&2; exit 1; }
allowed=$(IFS='|'; echo "${RUNTIME_LIBS[*]}|${BASE_LIBS[*]}")

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# unzip exits 1 for a warning -- "extra bytes at beginning", for bytes in
# front of the archive its offsets do not account for; 2 and up is a failure.
rc=0
unzip -qq -o "$BIN" -d "$work/par" || rc=$?
if [ "$rc" -gt 1 ]; then
  echo "FAIL: cannot unpack the PAR archive in $BIN (unzip exit $rc)" >&2
  exit 1
fi

objects=("$BIN")
while IFS= read -r -d '' f; do objects+=("$f"); done \
  < <(find "$work/par" -type f \( -name '*.so' -o -name '*.so.*' \) -print0 | sort -z)
if [ "${#objects[@]}" -lt 2 ]; then
  echo "FAIL: no shared objects inside $BIN -- is it a pp binary?" >&2
  exit 1
fi

# One "lib<TAB>object" line per library each object needs, direct or
# transitive, by name: "libthai.so.0 => not found" counts like a resolved one.
# ldd exits non-zero on an object with no dynamic section, which needs nothing,
# and prints "statically linked" for one without NEEDED entries; neither names
# a .so, so neither adds a line.
: > "$work/needs"
for obj in "${objects[@]}"; do
  { ldd "$obj" 2>/dev/null || true; } \
    | awk -v obj="${obj#"$work/par/"}" '$1 ~ /\.so/ {
        lib = $1; sub(/.*\//, "", lib); sub(/\.so.*/, "", lib); print lib "\t" obj
      }' \
    | sort -u >> "$work/needs"
done

echo "Shared libs the binary needs on the target (${#objects[@]} objects checked):"
cut -f1 "$work/needs" | sort -u | sed 's/^/  /'

undocumented=$(cut -f1 "$work/needs" | sort -u | grep -vxE "$allowed" || true)
if [ -n "$undocumented" ]; then
  for lib in $undocumented; do
    printf '::error::undocumented runtime lib %s, needed by: %s\n' "$lib" \
      "$(awk -F'\t' -v l="$lib" '$1 == l {print $2}' "$work/needs" | sort -u | paste -sd' ')" >&2
  done
  echo "FAIL: the binary needs libs outside the documented runtime set (${RUNTIME_LIBS[*]})." >&2
  echo "A target without them cannot start it. Build on an image that does not link them" >&2
  echo "(release-binaries.yml pins perl:5.40-bookworm for this), or, if the new dependency" >&2
  echo "is meant to ship, add it to RUNTIME_LIBS here and to the README's runtime list." >&2
  exit 1
fi
echo "runtime-libs check: only the documented libs are needed"
