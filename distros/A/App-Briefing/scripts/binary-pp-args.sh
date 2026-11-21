#!/usr/bin/env bash
# The extra pp arguments of the briefing binary, one per line on STDOUT: binary_pp_args of
# the [@Author::GETTY] bundle (dist.ini). Run from the dist root with the perl that packs;
# problems go to STDERR and end the run with exit 1, which fails the build.
#   scripts/binary-pp-args.sh
#
# The bundle runs pp itself (locally after `dzil build`, per platform in its dzil-binary
# workflow) as  PAR_VERBATIM=1 pp -o OUT -I lib <these lines> script/briefing. This adds what
# pp's static scan cannot see: the module set computed by scripts/loaded-modules.pl.
# briefing never talks to a network, so no TLS module is packed; binary-verify.sh rejects one.
#
# pp exits 0 on a binary that only dies at run time; scripts/binary-verify.sh and
# scripts/binary-smoke.sh are what prove a build.
set -euo pipefail

[ -f script/briefing ] && [ -f lib/App/Briefing.pm ] || { echo "ERROR: run from the dist root" >&2; exit 1; }
perl -Ilib -MMoo -MPath::Tiny -MJSON::MaybeXS -MTOML::Tiny::Parser -Mnamespace::clean -e1 \
  || { echo "ERROR: runtime dependencies missing (cpanm --installdeps .)" >&2; exit 1; }

loaded=$(perl -Ilib scripts/loaded-modules.pl | tr -d '\r') \
  || { echo "ERROR: scripts/loaded-modules.pl failed" >&2; exit 1; }
n=$(printf '%s\n' "$loaded" | wc -l | tr -d ' ')
[ "$n" -gt 30 ] || { echo "ERROR: loaded set suspiciously small ($n modules)" >&2; exit 1; }
for m in App::Briefing App::Briefing::CLI App::Briefing::Team Moo Path::Tiny TOML::Tiny::Parser; do
  printf '%s\n' "$loaded" | grep -qx "$m" || { echo "ERROR: the module list lacks $m" >&2; exit 1; }
done
# Windows only: Strawberry Perl's Config.pm mentions Portable (portable-mode startup), which pp's
# static scan follows into Portable::CPAN -> CPAN::Config -> LWP -> Net::SSLeay. None of that runs
# in briefing, so exclude the chain (pp -X, --exclude=MODULE; given before the script, like the -M lines).
case "$(perl -e 'print $^O')" in
  MSWin32|msys|cygwin)
    for x in Portable Portable::CPAN CPAN::Config Net::SSLeay IO::Socket::SSL; do printf -- '-X\n%s\n' "$x"; done ;;
esac
# One argument per line, never word-split (the bundle's rule for binary_pp_args).
printf '%s\n' "$loaded" | while IFS= read -r m; do printf -- '-M\n%s\n' "$m"; done
