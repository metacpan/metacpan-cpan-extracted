# Release Notes — CPAN::Maker::Bootstrapper 2.3.5

## Summary

This release adds DarkPAN dependency manifest generation, a new
dependency deduplication filter, and direct CPAN publishing via
PAUSE. The dependency list is cleaned up by removing redundant
sub-module entries, and the build system gains an auto-generated
`MANIFEST` and improved separation of managed make files.

---

## New Features

### DarkPAN Dependency Manifests

A new `create-darkpan-requires` command (`cmb create-darkpan-requires`)
examines the `requires` file and generates two manifest files for
dependencies hosted on a private CPAN-compatible repository:

- `cpanfile.darkpan` — dependencies in cpanfile syntax
- `cpanm.darkpan` — one module requirement per line for `cpanm`

Enable generation via the Makefile by setting:

    DARKPAN_REQUIRES = yes
    DARKPAN_URL = https://cpan.example.com/repository

When enabled, `DARKPAN_URL` is required. The generated files are
included in the distribution as installation aids and are
automatically added to `extra-files.skip` (they are generated
artifacts, not source-controlled files).

### Dependency Deduplication Filter (`deps-filter`)

A new `deps-filter` command removes modules from a dependency list
that are already provided by another listed distribution. It
consults the public CPAN package index and any repositories in
`build-mirrors`, caching indexes locally. This command is now
invoked automatically by the Makefile when processing `requires`,
`recommends`, `suggests`, and `test-requires`.

### PAUSE Publishing (`publish-to-cpan` / `make publish`)

A new `publish-to-cpan` command uploads a distribution tarball to
PAUSE:

    cmb publish-to-cpan distribution.tar.gz [username [password]]

Credentials may also be supplied via `PAUSE_USER` and
`PAUSE_PASSWORD`. A new `make publish` target builds the
distribution, runs the full test suite, and uploads on success:

    make publish PAUSE_USER=username PAUSE_PASSWORD=password

### `TARBALL_ORDER_ONLY_PREREQS`

A new Makefile variable allows `project.mk` to declare order-only
prerequisites for the distribution tarball — steps that must run
before the tarball is built but that do not themselves make the
tarball out of date:

    TARBALL_ORDER_ONLY_PREREQS += prepare-assets

---

## Changes

### Dependency Cleanup

Several redundant sub-module entries have been removed from
`requires` and `cpanfile`. Modules that are re-exported by a
top-level distribution they already depend on no longer appear as
separate entries:

- Removed: `CLI::Simple::Constants`, `CLI::Simple::Utils`,
  `CPAN::Maker::Role::ModuleUtils`, `CPAN::Maker::Role::Provides`,
  `Role::Tiny::With`
- Added: `HTTP::Tiny`, `IO::Socket::SSL`, `Net::SSLeay`

### Makefile: Separated `test-requires` Filtering

The `test-requires.raw` recipe now only normalises the scan output.
A new dedicated `test-requires` recipe handles the full filter,
deduplication, and `provides` exclusion pipeline. The
`test-requires.skip` file has been removed as it is no longer needed.

### `MANIFEST` Now Auto-Generated

`MANIFEST` is now a build target generated from the list of managed
files and is added to `DEPS` in `project.mk`. The file is kept
sorted.

### `update.mk` Refactored

Managed make files are now tracked in a separate `MANAGED_MK_FILES`
variable, distinct from non-make managed files (`MANAGED_FILES`).
`publish.mk` is included in the managed set.

---

## Build System Changes

The build system has been updated in this release. Notable changes
include the addition of `.includes/publish.mk` (new managed include),
auto-generation of `MANIFEST` as a build target, and the introduction
of `MANAGED_MK_FILES` / `MANAGED_FILES` separation in `update.mk`.
The `CLEANFILES` list now also covers `*.darkpan` artifacts.

---

