#!/usr/bin/env bash
# Build a standalone `karr` binary with PAR::Packer (pp).
# Run from the checkout root. Requires perl, a share-build Alien::Libgit2 +
# Git::Native, and PAR::Packer on PATH/PERL5LIB. Output: $KARR_BIN_OUT
# (default ./karr). Reference:
# .claude/skills/karr-single-binary/references/pp-recipe.md
set -euo pipefail

OUT="${KARR_BIN_OUT:-./karr}"

# Alien::Libgit2 must be a share build, or dynamic_libs resolves to host paths
# that are absent on the target and FFI dlopen fails at runtime.
install_type=$(perl -MAlien::Libgit2 -e 'print Alien::Libgit2->install_type')
if [ "$install_type" != "share" ]; then
  echo "ERROR: Alien::Libgit2 install_type='$install_type', need 'share'." >&2
  echo "Reinstall with ALIEN_INSTALL_TYPE=share before building." >&2
  exit 1
fi

DISTDIR=$(perl -MAlien::Libgit2 -e 'print Alien::Libgit2->dist_dir')

# -M only the JSON XS backend that is actually installed: -M on an absent
# module aborts pp. JSON::MaybeXS chooses one at runtime; bundle what is present.
json_mods=()
for m in Cpanel::JSON::XS JSON::XS JSON::PP; do
  perl -M"$m" -e1 >/dev/null 2>&1 && json_mods+=("-M" "$m")
done

# -I lib: put the checkout's lib/ on @INC so the -M 'App::karr::**' glob (and
# bin/karr's own `use App::karr::*`) resolve even when karr itself is not
# installed -- e.g. a fresh CI container that only installed the deps. Without
# it the glob finds nothing and the packed binary dies at startup on the first
# missing App::karr::* module.
PAR_VERBATIM=1 pp -o "$OUT" \
  -I lib \
  -M 'App::karr::**' -M 'App::karr::Cmd::**' \
  -M YAML::XS \
  -M JSON::MaybeXS "${json_mods[@]}" \
  -M Module::Runtime \
  -M MooX::Cmd -M 'MooX::Cmd::**' \
  -M MooX::Options -M 'MooX::Options::**' \
  -M Git::Native -M 'Git::Native::**' \
  -M Git::Libgit2 -M 'Git::Libgit2::**' \
  -M Alien::Libgit2 \
  -M FFI::Platypus -M 'FFI::Platypus::**' -M FFI::CheckLib \
  -a "$DISTDIR;lib/auto/share/dist/Alien-Libgit2" \
  bin/karr

chmod +x "$OUT"
echo "Built $OUT ($(du -h "$OUT" | cut -f1))"
