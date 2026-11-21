# App::Briefing Perl Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Project roles own tests and implementation; no built-in substitutes or commits/pushes without the appropriate instruction.

**Goal:** Create an installable Getty Perl distribution in the root, with a real library and CLI covering the existing hook/doctor behavior.
**Architecture:** Moo core, encapsulated filesystem and thin CLI. Native Perl tests exercise the library; existing subprocess tests can also target the new CLI.
**Tech Stack:** Perl 5.20+, Moo, namespace::clean, JSON::MaybeXS, Path::Tiny, platform-specific Win32::LongPath, a suitable TOML parser, Dist::Zilla [@Author::GETTY], Test::More.
**Spec:** `docs/superpowers/specs/2026-11-16-app-briefing-perl-design.md`

## Global Constraints

- App-Briefing distribution, App::Briefing library, briefing CLI, all in the repository root.
- New Perl files initially start at version 0.001; verify that value at first-build acceptance. Retained tests check version consistency so normal release bumps keep working. No publication or claimed CPAN availability.
- Keep production plugin starters until a separately verified binary cutover.
- No Python execution from the library or CLI. Python is only a reference/test tool during migration.
- Declare dependencies, load known imports at module scope and condition native Windows dependencies by platform.
- Preserve hook contracts: guard without rewriting, no partial briefing, read-only core.
- Marker writes belong only to the separate notice operation.
- Leave the published prototype branch and main untouched during this new feature step.
- All repository prose is English; non-English strings are intentional test data only.

## Review Focus

- Unicode paths: file tests, directory traversal and reads must identify the same file on Windows.
- Harness/plugin resolution: parser or path changes must not alter precedence or disabled/scoped install handling.
- Result boundaries: absent declaration means no-op; missing declared skill means failure, never partial public briefing text.
- CPAN content: Git::GatherDir only sees tracked files; old .exe/doctor starters must not become CPAN executables.
- Transition: keep the existing plugin route usable; the new source CLI must not depend on Python. Source checks are not binary/native-OS proof.

## Task 1: Contract tests and interchangeable test driver

**Owner:** briefing-test-writer
**Files:** new `t/00-load.t`, `t/10-library.t`, `t/20-cli.t`, `t/30-unicode.t`; helper under `t/lib/` if needed; shared Python driver under `tests/` and command changes in existing suites.
**Interfaces:** Public library/CLI methods exactly as specified. The Python driver optionally reads `BRIEFING_TEST_CLI` as a JSON array of absolute CLI arguments. When set, append `hook`, `doctor` or `notice`; otherwise retain existing Python entry points. Never evaluate a shell command.

- [ ] Write native tests for no-op, successful injection, missing skill without partial text, guard without updatedInput, preflight/doctor, CLI version and Unicode paths.
- [ ] Isolate HOME/cwd/CODEX_HOME explicitly; never use real user files.
- [ ] Run the missing library/CLI as the red baseline and record it.
- [ ] Preserve existing Python assertions; make only command dispatch configurable. Include notice; Windows wiring still checks the existing plugin route.
- [ ] Run `python3 -m unittest discover tests -v` against Python: expect all 105 existing tests plus deliberate additions, with no lost cases.
- [ ] Identify Python-specific tomllib shims; retain semantic TOML cases for Perl without claiming its execution exercised Python import fallback.

## Task 2: Library, CLI and root distribution

**Owner:** briefing-worker
**Files:** `lib/App/Briefing.pm`, `lib/App/Briefing/Filesystem.pm`, `lib/App/Briefing/CLI.pm`, `bin/briefing`, `dist.ini`, `cpanfile`, `LICENSE`, `.gitignore`, `README.md`; test edits only after coordinating with the test writer.
**Consumes:** Task-1 contracts, current Python implementation and `docs/perl-direction.md`.
**Produces:** The public API in the spec and a functional CPAN source build.

- [ ] Run Task 1's red tests; read current hook/notice functions before porting.
- [ ] Implement filesystem access: Path::Tiny on POSIX, documented wide Windows APIs for Unicode. No global monkeypatches; explain the house-rule exception.
- [ ] Port parsing, agent/skill resolution and result construction. Public results contain no partial text when any skill is missing.
- [ ] Implement `process_hook`, `process_notice`, doctor evaluation and thin `bin/briefing`; library methods do not print CLI output.
- [ ] Add the root scaffold following the Karr/Getty reference: main_module, author bundle, cpanfile, versions/POD, license and ignore additions. Preserve product documentation and add the source CLI.
- [ ] Limit CPAN executable installation to `bin/briefing`; prune old plugin doctor files from the distribution's executable installation while retaining them in the checkout.
- [ ] Install missing build dependencies project-locally only; never silently upgrade the global toolchain.
- [ ] Run `prove -lr t` and Python conformance with `BRIEFING_TEST_CLI`; fix discrepancies rather than changing assertions to match.

## Task 3: Standards, distribution and CI evidence

**Owners:** main session for team/CI configuration and prose; briefing-worker for skill text/code; briefing-release-manager for required explicit staging.
**Files:** `.claude/agents/*.md`, `.claude/rules/briefing-rules.md`, `.claude/skills/briefing-core/`, `.claude/skilletor.json`, CI configuration; `Changes` belongs to the release manager.

- [x] Install `getty-cpan-dist`, `getty-perl-core`, `getty-perl-moo`, `perl-release-dist-ini` with skilletor.
- [x] Align roles with `lib/`, `bin/briefing`, `t/` and Perl standards; keep commit/changelog/release skills only in the release manager.
- [ ] Track new build files explicitly so Git::GatherDir includes them; no unrequested commit/push.
- [ ] Run `dzil build` and `dzil test`; inspect generated Makefile.PL/EXE_FILES and package content.
- [ ] Prepare native source CI on Linux/macOS/Windows; use PowerShell for Windows dependency steps, not Git Bash. Python is only a test-host conformance tool.
- [ ] Obtain separate authorization before pushing this new feature branch; only then run native CI.
- [ ] Check team wiring and both migration-phase hook paths. Do not publish or perform binary cutover.

## Task 4: Final review and handover

**Owner:** briefing-reviewer, then main session.

- [ ] Independently review API, packaging and behavioral parity; run the checks.
- [ ] Name every skipped platform/binary/live-harness check; never report open work as done.
- [ ] Record progress and rulings below; hand over actual commands and test counts.

## Execution state

- Baseline: main 4a07f32 is pushed; regular CI and tests pass. New branch: `feat/app-briefing-perl`.
- The user explicitly requested the root layout and Perl port; no further language/layout selection.
- Ruling: first verify the CPAN library/CLI against the contracts. Existing Windows winlaunch does not support generic `run perl`; switching starters prematurely would break installations. Binary cutover is therefore a separate verified step.
- User correction: repository content must be English, including skills and agents. Translate earlier assistant-authored repository prose without removing intentional Unicode fixtures.
