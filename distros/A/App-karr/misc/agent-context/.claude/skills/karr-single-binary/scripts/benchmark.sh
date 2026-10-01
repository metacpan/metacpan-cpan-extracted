#!/usr/bin/env bash
# EXECUTE this script. Benchmarks a packed karr binary against the perl CLI on
# the hot path (startup + typical board ops), plus binary size and peak RSS.
#
#   scripts/benchmark.sh <path-to-packed-karr-binary> [perl-cli-command...]
#
# perl-cli-command defaults to `perl -Ilib bin/karr` when run from the karr
# checkout, else the `karr` on PATH. N iterations via env N (default 100).
#
# Headline number for the Perl-vs-Go question: median startup on the cheapest
# real command. Under ~50ms and close to a static binary => rewrite premise moot.
# Portable to mawk (no gawk asort) and needs no bc.
set -uo pipefail

BIN="${1:-}"; shift || true
if [[ -z "$BIN" || ! -x "$BIN" ]]; then
  echo "usage: $0 <packed-karr-binary> [perl-cli-command...]" >&2; exit 2
fi
if [[ $# -gt 0 ]]; then PERLCLI=("$@")
elif [[ -f bin/karr ]]; then PERLCLI=(perl -Ilib bin/karr)
else PERLCLI=(karr); fi
N="${N:-100}"

# --- throwaway board -------------------------------------------------------
BOARD="$(mktemp -d)"; trap 'rm -rf "$BOARD"' EXIT
( cd "$BOARD"
  git init -q && git config user.email b@b && git config user.name b
  "$BIN" init >/dev/null 2>&1 || { echo "karr init failed in $BOARD" >&2; exit 1; }
  for i in $(seq 1 20); do "$BIN" create "bench task $i" >/dev/null 2>&1 || true; done
) || exit 1

# stats <label>: reads numeric ms values on stdin, prints summary (sorts first).
stats() {
  sort -n | awk -v L="$1" '
    {a[NR]=$1; s+=$1}
    END{
      n=NR;
      if(n==0){ printf "  %-22s (no data)\n",L }
      else{
        mn=a[1]; mx=a[n]; mean=s/n;
        med=(n%2)?a[(n+1)/2]:(a[n/2]+a[int(n/2)+1])/2;
        pi=int(n*0.95); if(pi<1)pi=1; p95=a[pi];
        printf "  %-22s min %6.1f  med %6.1f  mean %6.1f  p95 %6.1f  max %6.1f ms\n",
               L,mn,med,mean,p95,mx
      }
    }'
}

# time_cmd <runner-array-name> <args...>: prints N per-run millisecond deltas.
time_cmd() {
  local -n R="$1"; shift
  ( cd "$BOARD"; "${R[@]}" "$@" >/dev/null 2>&1 )   # warm PAR cache / OS cache
  local i t0 t1
  for ((i=0; i<N; i++)); do
    t0=$(date +%s%N)
    ( cd "$BOARD"; "${R[@]}" "$@" >/dev/null 2>&1 )
    t1=$(date +%s%N)
    awk "BEGIN{printf \"%.1f\n\", ($t1-$t0)/1000000}"
  done
}

run_suite() { # <label> <runner-array-name>
  local label="$1" arr="$2"; local -n RR="$2"
  echo "$label:"
  if ( cd "$BOARD"; "${RR[@]}" --version >/dev/null 2>&1 ); then
    time_cmd "$arr" --version | stats "startup (--version)"
  fi
  time_cmd "$arr" list | stats "list (startup+read)"
}

declare -a BINR=("$BIN")
echo "== karr binary vs perl CLI ==  N=$N  board=$BOARD"
echo "binary: $BIN  ($(du -h "$BIN" | cut -f1))"
echo "perl:   ${PERLCLI[*]}"
echo
run_suite "BINARY"  BINR
run_suite "PERLCLI" PERLCLI

# --- peak RSS (one invocation each) ---------------------------------------
if command -v /usr/bin/time >/dev/null; then
  echo; echo "peak RSS (Maximum resident set, one 'list'):"
  for name in BINARY PERLCLI; do
    if [[ $name == BINARY ]]; then r=("$BIN"); else r=("${PERLCLI[@]}"); fi
    rss=$( cd "$BOARD"; /usr/bin/time -v "${r[@]}" list 2>&1 >/dev/null \
           | awk -F': ' '/Maximum resident/{print $2}' )
    printf "  %-8s %s kB\n" "$name" "${rss:-?}"
  done
fi
echo; echo "done. First-run (cold PAR cache) cost is separate — measure once with:"
echo "  PAR_GLOBAL_TEMP=\$(mktemp -d) $BIN list   # before the cache is warm"
