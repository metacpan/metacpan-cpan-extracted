# CPAN::Maker::Bootstrapper 2.3.3 Release Notes

**Released:** Fri Sep 25 2026

## Overview

This is a maintenance release focused on build system housekeeping:
template files have been relocated to a dedicated `share/`
subdirectory, dependency scanning has been made more efficient by
separating test and runtime dependency workflows, and `.gitignore`
management has been cleaned up and aligned.

---

## Changes

### Template Files Relocated to `share/`

The following template files have been moved from the project root
into the `share/` subdirectory. References in `buildspec.yml` and the
project `.gitignore` have been updated accordingly.

| Old Location | New Location |
|---|---|
| `buildspec.yml.tmpl` | `share/buildspec.yml.tmpl` |
| `class-module.pm.tmpl` | `share/class-module.pm.tmpl` |
| `cli-module.pm.tmpl` | `share/cli-module.pm.tmpl` |
| `modulino.tmpl` | `share/modulino.tmpl` |
| `test.t.tmpl` | `share/test.t.tmpl` |

> **Note:** `share/modulino.tmpl` has had its executable bit removed (`chmod -x`).

---

### Build System Improvements (`Makefile`)

#### New Target: `cpanfile.runtime`

A new `cpanfile.runtime` target has been added that generates a
cpanfile containing only runtime (`requires`) dependencies — excluding
test dependencies. This is now the file that the `local` target
depends on, meaning that installing local dependencies for hermetic
syntax checking no longer pulls in test-only modules.

```makefile
cpanfile.runtime: requires
    $(CPAN_MAKER) create-cpanfile --dependency-type requires $< -o $@
```

#### New Target: `test-requires.scan`

Test dependency scanning has been split into two distinct steps to
avoid unnecessary rescans:

- **`test-requires.scan`** — scans test files (`t/`) and writes a raw
  sorted module list. This step depends only on the test files
  themselves.
- **`test-requires.raw`** — filters `test-requires.scan` against the
  `provides` file to remove internal modules. This step now depends on
  `test-requires.scan` and `provides` separately.

Previously these two operations were combined into a single
`test-requires.raw` recipe. The separation means a change to
`provides` no longer forces a full rescan of the test files.

#### `test-requires` Target Reworked

The `test-requires` phony target now depends directly on
`test-requires.raw` rather than `$(TESTS)`, reflecting the new
two-stage pipeline.

#### Generated Files Tracking

The following files are now explicitly listed in `GENERATED_FILES`
(and thus included in `CLEANFILES`):

- `provides`
- `cpanfile`
- `test-requires.scan`

All `cpanfile.*` variant files are also now cleaned up on `make clean`.

---

### `.gitignore` / `gitignore` Cleanup

Both `.gitignore` and the distributed `gitignore` template have been
aligned and reorganised. Key additions and changes:

- Entries are now grouped and sorted consistently using recursive glob patterns (`**/`)
- Added: `**/*.bak`, `**/*.log`, `**/*.pod`, `**/*.tdy`, `**/*.tmp`
- Added: `test-requires.scan`, `cpanfile.*`, `buildspec.yml.tmpl`, `test.t.tmpl`, `local/**`
- Removed redundant or inconsistently scoped patterns
- CMB-specific artifacts (`bin/bootstrapper`, `bin/cmb`,
  `bin/cpan-maker-bootstrapper`, `cmb_md5sums.txt`) are now clearly
  identified with a `# cmb specific` comment in `.gitignore`

---

### Local Dependency Installation (`local.mk`)

The `local` target now depends on `cpanfile.runtime` instead of the
full `cpanfile` (which includes test requirements). The `cpm install`
invocation has been updated to pass the cpanfile explicitly via
`--cpanfile $<`:

```makefile
cpm install -L local --cpanfile $< ...
```

This ensures that only runtime dependencies are installed into the
local hermetic library used for syntax checking.

---

## Upgrade Notes

- If you are using `make update` to manage your build system files, run it after upgrading to pick up the updated `Makefile`, `.includes/local.mk`, and `gitignore` template.
- The template files previously installed at the project root (`class-module.pm.tmpl`, `cli-module.pm.tmpl`, etc.) are now distributed under `share/`. Projects scaffolded with earlier versions are unaffected — the bootstrapper resolves these via `File::ShareDir` at install time.
- `cpanfile.*` files (including `cpanfile.runtime`, `cpanfile.requires`, etc.) are now listed in `CLEANFILES` and will be removed by `make clean`. Regenerate them with `make cpanfile` or `make local` as needed.

---

## Links

- [GitHub Repository](http://github.com/rlauer6/CPAN-Maker-Bootstrapper)
- [Issue Tracker](http://github.com/rlauer6/CPAN-Maker-Bootstrapper/issues)
