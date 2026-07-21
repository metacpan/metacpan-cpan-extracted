# Release Notes: CPAN::Maker::Bootstrapper 2.0.11

**Release Date:** 2026-07-20
**Version:** 2.0.11

---

## Overview

This release refactors the build system's syntax-checking
infrastructure to decouple syntax/POD validation from the templating
pipeline. The change resolves a class of build ordering failures
caused by GNU Make treating intermediate `.pm`/`.pl` files as
disposable, and introduces a cleaner, two-phase approach to module
generation and validation.

---

## What's Changed

### Build System: Syntax Checking Decoupled from Templating (`perl.mk`)

The most significant change in this release is the separation of Perl
syntax and POD checking from the template expansion rules that
generate `.pm` and `.pl` files.

**Previously**, syntax checking was embedded directly in the `%.pm`
and `%.pl` pattern rules. This caused two problems:

1. GNU Make could treat built `.pm`/`.pl` files as disposable
   intermediate files and delete them after the check-syntax step
   consumed them, even though they are actual build deliverables.
2. During `deps.mk` regeneration, syntax checking could fail because
   sibling modules referenced by a freshly added `use` statement might
   not yet exist on disk.

**Now**, a dedicated two-phase approach is used:

- **Phase 1 — Templating** (`%.pm.in → %.pm`, `%.pl.in → %.pl`):
  Performs only token substitution and POD extraction. Cannot fail due
  to cross-module ordering issues.
- **Phase 2 — Syntax checking** (`%.pm → %.pm.checked`, `%.pl →
  %.pl.checked`): Runs `perl -wc` and `podchecker` only after *all*
  modules and scripts in the build are already on disk, so
  inter-module dependency ordering is a non-issue by the time
  validation runs.

A new `.PHONY` target, `check-syntax`, aggregates all sentinel
`.checked` files:

```make
check-syntax: $(PERL_MODULES:%.pm=%.pm.checked) $(PERL_BIN_FILES:%.pl=%.pl.checked)
```

`.checked` sentinel files are added to `CLEANFILES` and to `.gitignore`/`gitignore`.

The `%.pm` and `%.pl` targets are now declared `.PRECIOUS` to prevent
GNU Make from deleting them as intermediate files during the
pattern-rule chain.

### Improved Skip-List Handling for Syntax Checking

Both `check_syntax_pm` and `check_syntax_pl` make macros now support a
`compile.skip` file in addition to the existing `PERLWC_SKIP` make
variable:

- If `compile.skip` exists in the project root, its contents are
  merged with `PERLWC_SKIP`.
- A temporary file is used to combine both sources cleanly, with a
  `trap`-based cleanup to prevent temp file leakage.
- Variable references now correctly use `$<` (the prerequisite) rather
  than `$@` (the target), fixing a latent bug.

### `check-syntax` Added as a Tarball Dependency (`Makefile`)

The `$(TARBALL)` target now explicitly depends on `check-syntax`,
ensuring all modules and scripts pass syntax and POD validation before
a distribution tarball is produced:

```make
$(TARBALL): $(DEPS) \
    check-syntax \
    ...
```

### `tidy` Target Updated

The `tidy` convenience target has been updated to invoke `make
check-syntax` rather than building the raw `.pm`/`.pl` files directly,
keeping it consistent with the new two-phase build model.

### Git::Raw is now optional

In previous versions `Git::Raw` was required. It is now only
*recommended*.  `Git::Raw` requires the libgit2 and building the XS
module is typically rather slow. User's who want to use the `make
release-notes` feature should install `Git::Raw` and `LLM::API`.

---

## Files Changed

| File | Change |
|------|--------|
| `.includes/perl.mk` | Decoupled syntax checking; added `.checked` sentinel rules; added `compile.skip` support; added `.PRECIOUS` declaration; fixed `$@` → `$<` in check macros |
| `Makefile` | Added `check-syntax` as a dependency of `$(TARBALL)` |
| `.gitignore` | Added `**/*.checked` |
| `gitignore` | Added `**/*.checked` |
| `VERSION` | Bumped to `2.0.11` |
| `README.md` | Regenerated from POD |

---

## Upgrade Notes

Run `make update` in any project using the bootstrapper to pull the
updated `.includes/perl.mk` and `Makefile` into your project.

```bash
make update
git diff .includes/ Makefile
```

If you have any files that cannot be compiled outside their runtime
environment (e.g. Apache handlers, mod_perl modules), add them to a
`compile.skip` file in your project root or to `PERLWC_SKIP` in
`project.mk`:

```make
# project.mk
PERLWC_SKIP = lib/My/Apache/Handler.pm
```

or:

```
# compile.skip
lib/My/Apache/Handler.pm
```

---

## Bug Fixes

- Fixed a latent variable reference bug in `check_syntax_pm` and
  `check_syntax_pl` macros where `$@` (the rule target) was used
  instead of `$<` (the rule prerequisite) when referring to the file
  being checked.
- Resolved a class of build failures where GNU Make deleted freshly
  built `.pm`/`.pl` files as disposable intermediates during
  pattern-rule chain execution.
- Fixed a race-like build ordering issue where syntax checking of a
  module containing a `use` of a sibling module could fail during
  `deps.mk` regeneration if that sibling had not yet been built.
