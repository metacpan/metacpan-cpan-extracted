---
name: dbio-perl-syntax
description: Load before editing any .pm, .pl or .t in a DBIO distribution — module loading, file preamble, per-module $VERSION, whitespace, idioms, cpanfile versioning.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO Perl Syntax — The Baseline

This is **the one way** DBIO writes pure Perl. Every DBIO distribution follows
this as its base, then adapts where its domain demands. Derived from the actual
core code in `dbio/lib/DBIO/`.

This skill covers *pure Perl syntax and conventions only*. For building classes
(CAG accessor groups, constructors, `load_components`) see
[[dbio-perl-class-patterns]]. For the optional Moo/Moose bridges and codegen see
[[dbio-moo-moose]] (installed in core only). For release/dzil see [[dbio-perl-release]].

## File preamble

Every `.pm` looks like this — copy the shape exactly:

```perl
package DBIO::AccessBroker::Static;
# ABSTRACT: One fixed set of connection parameters as an AccessBroker

use strict;
use warnings;

use base 'DBIO::AccessBroker';
```

- `package` first, then **`# ABSTRACT:`** on the very next line (PodWeaver reads it).
- **strict and warnings are always active** — who loads them doesn't matter.
  Plain Perl: `use strict; use warnings;` right after the abstract. Moo/Moose/Cake
  load them themselves; that satisfies the rule, it is not an exception.
- Blank line between logical groups of `use` statements.
- **`use namespace::clean` wipes every sub defined before it** at the end of compile. A method that must stay callable (`dbio_deploy_class`, a hook, an override) is defined *after* it.

## `$VERSION` in every module

**Every shipped `.pm` under `lib/` carries a literal `our $VERSION = '...'`** — not
only the main module, and all of them the *same* version. Canonical placement is
right after `use warnings;`; some main modules carry it directly under `package` /
`# ABSTRACT:` — both are fine, don't churn existing files just to move the line. Do
NOT remove a `$VERSION`, and do NOT flag one in a sub-module as a violation.

## Module loading

- **`use Module;`** at the top. Always. Every dependency is loaded at compile time.
- **Empty-import idiom:** when you only call functions fully-qualified, load with
  empty parens so nothing is exported:
  ```perl
  use Scalar::Util ();
  use DBIO::Util ();
  ...
  Scalar::Util::blessed($class);
  ```
- **For new code:** existing `require`s in core (some in method bodies) are heritage, not the model.
- **`require` is forbidden as a "lazy optimization".** Never use it to shave
  startup. If you write `require Foo;` inside a method body, stop — hoist it to a
  top-level `use`.
- **`require` is allowed ONLY when essential** — true runtime plugin loading (the
  class is determined from config/DB at runtime, e.g.
  `ensure_class_loaded($class_from_db)`, `Module::Runtime::use_module($x)`), a
  documented **optional** dependency probed at runtime, or inside a `::Util`
  class. `::Util` classes are the exception: they wrap the things that are
  otherwise forbidden (see File I/O). If the class name is known at write-time
  and the dep is required, `use` it.
- **`require Foo; Foo->new` inside a controller action** is a red flag. Hoist to `use`.

## Singletons

- **`->instance`** for `MooseX::Singleton` / `MooX::Singleton` classes. Never `->new` a singleton.
- **`->new`** for everything else.

## Whitespace & idioms

- **2-space indentation.** Not 4. Not tabs. Heritage 4-space files stay as-is
  until they are touched; new code is 2-space.
- **Trailing commas are the standard** on multi-line lists — preferred, not just
  allowed. Single-line lists stay comma-free.
- **`//` defined-or** for argument defaults, not `||`:
  ```perl
  $self->username($args{username} // '');
  $mode //= 'write';
  ```
- **`$_[0]`** direct argument access is fine in hot/tiny accessors (see core `Base.pm`);
  prefer named `my ($self, ...) = @_;` everywhere else for readability.
- POD is **inline** next to the code it documents (`=method`, `=attr`), not in a block at EOF.
- `=encoding` depends on whether the file is valid POD before weaving. PodWeaver
  (`-SingleEncoding` in `@DBIO`) strips every source `=encoding` and emits exactly one at
  build time, `.pod` files included, so the build never needs the source line (core k217).
  - A file using `=method`/`=attr` carries **no `=encoding` line**, even with
    non-ASCII (em-dashes, `§`) in the POD. It is not valid POD until the weaver runs, and
    `xt/pod.t` skips it, so the line serves nothing (core k167).
  - A file with **only plain POD** (`=head1`/`=item`, no weaver directives; every `.pod`
    manual) **keeps `=encoding UTF-8`** at the head of its first POD block. `xt/pod.t`
    checks these files raw and fails on "Non-ASCII character seen before =encoding"
    (core k115). Keep the line even while the file is pure ASCII, so the first em-dash
    does not break it.
  - Check woven POD on the `dzil build` output; `podchecker` on a raw directive file
    measures nothing.
- End every module with a lone `1;`.

## File I/O

- **`DBIO::Util` file helpers** for every file operation. Core deliberately
  excludes `Path::Tiny` (see core cpanfile) and wraps the core-Perl modules
  instead: `dir_path`, `file_path`, `parent_dir`, `slurp_file`,
  `slurp_file_utf8`, `write_file`, `mkpath`, `rmtree`.
  ```perl
  use DBIO::Util qw(file_path slurp_file_utf8);
  my $src = slurp_file_utf8(file_path($tmpdir, 'Result', 'User.pm'));
  ```
- **`File::Temp`** for temporary files/dirs (mostly tests). Core module, fine as-is.
- No `Path::Tiny`. No direct `File::Spec`. No bare `open` in app code — `::Util`
  classes are the wrapper for the forbidden things: they may `require` and
  bare-`open` internally, app code never does.

## JSON

- **`JSON::MaybeXS`** always. On the encoder object set `canonical => 1, convert_blessed => 1`.

## cpanfile versioning — DBIO-authored deps

The family is developed against the **staged, unreleased** version: every repo's `$VERSION`
is the number the family is released as, ahead of the last CPAN tag.

1. **Pin a DBIO-family dep to the staged family version** — the dep repo's own
   `$VERSION` (`grep VERSION dbio/lib/DBIO.pm`), the same number in every repo's
   cpanfile. A pin equal to the dep repo's `$VERSION` is correct, not a defect; do
   **not** "correct" it back to the last released number.
2. **Consistency is the check:** `grep "'DBIO'" */cpanfile` shows one number everywhere.
   A repo still on the previous number was missed by the sweep — bring it forward.
3. Never `'0'` and never a stale number for a DBIO-authored dep.
4. A non-DBIO dep pinned to a specific version is checked with `cpanm --info Module::Name`.
5. Staging pins are set deliberately, as part of a release run, never in passing.
   Cross-repo development installs happen via `dzil install` in the dependency's repo.

## Testing

- Core tests MUST use `DBIO::Test::Storage` (fake storage). Never `dbi:SQLite` or any real DB in core.
  (Integration dists like `dbio-graphql` that exist to test full roundtrips may
  use in-memory SQLite — the hard rule is for core.)
- Driver tests read DSN from env: `DBIO_TEST_<DRIVER>_DSN` / `_USER` / `_PASS`.
- Optional deps skip cleanly, and go in cpanfile as `suggests`, never `requires`:
  ```perl
  BEGIN { eval { require Moo; 1 } or plan skip_all => 'Moo not installed' }
  ```

## Forbidden / anti-patterns

- ❌ `require Foo` inside a method to "speed up startup" (exception: `::Util` classes)
- ❌ Using a `$VERSION` from a DBIO repo as a cpanfile requirement
- ❌ 4-space indent or tabs in new Perl files (heritage 4-space files stay until touched)
- ❌ `Path::Tiny`, direct `File::Spec`, or bare `open` in app code — use the `DBIO::Util` file helpers (`::Util` classes may wrap them)
- ❌ `||` where `//` is meant (clobbers legitimate `0`/`''`)
- ❌ `Data::Dumper` in shipped code (use `DDP`/`Data::Printer` for debug, strip before commit; `DBIO::Util::dump_value` is the sanctioned debug helper)

## When in doubt

Grep real core code: `../dbio/lib/DBIO/` (the core checkout next to this repo). For class-building
specifics go to [[dbio-perl-class-patterns]].
