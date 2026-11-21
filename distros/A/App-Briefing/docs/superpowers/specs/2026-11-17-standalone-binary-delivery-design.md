# Standalone Binary Delivery Design

**Date:** 2026-11-17
**Status:** Approved

## Intent

Finish the existing `App::Briefing` PAR delivery path so the briefing plugin runs on its supported platforms without a system Perl or Python. Preserve the single Perl implementation of resolution, Doctor, and hook behavior, and make the plugin provision and execute only release binaries whose exact SHA-256 hashes are pinned in the plugin checkout.

The immediate user-visible result is that a normal online plugin installation provisions the platform binary during `SessionStart`; later hooks and CLI commands use the verified cached binary. Perl and Python may remain compatibility fallbacks, but they are no longer runtime requirements.

## Goals

- Deliver the existing Perl core as PAR binaries on the five current native CI runners:
  - Linux x86_64.
  - Linux arm64.
  - macOS x86_64.
  - macOS arm64.
  - Windows x86_64.
- Record the concrete runner image, operating-system version, architecture, and relevant ABI version for every release. Support follows those current runner versions; the product does not promise a fixed historic OS or ABI floor.
- Provision the correct release asset on first `SessionStart`, verify it against a repository-pinned SHA-256 value, warm its PAR extraction tree, and then execute it.
- Use the cached binary on later hook and CLI calls, including while offline.
- Replace the Windows Python launcher path with a native bootstrap that uses wide Win32 APIs and requires neither Perl, Python, nor PowerShell.
- Preserve the established hook contract for Claude Code and Codex.
- Prove the cutover with source tests, starter tests, clean-machine binary smoke tests, native Windows Unicode tests, and real harness positive/control runs.
- Make the release-to-plugin checksum handoff explicit, repeatable, and auditable.

## Non-goals

- Reimplement `App::Briefing` in Rust, Go, or another second core.
- Make PAR binaries fully static or remove their documented operating-system ABI dependencies.
- Add Windows arm64 or platforms outside the current five-runner matrix.
- Promise compatibility with an older operating-system or ABI version after the CI provider removes that version from the native runner matrix. Older systems may work, but are not supported without a separately added native proof target.
- Guarantee a fresh offline installation without any previously cached binary. A fresh install needs network access once; an already verified cache must work offline.
- Change skill resolution, hook semantics, Doctor semantics, or the source distribution's public CLI.
- Install plugin launchers from CPAN. CPAN continues to install only `script/briefing`.
- Modify the shared `winlaunch` source owned by the windows-developer repository.
- Publish a release, tag, bundle version, or binary asset without a separate explicit publish authorization.

## Anti-goals

- Never execute a downloaded binary before its bytes match a locally pinned SHA-256 value.
- Treat repository and release permissions as the publisher trust root, but pin every reusable binary workflow to a full immutable commit SHA. Mutable workflow tags such as `binary-v1` are not accepted for production publication.
- Never trust a checksum manifest downloaded from the same release as sufficient runtime authorization to execute that release.
- Never silently fall back to a partial briefing.
- Never add network or cache side effects to `hooks/briefing-preload`; provisioning remains a starter responsibility and occurs only for `SessionStart`.
- Never claim a platform is supported from a cross-build or Linux-hosted test alone.

## Current State

The current feature branch is an ancestor of `main`; `main` already contains the source port and later binary-delivery work. New work must start from current `main` rather than rebasing or merging unique feature commits.

On `main`, `dist.ini` and `.github/workflows/binaries.yml` describe PAR builds for the five target platforms. `bin/briefing` is a POSIX starter that checks a cache, provisions only during `SessionStart`, and otherwise falls back to Python for hooks or Perl for the source CLI. Claude Code and Codex hooks already route through that starter.

The route is not active in a release installation because `bin/briefing-binaries.sha256` is absent. Windows still routes `bin/briefing.exe` through winlaunch to Python. The starter also constructs the Windows asset name without the required `.exe` suffix, and its tests skip Windows.

## Approaches Considered

### 1. Finish the existing PAR route — selected

Keep `App::Briefing` as the single implementation and complete the existing starter, pinning, Windows bootstrap, release handoff, and native verification.

This is the smallest change, reuses the existing build and smoke scripts, and matches the documented Perl direction. Its costs are PAR extraction, user cache writes, operating-system ABI dependencies, and the need to measure cold provisioning carefully.

### 2. Install a portable Perl runtime bundle

Ship a relocatable Perl, modules, and `script/briefing` as an extracted directory per platform. This avoids PAR extraction during hook startup and is easier to inspect, but produces larger artifacts and introduces a substantially harder relocation, DLL/dylib, signing, and update problem on every platform.

### 3. Add a native Rust or Go core

A second implementation could be smaller and faster at runtime, but it would duplicate the resolver and hook contract and create permanent parity risk. It conflicts with the existing single-Perl-core direction and is not justified while the PAR route is already substantially implemented.

## Design

### 1. Work from current `main`

Fast-forward the existing feature branch to `main` before implementation. Keep the work in the existing checkout. The existing karr card `k7` owns the work and should move from backlog to active work when implementation begins.

### 2. Treat the tracked pin file as the execution authority

Add a tracked `bin/briefing-binaries.sha256` in a strict SHA256SUMS-compatible form. It contains exactly five canonical lines, one for each supported platform, all for one version equal to `$App::Briefing::VERSION`. The committed form uses lowercase hexadecimal hashes, two ASCII spaces before the asset name, LF line endings, and the canonical order below. The import path may read CRLF input but normalizes it to this committed form. Both importer and runtime reject malformed hashes, duplicate names, duplicate platforms, mixed or unexpected versions, missing entries, extra entries, absolute paths, and non-canonical asset names.

Asset naming is canonical and includes `.exe` for Windows:

- `briefing-<version>-linux-x86_64`
- `briefing-<version>-linux-arm64`
- `briefing-<version>-macos-x86_64`
- `briefing-<version>-macos-arm64`
- `briefing-<version>-windows-x86_64.exe`

The starter selects only an exact supported name from this file. It does not accept aliases, wildcard versions, unexpected extra platforms, or a remote checksum as authority. A downloaded file is executed only after hashing the complete temporary file and matching the tracked value. A cached executable is rehashed before every execution.

Add a release-maintainer command or script that imports the binary workflow's `SHA256SUMS`, validates that it contains exactly the expected assets and version, and writes the tracked pin file deterministically. The binary workflow reference is a reviewed full commit SHA, not a mutable tag. The release evidence records the briefing source commit, the workflow commit, runner image/version, and resulting asset hashes. Repository and release permissions are the selected trust root; artifact attestations, external signatures, and independent rebuilds are outside this scope.

The handoff is intentionally two-phase:

1. Under separate publish authorization, build and publish the immutable binary assets and `SHA256SUMS` for a release.
2. Import those exact published hashes into the plugin checkout, review the diff, and commit the pin update. Only the plugin state containing that pin is considered binary-enabled.

The runtime never downloads and trusts a new checksum manifest on its own. If publication is not authorized during implementation, tests use fixtures and the work stops before the release step with the required command and evidence documented.

### 3. Keep POSIX provisioning narrow and fail safe

Retain `bin/briefing` as the POSIX starter and make its platform table and asset extension handling explicit. Provisioning remains limited to `hook session-start`; `--version`, Doctor, and spawn hooks do not initiate network activity.

The POSIX starter may rely on native operating-system tools supplied by the current runner image: `sh`, `curl` or `wget`, and a native SHA-256 implementation. Linux uses native `sha256sum`; macOS uses a natively compiled `openssl` SHA-256 path and never `shasum`, because `shasum` itself requires Perl. The native matrix verifies the exact commands used. A missing required tool fails safely and may use an already available compatibility runtime, but does not weaken verification.

The provisioner:

1. Finds the exact platform asset and pinned hash.
2. Creates versioned cache directories private to the current user (`0700`) under `umask 077`, rejects symlinked cache components, and creates a per-process temporary file exclusively.
3. Downloads only over HTTPS from the configured release location. Redirects may change hosts only while remaining HTTPS; TLS downgrade is rejected.
4. Enforces a 256 MiB maximum asset size through the downloader where supported and always rejects an oversized completed file before hashing or execution.
5. Verifies SHA-256 before adding execute permission or moving the file into place.
6. Atomically installs the verified file with mode `0700`.
7. Sets a stable, versioned `PAR_GLOBAL_TEMP` and performs one warm-up execution within the `SessionStart` budget.
8. Re-verifies and executes the cached binary on subsequent calls.

Production accepts only HTTPS. Tests may use local HTTP or `file://` fixtures only when an explicit test-only switch is set by the test harness; production behavior and release tests run with that switch absent.

A failed download, missing tool, wrong hash, unsupported platform, or interrupted install never leaves an executable trusted cache entry. Existing Perl/Python compatibility fallbacks may remain for systems that have them. Without a fallback runtime, hook invocations retain the established safe warning/exit behavior rather than executing unverified content.

### 4. Add a briefing-owned native Windows bootstrap

Do not change the shared `winlaunch` source. Keep the existing `bin/briefing.exe` as the generic winlaunch copy, but change the adjacent `bin/briefing` directive to execute a new plugin-relative `bin/briefing-bootstrap.exe`. Generic relative execution is already supported by winlaunch.

The new bootstrap has source and reproducible build/test instructions in this repository, separate from `winlaunch/`. It uses wide Win32 APIs throughout:

- Resolve plugin and cache paths from the executable location and `CLAUDE_CONFIG_DIR`; when the variable is absent, use `%USERPROFILE%\.claude`. Reject relative configuration paths.
- Parse the strict tracked pin file and select `briefing-<version>-windows-x86_64.exe` exactly.
- Create cache directories with a DACL limited to the current user, reject reparse-point cache components, and create per-process temporary files exclusively.
- Download with WinHTTP over HTTPS, permitting cross-host HTTPS redirects but no TLS downgrade, with a 256 MiB maximum asset size.
- Hash with BCrypt SHA-256.
- Install verified bytes atomically with wide filesystem APIs and a final destination verification.
- Rehash cached binaries before every execution.
- Set the versioned `PAR_GLOBAL_TEMP`.
- Start the verified PAR binary with `CreateProcessW`, correct Windows argument quoting, inherited stdin/stdout/stderr, and the original exit code.

The bootstrap may invoke the existing Python compatibility path only after verified provisioning is unavailable and only when Python is actually present. Python is not required for the normal or tested standalone path.

Build checks must distinguish the generic `bin/briefing.exe` winlaunch copy from the new bootstrap executable; the current byte-identity assertion for every `bin/*.exe` must no longer classify the bootstrap as winlaunch.

### 5. Preserve hook and distribution boundaries

`hooks/briefing-preload` stays read-only and side-effect-free. Claude Code continues to use `PreToolUse` only as a deny/empty guard and `SubagentStart` for `additionalContext`; Codex keeps `additionalContextLimit: 0`. No prompt rewriting or partial briefing is introduced.

`dist.ini` continues to exclude plugin-only `bin/` launchers from the CPAN installation and installs only `script/briefing`. Binary verification compares the packaged executable with that source CLI and rejects unwanted TLS modules exactly as the current scripts intend.

### 6. Verify cold provisioning before calling the cutover complete

Measure, do not infer, download plus hash plus first PAR extraction on every current target runner. Three independent cold native runs per platform must each finish within 75 seconds, leaving at least 15 seconds of the configured 90-second `SessionStart` timeout. If any supported platform misses that gate, stop the cutover and revisit install-time extraction or the timeout explicitly; do not hide the failure behind a compatibility fallback.

The binary hook-latency card `k6` remains separate from correctness unless measurements show that the selected delivery design cannot meet the startup contract.

## Test Strategy

### Source and contract tests

- `prove -lr t`
- Python hook contract tests against both the retained Python reference and the Perl CLI.
- Shell syntax checks for starters and binary scripts.
- `dzil build` and `dzil test`.
- Inspect the generated install list to prove CPAN installs `script/briefing` but no plugin launchers.

### Starter and trust tests

Use fixture assets and a local test server to cover:

- Exact platform and extension selection, including Windows `.exe`.
- Valid first provision and cache hit.
- Wrong hash, changed cached bytes, truncated download, interrupted install, unavailable network, missing downloader, and concurrent provision attempts.
- No execution before verification.
- No download from commands other than `hook session-start`.
- Offline execution from an already verified cache.
- Deterministic checksum import and rejection of missing, duplicate, renamed, or extra assets.

### Native platform smoke tests

For every target, run the packaged binary on the current native CI runner in a clean environment with no external Perl or Python and exercise version, help, Doctor, hook events, ASCII paths, Unicode paths, invalid input, and missing-skill behavior. Each release records the exact runner image and OS/ABI versions used; support moves with that recorded runner matrix rather than claiming an untested historical floor.

On native Windows x86_64, additionally test the complete `bin/briefing.exe` to `briefing-bootstrap.exe` to cached PAR chain with:

- Empty runtime `PATH` except unavoidable operating-system components.
- Unicode plugin, cache, and working-directory paths.
- UTF-8 JSON through stdin and preserved stdout/stderr.
- `doctor --tsv --cwd` with a non-ANSI path passed through argv.
- Cache tampering and failed downloads.

A Linux-hosted unit test or cross-build is not Windows proof.

### Live harness verification

After all local and CI checks are green, run the documented positive/control checks in real Claude Code and Codex installations on native Windows x86_64 and on at least one current native POSIX runner. Verify that declared skill bodies arrive only through `additionalContext`, unknown skills follow the guard/abort contract, Agent input is unchanged, the Windows harness actually traverses the `.exe` bootstrap path, and the loaded plugin copy is the binary-enabled version.

## Delivery Sequence

1. Update the working branch to current `main` and establish a green baseline.
2. Add regression tests for pin import, platform naming, trust failures, and Windows wiring.
3. Correct POSIX starter asset handling and add the deterministic pin-import path.
4. Implement and test the briefing-owned native Windows bootstrap.
5. Run source, distribution, starter, and native binary verification across the five-platform matrix.
6. Measure cold provisioning and hook latency; resolve any timeout failure before cutover.
7. Run real Claude Code and Codex positive/control verification.
8. Have the briefing reviewer independently verify the uncommitted implementation diff and all checks that do not require publication.
9. Have the release manager update `Changes` and commit that reviewed implementation, but keep `k7` open and blocked at the publish gate.
10. Stop for explicit authorization naming every required external action: publishing the bundle workflow commit/tag, pushing repository commits, creating the briefing release, and uploading binary assets.
11. Once authorized, publish the exact assets through the commit-SHA-pinned workflow, import their real hashes, rerun native and live-harness verification against the published bytes, review and commit the pin update, and only then close `k7`.

## Acceptance Criteria

The work is complete only when:

- All five canonical assets build with the exact expected names and pass their native clean-machine smoke tests on the current recorded CI runners.
- The binary workflow is referenced by a reviewed full commit SHA, and release evidence records source commit, workflow commit, runner versions, and asset hashes.
- A normal online first session provisions and warms the correct verified asset without Perl or Python, using only the explicitly allowed native POSIX tools or the native Windows bootstrap.
- Later hooks and CLI calls use the reverified cache and work offline.
- Windows uses the native bootstrap and passes Unicode argv, cwd, stdin, and filesystem tests without Perl, Python, or PowerShell.
- Wrong or absent pins, tampered cache files, corrupt downloads, and unsupported platforms never execute unverified code.
- Three cold provisioning runs on every current native runner each finish within 75 seconds.
- Source, contract, distribution, and starter suites are green, with no skipped platform proof described as a pass.
- Real Claude Code and Codex positive/control runs confirm the hook contract.
- The release-to-pin procedure is deterministic and documented.
- Any actual release, upload, tag, push, or external bundle publication has separate explicit authorization and recorded evidence.
