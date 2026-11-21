# Standalone Binary Delivery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the briefing plugin provision and run verified PAR binaries on its five current native CI runners without requiring system Perl or Python.

**Architecture:** Keep `App::Briefing` as the single product core. A strict tracked SHA-256 manifest authorizes release assets; the POSIX shell starter and a new briefing-owned Windows C bootstrap provision, reverify, cache, and execute the matching PAR binary. Existing Python and Perl paths remain compatibility fallbacks, while native tests and real harness checks prove that the normal path does not require either runtime.

**Tech Stack:** Perl 5/App::Briefing, PAR::Packer, POSIX shell, Python 3 standard-library `unittest` drivers, C/Win32 (`WinHTTP`, `BCrypt`, wide APIs), Zig `0.13.0` via `ziglang==0.13.0.post1`, GitHub Actions, Dist::Zilla.

**Spec:** `docs/superpowers/specs/2026-11-17-standalone-binary-delivery-design.md`

## Global Constraints

- Start from current `main`; the original feature branch has no commits not already in `main`.
- Work in the existing checkout. Do not create an isolated worktree unless the maintainer explicitly changes that decision.
- Repository content is English.
- `App::Briefing` remains the only resolver, Doctor, and hook implementation shipped in the binary.
- `hooks/briefing-preload` remains read-only, idempotent, side-effect-free, and Python 3.8+ standard-library-only.
- Only `hook session-start` may provision a binary. `--version`, Doctor, and spawn hooks never initiate network activity.
- Claude Code keeps `PreToolUse` as deny/empty only and injects at `SubagentStart`; Codex keeps `additionalContextLimit: 0`.
- The production manifest contains exactly five canonical entries, one shared version equal to `$App::Briefing::VERSION`, lowercase hashes, two ASCII spaces, LF endings, and canonical order.
- Canonical assets are `briefing-<version>-linux-x86_64`, `briefing-<version>-linux-arm64`, `briefing-<version>-macos-x86_64`, `briefing-<version>-macos-arm64`, and `briefing-<version>-windows-x86_64.exe`.
- Current native CI runner versions define support. Every release records runner image, OS, architecture, and relevant ABI; no fixed historical OS floor is promised.
- Production downloads are HTTPS-only, allow no TLS downgrade, and have a 256 MiB maximum asset size.
- POSIX may use native `sh`, `curl`/`wget`, Linux `sha256sum`, and macOS native `openssl`; never use Perl-backed `shasum` for the no-Perl path.
- Windows uses a briefing-owned bootstrap with wide Win32 APIs, WinHTTP, BCrypt, private DACLs, reparse-point rejection, and `CreateProcessW`. Do not modify shared `winlaunch` source.
- The reusable binary workflow is referenced by a full reviewed commit SHA, never `binary-v1` or another mutable ref.
- Three independent cold provisions on each current native runner must each complete in at most 75 seconds.
- Fresh offline installation is not promised. An already verified cache must work offline.
- CPAN installs only `script/briefing`; plugin launchers under `bin/` stay excluded.
- Workers and test writers never commit. The reviewer checks the complete uncommitted diff; only `briefing-release-manager` makes authorized commits and updates `Changes`.
- Do not publish, push, tag, upload assets, release the external bundle, or run an outward-facing release action without separate explicit authorization naming that action.
- Keep `k7` open until published assets, real pins, native evidence, and live harness evidence all exist. A local implementation commit is not completion.

## Review Focus

1. **Malformed or mixed-version pin input:** importer and both starters must reject missing, duplicate, extra, renamed, path-bearing, mixed-version, malformed, and oversized manifests without selecting or executing a binary. Covered in Tasks 2, 3, and 6.
2. **User-cache path attacks:** symlinked POSIX components and Windows reparse points must not redirect writes; cache directories/files must be private. Covered in Tasks 4 and 6.
3. **Interrupted or concurrent provisioning:** partial, colliding, tampered, oversized, or wrong-hash downloads must never become trusted executables; concurrent success must converge on one verified cache entry. Covered in Tasks 4 and 6.
4. **Windows process fidelity:** Unicode argv/cwd, UTF-8 stdin/stdout/stderr, environment, quoting, and child exit status must survive `winlaunch -> bootstrap -> PAR` unchanged. Covered in Tasks 5 and 6.
5. **Mutable or mismatched release provenance:** CI must reject mutable workflow refs, pins that do not match the released version, and a release lacking recorded source/workflow/runner evidence. Covered in Tasks 7, 10, and 11.

---

## File Structure

### Create

- `scripts/import-binary-sums.py` — validate an authorized release `SHA256SUMS` file and atomically render the canonical tracked pin manifest.
- `tests/test_binary_pins.py` — black-box importer and committed-manifest contract tests.
- `briefing-bootstrap/briefing-bootstrap.c` — Windows-only cache, download, verification, fallback, and child-process bootstrap.
- `briefing-bootstrap/build.py` — reproducible Zig PE build using the same pinned toolchain contract as `winlaunch/build.py`.
- `briefing-bootstrap/README.md` — source ownership, build command, APIs used, and native verification boundary.
- `tests/test_briefing_bootstrap.py` — native Windows black-box tests for the bootstrap.
- `tests/fixtures/briefing-bootstrap-stub.c` — native child fixture that reports argv/environment/stdin and returns a requested exit code.
- `tests/test_binary_workflow.py` — static workflow, immutable-ref, matrix, and distribution-boundary tests.
- `bin/briefing-bootstrap.exe` — reproducibly built Windows x86_64 bootstrap; not a winlaunch copy.
- `bin/briefing-binaries.sha256` — created only in the publish-gated phase from the actual released assets, never populated with fixture hashes.

### Modify

- `bin/briefing` — strict pin parsing, native POSIX hashing, HTTPS/test-mode boundary, secure cache/provisioning, `.exe` naming, and Windows winlaunch directive.
- `tests/test_starter.py` — canonical five-entry fixtures and POSIX trust/cache/concurrency regressions.
- `tests/test_windows_wiring.py` — distinguish generic winlaunch executables from the briefing bootstrap and cover Codex wiring.
- `.cicd/python+3.12+test.winlaunch.sh` — compare only generic launchers with winlaunch and build/compare the bootstrap separately.
- `.github/workflows/binaries.yml` — pin the external reusable workflow to a full commit SHA.
- `.github/workflows/test.yml` — run pin importer, starter, workflow, and shell/static checks.
- `.github/workflows/ci.yml` — build and run the bootstrap tests on native Windows; preserve source-distribution checks.
- `dist.ini` — keep `bin/` excluded and align binary comments/configuration with canonical Windows `.exe` naming.
- `scripts/binary-smoke.sh` — retain runtime smoke coverage and emit the runner/OS/architecture evidence required by the release workflow if the external workflow does not already capture it.
- `.claude/skills/briefing-core/SKILL.md` — after verified cutover, replace transitional Python-launcher statements with the actual binary/fallback contract.
- `README.md`, `docs/perl-direction.md` — document supported runner policy, provisioning, trust root, cache, fallbacks, and limitations.
- `Changes` — release-manager-owned summary after independent review.

### Must Not Change

- `winlaunch/winlaunch.c`
- `winlaunch/build.py`
- `winlaunch/test_winlaunch.py`

The existing relative-program test already proves that generic winlaunch can execute `bin/briefing-bootstrap.exe`.

---

### Task 1: Establish the Current Main Baseline and Activate k7

**Owner:** Main coordinator; release manager only for the approved design/plan commit.

**Files:**
- Existing: `docs/superpowers/specs/2026-11-17-standalone-binary-delivery-design.md`
- Existing: `docs/superpowers/plans/2026-11-17-standalone-binary-delivery.md`

**Interfaces:**
- Consumes: `main` at or after `be2b19df145dd64144e8a50b10e8f11c3c3e51d2`.
- Produces: current feature branch fast-forwarded to `main`, a claimed active `k7`, green baseline evidence, and committed approved planning documents.

- [ ] **Step 1: Verify that the working branch has no unique commits and only the approved docs are uncommitted**

Run:

```sh
git status --short
git rev-list --left-right --count main...HEAD
git merge-base main HEAD
```

Expected before update: `main...HEAD` reports main ahead and HEAD ahead by `0`; status lists only the design and plan documents.

- [ ] **Step 2: Fast-forward the existing feature branch to current `main`**

Run:

```sh
git merge --ff-only main
```

Expected: fast-forward succeeds; no merge commit is created; the untracked/modified planning documents remain.

- [ ] **Step 3: Promote and claim k7 with serialized board writes**

Run one command at a time:

```sh
export KARR_CLAIM=$(karr agent-name)
karr move k7 todo
karr move k7 in-progress
karr edit k7 -a "Approved design: docs/superpowers/specs/2026-11-17-standalone-binary-delivery-design.md; implementation plan: docs/superpowers/plans/2026-11-17-standalone-binary-delivery.md"
```

Expected: `k7` is `in-progress`, held by the current checkout claim, and remote board synchronization succeeds after every write.

- [ ] **Step 4: Run the green local baseline**

Run:

```sh
export PERL5LIB="$PWD/.build-deps/lib/perl5${PERL5LIB:+:$PERL5LIB}"
prove -lr t
python3 -m py_compile hooks/briefing-preload hooks/briefing-marketplace-notice
sh -n bin/briefing bin/briefing-doctor
bash -n scripts/binary-lib.sh scripts/binary-pp-args.sh scripts/binary-smoke.sh scripts/binary-verify.sh
python3 -m unittest discover tests -v
python3 hooks/briefing-preload doctor --cwd . --harness both
DZIL_BINARY_SKIP=1 dzil build
DZIL_BINARY_SKIP=1 dzil test
```

Expected: every command passes. Record every skip exactly; a skipped native platform is not proof. If a baseline command fails, stop and send `k7` a note before assigning implementation.

- [ ] **Step 5: Have the release manager commit only the approved design and plan**

The release manager reviews the two docs, uses the repository commit style, and commits no behavior files. Do not push.

---

### Task 2: Canonical Binary Pin Importer

**Owner:** `briefing-test-writer` for tests, then `briefing-worker` for the importer. Run sequentially.

**Files:**
- Create: `tests/test_binary_pins.py`
- Create: `scripts/import-binary-sums.py`
- Later publish phase: `bin/briefing-binaries.sha256`

**Interfaces:**
- Consumes: release `SHA256SUMS`, expected version string, output path.
- Produces CLI:

```text
python3 scripts/import-binary-sums.py \
  --version VERSION \
  --input /absolute/path/SHA256SUMS \
  --output /absolute/path/bin/briefing-binaries.sha256
```

Successful output is canonical UTF-8/ASCII text with exactly five LF-terminated lines. Invalid input exits `2`, writes one concise error to stderr, emits nothing to stdout, and leaves an existing output file byte-for-byte unchanged.

- [ ] **Step 1: Write failing importer tests**

Create `BinaryPinImportTests` with these test methods and assertions:

```python
def test_writes_exact_five_entries_in_canonical_order(): ...
def test_normalizes_crlf_and_uppercase_hashes(): ...
def test_rejects_missing_duplicate_and_extra_entries(): ...
def test_rejects_mixed_or_unexpected_versions(): ...
def test_rejects_malformed_hashes_paths_and_renamed_assets(): ...
def test_failure_does_not_replace_existing_output(): ...
def test_help_documents_the_three_required_options(): ...
```

Use version `0.001` in fixtures and assert the exact five canonical asset names from Global Constraints.

- [ ] **Step 2: Run the tests and verify the red state**

Run:

```sh
python3 -m unittest tests.test_binary_pins -v
```

Expected: FAIL because `scripts/import-binary-sums.py` does not exist.

- [ ] **Step 3: Implement the minimal standard-library importer**

Implement `main(argv=None) -> int` in `scripts/import-binary-sums.py`. Parse whitespace strictly enough to accept ordinary SHA256SUMS and CRLF, then validate the complete set before opening a temporary output in the destination directory. Flush and atomically replace only after full validation and write success.

Do not read the network, infer a version from the first line, accept wildcard platforms, or generate fixture pins.

- [ ] **Step 4: Run focused and full Python tests**

Run:

```sh
python3 -m unittest tests.test_binary_pins -v
python3 -m unittest discover tests -v
```

Expected: all tests pass; no existing test is skipped because of the importer.

- [ ] **Step 5: Record the uncommitted checkpoint on k7**

Main coordinator serially adds a short note naming the passing commands. Neither agent commits.

---

### Task 3: Strict POSIX Pin and Platform Selection

**Owner:** `briefing-test-writer`, then `briefing-worker`.

**Files:**
- Modify: `tests/test_starter.py:55-111`
- Modify: `bin/briefing:40-264`

**Interfaces:**
- Consumes: canonical pin manifest, detected `uname -s`/`uname -m`, and existing starter argv/stdin.
- Produces shell functions `read_pins PIN_FILE`, `platform_asset OS ARCH VERSION`, and `hash_file PATH` used by `find_binary`; exact function status is `0` on one valid selection and non-zero on all malformed/unsupported input.
- Test-only environment: `BRIEFING_STARTER_TESTING=1` enables `BRIEFING_STARTER_TEST_OS` and local fixture URLs. Production ignores test override variables unless the gate is exactly `1`.

- [ ] **Step 1: Replace one-line fixture pins with canonical five-entry fixtures**

Update the fixture helper so each test manifest contains all five names for one version. Add focused tests:

```python
def test_rejects_noncanonical_pin_manifest(): ...
def test_rejects_mixed_versions_before_selecting_platform(): ...
def test_selects_current_platform_only_after_full_manifest_validation(): ...
def test_macos_hash_path_uses_native_openssl_not_shasum(): ...
def test_test_platform_override_is_ignored_without_testing_gate(): ...
```

For the macOS case, supply fake native tools in the isolated test `PATH`, make `shasum` fail loudly, and assert it is never invoked.

- [ ] **Step 2: Verify the new tests fail for the intended reasons**

Run each new method directly, then the module:

```sh
python3 -m unittest tests.test_starter.StarterTest.test_rejects_noncanonical_pin_manifest -v
python3 -m unittest tests.test_starter.StarterTest.test_macos_hash_path_uses_native_openssl_not_shasum -v
python3 -m unittest tests.test_starter -v
```

Expected: new cases fail because current `find_binary` accepts the first matching line and the current hash path may use `shasum`.

- [ ] **Step 3: Implement full-manifest validation before selection**

Refactor only the starter's pin/platform/hash section. Validate the entire file, derive its one shared version, then select the exact current-platform asset. Preserve existing external argv, stdin, stdout, exit code, fallback, cache location, and backoff interfaces.

Linux hash order: native `sha256sum`. macOS hash order: native `openssl dgst -sha256`; do not invoke `shasum`.

- [ ] **Step 4: Run focused starter and contract tests**

Run:

```sh
sh -n bin/briefing
python3 -m unittest tests.test_starter -v
python3 -m unittest discover tests -v
```

Expected: all pass on the current POSIX host. Windows remains unproven until Tasks 5–6.

- [ ] **Step 5: Record the uncommitted checkpoint on k7**

Main adds a serialized board note. No commit.

---

### Task 4: Secure POSIX Provisioning and Cache

**Owner:** `briefing-test-writer`, then `briefing-worker`.

**Files:**
- Modify: `tests/test_starter.py:146-282`
- Modify: `bin/briefing:99-178,266-398`

**Interfaces:**
- Consumes: validated asset name/hash from Task 3.
- Produces `ensure_private_cache PATH`, `new_temp CACHE_DIR`, `download URL DEST MAX_BYTES`, and `fetch_binary` behavior with `0700` directories/files, exclusive temporary files, HTTPS-only production redirects, 256 MiB production limit, atomic install, and cache rehash on every execution.
- Test-only `BRIEFING_STARTER_TEST_MAX_BYTES` is honored only with `BRIEFING_STARTER_TESTING=1`.

- [ ] **Step 1: Write failing trust-boundary tests**

Add these methods:

```python
def test_production_rejects_http_and_file_urls(): ...
def test_testing_gate_allows_local_fixture_url(): ...
def test_rejects_symlinked_cache_component(): ...
def test_cache_directories_and_binary_are_mode_0700(): ...
def test_oversized_download_never_reaches_cache(): ...
def test_interrupted_download_leaves_no_trusted_cache_entry(): ...
def test_wrong_hash_is_never_executed(): ...
def test_two_concurrent_provisions_converge_on_one_verified_binary(): ...
def test_verified_cache_runs_offline_and_tampering_is_rejected(): ...
def test_non_session_start_commands_never_download(): ...
```

Use a low test-only byte limit rather than allocating a 256 MiB fixture. Make the fixture binary write a marker when executed and assert the marker is absent in every failure case.

- [ ] **Step 2: Verify the red state**

Run:

```sh
python3 -m unittest tests.test_starter.StarterTest.test_production_rejects_http_and_file_urls -v
python3 -m unittest tests.test_starter.StarterTest.test_rejects_symlinked_cache_component -v
python3 -m unittest tests.test_starter.StarterTest.test_two_concurrent_provisions_converge_on_one_verified_binary -v
```

Expected: FAIL against the current permissive download/cache implementation.

- [ ] **Step 3: Implement secure provisioning minimally**

Use `umask 077`; reject symlinks in every existing cache path component; create a per-process temporary file exclusively; keep it non-executable until its size and hash pass; move it atomically; then set mode `0700`. Restrict production to HTTPS and reject a redirect result whose effective URL is not HTTPS. Apply downloader size limits where supported and independently reject an oversized completed file.

A failed or competing provision may remove only its own temporary file. It must not remove a verified destination installed by another process.

- [ ] **Step 4: Run starter, shell, and full contract suites**

Run:

```sh
sh -n bin/briefing
python3 -m unittest tests.test_starter -v
python3 -m unittest discover tests -v
```

Expected: all pass; failure cases do not create the execution marker.

- [ ] **Step 5: Record the uncommitted checkpoint on k7**

No commit.

---

### Task 5: Windows Bootstrap Build, Wiring, and Process Contract

**Owner:** `briefing-test-writer`, then `briefing-worker`.

**Files:**
- Create: `tests/test_briefing_bootstrap.py`
- Create: `tests/fixtures/briefing-bootstrap-stub.c`
- Create: `briefing-bootstrap/briefing-bootstrap.c`
- Create: `briefing-bootstrap/build.py`
- Create: `briefing-bootstrap/README.md`
- Create: `bin/briefing-bootstrap.exe`
- Modify: `tests/test_windows_wiring.py:20-50`
- Modify: `bin/briefing:25-38`

**Interfaces:**
- Build CLI:

```text
python3 briefing-bootstrap/build.py OUT.exe [--target TARGET] [--src SOURCE]
```

Defaults: target `x86_64-windows-gnu`, source `briefing-bootstrap.c`, Zig package `ziglang==0.13.0.post1`, compiler version exactly `0.13.0`, optimization/strip flags `-Os -s`, final native libraries `-lwinhttp -lbcrypt -ladvapi32`, PE validation, COFF timestamp zeroing, and `.pdb`/`.lib` removal.

- Runtime entry: `wmain(int argc, wchar_t **argv)`.
- Winlaunch directive: `# winlaunch: run bin/briefing-bootstrap.exe`.
- The bootstrap forwards original arguments, environment, stdin/stdout/stderr, and child exit status.
- At this task boundary, `BRIEFING_BOOTSTRAP_TESTING=1` plus an absolute `BRIEFING_BOOTSTRAP_TEST_CHILD` may select the native fixture child solely to test process fidelity; production ignores that override. Real pin parsing, cache verification, and network provisioning arrive in Task 6.

- [ ] **Step 1: Write failing wiring and build tests**

Update/add tests:

```python
def test_briefing_uses_native_bootstrap_directive(): ...
def test_generic_launchers_remain_winlaunch_copies(): ...
def test_bootstrap_exists_and_is_not_a_winlaunch_copy(): ...
def test_claude_and_codex_commands_route_through_bin_briefing(): ...
def test_build_is_reproducible_and_has_zero_coff_timestamp(): ...
```

The wiring test must enumerate both `hooks/hooks.json` and `hooks/codex-hooks.json`.

- [ ] **Step 2: Add failing native process-fidelity tests**

In `tests/test_briefing_bootstrap.py`, accept an optional explicit bootstrap path and otherwise build into a temporary directory. Build the C stub fixture and add:

```python
def test_cached_child_receives_unicode_argv_and_cwd(): ...
def test_cached_child_round_trips_utf8_stdin_stdout_stderr(): ...
def test_returns_exact_child_exit_code(): ...
def test_par_global_temp_is_versioned_under_private_cache(): ...
def test_relative_config_dir_is_rejected(): ...
```

Run on native Windows:

```text
python -m unittest tests.test_windows_wiring -v
python tests/test_briefing_bootstrap.py C:\absolute\path\to\briefing-bootstrap.exe
```

Expected: FAIL because the bootstrap and directive do not exist.

- [ ] **Step 3: Implement reproducible build and minimal cached-child execution**

Copy only the build contract, not source code or ownership, from `winlaunch/build.py`. Implement wide path discovery, absolute config validation, `%USERPROFILE%\.claude` fallback, versioned `PAR_GLOBAL_TEMP`, Windows command-line quoting, inherited standard handles, and `CreateProcessW`/exit propagation. Add the gated absolute fixture-child override defined above; reject it unless the test gate is exactly `1`.

Do not implement real pin/cache selection or WinHTTP yet. Keep shared `winlaunch/` byte-for-byte unchanged.

- [ ] **Step 4: Build the tracked bootstrap twice and compare bytes**

Run with the repository's approved Zig invocation:

```text
python briefing-bootstrap/build.py build\briefing-bootstrap-a.exe
python briefing-bootstrap/build.py build\briefing-bootstrap-b.exe
```

Expected: byte-identical PE files with zero COFF timestamp. Copy the verified output to `bin/briefing-bootstrap.exe` through the worker's normal file tool, not an unreviewed external download.

- [ ] **Step 5: Run native wiring/process tests**

Expected: all Task 5 tests pass on native Windows. A cross-build alone is not a pass.

- [ ] **Step 6: Record the uncommitted checkpoint on k7**

No commit.

---

### Task 6: Windows Trust, Provisioning, Cache, and Fallbacks

**Owner:** `briefing-test-writer`, then `briefing-worker`.

**Files:**
- Modify: `tests/test_briefing_bootstrap.py`
- Modify: `briefing-bootstrap/briefing-bootstrap.c`
- Rebuild: `bin/briefing-bootstrap.exe`

**Interfaces:**
- Consumes: canonical pin manifest and original CLI argv.
- Produces Windows equivalents of the POSIX trust contract using wide APIs, WinHTTP, BCrypt, private current-user DACLs, reparse-point rejection, exclusive temporary files, atomic replacement, cache rehash, and original child exit status.
- Test-only variables `BRIEFING_BOOTSTRAP_TESTING=1`, `BRIEFING_BINARY_BASE_URL`, and `BRIEFING_BOOTSTRAP_TEST_MAX_BYTES` permit localhost HTTP and low size limits only under the explicit gate.
- Compatibility fallback order remains: verified PAR binary; Python hook path for hook/Doctor commands when available; Perl source CLI for other commands when available; established safe hook warning/exit behavior when no runtime exists.

- [ ] **Step 1: Write failing pin, cache, and download tests**

Add:

```python
def test_rejects_every_noncanonical_pin_class(): ...
def test_selects_windows_exe_name_only(): ...
def test_production_rejects_plain_http_and_tls_downgrade(): ...
def test_hash_mismatch_and_oversize_never_execute(): ...
def test_reparse_point_cache_component_is_rejected(): ...
def test_cache_dacl_is_current_user_only(): ...
def test_interrupted_and_concurrent_downloads_are_atomic(): ...
def test_cached_binary_is_rehashed_before_every_execution(): ...
def test_verified_cache_runs_without_network_perl_python_or_powershell(): ...
```

- [ ] **Step 2: Write failing fallback and no-runtime tests**

Build fixture `python.exe` and `perl.exe` stubs in isolated temporary `PATH` directories and add:

```python
def test_hook_falls_back_to_python_when_provisioning_is_unavailable(): ...
def test_cli_falls_back_to_perl_when_provisioning_is_unavailable(): ...
def test_hook_without_binary_or_runtime_uses_safe_warning_exit_contract(): ...
def test_non_hook_without_binary_or_runtime_reports_failure(): ...
```

Assert exact selected executable, forwarded argv, stderr shape, and exit status against the POSIX starter's established behavior.

- [ ] **Step 3: Verify native red tests**

Run the focused methods on native Windows. Expected: FAIL because Task 5 has no provisioner/fallback implementation.

- [ ] **Step 4: Implement the minimal native trust path**

Implement strict full-manifest parsing, WinHTTP download, HTTPS-only redirect validation, Content-Length/streamed byte cap, BCrypt SHA-256, private directory DACLs, reparse-point checks, exclusive temporary creation, atomic install, destination rehash, and compatibility fallback dispatch. Use dynamically sized wide buffers rather than copying winlaunch's fixed path buffers.

- [ ] **Step 5: Rebuild and run the complete native bootstrap suite**

Run:

```text
python briefing-bootstrap/build.py bin\briefing-bootstrap.exe
python -m unittest tests.test_windows_wiring -v
python tests/test_briefing_bootstrap.py bin\briefing-bootstrap.exe
```

Expected: all pass on native Windows, including Unicode argv/cwd/stdin and empty-runtime-PATH cases.

- [ ] **Step 6: Record native evidence on k7**

Main records Windows version, architecture, commands, pass count, and every skip. No commit.

---

### Task 7: Workflow, Build, and Distribution Integration

**Owner:** Main coordinator for cross-repo dependency; `briefing-test-writer` for static tests; `briefing-worker` for behavior-relevant configuration.

**Files:**
- Create: `tests/test_binary_workflow.py`
- Modify: `.github/workflows/binaries.yml`
- Modify: `.github/workflows/test.yml`
- Modify: `.github/workflows/ci.yml`
- Modify: `.cicd/python+3.12+test.winlaunch.sh`
- Modify: `dist.ini`
- Modify if required: `scripts/binary-smoke.sh`

**Interfaces:**
- Consumes: reviewed 40-hex commit SHA of the external `dzil-binary.yml` implementation and its documented five-platform output contract.
- Produces: immutable reusable-workflow reference; native Windows bootstrap CI; separate generic-winlaunch/bootstrap reproducibility checks; release logs or artifacts recording source commit, workflow commit, runner image/version, OS, architecture, ABI, and asset hashes.

- [ ] **Step 1: Resolve the cross-repository workflow dependency without silent edits**

Inspect the sibling bundle repository's board and workflow commit. If any bundle change or publication is needed, create/claim a card on that repository's karr board and route it through that repository's own team. Record the resulting reviewed full commit SHA on `k7`.

Do not push or publish the external commit yet.

- [ ] **Step 2: Write failing static workflow/distribution tests**

Add:

```python
def test_binary_workflow_uses_full_commit_sha(): ...
def test_binary_workflow_has_five_canonical_platforms(): ...
def test_windows_asset_contract_requires_exe(): ...
def test_cpan_excludes_all_plugin_bin_files(): ...
def test_winlaunch_check_excludes_bootstrap_and_rebuilds_it_separately(): ...
def test_native_windows_ci_runs_bootstrap_suite(): ...
def test_release_evidence_fields_are_emitted(): ...
```

Use only the Python standard library; do not add a YAML dependency.

- [ ] **Step 3: Verify the static tests fail**

Run:

```sh
python3 -m unittest tests.test_binary_workflow -v
```

Expected: FAIL on mutable `@binary-v1`, absent bootstrap CI, and old `.exe` classification.

- [ ] **Step 4: Implement the minimal workflow/configuration changes**

Replace `@binary-v1` with the reviewed full SHA. Keep `contents: write` only where release asset upload requires it. Add the native Windows bootstrap job and adjust `.cicd` so generic launchers remain byte-identical to winlaunch while the bootstrap is rebuilt through its own script. Preserve `gather_exclude_match = ^bin/`.

If the external workflow already emits every evidence field, assert its contract rather than duplicating it. Otherwise emit the missing fields from the platform smoke step and route the external change through its own card.

- [ ] **Step 5: Run local static, source, and distribution checks**

Run:

```sh
python3 -m unittest tests.test_binary_workflow -v
python3 -m unittest discover tests -v
bash -n .cicd/python+3.12+test.winlaunch.sh scripts/binary-smoke.sh
DZIL_BINARY_SKIP=1 dzil build
DZIL_BINARY_SKIP=1 dzil test
```

Inspect the generated install list and assert `script/briefing` is installed while no `bin/briefing*` file is installed by CPAN.

- [ ] **Step 6: Record the uncommitted checkpoint and external dependency state on k7**

No commit or publication.

---

### Task 8: Documentation and Complete Local Verification

**Owner:** Main coordinator for plain prose; `briefing-worker` for `briefing-core` behavior text; reviewer still pending.

**Files:**
- Modify: `README.md`
- Modify: `docs/perl-direction.md`
- Modify: `.claude/skills/briefing-core/SKILL.md`

**Interfaces:**
- Consumes: implemented behavior and verified commands from Tasks 2–7.
- Produces: exact user/operator documentation for provisioning timing, supported-runner policy, trust root, native tool requirements, cache location, offline cache behavior, fallback behavior, Windows bootstrap ownership, release pin import, and publish gate.

- [ ] **Step 1: Update plain prose without claiming unpublished support**

Document the implementation as pending release pins until Task 10. State that support follows the recorded current native runners. Name native POSIX tool requirements and the fact that macOS does not use `shasum`.

- [ ] **Step 2: Update the development skill's transitional statements**

The worker changes only statements made false by the implementation. Keep the warning that native platform proof is required and that checkout, installed plugin, and harness versions may differ.

- [ ] **Step 3: Run the complete local verification set**

Run:

```sh
export PERL5LIB="$PWD/.build-deps/lib/perl5${PERL5LIB:+:$PERL5LIB}"
prove -lr t
python3 -m py_compile hooks/briefing-preload hooks/briefing-marketplace-notice scripts/import-binary-sums.py
sh -n bin/briefing bin/briefing-doctor
bash -n scripts/binary-lib.sh scripts/binary-pp-args.sh scripts/binary-smoke.sh scripts/binary-verify.sh .cicd/python+3.12+test.winlaunch.sh
python3 -m unittest discover tests -v
BRIEFING_TEST_CLI="[\"$(command -v perl)\",\"-I$PWD/lib\",\"$PWD/script/briefing\"]" \
  python3 -m unittest discover tests -v
python3 hooks/briefing-preload doctor --cwd . --harness both
DZIL_BINARY_SKIP=1 dzil build
DZIL_BINARY_SKIP=1 dzil test
git diff --check
```

Expected: all applicable local suites pass. Report native Windows/macOS/arm64 checks as pending, not passing, unless they actually ran.

- [ ] **Step 4: Hand the complete uncommitted diff to `briefing-reviewer`**

The reviewer independently reads the spec, plan, and diff; runs all local checks; confirms shared `winlaunch/` is unchanged; and reports file/line findings. Any red result goes back to the owning test writer or worker before commit.

---

### Task 9: Reviewed Local Implementation Commit and Publish-Gate Stop

**Owner:** `briefing-release-manager`.

**Files:**
- Modify: `Changes`
- Commit: all reviewed implementation/test/docs files except a fake or absent real pin file.

**Interfaces:**
- Consumes: reviewer-approved diff and green local/native checks available before publication.
- Produces: local implementation commit(s), clean working tree, and `k7` blocked at the publish gate rather than closed.

- [ ] **Step 1: Update `Changes` with only verified implementation facts**

Do not say binaries are released or the cutover is complete. State which native tests actually ran and which publish-gated evidence remains.

- [ ] **Step 2: Run release-manager distribution checks**

Run `prove -lr t`, `DZIL_BINARY_SKIP=1 dzil build`, `DZIL_BINARY_SKIP=1 dzil test`, and inspect the generated installation list.

- [ ] **Step 3: Commit the reviewer-approved local implementation**

Use the Getty commit style and required attribution. Do not push.

- [ ] **Step 4: Block k7 explicitly at the publish gate**

Record the local commit, exact remaining external workflow/release actions, and the permission required. `k7` remains open.

---

### Task 10: Publish-Gated Binary Build, Native Matrix, and Real Pin Import

**Owner:** Main coordinator plus the authorized release managers for each repository. Do not begin without explicit permission naming the external actions.

**Files:**
- Create from real release evidence: `bin/briefing-binaries.sha256`
- Modify as evidence requires: release documentation only; behavior changes return to Tasks 2–8 and re-review.

**Interfaces:**
- Consumes: authorized pushed workflow commit, authorized briefing source/release commit, five published assets, `SHA256SUMS`, and recorded native runner evidence.
- Produces: canonical tracked pins matching the exact published bytes and three cold-provision timings per runner.

- [ ] **Step 1: Ask for and record explicit publish authorization**

Name separately: external bundle push/tag/release if needed, briefing commit/tag push, GitHub release creation, asset upload, and workflow dispatch. A prior approval to implement is not approval to publish.

- [ ] **Step 2: Publish or expose the immutable external workflow commit**

Use that repository's release manager and board. Confirm `.github/workflows/binaries.yml` references the exact pushed 40-hex commit.

- [ ] **Step 3: Build and publish the five exact assets once**

The authorized workflow checks out the intended briefing source commit, records provenance fields, runs verify/smoke natively, and uploads those exact bytes plus `SHA256SUMS`. Do not rebuild different bytes after pin import.

- [ ] **Step 4: Verify the native matrix and cold gate**

For each recorded current runner, require clean no-Perl/no-Python smoke and three cold complete provisions, each `<= 75` seconds. Record all raw timings and every skip/failure. Any failure keeps `k7` blocked and returns to the owning task.

- [ ] **Step 5: Import the real release sums**

Run:

```sh
python3 scripts/import-binary-sums.py \
  --version "<released App::Briefing version>" \
  --input "/absolute/path/to/downloaded/SHA256SUMS" \
  --output "$PWD/bin/briefing-binaries.sha256"
python3 -m unittest tests.test_binary_pins -v
```

Expected: the tracked file contains exactly the five released asset hashes; each downloaded asset independently matches its pinned hash.

- [ ] **Step 6: Review and commit the real pin update locally**

`briefing-reviewer` verifies evidence and diff; `briefing-release-manager` updates `Changes` accurately and commits. Any push of this pin commit still requires the named authorization.

---

### Task 11: Live Harness Cutover Verification and Completion

**Owner:** Main coordinator for live checks; `briefing-reviewer` for evidence review; `briefing-release-manager` for final commit/card closure.

**Files:**
- Modify only if facts require: `README.md`, `docs/perl-direction.md`, `.claude/skills/briefing-core/SKILL.md`, `Changes`

**Interfaces:**
- Consumes: installed plugin state containing the real pins and published assets.
- Produces: real Claude Code and Codex positive/control evidence on native Windows x86_64 and at least one current native POSIX runner; final truthful docs; closed `k7` only after a reviewed commit.

- [ ] **Step 1: Verify the installed copy, not only the checkout**

Run both Doctor versions and record the resolved plugin paths. Confirm the loaded plugin contains the committed pins, native Windows bootstrap, and expected starter version.

- [ ] **Step 2: Run documented Claude Code positive/control checks**

On native Windows and one current POSIX runner, prove:

- declared skill body arrives through `additionalContext`;
- Agent input is unchanged;
- unknown skill is denied at the guard or receives only the required abort instruction at `SubagentStart`;
- the Windows invocation traverses `bin/briefing.exe -> bin/briefing-bootstrap.exe -> verified PAR`;
- no Perl or Python is available on the standalone path.

- [ ] **Step 3: Run documented Codex positive/control checks**

On the same platform classes, prove full `additionalContext`, the unknown-skill abort contract, and the actual binary-enabled installed path.

- [ ] **Step 4: Re-run offline verified-cache checks**

Disable network access after successful provisioning and confirm later hooks/CLI use the rehashed cache on POSIX and Windows.

- [ ] **Step 5: Independently review completion evidence**

The reviewer compares every Acceptance Criterion in the spec with a concrete command/run/artifact. Missing native or harness evidence is a blocker, not a documentation note.

- [ ] **Step 6: Make the final truthful documentation/Changes commit and close k7**

Only the release manager commits. Record the commit and evidence in `k7`, release the claim, move `k7` to done, and serialize the board writes. Push only if the existing explicit authorization includes that push.

---

## Self-Review Results

- **Spec coverage:** Every goal, non-goal, trust boundary, platform rule, publish gate, native proof, and live harness criterion maps to Tasks 2–11. The real pin file is intentionally deferred to Task 10 so fixture hashes can never masquerade as release authorization.
- **Step scan:** Test steps name exact cases and expected red reasons; implementation steps define interfaces and fixed values without prescribing full bodies. Cross-repo and publish actions have explicit gates rather than placeholders.
- **Type/interface consistency:** The canonical manifest contract is shared by importer, POSIX starter, Windows bootstrap, workflow tests, and release import. Test-only environment names are fixed where introduced.
- **Review focus:** All five high-risk classes have named regression tests in their owning tasks.
- **Proportion:** The plan is longer than the design because it coordinates two editing lanes, native platform evidence, a cross-repository workflow dependency, and a two-phase publish gate; implementation bodies remain delegated rather than transcribed.
