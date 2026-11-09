---
name: dbio-perl-class-patterns
description: Use when building or refactoring a DBIO class — the Class::Accessor::Grouped accessor groups and when to reach for each.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO Class Patterns mit CAG

DBIO nutzt **kein Moo, kein Moops, keine Role::Tiny**. Alles CAG (`Class::Accessor::Grouped`): kleines Interface, tiefe Implementation.

Pure-Perl-Syntax/Style (Modul-Loading, Whitespace, cpanfile) → [[dbio-perl-syntax]]. Die seltenen Moo/Moose-Bridges → [[dbio-moo-moose]].

```perl
# Statt: has 'host' => (is => 'rw', isa => 'Str');
__PACKAGE__->mk_group_accessors(simple => qw/host port user password/);
```

Generierte Accessoren rufen intern `get_simple('host')` / `set_simple('host', $v)` auf — Logik steckt in `get_*`/`set_*` Hooks.

## Accessor-Gruppen

### `simple` — Instanzdaten

```perl
__PACKAGE__->mk_group_accessors(simple => qw(_storage _credentials _read_index));
```

Speichert direkt im Objekt-Hash. `$obj->host(1)` → `set_simple('host', 1)`.

### `inherited` — vererbbare Klassendaten

```perl
__PACKAGE__->mk_group_accessors(inherited => qw(sql_name_sep sql_quote_char));
__PACKAGE__->sql_name_sep('.');
```

Wenn Subklasse nichts setzt, sucht via `mro::get_linear_isa` in Elternklassen. DBIO nutzt das für SQL-Defaults in `Storage::DBI`.

Falle: der Instanz-Slot wird mit `exists` gelesen, nicht `defined` — ein `undef` auf der Instanz bleibt als Tombstone stehen und überdeckt die Klassen-Deklaration. Die Capability-Accessoren (`set_use_dbms_capability`) löschen den Slot deshalb bei `undef` (ADR 0041).

### `component_class` — lazy ladende Klassen

```perl
__PACKAGE__->mk_group_accessors(component_class => qw(cursor_class resultset_class));
__PACKAGE__->cursor_class('DBIO::Cursor');
```

`DBIO::Base` überschreibt `get_component_class`: holt Wert via `get_inherited`, lädt via `ensure_class_loaded`, gibt Klasse zurück. Danach normale Methodenaufrufe:

```perl
$self->cursor_class->new($self, \@_, $attrs);
$self->resultset_class->new($self, ...);
```

**Keine automatische Delegation** — gibt nur die Klasse zurück.

### Eigene Gruppen (Domänenlogik)

```perl
__PACKAGE__->mk_group_accessors(column => 'title');
```

Capabilities eines Storage laufen über die Gruppen `dbms_capability` (`_supports_X`) und `use_dbms_capability` (`_use_X`), siehe [[dbio-driver-development]].

Eigene `get_column`/`set_column` Hooks. `DBIO::Row` nutzt das für dynamische Spaltenaccessoren mit Inflation/Dirty-Tracking.

## Konstruktor — pure Perl

```perl
sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;
  $self->host($args{host}) if exists $args{host};
  return $self;
}
```

**Immer** `bless {}`, nie `bless []`. Keine `Moo::Object`.

## base vs. Role::Tiny

```perl
# Falsch:
use Role::Tiny;
with 'SomeRole';

# Richtig — Basisklasse (Rolle würde requires() brauchen, CAG kann das nicht):
use base qw/DBIO::Base Class::Accessor::Grouped/;
```

## load_components — Result- und Schema-Klassen

DBIO-spezifisches System: lazy-load + `mk_group_accessors` + in `$class` ablegen. **Nur** für Result-Klassen (Basis `DBIO::Core`) und Schema-Klassen (Treiber-Komponenten) — nicht für Storage, nicht für AccessBroker. Ein Storage wird über Storage-Layer und C3-Komposition erweitert (`register_storage_layer`, ADR 0032) → [[dbio-driver-development]].

```perl
# Richtig:
package MyApp::Schema::Result::Artist;
use base qw/DBIO::Core/;
__PACKAGE__->load_components('InflateColumn::DateTime');

# Falsch:
package MyApp::Credentials;
__PACKAGE__->load_components('Role::Tiny');  # NEIN
```

## Deep Module Pattern

Sauberer Schnitt zwischen kleinem Interface und tiefer Semantik:

```perl
# Interface:
$row->title;
$row->title('New');

# Deklaration:
__PACKAGE__->mk_group_accessors(column => 'title');

# Semantik tief im Hook:
sub get_column {
  my ($self, $col) = @_;
  # inflation cache, validation, lazy load ...
}
```

Erlaubt:
- `InflateColumn` ersetzt `column`-Handler durch `inflated_column` für bestimmte Spalten
- `FilterColumn` ersetzt für skalare Filter
- `Row` erzeugt dynamische Accessoren pro DB-Spalte

Faustregel:

```perl
__PACKAGE__->mk_group_accessors(simple          => qw/runtime_state/);
__PACKAGE__->mk_group_accessors(inherited       => qw/config_knob/);
__PACKAGE__->mk_group_accessors(component_class => qw/strategy_class/);
```

`simple` für Objektzustand, `inherited` für vererbbare Konfig, `component_class` für austauschbare Implementationen.

## Keine Magie — explizit

Kein `has`, kein `with`, kein `requires`. `_build_*` (private Builder) statt `BUILD`.

```perl
package MyApp::Credentials;
use base qw/Class::Accessor::Grouped/;
__PACKAGE__->mk_group_accessors(simple => qw(
  _storage _credentials _credentials_provider _base_params _read_index
));

sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;
  # ... direkt arbeiten
  return $self;
}
```

## Composition seams — `@ISA` is not a bugfix surface

Changing `@ISA` / `use base` on a component, a storage layer, or a storage class is an
architecture change, whatever prompted it. It never lands as an undiscussed one-liner
inside a fix, and never on the strength of "the suite is green afterwards". It needs a
ticket and an ADR (skill `dbio-adr`).

The recurring case this rule exists for: **an extension never determines the driver.**
Not via `storage_type`, not by inheriting a driver component, not by a role. The
extension component registers a storage layer and inherits no driver component's
`connection()` hook; the schema declares the driver and core composes the layer over it.
The rule is about the connect path, not a mandated base class — what the component
derives from otherwise is style. This has been broken twice with
two different tools (karr dbio-mysql-ev k14, karr dbio-postgresql-age k8) — ADR 0032 §7
plus its 2026-08-07 addendum is the full rule, and core carries a structural test for it.

Corollary when you assert on a layered storage: **driver resolution is lazy.** The schema
declares its driver, so from `connect` on the composed base is the declared driver
storage; resolution — adapting it to its access path — runs on the first `dbh` access,
not on `connect`. Connect before asserting the specialised class — sampling the
intermediate state and "fixing" it is exactly how both violations above started.
