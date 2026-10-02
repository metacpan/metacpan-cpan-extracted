## CPAN::Maker::Bootstrapper 2.3.6 Release Notes

### Overview

This release adds selective filtering for DarkPAN dependency
manifests, allowing specific modules to be excluded from the
generated `cpanfile.darkpan` and `cpanm.darkpan` files. It also
fixes a bug where the `deps-filter` command would emit a trailing
newline on empty output, and includes documentation and build
system improvements.

### New Features

#### DarkPAN Module Filtering

The `create-darkpan-requires` command now accepts an optional
`--filter` flag naming a file that contains module names to exclude
from the generated DarkPAN manifests, one module per line:

```
cmb create-darkpan-requires --filter darkpan.skip requires
```

This is useful when a module exists on both CPAN and the DarkPAN
but should be resolved from CPAN. When invoked through the project
`Makefile`, a `darkpan.skip` file in the project root is detected
and applied automatically.

The command also now accepts an optional positional argument
specifying an alternative `requires` file, rather than always
reading from the default `requires` file.

### Bug Fixes

- `deps-filter` no longer writes empty output when the filtered
  dependency list is empty, preventing spurious blank files from
  being generated.

### Documentation

- Expanded documentation for `DARKPAN_REQUIRES` and
  `create-darkpan-requires` to describe the DarkPAN/CPAN
  precedence behavior and the new `darkpan.skip` mechanism.
- Clarified the rationale for including `cpanfile.darkpan` and
  `cpanm.darkpan` in `extra-files.skip`.

### Build System Changes

- `CLEANFILES` list updated: `*.darkpan` glob replaced with
  explicit entries for `cpanfile.requires`, `cpanfile.recommends`,
  `cpanfile.runtime`, and `cpanfile.suggests`. Note that
  `cpanfile.darkpan` is now intentionally excluded from the clean
  target and preserved in `.gitignore` via a negation rule
  (`!cpanfile.darkpan`).
- The `--filter` option was added to `cpan-maker-bootstrapper.yml`.
- Code reorganization in `Filter.pm.in`: `cmd_filter` moved to the
  top of the file with no functional change.

---

