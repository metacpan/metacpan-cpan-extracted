# CPAN::Maker::Bootstrapper 2.0.2 Release Notes

## Overview

A patch release addressing bugs shaken out during real-world use of the
2.0.1 toolchain. The main themes are: immutability enforced on installed
files, smarter `make update`, conditional linting dep installation,
build-time deps embedded in `builder`, and two `find`/`scan` fixes for
multi-directory projects.

---

## Bug Fixes

**`find-files` and `scan-deps` broken for multi-directory source trees**

Both the `find-files` make function and the `scan-deps` recipe used
`find $(2)` where `$(2)` could be a space-separated list such as
`lib bin`. `find` interprets this as a single path argument and fails.
Both are now wrapped in a `for d in $(2)` loop so multiple directories
are traversed correctly.

**`update-available` version comparison was string equality**

The version check used `=` to compare the installed and available
Bootstrapper versions, which would incorrectly report "up to date"
whenever the strings matched exactly but fail to detect patch-level
upgrades in some orderings. It now uses `version->parse()` from the
core `version` module for a proper semantic comparison:

```bash
update_available=$(current="..." cpan="..." perl -Mversion -e \
  'print version->parse($ENV{cpan}) > version->parse($ENV{current});')
```

**`make update` left managed files writable**

The `update` target was setting files writable before copying but
never restoring them to read-only afterward, leaving `Makefile` and
`.includes/*` writable after every update. The target now explicitly
runs `chmod -w` after all copies complete. The `post-update` loop also
applies `chmod -w` immediately after each file is copied rather than
before.

**`_install_files` not enforcing immutability**

The `bootstrapper` initializer set `.includes/*.mk` files to `0644`
(writable by owner), making it easy to accidentally edit a managed
file. Files are now installed as:

- `.includes/*.mk` - `0444` (read-only)
- `Makefile` - `0444` (read-only)
- `builder` - `0555` (read-only, executable)

---

## Changes

**`builder` - build deps embedded, linting conditional on rc files**

`build-requires` is removed as a separate file. The Perl build-time
dependencies it contained are now embedded directly in `builder`'s
`EXTRA_DEPS` array, eliminating one file for `make workflow` to manage
and one potential source of drift between projects.

`Perl::Tidy` and `Perl::Critic` (and its policy plugins) are now only
installed when the corresponding rc file is detected in the repo
(`$PERLTIDYRC` / `$PERLCRITICRC`). Previously they were always
installed, adding unnecessary install time to projects that don't use
them.

**`build-ci` - build time recorded and `build.log` symlink**

`make build-ci` now records total elapsed build time at the end of the
log and creates a `build.log` symlink pointing to the timestamped log
file, so `less build.log` always shows the most recent run without
needing to remember the timestamp.

**`test` and `check` targets added to Makefile**

`make test` runs the unit test suite via `prove`. `make check` performs
a syntax check and generates source files from `.in` templates - useful
as a pre-build sanity step.

---

## Deleted

`build-requires` - contents absorbed into `builder`. Removed from
`buildspec.yml` `extra-files` and no longer installed by `make workflow`.
