# karr binary release — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the `karr` CLI as a downloadable single-file binary (raw + `.tar.gz`, each with a `.sha256`) for Linux x86_64 and arm64, attached to every GitHub release.

**Architecture:** Two committed shell scripts (`scripts/build-binary.sh`, `scripts/verify-binary.sh`) encapsulate the verified `pp` build and the smoke test, so the same steps run locally and in CI. A GitHub Actions workflow (`.github/workflows/release-binaries.yml`) triggers on a published release, builds each target in an old-glibc container on a native runner, verifies, packages, and uploads assets to that release. The `dzil release` flow and the `[@Author::GETTY]` bundle are untouched.

**Tech Stack:** Perl 5.40, PAR::Packer (`pp`), Alien::Libgit2 (share build), FFI::Platypus/libgit2, GitHub Actions, bash.

**Spec:** `docs/superpowers/specs/2026-09-14-karr-binary-release-design.md`

## Global Constraints

- Targets: **Linux x86_64** and **Linux arm64**, glibc dynamic build only. No macOS, Windows, or musl/static.
- Build container: **`perl:5.40-bookworm`** (glibc 2.36, multi-arch) on both runners; x86_64 on `ubuntu-latest`, arm64 on `ubuntu-24.04-arm`.
- `Alien::Libgit2` MUST be an **`ALIEN_INSTALL_TYPE=share`** build in the build environment, or the binary's FFI `dlopen` fails on the target.
- `pp` invariants (from `.claude/skills/karr-single-binary/references/pp-recipe.md`): **`PAR_VERBATIM=1`**; globs `-M 'App::karr::**' -M 'App::karr::Cmd::**' -M 'MooX::Cmd::**' -M 'MooX::Options::**' -M 'Git::Native::**' -M 'Git::Libgit2::**' -M 'FFI::Platypus::**'`; `-a "$DISTDIR;lib/auto/share/dist/Alien-Libgit2"`; only `-M` a JSON backend that is actually installed.
- Asset names: `karr-<v>-linux-<arch>` and `karr-<v>-linux-<arch>.tar.gz` (+ `.sha256` each), where `<v>` is the release tag without a leading `v`, `<arch>` in {`x86_64`, `arch64`→`arm64`}.
- Trigger: `on: release: { types: [published] }` plus `workflow_dispatch` (a `tag` input) for dry-runs. Upload with `--clobber` for idempotent re-runs.
- Runtime requirement documented for downloaders: target must have libssl, libcrypto, libssh2, libz, libzstd.
- No change to `lib/`, `bin/`, `dist.ini`, or the release machinery. **Never run `dzil release`.** Pushing the branch and dispatching CI is outward-facing — get the maintainer's OK before the first push (Task 3).
- This is build/release infrastructure, not karr behaviour: no `.pm` under `lib/` is touched, so no POD/ABSTRACT work. If any `.pm` ever needs touching, POD/ABSTRACT stay ASCII.

---

### Task 1: `scripts/build-binary.sh` — the pp build, locally verified

**Files:**
- Create: `scripts/build-binary.sh`
- Verify against: `bin/karr`, `lib/App/karr/**`, `.claude/skills/karr-single-binary/references/pp-recipe.md`

**Interfaces:**
- Consumes: a build environment with perl, a share-build `Alien::Libgit2`/`Git::Native`, and `PAR::Packer` on `PATH`/`PERL5LIB`. Run from the checkout root.
- Produces: an executable at `$KARR_BIN_OUT` (default `./karr`). Task 2/3 call this script; Task 2's verify step (Task 1 also uses it) consumes the produced binary.

**Notes for the implementer (zero-context):** karr loads its 33 `App::karr::Cmd::*` classes dynamically, so `pp`'s static scanner misses them — hence the namespace globs. libgit2 is opened by FFI `dlopen` at runtime, so the Alien share dir must be bundled with `-a`. `PAR_VERBATIM=1` disables PodStrip, which otherwise corrupts karr's interleaved `=func`/`=method` POD and makes every command die at startup. All three are non-negotiable; see the pp-recipe reference.

- [ ] **Step 1: Ensure PAR::Packer is available without polluting `~/perl5`**

Run (local dev; CI installs it in the container instead):
```bash
cpanm -l /tmp/karrbuild/parlib PAR::Packer
export PATH=/tmp/karrbuild/parlib/bin:$PATH
export PERL5LIB=/tmp/karrbuild/parlib/lib/perl5:${PERL5LIB:-}
```
Expected: `pp --version` prints a version.

- [ ] **Step 2: Write `scripts/build-binary.sh`**

```bash
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

PAR_VERBATIM=1 pp -o "$OUT" \
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
```
Then: `chmod +x scripts/build-binary.sh`.

- [ ] **Step 3: Build the binary locally**

Run: `KARR_BIN_OUT=/tmp/karrbuild/karr ./scripts/build-binary.sh`
Expected: prints `Built /tmp/karrbuild/karr (~23M)` and exits 0. If it prints the install_type error, reinstall Alien::Libgit2 share into an isolated lib per the pp-recipe preconditions and retry.

- [ ] **Step 4: Sanity-check startup from a fresh cache**

Run: `PAR_GLOBAL_TEMP="$(mktemp -d)" /tmp/karrbuild/karr --version`
Expected: prints the karr version, exit 0. (Full trap coverage is Task 2.) A `did not return a true value` here means `PAR_VERBATIM=1` was dropped.

- [ ] **Step 5: Commit**

```bash
git add scripts/build-binary.sh
git commit -m "build: scripts/build-binary.sh packs karr with pp

Encapsulates the verified pp invocation (PAR_VERBATIM, the dynamic-Cmd-class
and framework globs, the Alien::Libgit2 share dir) so the binary builds the
same way locally and in CI. Refuses a system-build Alien::Libgit2 up front."
```

---

### Task 2: `scripts/verify-binary.sh` — smoke-test both pp traps

**Files:**
- Create: `scripts/verify-binary.sh`

**Interfaces:**
- Consumes: a built binary path (arg 1), produced by `scripts/build-binary.sh`.
- Produces: exit 0 iff every subcommand loads and a real libgit2 board flow succeeds. Task 3's CI job calls this before uploading.

**Notes:** Two traps only surface at runtime — a missing `Cmd::*` class (subcommand dies when first called) and a libgit2/FFI break (any board op dies). The verify must therefore load every subcommand and run one real board flow, in a throwaway repo (never the checkout, whose `refs/karr/*` is the live board).

- [ ] **Step 1: Confirm the exact subcommand list and flow signatures**

Run: `/tmp/karrbuild/karr --help` and, for the flow commands, `/tmp/karrbuild/karr create --help`, `move --help`, `handoff --help`, `backup --help`, `destroy --help`.
Expected: note the real flag names (e.g. how `create` reports the new id, the `destroy` confirmation flag). Use these exact forms in Step 2. The command list to load is the "Commands (current)" table in `CLAUDE.md`.

- [ ] **Step 2: Write `scripts/verify-binary.sh`**

```bash
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
           set-refs get-refs disable enable; do
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
)
echo "trap2 (libgit2 board flow): OK"
echo "verify: OK"
```
Then: `chmod +x scripts/verify-binary.sh`. Adjust the id-extraction and any flag to match what Step 1 showed.

- [ ] **Step 3: Run the verify against the locally built binary**

Run: `./scripts/verify-binary.sh /tmp/karrbuild/karr`
Expected: prints `trap1 ... OK`, `trap2 ... OK`, `verify: OK`, exit 0. A failure on a single subcommand means that `Cmd::*` class needs its namespace covered by a glob in `build-binary.sh` (it already uses `App::karr::Cmd::**`, so this should pass — if not, that is the signal).

- [ ] **Step 4: Commit**

```bash
git add scripts/verify-binary.sh
git commit -m "build: scripts/verify-binary.sh smoke-tests the packed binary

Loads every dynamically-resolved subcommand (trap 1) and runs one real
libgit2 board flow in a throwaway repo (trap 2), the two failures a pp build
only shows at runtime. CI gates asset upload on this."
```

---

### Task 3: `.github/workflows/release-binaries.yml` — build the matrix and attach assets

**Files:**
- Create: `.github/workflows/release-binaries.yml`
- Reference: `.github/workflows/ci.yml` (existing patterns — container, checkout, safe.directory)

**Interfaces:**
- Consumes: `scripts/build-binary.sh`, `scripts/verify-binary.sh`, a published release (or a `workflow_dispatch` tag input).
- Produces: four assets per target on the release.

**Notes:** The release event fires because `dzil release` creates the release with the maintainer's PAT, not a workflow `GITHUB_TOKEN`. The build container is the official multi-arch `perl:5.40-bookworm`; its perl is source-built so PAR::Packer's `libperl-dev` need is already satisfied (no Debian shim needed). The Alien share build compiles libgit2 from source, so the container needs `cmake` + build-essential.

- [ ] **Step 1: Write the workflow**

```yaml
name: release-binaries
on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      tag:
        description: Existing tag to build and attach assets to (dry-run)
        required: true
permissions:
  contents: write
jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          - arch: x86_64
            runner: ubuntu-latest
          - arch: arm64
            runner: ubuntu-24.04-arm
    runs-on: ${{ matrix.runner }}
    container:
      image: perl:5.40-bookworm
    env:
      TAG: ${{ github.event.release.tag_name || inputs.tag }}
    steps:
      - name: Install system build deps
        run: apt-get update && apt-get install -y cmake build-essential git jq
      - uses: actions/checkout@v5
        with:
          ref: ${{ env.TAG }}
      - name: Fix safe.directory
        run: git config --global --add safe.directory "$GITHUB_WORKSPACE"
      - name: Install Perl deps (Alien share build + PAR::Packer)
        env:
          ALIEN_INSTALL_TYPE: share
        run: |
          cpanm --notest --installdeps .
          cpanm --notest Alien::Libgit2 Git::Libgit2 Git::Native
          cpanm --notest PAR::Packer
      - name: Compute version
        id: v
        run: echo "v=${TAG#v}" >> "$GITHUB_OUTPUT"
      - name: Build binary
        env:
          KARR_BIN_OUT: karr-${{ steps.v.outputs.v }}-linux-${{ matrix.arch }}
        run: ./scripts/build-binary.sh
      - name: Verify binary
        run: ./scripts/verify-binary.sh "karr-${{ steps.v.outputs.v }}-linux-${{ matrix.arch }}"
      - name: Record runtime libs
        run: |
          LG=$(perl -MAlien::Libgit2 -e 'print +(Alien::Libgit2->dynamic_libs)[0]')
          ldd "$LG" | tee runtime-libs-${{ matrix.arch }}.txt
      - name: Package
        id: pkg
        run: |
          base="karr-${{ steps.v.outputs.v }}-linux-${{ matrix.arch }}"
          mkdir -p "pkg/$base"
          cp "$base" "pkg/$base/karr"
          cp LICENSE "pkg/$base/LICENSE"
          printf 'karr %s (linux-%s)\nRuntime libs required on target: libssl libcrypto libssh2 libz libzstd\nhttps://github.com/Getty/karr\n' \
            "${{ steps.v.outputs.v }}" "${{ matrix.arch }}" > "pkg/$base/README"
          tar -C pkg -czf "$base.tar.gz" "$base"
          sha256sum "$base" > "$base.sha256"
          sha256sum "$base.tar.gz" > "$base.tar.gz.sha256"
      - name: Upload assets to the release
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          base="karr-${{ steps.v.outputs.v }}-linux-${{ matrix.arch }}"
          gh release upload "$TAG" \
            "$base" "$base.sha256" \
            "$base.tar.gz" "$base.tar.gz.sha256" \
            --clobber --repo "$GITHUB_REPOSITORY"
```

- [ ] **Step 2: Lint the workflow YAML**

Run: `perl -MYAML::XS -e 'YAML::XS::LoadFile(shift)' .github/workflows/release-binaries.yml` (or `actionlint` if installed).
Expected: no parse error. Fix indentation/quoting until it loads.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/release-binaries.yml
git commit -m "ci: release-binaries workflow builds linux x86_64/arm64 binaries

On a published release (or workflow_dispatch dry-run), builds karr with pp in
a perl:5.40-bookworm container on native x86_64/arm64 runners, verifies both
pp traps, and uploads the raw binary + .tar.gz + sha256 to the release. No
change to the dzil release flow or the @Author::GETTY bundle."
```

- [ ] **Step 4: Dry-run on CI (needs maintainer OK — outward-facing)**

Pre-req: maintainer approves pushing the branch. Then:
```bash
git push -u origin binary-release
```
Create a throwaway tag/pre-release, or use an existing tag, and dispatch:
```bash
gh workflow run release-binaries.yml -f tag=<existing-or-test-tag>
gh run watch
```
Expected: both matrix jobs (x86_64, arm64) go green; the four assets per arch appear on the release. Inspect `runtime-libs-*.txt` in the logs to confirm the documented `.so` list is accurate; correct the README/spec if it drifts. If the arm64 runner is unavailable (private repo), note it and resolve per the spec's risk item. Delete the throwaway tag/pre-release and its assets afterward.

---

### Task 4: Documentation and board bookkeeping

**Files:**
- Modify: `README` / `README.pod` or `lib/App/karr.pm` POD (whichever holds the user-facing README — check which the dist gathers)
- Modify: `Changes`

**Interfaces:** none (docs only).

- [ ] **Step 1: Find where the README lives**

Run: `ls README* ; grep -rl "=head1" lib/App/karr.pm | head`
Expected: identifies the file the built dist ships as README. If it is POD in `lib/App/karr.pm`, keep ASCII.

- [ ] **Step 2: Add an "Install the binary" section**

Content to add (adapt heading style to the file):
```
Prebuilt Linux binaries are attached to each GitHub release
(https://github.com/Getty/karr/releases): karr-<version>-linux-x86_64 and
-linux-arm64, as a raw binary and a .tar.gz, each with a .sha256. Download,
verify (sha256sum -c), chmod +x, and run -- no Perl or CPAN needed. The
target must have the usual system libraries libssl, libcrypto, libssh2,
libz, and libzstd. The binary is ~23 MB and starts slower than the CPAN
install (~450 ms vs ~300 ms); it is for distribution, not speed.
```

- [ ] **Step 3: Add the `Changes` bullet under `{{$NEXT}}`**

```
    - Prebuilt Linux x86_64/arm64 binaries are now attached to each GitHub
      release (raw + .tar.gz + sha256), built with PAR::Packer -- run karr
      with no Perl or CPAN install. Distribution only; not faster than the
      CPAN install (kNNN).
```
Replace `kNNN` with the tracking ticket id from Step 5.

- [ ] **Step 4: Commit**

```bash
git add README* lib/App/karr.pm Changes
git commit -m "docs: document the prebuilt binary downloads"
```

- [ ] **Step 5: File the tracking ticket on the board (dogfood)**

Run (only if not already created by the orchestrator):
```bash
karr create "Ship karr binary at release (linux x86_64/arm64)" \
  --priority normal --tags release,binary,ci \
  --body 'Implements docs/superpowers/specs/2026-09-14-karr-binary-release-design.md and .../plans/2026-09-14-karr-binary-release.md.'
```
Put the returned id into the Task 4 Step 3 `Changes` bullet.

---

## Self-Review

**Spec coverage:**
- Decision 1 (release-triggered workflow, no bundle change) → Task 3.
- Decision 2 (build recipe as repo script) → Task 1.
- Decision 3 (old-glibc container) → Task 3 `perl:5.40-bookworm`.
- Decision 4 (native arm64 runner) → Task 3 matrix.
- Architecture A (build-binary.sh) → Task 1; B (workflow) → Task 3; C (asset layout) → Task 3 Package/Upload; D (verification) → Task 2 + Task 3 Verify step.
- Runtime requirements doc → Task 3 Step 4 (ldd capture) + Task 4 Step 2.
- Documentation & bookkeeping → Task 4.
- Testing strategy (in-job verify, workflow_dispatch dry-run) → Task 2 + Task 3 Step 4.

**Placeholder scan:** No "TBD/TODO". `kNNN` in Task 4 is a deliberate cross-reference resolved in Task 4 Step 5. Task 2 Step 1 / Task 4 Step 1 are real discovery steps (confirm CLI signatures / README location), not placeholders.

**Type consistency:** Script names (`scripts/build-binary.sh`, `scripts/verify-binary.sh`), the `KARR_BIN_OUT` contract, and the asset base name `karr-<v>-linux-<arch>` are used identically across Tasks 1–4.

**Known soft spots the executor must close, not skip:** the exact `create`/`list`/`move` flag forms in `verify-binary.sh` (Task 2 Step 1 confirms them), and the real README location (Task 4 Step 1).
