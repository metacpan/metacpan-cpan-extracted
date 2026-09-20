---
name: karr-single-binary
description: Use when packaging the karr CLI into a single distributable binary, or benchmarking such a binary against the perl CLI — pp / PAR::Packer, staticperl, standalone/single-file build, "no perl on the target", cold-start pick/move/claim timing. Covers the libgit2 FFI-dlopen trap and the dynamically loaded App::karr::Cmd::* classes that a packer's scanner never sees.
---

# Packing karr into a single binary

Goal: one file you ship that runs `karr` on a box with no CPAN install. The Perl
side is easy. The hard part is that **libgit2 is opened by FFI at runtime**, not
linked at build time — so a naive pack builds fine and then dies on first git
access. Read the verdict, avoid the two traps, follow the runbook.

## Verdict: which packer

- **App::FatPacker — no.** It inlines only pure-Perl `.pm` files. karr pulls XS
  (`YAML::XS`, a JSON XS backend, `FFI::Platypus`) and a C library (`libgit2`).
  FatPacker cannot carry either. Dead on arrival — don't spend time here.
- **staticperl — no (for karr).** A true `--static` binary cannot reliably
  `dlopen`, and libgit2 is loaded via FFI/`dlopen` at runtime → git dies. Without
  `--static` you must ship the `.so`s anyway, so it is no longer one file. It
  solves only the XS-perl part and adds nothing for the C lib. Timebox any
  attempt and abort on the first `.so` error. Why, and the exact abort signals:
  `references/staticperl-dead-end.md`.
- **PAR::Packer (`pp`) — yes.** It bundles the interpreter + XS `.so`s + the
  Alien share dir into one executable that extracts to a runtime cache where FFI
  finds libgit2. Full worked recipe, runtime-path mechanics, cache tuning, and
  the six failure modes: `references/pp-recipe.md`.

## Two traps that decide the night

### 1. The command classes load dynamically
`lib/App/karr.pm` `use`s only `App::karr::Cmd::Board`; `MooX::Cmd` resolves the
other 33 `App::karr::Cmd::*` from `@ARGV` at runtime, so `pp`'s static scanner
never sees them. Force the whole namespace with a glob:

```
-M 'App::karr::**' -M 'App::karr::Cmd::**'
```

`::**` = every module below the namespace at any depth (without the parent);
trailing `::` (e.g. `-M 'App::karr::Cmd::'`) includes the parent too. Quote the
glob so the shell does not expand it. A class left out only dies at runtime when
that subcommand is first called — hence the "exercise every subcommand" step.

### 2. libgit2 is opened by FFI, not linked
`Git::Libgit2::FFI` runs `FFI::Platypus->new(lib => [Alien::Libgit2->dynamic_libs])`
— a runtime `dlopen`. Two consequences:

- **Bundle the Alien share dir** or `dist_dir` croaks at startup. `pp` does not
  carry File::ShareDir trees automatically:
  `-a "$DISTDIR;lib/auto/share/dist/Alien-Libgit2"`. libgit2 itself needs no
  `-l` — it resolves through `@INC`/File::ShareDir to the extracted copy.
- **Its transitive `.so`s** (this box: `libssl libcrypto libssh2 libz libzstd`
  — always re-check with `ldd`) are resolved by the dynamic loader at `dlopen`.
  On Linux, PAR's mid-process `LD_LIBRARY_PATH` patch is not reliably honored by
  glibc, so do not count on `-l` for these. They are ordinary OS libraries
  present on any normal Linux target — require them there, and bundle only for a
  bare/musl container. The reliable options are in `references/pp-recipe.md`.

## This machine — verified start state
- `Alien::Libgit2 install_type=share` **already** → build against the existing
  `~/perl5`; do not reinstall karr's deps, so `~/perl5` stays untouched.
- `PAR::Packer` is **not** installed → install it first (a build tool, additive;
  it is not a karr runtime dep).
- perl is `/usr/bin/perl` (5.40.x) with `PERL5LIB=~/perl5/lib/perl5` → run `pp`
  in exactly this environment or it will miss deps.

## Build & verify runbook
1. **Isolate.** Work in a git worktree/branch of `~/dev/karr`. Never edit
   `dist.ini` or the release machinery. Do not reinstall deps into `~/perl5`.
2. **Install** `PAR::Packer`.
3. **Build** with the recipe in `references/pp-recipe.md`.
4. **Verify in a fresh cache and clean cwd:**
   `PAR_GLOBAL_TEMP="$(mktemp -d)" ./karr --help`, then run **every** subcommand
   against a real board (trap 1). Ideally repeat in a minimal container with no
   dev libraries to catch a transitive-`.so` break before deployment.
5. **Benchmark** against the perl CLI: run `scripts/benchmark.sh` (execute it) —
   cold-start `--version`/`list` and mutating `create` ×N, binary vs perl CLI,
   plus binary size and RSS.
6. **Report** the working tool, the exact command, binary size, the benchmark
   table, and any target-machine requirement (which system `.so`s must exist).

## Done when
- `./karr` runs from a fresh `$PAR_GLOBAL_TEMP` with nothing on the target beyond
  the documented system `.so`s, **and** every subcommand works against a real
  board, **and** `scripts/benchmark.sh` produced numbers for binary vs perl CLI.
  The headline number that answers the original question: cold-start `--version`
  — is it under ~50 ms, and how does it compare to the perl CLI?
