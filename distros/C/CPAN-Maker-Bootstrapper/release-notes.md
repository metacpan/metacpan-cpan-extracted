# Release Notes — CPAN::Maker::Bootstrapper 2.5.0

## Overview

This release introduces a new LLM-assisted `change-log` command and a
dedicated `import` command, refactors release-notes and prompt handling
to be more consistent, and makes several build-system adjustments to
dependency reconciliation and test-target source handling. Existing
projects that upgrade the build system should refresh their managed
files with `make update`.

## New `change-log` Command

A new `change-log` command generates a draft ChangeLog entry for a
release using an LLM and the same release artifacts produced for
release notes (Git status, diffs, file inventory, and the distribution
tarball).

- Implemented in the new role
  `CPAN::Maker::Bootstrapper::Role::LLM::ChangeLog`, registered in
  `cpan-maker-bootstrapper.yml` as the `change-log` command.
- Driven by a new managed make fragment, `.includes/change-log.mk`,
  and exposed through the `make change-log` target.
- Uses the new `.prompts/change-log.prompt`, which has been restructured
  into directive sections consistent with the project's other prompt
  files.
- The generated entry is written to `ChangeLog-VERSION.tmp`; the
  existing `ChangeLog` is not modified. Review and incorporate the entry
  manually before finalizing a release.
- `make change-log` supports `MODEL=<model-name>` to override the
  configured LLM model and `DRYRUN=1` to prepare the request without
  submitting it.

The `change-log` output is a file-oriented engineering record and is
distinct from the developer-facing `release-notes` output.

## New `import` Command

An `import` command has been added, mapped to the new
`CPAN::Maker::Bootstrapper::Role::Importer` role in
`cpan-maker-bootstrapper.yml`. This provides manifest-driven project
imports as a counterpart to the existing `--import` option, which
performs automatic file discovery.

Alongside this, `Role::Installer` was refactored so that project
construction is extracted from `cmd_install` into a new
`_import_project` method that accepts `module`, `stub`, and
`import_paths` as named arguments. This shared construction path is the
basis for both the `install` and `import` commands.

## MODEL Support for Release and ChangeLog Generation

`.includes/release-notes.mk` now honors a `MODEL` variable and passes
`--model` to `cmb release-notes` when it is set. The `change-log`
fragment supports the same variable. This allows the LLM model to be
overridden per invocation without changing the configured default.

## Release-Notes and Prompt Handling Changes

`Role::LLM::ReleaseNotes` received several internal changes affecting
behavior:

- `_extract_changelog_section` and the renamed
  `_strip_pod_from_content` (previously `_strip_pod`) are now methods
  rather than plain functions, and `cmd_release_notes` calls them
  accordingly.
- `cmd_release_notes` now installs `release-notes.prompt` via
  `_install_prompts` when it is absent, so the prompt is available on
  first use.
- The dry-run guard around prompt construction has been consolidated
  into a single block.

`Role::LLM::Reviewer`'s `_install_prompts` now accepts an optional list
of prompt names, defaulting to `code-review.prompt` and
`pod-review.prompt` when none are supplied. This generalization is what
allows `ReleaseNotes` to request installation of a specific prompt.

## Build and Dependency Reconciliation Changes

- `Makefile` gains `DEPENDENCY_FILES` and `MISSING_DEPENDENCY_FILES`
  variables and a `force-reconcile` phony target. The grouped
  reconciliation recipe now treats a missing dependency file as a
  reason to reconcile, and the reconcile loop checks for a missing
  target file (`! -e "$$type"`) in addition to the stale-sentinel
  check. These changes cause dependency files to be regenerated when
  they are absent, not only when their inputs are newer.
- `local/.installed` is now an optional tarball prerequisite when
  `SKIP_TESTS` is set.
- The `test-requires.scan` scandeps invocation no longer passes
  `--log-level info`.
- `change-log.mk` was added to `MANAGED_MK_FILES` and the `MANIFEST`,
  and recorded in `buildspec.yml` extra-files and `cmb_md5sums.txt`.

## Test Target Source Handling

`.includes/test.mk` now uses `SOURCE_FILES` in place of
`GSOURCE_FILES` for the `test`, `test-all`, and `check` targets.

## Managed Include Variable Definitions

`.includes/update.mk` now defines `INCLUDES_DIR` and
`BOOTSTRAPPER_DIST_DIR` locally rather than relying on them being set
elsewhere.

## Dependency Graph

`deps.mk` records the new `ChangeLog` role's dependency on `Constants`
and `Git::ReleaseDiffs`.

## Upgrade Notes

Projects tracking this build system should run `make update` to pick up
`.includes/change-log.mk` and the revised `release-notes.mk`,
`test.mk`, and `update.mk` fragments, along with the updated
`Makefile`. The managed-file drift check will report drift until this
is done.

