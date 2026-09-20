# pp (PAR::Packer) recipe for karr

Verified against the pp POD, `PAR.pm`, `Alien::Base`, `Git::Libgit2::FFI`, and
the `Alien::Libgit2` alienfile, then **built and run end-to-end** (2026-09-14,
perl 5.40.1) — the three corrections marked **[verified]** below are what turned
a recipe that scans clean but dies at startup into a working binary. Prefer the
query commands over any hard-coded path — versions and dist dirs move.

## 0. Preconditions
```bash
# Alien::Libgit2 MUST be a `share` build, or dynamic_libs resolves to system
# paths that are absent on a bare target. On this box it already is:
perl -MAlien::Libgit2 -e 'print Alien::Libgit2->install_type, "\n"'   # -> share
# If it ever prints `system`: reinstall into an ISOLATED local::lib (not ~/perl5)
#   ALIEN_INSTALL_TYPE=share cpanm -l /tmp/karrbuild Alien::Libgit2 Git::Libgit2 Git::Native
# and run pp with that lib on PERL5LIB.

cpanm PAR::Packer          # build tool; not a karr runtime dep
# To keep ~/perl5 pristine, install into an isolated lib and put it first on the path:
#   cpanm -l /tmp/karrbuild/parlib PAR::Packer
#   export PATH=/tmp/karrbuild/parlib/bin:$PATH
#   export PERL5LIB=/tmp/karrbuild/parlib/lib/perl5:$PERL5LIB
```

**Debian/Ubuntu: PAR::Packer needs `libperl-dev`.** Its `myldr` boot loader
links `-lperl`, which needs the dev symlink `/usr/lib/.../libperl.so` (the runtime
`libperl.so.5.40` alone is not enough). Missing it, `pp`'s own install dies at
Configure with `you need to install package "libperl-dev"`.
- With root: `apt-get install libperl-dev`. Done.
- **No root / no sudo** (still no `~/perl5` touch): satisfy it in user space.
  0. `SHIM=/tmp/karrbuild/shim; mkdir -p "$SHIM/bin"`
  1. Link the dev name and hand the dir to the linker (gcc honors `LIBRARY_PATH`):
     ```bash
     ln -sf /usr/lib/x86_64-linux-gnu/libperl.so.5.40.1 "$SHIM/libperl.so"
     export LIBRARY_PATH="$SHIM:${LIBRARY_PATH:-}"
     ```
  2. The die is gated solely on `dpkg-query --status libperl-dev`; shadow it on PATH:
     ```bash
     printf '#!/bin/bash\nfor a in "$@"; do [ "$a" = libperl-dev ] && exit 0; done\nexec /usr/bin/dpkg-query "$@"\n' > "$SHIM/bin/dpkg-query"
     chmod +x "$SHIM/bin/dpkg-query"; export PATH="$SHIM/bin:$PATH"
     ```
  Then `cpanm -l …/parlib PAR::Packer` succeeds. The final binary bundles
  `libperl.so.5.40`, so the shim is a **build-time** crutch only — it is not needed
  on the target (and the target needs no Perl at all).

## 1. Locate the share dir and inspect the real transitive libs
```bash
DISTDIR=$(perl -MAlien::Libgit2 -e 'print Alien::Libgit2->dist_dir')
LIBGIT2=$(perl -MAlien::Libgit2 -e 'print +(Alien::Libgit2->dynamic_libs)[0]')
ldd "$LIBGIT2"     # the DT_NEEDED .so that must exist on the target
# observed on this box: libssl libcrypto libssh2 libz libzstd  (no pcre:
# the alienfile builds libgit2 with -DREGEX_BACKEND=builtin)
```

## 2. Build
```bash
# Run from the checkout root (bin/karr, lib/ visible), with $DISTDIR from step 1.
# The [verified] lines below the block explain PAR_VERBATIM, the JSON list, and ::**.
PAR_VERBATIM=1 \
pp -o karr \
   -M 'App::karr::**' -M 'App::karr::Cmd::**' \
   -M YAML::XS \
   -M JSON::MaybeXS -M Cpanel::JSON::XS -M JSON::PP \
   -M Module::Runtime \
   -M MooX::Cmd -M 'MooX::Cmd::**' \
   -M MooX::Options -M 'MooX::Options::**' \
   -M Git::Native -M 'Git::Native::**' \
   -M Git::Libgit2 -M 'Git::Libgit2::**' \
   -M Alien::Libgit2 \
   -M FFI::Platypus -M 'FFI::Platypus::**' -M FFI::CheckLib \
   -a "$DISTDIR;lib/auto/share/dist/Alien-Libgit2" \
   bin/karr
```
- **`PAR_VERBATIM=1` [verified].** Without it, pp's default `PAR::Filter::PodStrip`
  runs and **corrupts** karr's sources — see "Two build-breakers" below. This is
  the difference between a binary that dies on every command and one that works.
- **JSON: `-M` only the backend that is actually installed [verified].** `-M` on an
  absent module makes pp abort (`Cannot find module JSON/XS.pm`), so do not list all
  three speculatively. `JSON::MaybeXS` picks whatever is present (here
  `Cpanel::JSON::XS`); check with
  `perl -MJSON::MaybeXS -e 'print ref(JSON::MaybeXS->new)'` and name that one.
- **`-M 'MooX::Cmd::**'` and `-M 'MooX::Options::**'` [verified]** — same dynamic-load
  trap as karr's own Cmd classes, one layer deeper: `MooX::Cmd` string-loads
  `MooX::Cmd::Role` via `Module::Runtime`, which the scanner never sees. Without the
  glob: `Can't locate MooX/Cmd/Role.pm` at startup.
- **libgit2 gets no `-l`** — it is found at runtime via the bundled share dir
  (`dist_dir` resolves against `@INC`, which under PAR points into
  `$PAR_TEMP/inc/lib/auto/share/dist/Alien-Libgit2`).
- To flush out any runtime dep the scanner missed: add `-c` (compile-check) or,
  only if safe, `-x karr <args>` (really runs karr — may touch/write git; never in
  the karr checkout, whose `refs/karr/*` is the live board).

## 3. Verify
```bash
PAR_GLOBAL_TEMP="$(mktemp -d)" ./karr --help        # fresh cache, first-run extract
# then exercise EVERY subcommand against a throwaway board (trap 1 dies at runtime)
```
Exercise the subcommands in a **separate `mktemp -d` + `git init` repo**, never in
the karr checkout — a worktree shares `refs/karr/*` with the real board, so a
verification `create`/`move`/`destroy` there mutates live state. `karr <cmd> --help`
for each of the 32 commands is the cheap trap-1 probe (forces the class to load,
no side effects); pair it with one real init→create→list→move→handoff→backup→
restore→destroy flow to prove libgit2/FFI end-to-end.

## Building in a fresh container (CI), not the dev box

On the dev box the build works because `~/perl5` already has karr and all its
deps installed. A CI container (e.g. `perl:5.40-bookworm`) is a clean slate,
which exposes three traps the dev box hides — all found by karr's
`release-binaries.yml` dry-run, all now baked into `scripts/build-binary.sh` and
that workflow:

1. **`pp` needs `-I lib`.** `bin/karr` does `use App::karr::SyncGuard` with no
   `use lib`, and the `-M 'App::karr::**'` glob resolves against `@INC`. In a
   container that installed only the *deps* (karr itself is not installed), the
   glob finds nothing and the packed binary dies at startup: `Can't locate
   App/karr/SyncGuard.pm`. Add `-I lib` so the checkout's `lib/` is on `@INC`
   for the scan.

2. **The container has no `-dev` headers.** `Alien::Libgit2`'s share build is
   `-DUSE_SSH=ON -DUSE_HTTPS=OpenSSL`, so libgit2's cmake needs libssh2 + openssl
   + zlib + zstd *dev* headers, which `perl:*-bookworm` (buildpack-deps) does not
   carry for libssh2. Missing them, cmake aborts `LIBSSH2 not found` and nothing
   is built. `apt-get install -y pkg-config libssh2-1-dev libssl-dev zlib1g-dev
   libzstd-dev`.

3. **`ALIEN_INSTALL_TYPE=share` must scope to libgit2 only.** Setting it for the
   whole dep install forces *build-tool* aliens like `Alien::cmake3` to build
   cmake from source (and fail) instead of using the apt cmake. Install
   `Alien::cmake3` first (no env var → `system`, uses apt cmake), then set
   `ALIEN_INSTALL_TYPE=share` inline for just the `Alien::Libgit2 Git::Libgit2
   Git::Native` cpanm call so it does not leak.

Cosmetic, not a blocker: some CPAN tarballs (Cpanel::JSON::XS, Alien::Build,
FFI::Platypus) are packed on macOS and carry a `com.apple.provenance` xattr in a
LIBARCHIVE pax header; GNU tar warns `Ignoring unknown extended header keyword`.
`TAR_OPTIONS=--warning=no-unknown-keyword` silences it. (During bring-up those
warnings masked a *transient CPAN mirror outage* — 404s on the dep tarballs —
that looked like a tar bug but was not; if unpack fails with `gzip: unexpected
end of file`, suspect the mirror, not tar.)

## Two build-breakers the static scanner won't warn about
Both produce a binary that packs clean, and `perl -c` on the sources passes, yet
every command dies at startup.

1. **PodStrip corrupts karr's POD → `did not return a true value`.** karr uses
   Pod::Weaver `=func`/`=method` blocks interleaved with the code. pp's default
   `PAR::Filter::PodStrip` mishandles them: it leaves a `=func` opener without its
   `=cut`, so from there to end-of-file — **including the trailing `1;`** — is
   swallowed as POD. The module then returns false and you get, e.g.,
   `App/karr/Encoding.pm did not return a true value at .../Git.pm line 26`.
   `perl -c` does not catch it (POD is legal; the file just returns false at
   runtime). **Fix: `PAR_VERBATIM=1`** (Packer.pm honors `$ENV{PAR_VERBATIM}` to
   skip PodStrip) — bundles sources verbatim, ~+2 MB, and the sources are already
   `perl -c`-clean. Do not try to "fix the POD" instead; verbatim is the right knob.
2. **A framework role loaded by string require.** `MooX::Cmd` pulls
   `MooX::Cmd::Role` through `Module::Runtime` at runtime — invisible to the
   scanner, exactly like karr's own `App::karr::Cmd::*`. Cover it (and MooX::Options)
   with the `::**` globs in the build. Generalize: any dep that does a dynamic
   `require`/`use_module` needs its namespace globbed, not just the top module.

## Runtime cache (matters for the benchmark)
- Default cache is persistent: `TMPDIR/par-<userhex>/cache-<hash>/`, reused across
  runs; extraction happens only on the first run of a given binary (hash is
  content-based → a rebuilt binary = new cache dir).
- Pin it explicitly for a deployed tool: `PAR_GLOBAL_TEMP=/opt/karr/cache`.
- Do **not** use `--clean` / `PAR_GLOBAL_CLEAN` if fast restart matters — that
  re-extracts every run. Benchmark the **cached** path for the hot-CLI question,
  and separately note the one-time first-run cost.

## The transitive `.so` problem on Linux (highest risk)
libgit2's `DT_NEEDED` libs are resolved by the dynamic loader when FFI `dlopen`s
libgit2. PAR appends `$PAR_TEMP` to `LD_LIBRARY_PATH` mid-process, but glibc
reads `LD_LIBRARY_PATH` once at startup, so bundling these with `-l ssh2 -l ssl
-l crypto -l z -l zstd` is **not guaranteed** on Linux. Reliable choices, best
first:
1. **Require the system libs on the target** (openssl, zlib, zstd, libssh2 — on
   any normal Linux they are already there). Then bundle nothing; document the
   requirement. This is the pragmatic answer for karr's real targets.
2. Ship a tiny wrapper that sets `LD_LIBRARY_PATH=$PAR_TEMP/...` before exec
   (costs the single-file property).
3. Cleanest single-file: rebuild libgit2 in the alienfile with an `$ORIGIN`
   RPATH and its deps beside it, or static-link libssh2/openssl into libgit2 —
   an Alien-build change, not a pp change. Deepest; only for a bare/musl target.

## Failure modes to watch
1. Transitive `.so` missing on a bare target (see above) — symptom:
   `libssh2.so.1: cannot open shared object file` at runtime.
2. `install_type=system` → `dynamic_libs` empty on target → FFI fails immediately.
3. Forgotten `-a` share dir → `unable to find dist share directory` croak.
4. A missing `App::karr::Cmd::*` → that subcommand only fails at runtime.
5. OpenSSL ABI clash if you bundle libssl against a different system OpenSSL.
6. glibc portability — build on the oldest target glibc you must support.
7. **PodStrip corruption** → `... did not return a true value` at startup; every
   command dies. Fix: `PAR_VERBATIM=1` (see "Two build-breakers").
8. **`-M` on a module that isn't installed** → `pp` aborts with `Cannot find
   module X.pm`; the whole build stops. Only `-M` what `perl -M<mod> -e1` loads.
9. **`libperl-dev` absent** → `pp`'s own install fails at Configure with
   `you need to install package "libperl-dev"` (see Preconditions).

## Not a speed win — set expectations
Built and measured on this box (23 MB binary, N=100): warm startup **~457 ms**
vs. the perl CLI's **~305 ms**, cold-start (fresh cache, one-time extraction of
the 23 MB) **~1.8 s**, peak RSS **+30 %** (62 vs. 48 MiB). Packing buys
**distribution** (one file; the target needs no Perl, no CPAN, no Alien —
`libperl.so.5.40` and libgit2's share dir are bundled), **not** cold-start speed:
the cost is Perl interpreter startup + loading Moo/MooX/YAML::XS/FFI and the
libgit2 `dlopen`, which pp cannot remove and adds loader overhead on top. If
sub-50 ms startup is the actual goal, a single binary does not deliver it.

## Sources
- pp: https://metacpan.org/pod/pp
- PAR (DynaLoader/XS, shlib extraction, LD_LIBRARY_PATH): https://metacpan.org/pod/PAR
- Alien::Base (install_type, dist_dir, dynamic_libs): https://metacpan.org/pod/Alien::Base
- Git::Libgit2::FFI (FFI::Platypus + dynamic_libs): https://metacpan.org/pod/Git::Libgit2::FFI
- Alien::Libgit2 alienfile (builtin regex, USE_SSH, USE_HTTPS=OpenSSL): https://fastapi.metacpan.org/source/GETTY/Alien-Libgit2-0.002/alienfile
