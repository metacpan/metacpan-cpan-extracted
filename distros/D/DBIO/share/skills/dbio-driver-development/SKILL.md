---
name: dbio-driver-development
description: "How to develop a DBIO database driver: registry, storage class, SQLMaker, capabilities, async, Cake integration — developer guide"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO Driver Development

DBIO drivers are separate CPAN distributions binding DBIO to one DB engine.

## Architecture

```
User → DBIO::Schema → Driver Registry (DSN auto-detect)
                    → Storage class → SQLMaker → Capability system
```

| Family | Base | Protocol | Returns |
|--------|------|----------|---------|
| DBI-based (Pg, SQLite, MySQL) | `DBIO::Storage::DBI` | DBD | blocking |
| Async (PostgreSQL::Async) | `DBIO::Storage::Async` | libpq (EV::Pg) | Future |

## Registry & Auto-Detection

Storage classes register at load time:

```perl
package DBIO::PostgreSQL::Storage;
use base 'DBIO::Storage::DBI';

__PACKAGE__->register_driver('Pg' => __PACKAGE__);
```

Flow on first DB op (lazy):
1. `$schema->connect('dbi:Pg:dbname=myapp')`
2. `_determine_driver()` extracts DBD name (`Pg`) from DSN
3. Registry lookup → `DBIO::PostgreSQL::Storage`
4. Reblesses storage object, calls `_rebless()` hook

Manual override via Schema component (skips detection):

```perl
sub connection {
  my $self = shift;
  $self->storage_type('+DBIO::PostgreSQL::Storage');
  return $self->next::method(@_);
}
```

## Driver Structure

Up to 4 components per distribution.

### 1. Schema Component `DBIO::DriverName`

User-facing entry. It is a schema **component** loaded via
`load_components('DriverName')` — its base is `DBIO::Base`, NOT `DBIO::Schema`:

```perl
package DBIO::DriverName;
# ABSTRACT: DriverName support for DBIO
our $VERSION = '0.900000';

use strict;
use warnings;

use base 'DBIO::Base';

sub connection {
  my $self = shift;
  $self->storage_type('+DBIO::DriverName::Storage');
  return $self->next::method(@_);
}

1;
```

Users load it into their schema class:

```perl
package MyApp::Schema;
use DBIO 'Schema';
__PACKAGE__->load_components('DriverName');
```

(The classic `use base 'DBIO::Schema'` form on the **user's** schema class is
still supported — but the driver component itself always derives from
`DBIO::Base`.)

### 2. Storage Class `DBIO::DriverName::Storage` — required

```perl
package DBIO::DriverName::Storage;
# ABSTRACT: Storage for DriverName databases
use base 'DBIO::Storage::DBI';

__PACKAGE__->register_driver('DriverName' => __PACKAGE__);

# Class-data defaults
__PACKAGE__->sql_quote_char('"');
__PACKAGE__->datetime_parser_type('DateTime::Format::DriverName');
__PACKAGE__->sql_maker_class('DBIO::DriverName::SQLMaker');  # if custom

# Tier 1 capability (force on/off)
__PACKAGE__->_use_multicolumn_in(1);
__PACKAGE__->_use_insert_returning(1);

sub _rebless { ... }           # post-detection init
sub last_insert_id { ... }     # auto-increment retrieval
sub sqlt_type { 'DriverName' } # SQL::Translator name

# Optional: savepoints — core dispatches via ->can('_exec_svp_begin');
# a storage without these methods throws "doesn't support savepoints"
sub _exec_svp_begin { ... }
sub _exec_svp_release { ... }
sub _exec_svp_rollback { ... }

sub with_deferred_fk_checks { ... }   # FK deferral if supported
sub connect_call_set_encoding { ... } # connect-time setup
sub bind_attribute_by_data_type { ... }

1;
```

### Composing cross-cutting Storage behaviour

When a driver needs cross-cutting Storage behaviour (LOB handling, savepoints,
identity/autoincrement, FK deferral, connect-time setup), put each concern in
its own module and compose it via **`use base`** (ISA) with C3 mro -- exactly
like `DBIO::Storage::DBI`'s own mixins and the Sybase driver:

```perl
package DBIO::DriverName::Storage;
use base qw/
  DBIO::DriverName::Storage::LOBSupport
  DBIO::DriverName::Storage::Savepoints
  DBIO::Storage::DBI
/;
use mro 'c3';
```

The role modules are plain packages (no `Exporter`); they define methods and
document in a comment what the consuming class must provide.

**Do NOT compose roles via Exporter import** (`use Role qw(method)`). An
imported sub's CV still reports the *role* as its package, and the role is in
no MRO -- so any role method that calls `$self->next::method(...)` cannot find
the next implementation and dies ("No next::method 'X' found"). This is latent
for the live driver and fatal under the offline `DBIO::Test::Storage` hybrid
(it bit Oracle's `_prep_for_execute`).

**Ordering matters:** a role that *overrides* a `DBIO::Storage::DBI` method
(e.g. an `_prep_for_execute` that adds behaviour then calls `next::method`)
must come **before** `DBIO::Storage::DBI` in the `use base` list, so its
override wins and its `next::method` chains forward to the base.

### 3. SQLMaker `DBIO::DriverName::SQLMaker` — optional

Override SQL dialect or add operators via `special_ops`.

```perl
package DBIO::DriverName::SQLMaker;
# ABSTRACT: SQL dialect for DriverName
use base 'DBIO::SQLMaker';

sub _lock_select { '' }   # e.g. SQLite has no SELECT ... FOR UPDATE

sub new {
  my $class = shift;
  my %opts = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
  push @{ $opts{special_ops} }, {
    regex   => qr/^my_op$/i,
    handler => '_where_op_my_op',
  };
  $class->next::method(\%opts);
}

sub _where_op_my_op {
  my ($self, $col, $op, $val) = @_;
  my $quoted = $self->_quote($col);
  return ("$quoted MY_OP ?", $val);
}

1;
```

`special_ops` handler signature: `($self, $col_unquoted, $op, $val)` — quote yourself, return `($sql, @bind)`. The `regex` matches the **operator key** inside `{ op => val }`, not the field.

Examples:

| Driver | SQLMaker adds |
|--------|---------------|
| PostgreSQL | JSONB operators (`@>`, `?`, `@?`, ...) via `special_ops` |
| SQLite | disables `SELECT ... FOR UPDATE` |
| Oracle | `CONNECT BY`, `PRIOR`, identifier shortening, `RETURNING INTO` |

### 4. Result Component `DBIO::DriverName::Result` — optional

DB-specific column/table features for Result classes.

```perl
__PACKAGE__->load_components('DriverName::Result');
```

## DateTime Parsing

`datetime_parser_type` names a class providing `parse_datetime` /
`format_datetime` (class methods).

- DB has a maintained `DateTime::Format::<DB>` on CPAN → set it directly
  (Pg, MySQL, SQLite, Oracle, DB2 do this).
- No (or unmaintained) CPAN module → subclass the core fallback base
  `DBIO::Storage::DateTimeFormat`: declare strptime patterns, optionally
  prefer the CPAN module when it happens to be installed:

```perl
package DBIO::DriverName::DateTime::Format;
# ABSTRACT: DateTime parsing for DriverName
use base 'DBIO::Storage::DateTimeFormat';

__PACKAGE__->preferred_format_class('DateTime::Format::DriverName'); # optional
__PACKAGE__->datetime_parse_pattern('%Y-%m-%d %H:%M:%S.%3N');
__PACKAGE__->datetime_format_pattern('%Y-%m-%d %H:%M:%S.%3N');
__PACKAGE__->date_parse_pattern('%Y-%m-%d');    # optional, enables parse_date
__PACKAGE__->date_format_pattern('%Y-%m-%d');
```

Rules:
- The preferred CPAN class is used only when installed — cpanfile `suggests`,
  never `requires`. `DateTime::Format::Strptime` (the fallback engine) is a
  hard `requires` of core — drivers declare nothing extra for it.
- Fallback patterns MUST round-trip identically to the preferred class —
  contract-test BOTH paths (with and without the preferred class loadable).
- Never hand-roll a private strptime wrapper package inside Storage files.

## Capability System (2-tier)

```perl
# Tier 1: Force (class data set in driver)
__PACKAGE__->_use_insert_returning(1);
__PACKAGE__->_use_multicolumn_in(1);

# Tier 2: Detect at runtime (only if Tier 1 undef)
sub _determine_supports_insert_returning {
  return shift->_server_info->{normalized_dbms_version} >= 8.002 ? 1 : 0;
}
```

Result cached in `_supports_*` (computed once).

```perl
# SQLite: multicolumn IN since 3.14
sub _determine_supports_multicolumn_in {
  ( shift->_server_info->{normalized_dbms_version} < '3.014' ) ? 0 : 1
}
```

## Key Storage Methods

| Method | Purpose | Override? |
|--------|---------|-----------|
| `register_driver()` | auto-detect registry | yes (at load) |
| `_rebless()` | post-detect init hook | optional |
| `last_insert_id()` | autoincrement | usually |
| `sqlt_type()` | SQL::Translator name | yes |
| `_exec_svp_begin/_release/_rollback()` | savepoints | if DB supports |
| `with_deferred_fk_checks()` | defer FK | if DB supports |
| `connect_call_*()` | connect-time setup | optional |
| `bind_attribute_by_data_type()` | DBI bind per type | optional |
| `datetime_parser_type` | DateTime parser | class data |
| `sql_quote_char` | identifier quote | class data |
| `sql_maker_class` | custom SQLMaker | class data |
| `cake_defaults()` | Cake flags (`-Pg` etc) | optional |

### cake_defaults()

Optional. Driver flags for `DBIO::Cake`. Activated by `use DBIO::Cake '-Pg'`.

```perl
sub cake_defaults {
  return (
    inflate_jsonb     => 1,   # jsonb only (leaves json() free)
    inflate_datetime  => 1,
    retrieve_defaults => 1,   # PG generates UUIDs, serials, NOW()
  );
}
```

Cake looks up via `DBIO::Storage::DBI->driver_storage_class($name)`.

Inherited for free: connection/disconnection, SQL gen via SQLMaker, txn_*, insert/update/delete/select, handle caching, prepared statements, DBH attrs.

## AccessBroker

All drivers support AccessBroker. Pass broker to `Schema->connect($broker)` instead of raw DSN. **Full broker interface lives in dbio-core skill.**

Storage detects via `_is_access_broker_connect_info([$broker])` (true if single blessed). Then:
1. `set_access_broker($broker, 'write')` attaches
2. `_current_dbi_connect_info($mode)` → `current_access_broker_connect_info($mode)`
3. Broker returns HASHREF, Storage normalizes
4. Connection proceeds with broker credentials

Rotating creds: storage re-fetches on next connect. Async pools refresh via `_conninfo_provider` calling `current_connect_info_for_storage($storage, $mode)`.

## Async Drivers (ADR 0030/0031)

Async is an explicit, **per-connection mode** (ADR 0030), not a separate storage
class chosen at schema-author time. A schema connected with
`connect(..., { async => $mode })` answers the six `*_async` storage methods and
the ResultSet/Row `*_async` helpers through an embedded async backend; without
`{ async => ... }` it stays sync (`*_async` croaks — no auto-fallback). An add-on
registers its mode on the core base storage:

    DBIO::Storage::DBI->register_async_mode( $mode => 'DBIO::SomeDriver::Backend::Storage' );

`forked` (and the core `immediate`) register generically on the base class; a
native `ev` mode is registered by the concrete *sync* driver storage, so
`{ async => 'ev' }` resolves DB-specifically. `future_io` is **not registered** —
the core resolver discovers each driver's transport adapter by convention,
`ref($storage) . '::Async'` (`DBIO::X::Storage` → `DBIO::X::Storage::Async`), and
croaks early if a driver ships none (ADR 0030 refinement, karr #65).

### Extensions are storage LAYERS, not storage_type subclasses (karr #70)

A driver **extension** (AGE, PostGIS, a tenant add-on) does **not** subclass
`storage_type` and does **not** ship a per-extension `<pkg>::Async` transport of
its own. Under the storage-layer composition model it ships a plain storage
**layer** — a method package, no `@ISA` pointing at a storage — registered on
the schema:

    $schema->register_storage_layer('DBIO::X::Ext::Storage');

Core composes every registered layer over the base storage by C3-MRO class
synthesis (`DBIO::Storage::Composed->compose($base, \@layers)`): the synthesised
`DBIO::Storage::Composed::<Layer>__<Base>` has `@ISA = (@layers, $base)` under
the `c3` MRO and no methods of its own, so calls walk the layers (registration
order = precedence) and fall through to the base; layer hooks chain with
`$self->next::method(@_)`. Two layers defining the *same own method* is a compose-
time croak — silent shadowing between siblings is forbidden. The driver rebless
(`_determine_driver`) re-composes the same layers over the concrete driver class
(`recompose`), so a layer chosen on the generic storage survives onto the driver.

**Async rides the same layers.** When a layered schema connects
`{ async => $mode }`, core (1) resolves the transport off the composition
**BASE** — the driver, never the layers (`_async_resolution_class` strips the
layers back out of the linearised ISA, so a sync layer's plain `<Layer>::Async`
mixin is never mistaken for the transport, karr #70/#67) — then (2) mirrors each
registered sync layer `L` onto its async counterpart (`L->async_layer_class($mode)`
if defined, else the convention sibling `${L}::Async` via `load_optional_class`;
absent ⇒ that layer is sync-only and skipped) and composes those mirrors **on top
of** the transport. One behaviour, one transport: an extension's async behaviour
rides every transport exactly as its sync behaviour rides every driver, with no
hand-written extension×transport matrix. An async mirror that declares
`required_transport_capabilities` the transport does not advertise croaks at
compose time naming the gap (see the capability table below).

| Aspect | DBI | Async |
|--------|-----|-------|
| Base | `DBIO::Storage::DBI` | `DBIO::Storage::Async` |
| Protocol | DBD | native (EV::Pg/libpq, EV::MariaDB) |
| Returns | blocking | Future |
| Connection | single DBH | pool |
| Batching | no | pipeline (multi queries/round-trip) |

A `future_io` adapter (convention name `DBIO::X::Storage::Async`) subclasses the
shared `DBIO::Async::Storage` base (dist `dbio-async`) and overrides **only** the
DB-specific transport seams — the Model-B orchestration (CRUD runner, txn pinning,
pipeline, `*_async`) is inherited from core `DBIO::Storage::Async` (ADR 0030 §4):

```perl
package DBIO::DriverName::Storage::Async;   # convention: ref($storage).'::Async'
use base 'DBIO::Async::Storage';             # shared Future::IO base

sub sql_maker_class     { 'DBIO::DriverName::SQLMaker' }
sub _transform_sql      { ... }   # '?' -> the DB's positional placeholder (see below)
sub _submit_query       { ... }   # send query bytes on the DBD's async binding
sub _collect_result     { ... }   # read the ready result
sub _conn_fileno        { ... }   # socket fd for the Future::IO watcher
sub _normalize_conninfo { ... }   # DBD conninfo shape
```

#### The `?` placeholder seam — shaped once, in the transport

The SQLMaker is **shared with the sync DBI driver**, which needs SQL-standard
`?` placeholders, so the maker MUST keep emitting `?`. Any per-DB placeholder
rewrite (PostgreSQL `?` → `$N`, Oracle `?` → `:N`, …) lives in the transport's
`_transform_sql` seam, which the inherited `DBIO::Storage::Async::_query_async` /
`_query_async_pinned` invoke **once, internally**, on the maker's output before
it reaches the wire. **Callers never shape** — no code path outside the transport
touches placeholders, and there is no second/double shaping. `_transform_sql` is
a required seam (the base croaks until provided): a DB whose wire already takes
`?` overrides it to identity; a DB that needs positional placeholders rewrites
there (and only there). Test the seam directly (`$Adapter->_transform_sql($sql)`)
— that *is* the contract; do not re-add caller-side shaping in tests.

An `ev` backend (`DBIO::X::EV::Storage`) does the same over its native
event-loop client. Both must honour the resolution-shape contracts (ADR 0031 §3)
so the core
RS/Row helpers inflate uniformly: `select_async` → raw row arrayrefs (cursor
`->all` shape), `select_single_async` → a single arrayref, `insert_async` → the
returned-columns hashref sync `insert` returns; the Future's `then` must
auto-wrap plain returns (ADR 0031 §4).

#### Transport capabilities

A transport advertises what it supports via the `transport_capabilities` class
method; an async layer gates on it with `required_transport_capabilities`, and a
shortfall croaks at compose time (a transport gap becomes *that transport's*
ticket, never a silent feature loss). The two async transports for a driver
carry different capability sets:

| Feature | `future_io` (`DBIO::Async::Storage` base) | `ev` (`DBIO::X::EV::Storage`) |
|---|---|---|
| `on_connect_replay` (on_connect_do/call on pooled conns, karr #68) | ✅ advertised | ✅ |
| pooled CRUD + `txn_do_async` pinning | ✅ | ✅ |
| LISTEN / NOTIFY | ❌ (base `listen` croaks) | ✅ |
| COPY | ❌ | ✅ |
| pipeline (batch queries/round-trip) | ❌ (base `pipeline` croaks) | ✅ |

The generic `future_io` base advertises exactly `on_connect_replay` and nothing
more; a `future_io` adapter over a plain DBD binding declares no extra
capabilities. The native `ev` backend is the transport that carries
LISTEN/NOTIFY, COPY and pipelining. An add-on needing those must select the `ev`
mode (or the transport's dist grows the capability).

Implemented:
- **DBIO::PostgreSQL::EV** (EV::Pg, libpq) / **DBIO::MySQL::EV** (EV::MariaDB): the `ev` mode — native event-loop client: LISTEN/NOTIFY, COPY, pipeline (≤64 in-flight), txn pinning. Sync methods block via `->get`.
- **DBIO::Forked** (fork + pipe, any driver): the `forked` mode — no event loop, works for every driver (ADR 0030).
- **DBIO::Async** (Future::IO): the `future_io` mode — the abstract `DBIO::Async::Storage` base over a driver's own async binding (`pg_async`/`mysql_async`); each driver supplies a convention-resolved adapter `DBIO::X::Storage::Async` that fills the transport seams. No adapter yet ⇒ `future_io` croaks early for that driver.

## Distribution Layout

```
DBIO-DriverName/
  lib/DBIO/DriverName.pm           # Schema component
  lib/DBIO/DriverName/Storage.pm   # Storage (required)
  lib/DBIO/DriverName/SQLMaker.pm  # SQL dialect (optional)
  lib/DBIO/DriverName/Result.pm    # Result comp (optional)
  t/00-load.t                      # load tests (no DB)
  t/20-sqlmaker.t                  # SQL gen (no DB)
  t/10-integration.t               # needs live DB
  dist.ini                         # [@DBIO]
  cpanfile
```

## Naming

| Part | Pattern | Example |
|------|---------|---------|
| Dist | `DBIO-DriverName` | `DBIO-PostgreSQL` |
| Schema | `DBIO::DriverName` | `DBIO::PostgreSQL` |
| Storage | `DBIO::DriverName::Storage` | `DBIO::PostgreSQL::Storage` |
| SQLMaker | `DBIO::DriverName::SQLMaker` | `DBIO::PostgreSQL::SQLMaker` |
| DBD | `DBD::X` | `DBD::Pg`, `DBD::mysql` |
| Async (loop-agnostic, future_io) | `DBIO::DriverName::Storage::Async` | convention-resolved adapter on `DBIO::Async::Storage` |
| Async (EV-bound) | `DBIO::DriverName::EV` | `DBIO::PostgreSQL::EV`, `DBIO::MySQL::EV` |

## Testing

- Offline tests (no DB): SQLMaker SQL gen, module loading. Always required.
- Integration tests: live DB via env vars (see driver `CLAUDE.md` or `t/`).
- Driver tests run against the **installed** core — no `.proverc` / `-I../dbio/lib`
  tricks. After changing core, run `dzil install` in `dbio` before running
  driver tests (workflow: install core after every completed core ticket).

```perl
# Offline SQLMaker test:
my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::DriverName::Storage',
);
is_same_sql_bind( $rs->search(...)->as_query, $expected_sql, \@bind, 'desc' );
```

## Build

```ini
name = DBIO-DriverName

[@DBIO]
```
