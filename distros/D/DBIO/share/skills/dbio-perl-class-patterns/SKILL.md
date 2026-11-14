---
name: dbio-perl-class-patterns
description: Use when building or refactoring a DBIO class — the Class::Accessor::Grouped accessor groups and when to reach for each.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO Class Patterns with CAG

Everything in DBIO is CAG (`Class::Accessor::Grouped`): a small interface over a deep implementation.

Pure-Perl syntax and style (module loading, whitespace, cpanfile) → [[dbio-perl-syntax]]. The rare Moo/Moose bridges → [[dbio-moo-moose]].

```perl
# in place of: has 'host' => (is => 'rw', isa => 'Str');
__PACKAGE__->mk_group_accessors(simple => qw/host port user password/);
```

Generated accessors call `get_simple('host')` / `set_simple('host', $v)` internally — logic lives in the `get_*` / `set_*` hooks.

## Accessor groups

### `simple` — instance data

```perl
__PACKAGE__->mk_group_accessors(simple => qw(_storage _credentials _read_index));
```

Stores directly in the object hash. `$obj->host(1)` → `set_simple('host', 1)`.

### `inherited` — inheritable class data

```perl
__PACKAGE__->mk_group_accessors(inherited => qw(sql_name_sep sql_quote_char));
__PACKAGE__->sql_name_sep('.');
```

When a subclass sets nothing, the lookup walks the parent classes via `mro::get_linear_isa`. DBIO uses this for the SQL defaults in `Storage::DBI`.

The instance slot is read with `exists`, not `defined`: an `undef` on the instance stays as a tombstone and covers the class declaration. The capability accessors (`set_use_dbms_capability`) therefore delete the slot on `undef` (ADR 0041).

### `component_class` — lazily loaded classes

```perl
__PACKAGE__->mk_group_accessors(component_class => qw(cursor_class resultset_class));
__PACKAGE__->cursor_class('DBIO::Cursor');
```

`DBIO::Base` overrides `get_component_class`: it fetches the value via `get_inherited`, loads it via `ensure_class_loaded` and returns the class name. Ordinary method calls follow:

```perl
$self->cursor_class->new($self, \@_, $attrs);
$self->resultset_class->new($self, ...);
```

The accessor returns the class and delegates nothing.

### Own groups (domain logic)

```perl
__PACKAGE__->mk_group_accessors(column => 'title');
```

A storage's capabilities run through the groups `dbms_capability` (`_supports_X`) and `use_dbms_capability` (`_use_X`), see [[dbio-driver-development]].

Own `get_column` / `set_column` hooks. `DBIO::Row` uses this for dynamic column accessors with inflation and dirty tracking.

## Constructor — pure Perl

```perl
sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;
  $self->host($args{host}) if exists $args{host};
  return $self;
}
```

Objects are always `bless {}`.

## Extending a class

A class extends a base class: `use base qw/DBIO::Base Class::Accessor::Grouped/`.

`load_components` is the DBIO system for result and schema classes — lazy loading, `mk_group_accessors`, filed under `$class`. It applies to result classes (base `DBIO::Core`) and schema classes (driver components). A storage is extended through storage layers and C3 composition (`register_storage_layer`, ADR 0032) → [[dbio-driver-development]]; an AccessBroker is a plain subclass.

```perl
package MyApp::Schema::Result::Artist;
use base qw/DBIO::Core/;
__PACKAGE__->load_components('InflateColumn::DateTime');
```

## Deep module pattern

A clean cut between a small interface and deep semantics:

```perl
# Interface:
$row->title;
$row->title('New');

# Declaration:
__PACKAGE__->mk_group_accessors(column => 'title');

# Semantics deep in the hook:
sub get_column {
  my ($self, $col) = @_;
  # inflation cache, validation, lazy load ...
}
```

This allows:
- `InflateColumn` replaces the `column` handler with `inflated_column` for chosen columns
- `FilterColumn` replaces it for scalar filters
- `Row` generates dynamic accessors per DB column

Rule of thumb:

```perl
__PACKAGE__->mk_group_accessors(simple          => qw/runtime_state/);
__PACKAGE__->mk_group_accessors(inherited       => qw/config_knob/);
__PACKAGE__->mk_group_accessors(component_class => qw/strategy_class/);
```

`simple` for object state, `inherited` for inheritable configuration, `component_class` for exchangeable implementations.

## Explicit by design

The declaration is `mk_group_accessors`, construction is `new`, private builders are `_build_*`.

```perl
package MyApp::Credentials;
use base qw/Class::Accessor::Grouped/;
__PACKAGE__->mk_group_accessors(simple => qw(
  _storage _credentials _credentials_provider _base_params _read_index
));

sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;
  # ... work directly
  return $self;
}
```

## Composition seams — `@ISA` is not a bugfix surface

Changing `@ISA` / `use base` on a component, a storage layer, or a storage class is an
architecture change, whatever prompted it. It lands with a ticket and an ADR (skill
`dbio-adr`), never as a one-liner inside a fix and never on the strength of "the suite is
green afterwards".

The recurring case: **an extension never determines the driver** — not via `storage_type`, not by inheriting a
driver component, not by a role. The extension component registers a storage layer and
inherits no driver component's `connection()` hook; the schema declares the driver and core
composes the layer over it. The rule is about the connect path, not a mandated base class;
what the component derives from otherwise is style. ADR 0032 §7 and its addendum are the
full rule, and core carries a structural test for it.

Corollary when you assert on a layered storage: **driver resolution is lazy.** The schema
declares its driver, so from `connect` on the composed base is the declared driver
storage; resolution — adapting it to its access path — runs on the first `dbh` access, not
on `connect`. Connect first, then assert the specialised class.
