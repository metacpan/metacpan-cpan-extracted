---
name: dbio-perl-class-patterns
description: DBIO-Klassenpattern mit CAG (Class::Accessor::Grouped). Nutze wenn du DBIO-Klassen baust oder refactorst.
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

## load_components — NUR für Results

DBIO-spezifisches System: lazy-load + `mk_group_accessors` + in `$class` ablegen. **Nur** für `DBIO::Result` Subklassen — nicht für Storage, nicht für AccessBroker.

```perl
# Richtig:
package MyApp::Schema::Result::Artist;
use base qw/DBIO::Core/;
__PACKAGE__->load_components('InflateColumn::DateTime');

# Falsch:
package DBIO::AccessBroker::Credentials;
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
package DBIO::AccessBroker::Credentials;
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
