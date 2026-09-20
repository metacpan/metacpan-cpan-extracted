# karr binary release — design

**Date:** 2026-09-14
**Status:** Design, awaiting maintainer review
**Topic:** Ship a standalone `karr` binary as a download alongside each release

## Goal

Offer the `karr` CLI as a downloadable single-file binary at each release, so a
fleet machine can run `karr` with no Perl, no CPAN, and no Alien install. Two
artifact forms per target, per the maintainer's request:

- the **raw** binary, named with the version (`karr-<version>-linux-<arch>`),
- **and** a `.tar.gz` (the usual packaging), each with a `.sha256`.

Targets: **Linux x86_64** and **Linux arm64** (glibc). macOS, Windows, and
musl/static are explicitly out of scope (see below).

## Non-goals / out of scope

- **Speed.** The binary is not faster than the perl CLI — measured ~457 ms warm
  vs. ~305 ms (perl), ~1.8 s cold, ~23 MB, +30% RSS. The win is *distribution*,
  not latency. This is documented, not a target to optimise.
- **macOS / Windows.** Not built. pp binaries are not cross-compilable, and the
  fleet is Linux.
- **musl / fully static.** A `--static` perl cannot reliably `dlopen`, and
  libgit2 arrives via FFI `dlopen`; the `karr-single-binary` skill records this
  as a dead end. glibc dynamic build only.
- **Bundling libgit2's transitive `.so`s.** The target is required to have the
  ordinary system libs (see Runtime requirements). Static-linking them into
  libgit2 is a possible future Alien change, not part of this work.
- **Changing the CPAN release flow.** `dzil release` keeps doing exactly what it
  does today.

## Key decisions

1. **Decouple from `dzil release` via a release-triggered CI workflow.**
   `dzil release` already creates the git tag, the GitHub release, and uploads
   the CPAN tarball + sha256 (via `GitHub::CreateRelease` in `[@Author::GETTY]`,
   `draft => 0`). A new GitHub Actions workflow triggers `on: release:
   [published]`, builds the matrix, and *appends* the binary assets to that same
   release. **No change to `GitHub::CreateRelease` or the shared
   `[@Author::GETTY]` bundle** (which every one of the maintainer's dists uses).
   The release event fires because the release is created with the maintainer's
   PAT from the local `dzil release`, not by a workflow's `GITHUB_TOKEN`.

2. **Build recipe lives in a repo script, not only in the skill.**
   `scripts/build-binary.sh` encapsulates the whole `pp` invocation from
   `.claude/skills/karr-single-binary/references/pp-recipe.md`. The workflow just
   calls it, and the maintainer can build the identical artifact locally. The
   skill remains the rationale/reference; the script is the executable copy.

3. **Build in an old glibc container for broad compatibility.**
   Build inside the official `perl:5.40-bookworm` image (Debian bookworm,
   glibc 2.36) — the same image family the test CI already uses. A binary built
   against 2.36 runs on newer glibc too; building on ubuntu-latest would not run
   on older systems. bookworm's `perl` image is multi-arch, so the same
   container works on the x86_64 and arm64 runners.

4. **Native arm64 runner, no qemu.** `linux-arm64` builds on `ubuntu-24.04-arm`
   (native), `linux-x86_64` on `ubuntu-latest`. Both run the bookworm container.

## Architecture

Three pieces, each independently understandable:

### A. `scripts/build-binary.sh`
- **Does:** produce a working `karr` binary for the host arch in the current
  environment.
- **Inputs:** run from the checkout root; expects perl + a **share**-build
  `Alien::Libgit2`/`Git::Native` + `PAR::Packer` already installed (the workflow
  installs them; a local run reuses `~/perl5`, already share on the maintainer's
  box). Optional `KARR_BIN_OUT` for the output path.
- **Does exactly:** locate `$DISTDIR` via `Alien::Libgit2->dist_dir`; run the
  verified `pp` command — `PAR_VERBATIM=1`, the `App::karr::**` /
  `App::karr::Cmd::**` / `MooX::Cmd::**` / `MooX::Options::**` globs, the JSON
  backend that is actually installed, `-a "$DISTDIR;lib/auto/share/dist/Alien-Libgit2"`.
- **Output:** one binary at `$KARR_BIN_OUT` (default `./karr`).
- **Depends on:** the pp-recipe knobs; nothing about releases or GitHub.

### B. `.github/workflows/release-binaries.yml`
- **Does:** on a published release, build every target and attach the assets.
- **Trigger:** `on: release: { types: [published] }`.
- **Permissions:** `contents: write` (to upload assets).
- **Matrix:** `{ arch: x86_64, runner: ubuntu-latest }`,
  `{ arch: arm64, runner: ubuntu-24.04-arm }`, each `container: perl:5.40-bookworm`.
- **Steps per target:**
  1. checkout at the release tag (`github.event.release.tag_name`).
  2. install build deps: `cmake`/build-essential (for the Alien share build) via
     apt; `ALIEN_INSTALL_TYPE=share cpanm --notest Alien::Libgit2 Git::Libgit2
     Git::Native` and the karr runtime deps; `cpanm --notest PAR::Packer`.
  3. `scripts/build-binary.sh` → `karr-<version>-linux-<arch>`.
  4. **verify** (see D) — fail the job if anything is off.
  5. package: copy raw binary; `tar czf` with the binary + `LICENSE` + a short
     `README`/`VERSION`; compute `.sha256` for both.
  6. upload all four files to the release (`gh release upload "$TAG" ... --clobber`
     or `softprops/action-gh-release` with `files:`).

### C. Asset layout on the release
Per target `<arch>` in `{x86_64, arm64}`, version `<v>` = tag without leading `v`:
- `karr-<v>-linux-<arch>` + `karr-<v>-linux-<arch>.sha256`
- `karr-<v>-linux-<arch>.tar.gz` + `karr-<v>-linux-<arch>.tar.gz.sha256`
Alongside the CPAN tarball + sha256 that `dzil` already attached.

### D. In-job verification (before upload)
The two `pp` traps only surface at runtime, so the job must exercise them:
- **Trap 1 (dynamic Cmd classes):** `karr <cmd> --help` for every subcommand
  forces each `App::karr::Cmd::*` to load (no side effects).
- **Trap 2 (libgit2/FFI):** one real `init → create → list → move → handoff →
  backup → restore → destroy` flow in a throwaway `mktemp -d` + `git init` repo
  (never the checkout — its `refs/karr/*` is the live board), from a fresh
  `PAR_GLOBAL_TEMP`, proving libgit2 resolves through the bundled share dir.
- Ideally the verify step runs in a **minimal container without dev libs** to
  catch a missing transitive `.so` before release. At minimum, assert the
  documented Runtime requirements libs are the only external deps (`ldd` /
  runtime check).

## Runtime requirements (documented for downloaders)
The binary bundles the perl interpreter, karr's XS `.so`s, and libgit2's share
dir, but libgit2's `DT_NEEDED` libraries are resolved by the OS loader at
`dlopen`: **libssl, libcrypto, libssh2, libz, libzstd** must exist on the target
(present on any normal Linux). Re-verify the exact list with `ldd` on the built
libgit2 during CI and emit it into the release notes / README.

## Data flow (one release)
```
maintainer: dzil release  (local, PAT)
   └─> git tag + GitHub release (published) + CPAN tarball asset
          └─ release:published event
                └─> release-binaries.yml (x86_64 | arm64)
                       └─ build-binary.sh -> verify -> package
                              └─ gh release upload  (raw + tar.gz + sha256 ×2)
```

## Error handling
- **Build/verify failure:** the job fails; no partial assets are uploaded for
  that target (package+upload is the last step, gated on verify). The release
  still stands with its CPAN tarball; binaries can be re-run.
- **Re-run idempotency:** upload with `--clobber` so re-running the workflow
  replaces same-named assets rather than erroring on "already exists".
- **arm64 runner availability:** assumes `Getty/karr` is a public repo (public
  arm64 runners are GA). If private, `ubuntu-24.04-arm` may need a larger-runner
  entitlement — a documented risk, resolved at implementation if it bites.

## Documentation & bookkeeping
- README: an "Install the binary" section (download, `chmod +x`, the runtime
  libs, the sha256 check).
- `Changes`: a `{{$NEXT}}` bullet.
- A karr board ticket tracks the work (dogfood).

## Testing strategy
- `scripts/build-binary.sh` is exercised by the workflow itself; the in-job
  verification (D) *is* the test that the artifact works. There is no unit test
  that meaningfully covers "a 23 MB binary runs on a bare box" — the real proof
  is running every subcommand + one libgit2 flow, which D does.
- The workflow can be dry-run before a real release by pushing a pre-release /
  manually dispatching against a throwaway tag, so the first real release is not
  the first time it runs. (Add `workflow_dispatch` with a tag input for this.)

## Open questions / risks
1. **Alien share-build time on arm64.** Compiling libgit2 from source per job
   adds minutes; acceptable for a release cadence. Cache `~/perl5`/Alien across
   runs if it becomes annoying (optimisation, not required).
2. **Transitive `.so` on unusual targets.** Musl/minimal targets will miss the
   libs; those users fall back to the CPAN install. Documented, not solved here.
3. **Repo visibility for arm64 runner** (see Error handling).
4. **README/VERSION content in the tarball** — minimal (name, version, one-line
   usage, runtime libs, link to the repo). Confirm at implementation.
```
