# CPAN::Maker::Bootstrapper 2.0.4 Release Notes

## Overview

This release focuses on improving the LLM-powered release notes
generation pipeline, introducing a new `Git::ReleaseDiffs` module,
refining how source artifacts are prepared and sent to the LLM, and
tidying up the build infrastructure.

---

## What's New

### New Module: `Git::ReleaseDiffs`

A new module `Git::ReleaseDiffs` has been introduced to encapsulate
the logic for generating the release diff artifacts (`.diffs`, `.lst`,
and `.tar.gz`) that are used as input to the LLM. Previously, this was
handled externally via a shell script in the `release-notes.mk`
Makefile include. The release artifact generation is now performed
programmatically within Perl code, making the process more robust and
testable.

### Streamlined `release-notes` Make Target

The `release-notes.mk` Makefile include has been significantly
simplified. The previous multi-step shell script that manually invoked
`git diff`, `git tag`, and `tar` has been replaced with a single call
to `bootstrapper release-notes`:

```makefile
release-notes:
    @bootstrapper release-notes
```

All artifact generation is now delegated to `Git::ReleaseDiffs` within
the bootstrapper itself.

---

## Improvements

### `CPAN::Maker::Bootstrapper::Role::LLM::ReleaseNotes`

Several enhancements have been made to the `cmd_release_notes`
subroutine:

- **Artifact generation via `Git::ReleaseDiffs`**: Release diff files
  are now created programmatically using the new `Git::ReleaseDiffs`
  module rather than relying on pre-existing files generated
  externally.

- **ChangeLog truncation**: Only the current release section of the
  `ChangeLog` file is extracted and sent to the LLM. A new private
  helper, `_extract_changelog_section`, reads the `ChangeLog` up to
  (but not including) the second top-level block, keeping LLM context
  focused and reducing token usage.

- **POD stripping from Perl sources**: A new private helper,
  `_strip_pod`, uses `Pod::Extract` and `IO::Scalar` to strip POD
  documentation from `.pm.in` and `.pl.in` source files before they
  are submitted to the LLM. This reduces token consumption without
  losing meaningful code content.

- **Organised output directory**: Generated release notes are now
  written to a dedicated `release-notes/` subdirectory as
  `release-notes/release-notes-{version}.md`, with a convenience
  symlink `release-notes.md` pointing to the latest file. The output
  directory is created automatically via `File::Path::make_path` if it
  does not already exist.

- **Symlink management**: The `release-notes.md` symlink is updated on
  each run, replacing any existing symlink, so it always reflects the
  most recently generated notes.

---

## Build Infrastructure

### `builder` Script

- **Idempotent repository cloning**: The builder script no longer
  unconditionally clones a repository. It now checks whether the
  target directory already exists and skips cloning if it does, making
  repeated local runs more efficient.
- **Unpinned extra dependencies**: Version pins have been removed from
  `CPAN::Maker` and `Markdown::Render` in `EXTRA_DEPS`, allowing the
  latest available versions to be installed.
- **Improved installer verbosity**: The default `cpm` installer
  command now includes `--show-build-log-on-failure` and `--verbose`
  flags for better diagnostic output during CI builds.

---

## Dependencies Added

| Module | Purpose |
|---|---|
| `Git::ReleaseDiffs` | Programmatic generation of release diff artifacts |
| `File::Path` | Creating the `release-notes/` output directory |
| `IO::Scalar` | In-memory file handle for POD stripping |
| `Pod::Extract` | Extracting and stripping POD from Perl source files |

---

## Bug Fixes

- The `release-notes.mk` shell script could fail or produce unexpected
  results when `LAST_TAG` was unset or when `git diff --staged`
  produced no output. These edge cases are now handled within the
  `Git::ReleaseDiffs` implementation.

---

## Upgrade Notes

Consumers using the `release-notes` make target should ensure that the
`bootstrapper` CLI tool is installed and accessible in `PATH`. The old
shell-based workflow (producing `release-{version}.diffs`,
`release-{version}.lst`, and `release-{version}.tar.gz` externally
before invoking `make release-notes`) is no longer required — artifact
generation is fully automated.
