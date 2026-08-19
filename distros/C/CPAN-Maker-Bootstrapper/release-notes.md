# CPAN::Maker::Bootstrapper 2.2.3 Release Notes

**Release Date:** August 18, 2026
**Released by:** Rob Lauer

---

## Overview

Version 2.2.3 is a maintenance release delivering targeted bug fixes
and improvements to the build system, along with a new feature in the
installer for configuring build mirrors via an environment variable.

---

## What's New

### `BUILD_MIRRORS` Environment Variable Support

The `cmd_install` method in
`CPAN::Maker::Bootstrapper::Role::Installer` now supports a
`BUILD_MIRRORS` environment variable. When set, its value is written
to a `build-mirrors` file prior to invoking `make`, allowing you to
specify one or more CPAN mirrors (comma-separated) for use during
CI/Docker builds.

**Example:**

```bash
BUILD_MIRRORS="https://cpan.example.com,https://mirror.example.org" cmb install --module My::Module
```

---

## Build System Fixes & Improvements

### Makefile

- **`GIT_DIRTY` fix:** The fallback `echo 'unknown'` was previously
  missing, causing the shell to silently fail if `git describe` was
  unavailable. This has been corrected.
- **`TEMPLATE_VARS` updated:** `MIN_PERL_VERSION` is now included in
  the template variable set, making it available for use in `.in` file
  templating and `buildspec.yml` generation.
- **`buildspec.yml` recipe refactored:**
  - Now calls `gen-vars-file` to generate `buildspec.yml.tmpl.vars` before resolving variables.
  - A `trap` ensures `buildspec.yml.tmpl.vars` is cleaned up on exit.
  - `resolve-vars` now locates `buildspec.yml.tmpl.vars` by default,
    removing the need to pass template vars explicitly on the command
    line.

### MANIFEST

- `local.mk` has been added to the distribution manifest, ensuring it
  is included in packaged releases.

---

## Files Changed

| File | Change |
|------|--------|
| `lib/CPAN/Maker/Bootstrapper/Role/Installer.pm.in` | Added `BUILD_MIRRORS` environment variable support |
| `Makefile` | Fixed `GIT_DIRTY`, added `MIN_PERL_VERSION` to `TEMPLATE_VARS`, refactored `buildspec.yml` recipe |
| `MANIFEST` | Added `local.mk` |
| `VERSION` | Bumped to `2.2.3` |
| `README.md` | Regenerated |
| `release-notes.md` | Updated |

---

## Upgrade Notes

This release is fully backward compatible with 2.2.2. No changes to
public APIs or module interfaces are required.
