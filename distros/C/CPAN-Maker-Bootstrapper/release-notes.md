# CPAN::Maker::Bootstrapper 2.4.1 Release Notes

## Overview

This release significantly improves build performance, adds five new
`cmb` commands, extends several existing commands with
batch-processing and filtering capabilities, restructures the build
system around a new `build-config.mk` generated artifact, and requires
GNU Make 4.3 or newer. Projects using managed build files will need to
run `make update` after upgrading.

---

## Performance Improvements

A major focus of 2.4.1 is reducing both command startup time and
repeated work during builds.

The modulino wrapper now loads `CPAN::Maker::Bootstrapper` only once.
Previously, the wrapper started Perl and loaded the module to locate its
installed file, then started Perl again and loaded the same module to
execute it. In testing, eliminating the second module load reduced
startup time for a lightweight `cmb` command by roughly 60 percent.

CLI startup work has also been reduced by taking advantage of
CLI::Simple 2.3.0 selective role loading. Commands declared as selective
roles load only the roles they require rather than composing the
complete legacy command set.

Several roles also now lazy load heavier dependencies, reducing startup
cost even for commands that still use legacy role composition. The
actual savings depend heavily on each role's dependency graph, so these
results should be treated as representative rather than universal.

Build-time work has also been consolidated to reduce repeated process
startup and setup costs. `perlcritic`, `perltidy`, and `resolve-vars`
can now process batches of files through a single `cmb` invocation
rather than starting a new Perl process for each source file. Dependency
reconciliation similarly processes multiple dependency classes in one
invocation.

Across the CMB build itself, these changes reduced elapsed build time
from roughly 1 minute 20 seconds to about 30 seconds in our testing,
an overall improvement of approximately 60 percent.

Incremental builds benefit as well. Generated dependency artifacts are
no longer rewritten when their contents have not changed, preserving
their timestamps and allowing Make to avoid unnecessary downstream
rebuilds.

### Developer Impact

The result is that developers are no longer heavily penalized for
leaving the full quality pipeline enabled during normal development.
In testing, an incremental CMB build after modifying a source file,
with the normal quality gates enabled, completed in under nine
seconds.

The faster build graph also improves the normal edit-test cycle. Because
`make test` does not produce a distribution tarball, it does not invoke
the tarball-oriented quality gates. It still performs dependency
discovery and installs newly required modules into the project-local
`local-lib` environment as needed before running the test suite.

In testing, touching a source file and running `make test` completed in
roughly 2.5 seconds, making `edit -> make test` a practical low-latency
development loop without giving up automatic dependency maintenance.

## New Commands

### `create-build-config`

`cmb create-build-config` generates a `build-config.mk` file
containing Make variable assignments for module paths, project
defaults, and discovered build helper commands (`perltidy`,
`perlcritic`, etc.). The `Makefile` now includes this generated file
rather than discovering tools inline within `perl.mk`. On a fresh
checkout, `build-config.mk` is generated automatically as a
prerequisite of the first build.

### `perlcritic` and `perltidy`

Two new commands expose `Perl::Critic` and `Perl::Tidy` through
`cmb` for use as build-system CI gates:

- `cmb perlcritic [--file-list FILE] [--severity N]
  [--theme NAME] [--profile FILE] source ...`
  Critiques one or more source files and writes violations to `.crit`
  sentinel files.

- `cmb perltidy [--file-list FILE] [--profile FILE] source ...`
  Verifies source files against a perltidy profile and creates `.tdy`
  sentinel files for sources that pass.

Both commands accept either individual file arguments or a
newline-delimited `--file-list`, enabling `perl.mk` to batch
perltidy and perlcritic checks through a single `cmb` invocation
rather than calling the underlying tools directly. `Perl::Tidy` is
now listed as a suggested dependency.

### `reconcile-deps`

`cmb reconcile-deps TYPE [TYPE ...]` reconciles one or more dependency
types (`requires`, `recommends`, `suggests`, `test-requires`) in a
single invocation, applying both dependency and DarkPAN filtering
before writing results. The `Makefile` now calls this command through
a grouped Make target rather than running separate per-type
reconciliation steps. Files are not rewritten when their content has
not changed.

### `update-available`

`cmb update-available` queries MetaCPAN for the latest published
version of `CPAN::Maker::Bootstrapper` (or a named module) and
reports when a newer release is available. The `update-available`
Make target now delegates to this command instead of implementing
the check inline in `update.mk`.

---

## New Make Targets and Build System Changes

### GNU Make 4.3 Required

The `Makefile` now checks for the `grouped-target` feature at startup
and stops with an error if GNU Make 4.3 or newer is not available.
Grouped targets (`&:`) are used for dependency reconciliation and
several other rules; this is now a hard requirement rather than a
silent assumption.

### `build-config.mk` and `build-init.mk`

Build-time tool and configuration discovery has been moved out of
`perl.mk` and into two new files:

- `.includes/build-init.mk` — validates required build tooling,
  derives the CPAN installer in use, and centralizes prerequisite
  checks. This file is new and is now included in the distribution's
  managed file set (`MANIFEST`, `cmb_md5sums.txt`, `buildspec.yml`).

- `build-config.mk` — generated by `cmb create-build-config` on
  first build, contains resolved variable assignments for the current
  project. Added to `.gitignore` and `CLEANFILES`; it is not tracked
  in source control.

### Rendered Source Files as Build Intermediates

Module source files (`.pm.in`) now go through an explicit
`.rendered` intermediate step before POD processing and syntax
checking. `perl.mk` generates `.rendered` files in a single batched
`cmb resolve-vars` invocation using `--file-list`. The rendered
files are tracked as `.SECONDARY` build artifacts and are cleaned
by `make clean`. POD checking is now performed against the rendered
source rather than the `.in` file.

### `quick` and `real-quick` Targets

`make quick` now also disables POD checking in addition to scanning
and linting. A new `make real-quick` target disables scanning,
linting, POD checking, and syntax checking, for the fastest possible
iterative build.

### Dependency Reconciliation Changes

The `Makefile` uses a single grouped Make target to reconcile
`requires`, `recommends`, `suggests`, and `test-requires` together.
After reconciliation, modules listed in `provides` are removed from
`test-requires`. Reconciled files are not rewritten when their content
has not changed.

### `dist-file --path-only`

`cmb dist-file` gains a `--path-only` option that prints the resolved
filesystem path to a distribution file instead of its contents. The
`update-available` target in `update.mk` uses this to locate
`cmb_md5sums.txt` without reading the file.

### `resolve-vars` Batch Mode

`cmb resolve-vars` now accepts `--file-list FILE` to process multiple
`.in` sources in one invocation, writing each result to a
corresponding `.rendered` file. The `source-file` positional argument
and `--file-list` are mutually exclusive.

---

## Behavioral Changes

### Lazy Loading of Optional Dependencies

`HTTP::Tiny`, `IO::Uncompress::Gunzip`, `Storable`, and `MIME::Base64`
are now loaded on demand within the roles that use them
(`DarkPANRequires`, `DepsFilter`, `PAUSEUpload`). This avoids
loading network and I/O modules for commands that do not need them.

### `show-defaults` Resolution Order

`_resolve_defaults` in `ShowDefaults` now resolves `perltidyrc` and
`perlcriticrc` through a defined search order: environment variable,
configuration file, project-local file, home directory. The same
logic applies to the `syntax-checking` setting.

### `dist-file` Default Distribution

`cmb dist-file` now defaults the distribution name to
`CPAN-Maker-Bootstrapper` when only a filename is supplied, so
callers within the bootstrapper's own build do not need to name the
distribution explicitly.

### `deps-filter` Internal Refactoring

Hash filtering logic in `DepsFilter` has been extracted into
`_filter_package_hash`, separating it from file I/O. This makes the
filtering step available for reuse by `ReconcileDeps` without
duplicating code.

### Filter Role Extraction

`_filter_requires` in `Filter` has been separated from the command
output path (`cmd_filter`), making the filtering logic callable
internally without producing console output.

### Modulino Wrapper Simplified

`bin/cmb.in`, `bin/cpan-maker-bootstrapper.in`, and
`share/modulino.tmpl` now load the module once and invoke `main`
directly via `-e 'exit $ENV{MODULINO_MODULE_NAME}->main'`, removing
an intermediate wrapper step. The two invocations of `perl` also
caused `CPAN::Maker::Bootstrapper` to unnecessarily be loaded twice;
once to determine its path and the second for execution.

### Release Notes Generation

Release-note generation now includes a `release-X.Y.Z.status` artifact
containing the equivalent of `git diff --name-status HEAD`. This gives
the LLM an explicit classification of added, modified, deleted, and
renamed files alongside the full diff, changed-file list, draft
tarball, and ChangeLog.

The `releases-note` prompt has also been expanded to treat those artifacts
according to their roles: the status identifies file state, the diff
describes implementation changes, the tarball represents the final
release, and the ChangeLog provides the maintainer-reviewed technical
record. This produces release notes organized around release themes
rather than a reformatted ChangeLog.

---

## Dependency Changes

- `CLI::Simple` minimum version bumped to **2.3.0**.
- `File::Which` **1.27** added as a runtime requirement (used for
  build helper discovery in `CreateBuildConfig`).
- `Perl::Tidy` **20260204** added as a suggested dependency.
- `Perl::Critic` was already suggested; no version change.

---

## Test Changes

`t/find-primary-package.t` now loads and applies
`CPAN::Maker::Bootstrapper::Role::Installer` directly using
`Role::Tiny` rather than loading the full bootstrapper. Host-specific
paths have been removed from the test cases, making the test suite
portable across environments.

---

## User Action Required

- **GNU Make 4.3 or newer is required.** Builds on older Make
  versions will fail immediately with a descriptive error.
- **Run `make update`** after upgrading to refresh managed files
  in `.includes/`, including the new `build-init.mk`.
- Projects that set `PERLTIDYRC` or `PERLCRITICRC` to control linting
  should review `show-defaults` output; the resolution order for these
  settings is now documented and consistently applied.
- `build-config.mk`, `config.mk`, and `*.rendered`
  files should be added to `.gitignore` if not already present.
  The managed `gitignore` template now includes these entries and
  `make update` will merge them into `.gitignore` for existing
  projects.

---

## ChangeLog Review Notes

The following observations concern the ChangeLog for 2.4.1; they
are not reflected in the release notes above.

1. **`dist-file` is listed under new "selective roles"** in the
   `cpan-maker-bootstrapper.yml` entry, but `DistFile` has existed
   since 2.4.0. The entry accurately notes that `dist-file` gains
   `--path-only` and a default distribution name, but the phrasing
   "move … to selective roles" may mislead readers into thinking
   `DistFile` is new in this release.

2. **`update-available` role** (`Role::UpdateAvailable`) is listed
   as new in 2.4.1, but the `update-available` Make target has been
   present since at least 2.0.9. The ChangeLog correctly describes
   it as a new role that backs the existing target; this distinction
   could be clearer.

3. **`create-build-config` and the `build-config.mk` mechanism** are
   among the most significant structural changes in this release, but
   the ChangeLog entry is brief relative to the scope of the change.
   The interaction between `build-config.mk`, `build-init.mk`, and
   the removal of inline discovery from `perl.mk` is spread across
   multiple terse entries.

4. **`_filter_package_hash`** is listed under `DepsFilter` but its
   role as the shared primitive consumed by `ReconcileDeps` is not
   called out. The `deps.mk` entry notes the dependency, but the
   architectural connection between the two roles is absent from the
   prose.

5. **The `real-quick` target** is mentioned only as "add real-quick
   target" in the `Makefile` section; its semantics (disables syntax
   checking in addition to scanning and linting, unlike `quick`) are
   not stated.

6. **`reader` added to `extra_options`** in `cpan-maker-bootstrapper.yml`
   is noted in the ChangeLog but its purpose—storing the
   `ConfigReader` instance on the application object—is only
   explained in the `Init.pm.in` entry. The connection is non-obvious
   to readers scanning the YAML entry alone.

---

*Add four new `cmb` commands (`create-build-config`, `perlcritic`,
`perltidy`, `reconcile-deps`), batch-process lint and render steps
through `cmb`, require GNU Make 4.3, and restructure build
initialization around a generated `build-config.mk`.*
