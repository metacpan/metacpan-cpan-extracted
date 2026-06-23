---
name: dbio-perl-syntax
description: "The one canonical Perl syntax/style baseline for all DBIO distributions — module loading, file preamble, whitespace, idioms, cpanfile versioning. Use before editing any .pm, .pl, or .t in a DBIO distribution."
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
[[dbio-moo-moose]]. For release/dzil see [[dbio-perl-release]].

## File preamble

Every `.pm` looks like this — copy the shape exactly:

```perl
package DBIO::AccessBroker::Static;
# ABSTRACT: Single-DSN AccessBroker drop-in replacement

use strict;
use warnings;

use base 'DBIO::AccessBroker';
```

- `package` first, then **`# ABSTRACT:`** on the very next line (PodWeaver reads it).
- **`use strict; use warnings;`** always, right after the abstract.
- Blank line between logical groups of `use` statements.

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
- **`require` is forbidden as a "lazy optimization".** Never use it to shave
  startup. If you write `require Foo;` inside a method body, stop — hoist it to a
  top-level `use`.
- **`require` is allowed ONLY for true runtime plugin loading** — the class is
  determined from config/DB at runtime (e.g. `ensure_class_loaded($class_from_db)`,
  `Module::Runtime::use_module($x)`), or the module is a documented **optional**
  dependency probed at runtime. If the class name is known at write-time and the
  dep is required, `use` it.
- **`require Foo; Foo->new` inside a controller action** is a red flag. Hoist to `use`.

## Singletons

- **`->instance`** for `MooseX::Singleton` / `MooX::Singleton` classes. Never `->new` a singleton.
- **`->new`** for everything else.

## Whitespace & idioms

- **2-space indentation.** Not 4. Not tabs.
- **No trailing commas** at the end of a multi-line list.
- **`//` defined-or** for argument defaults, not `||`:
  ```perl
  $self->username($args{username} // '');
  $mode //= 'write';
  ```
- **`$_[0]`** direct argument access is fine in hot/tiny accessors (see core `Base.pm`);
  prefer named `my ($self, ...) = @_;` everywhere else for readability.
- POD is **inline** next to the code it documents (`=method`, `=attr`), not in a block at EOF.
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
- No `Path::Tiny`. No direct `File::Spec`. No bare `open` in new code.

## JSON

- **`JSON::MaybeXS`** always. On the encoder object set `canonical => 1, convert_blessed => 1`.

## cpanfile versioning — DBIO-authored deps

DBIO `dist.ini` uses `[@DBIO]`, which sets `$VERSION` in the repo to the **next,
unreleased** version. The repo is ALWAYS ahead of CPAN by one.

1. **NEVER copy a `$VERSION` from a DBIO repo into a `cpanfile`.** It is not
   released; `cpanm` cannot install it; the build breaks.
2. **Check `cpanm --info Module::Name`** for the actual released version.
3. **Every DBIO-authored dep must be pinned to the latest released CPAN version** —
   not `'0'`, not a stale number.
4. **Re-check on upgrade** with `cpanm --info` again.
5. **Family bootstrap exception:** until the DBIO family has had its first CPAN
   release, `cpanm --info` finds nothing to pin. DBIO-family deps stay
   **unversioned** in the cpanfile for now and get pinned as part of the first
   release ticket. Cross-repo development installs happen via `dzil install`
   in the dependency's repo, not via CPAN.

```bash
cpanm --info DBIO | tail -1
# → GETTY/DBIO-1.234.tar.gz  ← pin to 1.234 (once released)
```

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

- ❌ `require Foo` inside a method to "speed up startup"
- ❌ Using a `$VERSION` from a DBIO repo as a cpanfile requirement
- ❌ 4-space indent or tabs in new Perl files
- ❌ Trailing commas on multi-line lists
- ❌ `Path::Tiny`, direct `File::Spec`, or bare `open` in new code — use the `DBIO::Util` file helpers
- ❌ `||` where `//` is meant (clobbers legitimate `0`/`''`)
- ❌ `Data::Dumper` in shipped code (use `DDP`/`Data::Printer` for debug, strip before commit)

## When in doubt

Grep real core code: `~/dev/perl/dbio-dev/dbio/lib/DBIO/`. For class-building
specifics go to [[dbio-perl-class-patterns]].
