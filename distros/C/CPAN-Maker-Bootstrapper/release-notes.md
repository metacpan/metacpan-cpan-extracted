# CPAN::Maker::Bootstrapper 2.0.8 Release Notes

## Overview

This release introduces the new `extra-files` command for managing
distribution file installations, adds a `NO_COMMIT` option to `make
git`, and includes various documentation improvements and housekeeping
updates.

---

## What's New

### New Command: `extra-files`

A new `extra-files` command has been added to `cmb` for adding files
to a distribution without manually editing `buildspec.yml`:

```bash
cmb extra-files path file ...
```

- Use `.` as the path to include a file in the root of the
  distribution tarball (not installed to the share directory)
- Use `share` as the path to install a file into the distribution's
  share directory

**Examples:**

```bash
cmb extra-files . README.md
cmb extra-files share share/config.json
```

This command is backed by the new
`CPAN::Maker::Bootstrapper::Role::ExtraFiles` role.

---

### New Feature: `NO_COMMIT` Option for `make git`

The `make git` target now supports a `NO_COMMIT=1` flag to stage files
without making the initial `BigBang` commit. This is useful when you
want to review staged files before committing:

```bash
make git NO_COMMIT=1
```

---

## Changes

### Installation Simplified

The installation instruction has been simplified — `CPAN::Maker` no
longer needs to be listed as a separate install target since it is
pulled in as a dependency:

```bash
# Before
cpanm CPAN::Maker CPAN::Maker::Bootstrapper

# After
cpanm CPAN::Maker::Bootstrapper
```

### Documentation Updates

- The "WHY YOU SHOULD CONSIDER USING..." section heading has been
  renamed from "YET ANOTHER BUILD TOOL" to "CPAN::Maker::Bootstrapper"
  for clarity.
- POD and `README.md` updated throughout to reflect the new
  `extra-files` command, the `NO_COMMIT` option, and the simplified
  install command.

### Command Registry Alignment

`cpan-maker-bootstrapper.yml` has been updated to register the new
`extra-files` command and entries have been reformatted for improved
readability:

```yaml
extra-files: CPAN::Maker::Bootstrapper::Role::ExtraFiles
```

### `.gitignore` Updates

Two new ignore patterns have been added:

- `*.bak` — backup files
- `buildspec.yml.current` — transient build state file

---

## Files Changed

| File | Change |
|------|--------|
| `lib/CPAN/Maker/Bootstrapper/Role/ExtraFiles.pm.in` | **New** — implements `extra-files` command |
| `cpan-maker-bootstrapper.yml` | Registered `extra-files` command; formatting cleanup |
| `.includes/git.mk` | Added `NO_COMMIT` support to `make git` |
| `lib/CPAN/Maker/Bootstrapper.pm.in` | POD updates |
| `README.md` | Regenerated |
| `VERSION` | Bumped to `2.0.8` |
| `.gitignore` | Added `*.bak` and `buildspec.yml.current` |

---

## Upgrade

```bash
cpanm CPAN::Maker::Bootstrapper
make update
```
