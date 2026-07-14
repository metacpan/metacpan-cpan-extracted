# Release Notes - CPAN::Maker::Bootstrapper 2.0.6

**Release Date:** Mon Jul 13 2026
**Version:** 2.0.6

---

## Overview

This release focuses on documentation quality improvements, build
system enhancements, and a more streamlined user experience. The most
visible change is the introduction of `cmb` as the canonical short
alias for the `cpan-maker-bootstrapper` command throughout all
documentation and examples. POD validation has been integrated
directly into the syntax-checking pipeline, ensuring documentation
quality is enforced at build time alongside code quality.

---

## What's New

### `cmb` Command Alias

All documentation, examples, and SYNOPSIS blocks have been updated to
use `cmb` as the canonical command name in place of the verbose
`cpan-maker-bootstrapper`. The binary itself has been added to
`.gitignore`.

### POD Checking Integrated into Build Pipeline

`podchecker` is now run automatically as part of the syntax-checking
stage for both `.pm` and `.pl` files. If a generated file contains
invalid POD, the build will fail with a descriptive error before the
file is committed to the distribution. Files that contain no POD or
pass cleanly are accepted without issue.

```makefile
podcheck="$$($(PODCHECKER) $@ 2>&1 || true)";
echo "$$podcheck" | grep -q "does not contain\|OK" || { rm -f "$@"; echo "$$podcheck"; exit 1; }
```

This gate is subject to the same `LINT` and `PERLWC_SKIP` controls as
the existing syntax checks.

### `clean-local` Extension Target

The `Makefile` now defines a `clean-local` double-colon target that
projects can hook into without modifying the managed `Makefile`. Add
project-specific cleanup logic in `project.mk`:

```makefile
clean-local::
        rm -rf workdir
```

### Default Help Sections Configured

`cpan-maker-bootstrapper.yml` now declares default help sections so
that `--help` output is scoped to the most useful sections by default:

```yaml
default_options:
  help_sections:
    - SYNOPSIS
    - COMMANDS
    - OPTIONS
```

---

## Documentation Improvements

### Restructured COMMANDS and OPTIONS as Top-Level Sections

The `USAGE` section has been removed. `COMMANDS` and `OPTIONS` are now
promoted to top-level `=head1` POD sections, improving navigation in
generated `README.md` and on MetaCPAN.

### Improved QUICK START Section

The Quick Start walkthrough has been reorganised into a structured
`Next Steps` subsection with clearly labelled action items, making it
easier to follow as a step-by-step guide after scaffolding a first
project.

Linting behaviour at bootstrap time is now explicitly documented,
including guidance on temporarily disabling gates:

```sh
LINT=off make
SKIP_TESTS=1 make
```

### Clarified DESCRIPTION

The module description has been tightened to more accurately describe
what `CPAN::Maker::Bootstrapper` does and its relationship to
`CPAN::Maker`. The note about AI-generated release note examples now
links directly to the `release-notes/` directory in the GitHub
repository.

### Corrected `buildspec.yml` Examples

Example entries in the `extra_files` / `share` documentation now
correctly describe where files are installed and fix a typo
(`ChangleLog` → `ChangeLog`).

### Corrected `Makefile` Recipe Documentation

A stray typo (`repipes` → `recipes`) in the build step description has
been fixed.

### New `PERLWC_SKIP`, `POD`, and `PERLINCLUDE` Variables Documented

The `EXTENDING THE BUILD SYSTEM` section now documents three
previously undocumented Makefile variables:

| Variable | Purpose |
|---|---|
| `PERLWC_SKIP="file1 file2"` | Space-separated list of files excluded from syntax and POD checks |
| `POD=extract\|remove` | Extract POD to a companion `.pod` file or strip it from the built `.pm` |
| `PERLINCLUDE="-I path"` | Additional include paths used during `perl -wc` syntax checking |

### `SKIP_TESTS` Clarification

`SKIP_TESTS=1` is now documented as a `CPAN::Maker` variable (not a
bootstrapper variable), with an explicit description of its effect on
the distribution build.

### `What Belongs in project.mk` Capitalisation Fix

Section heading corrected from lowercase to title case.

### Continuous Integration Documentation Added

A new `Continuous Integration` subsection in the POD documents the
`builder` script, `make workflow`, and `make build-ci` targets in
detail, including:

- How to run `builder` manually inside Docker
- Environment variables (`INSTALLER`, `PERLTIDYRC`, `PERLCRITICRC`,
  `BUILD_BRANCH`, `GITHUB_REF_NAME`)
- Override files (`build-apt-deps`, `build-mirrors`)
- `make build-ci` control variables

### `make workflow` and `make build-ci` Documented in Makefile Targets

Both targets now appear in the documented Makefile target list with
descriptions and usage examples.

---

## Bug Fixes

- Fixed incorrect `buildspec.yml` example text: `include is
  distribution tarball` → `included in distribution tarball`
- Fixed stray reference to `bootstrapper` (old binary name) in import
  examples — all now use `cmb`
- Fixed `cpan-maker-bootstrapper` references in bug-reporting
  instructions — now use `cmb --version`

---

## Files Changed

| File | Change |
|---|---|
| `.gitignore` | Added `bin/cmb` |
| `.includes/perl.mk` | Added `podchecker` integration into `check_syntax_pm` and `check_syntax_pl` |
| `Makefile` | Added `clean-local` phony double-colon target; `clean` now depends on `clean-local` |
| `cpan-maker-bootstrapper.yml` | Added `help_sections` to `extra_options` and `default_options` |
| `lib/CPAN/Maker/Bootstrapper.pm.in` | Extensive POD fixes; `COMMANDS` and `OPTIONS` promoted to `=head1`; all `cpan-maker-bootstrapper` references replaced with `cmb`; CI documentation added |
| `README.md` | Regenerated from updated POD |
| `VERSION` | Bumped `2.0.5` → `2.0.6` |

---

## Upgrade Notes

Run `make update` in any existing project to pull in the updated
`.includes/perl.mk` with `podchecker` support. If your source files
contain invalid POD, the build will now fail at the syntax-check
stage. Resolve POD errors or add affected files to `PERLWC_SKIP` in
`project.mk` to bypass the check while you clean up.

If your project requires custom cleanup steps, move them from an
inline `clean` override to the new `clean-local` double-colon target
in `project.mk`.
