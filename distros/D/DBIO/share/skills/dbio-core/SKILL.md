---
name: dbio-core
description: "DBIO ORM architecture, API, component system, and coding conventions (DBIx::Class fork)"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO = DBIx::Class fork. Namespace `DBIO::`, SQL::Abstract (not ::Classic). Integrated: TimeStamp, Helpers. SQL::Translator optional (legacy deploy only).

## Architecture

```
DBIO::Schema → ResultSource → ResultSet → Row
Storage → DBIO::Storage::DBI
SQLMaker
```

## Components

`load_components('Foo')` resolves under `DBIO::`. `+` = absolute path.

```perl
__PACKAGE__->load_components('PostgreSQL');  # DBIO::PostgreSQL
__PACKAGE__->load_components('+My::Custom'); # absolute
```

Driver components override `connection()` to set `storage_type`.

## Drivers

| Dist | Component | Storage |
|------|-----------|---------|
| DBIO-PostgreSQL | `DBIO::PostgreSQL` | `DBIO::PostgreSQL::Storage` |
| DBIO-MySQL | `DBIO::MySQL` | `DBIO::MySQL::Storage` |
| DBIO-SQLite | `DBIO::SQLite` | `DBIO::SQLite::Storage` |
| DBIO-Replicated | — | `DBIO::Storage::DBI::Replicated` |

## Result Class

```perl
package MyApp::DB::Result::User;
use base 'DBIO::Core';
__PACKAGE__->table('users');
__PACKAGE__->add_columns(
  id   => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 255 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(posts => 'MyApp::DB::Result::Post', 'user_id');
```

Relationships: `belongs_to`, `has_many`, `has_one`, `might_have`, `many_to_many`.

ResultSet chaining: `$schema->resultset('User')->search({active=>1})->search({role=>'admin'})->order_by('name')`

## Testing Rules

- Core tests MUST use `DBIO::Test::Storage` (fake). Never `dbi:SQLite` or real DB in core
- Driver integration: `DBIO_TEST_PG_DSN`, `DBIO_TEST_MYSQL_DSN`, etc.
- `t/` = tests; `xt/` = author tests
- Shared test schemas → `DBIO::Test::Schema::*` in `dbio/lib/`. Do NOT redefine result classes inline in driver tests
- Optional dep skip:
  ```perl
  BEGIN { eval { require Moo; 1 } or plan skip_all => 'Moo not installed' }
  ```
  List in cpanfile as `suggests`, never `requires`

## Shared Schemas

| Schema | Layer | DDL |
|--------|-------|-----|
| `DBIO::Test::Schema::Moo` | Moo | `add_columns` |
| `DBIO::Test::Schema::Moose` | Moose | `add_columns` |
| `DBIO::Test::Schema::MooCake` | Moo + Cake | Cake DDL |
| `DBIO::Test::Schema::MooseSugar` | Moose + Cake | Cake DDL |

Each: Artist + CD, has_many/belongs_to, one custom + one default ResultSet.

## AccessBroker

AccessBroker provides connection credential management and routing. Pass a broker to `Schema->connect($broker)` instead of raw DSN.

```perl
use DBIO::AccessBroker::Static;

my $broker = DBIO::AccessBroker::Static->new(
  host     => 'localhost',
  dbname   => 'myapp',
  user     => 'myapp',
  password => 'secret',
);

my $schema = MyApp::Schema->connect($broker);
```

### Interface

All brokers must implement:

A broker is a **CredentialSource**: one backend identity, one set of credentials. It does NOT route and does NOT own a host list — routing + topology belong to `DBIO::Replicated`. See `CONTEXT.md`.

| Method | Returns | Purpose |
|--------|---------|---------|
| `connect_info_for` | HASHREF | `{host, port, dbname, user, password, dbi_attrs}` |
| `connect_info_for_storage($storage)` | HASHREF | Storage-aware version |
| `needs_refresh` | Bool | True if credentials need rotation |
| `refresh` | - | Perform credential rotation |
| `has_rotating_credentials` | Bool | True if credentials rotate |
| `is_transaction_safe` | Bool | False if rotating (default) |
| `for_host($host)` | broker view | One credential, pinned to one host (HostBound) |

The trailing `$mode` ('read'/'write') arg is **vestigial** — accepted for back-compat, ignored. Routing decides read vs write, not the broker.

### Implemented Brokers

| Broker | File | Use Case |
|--------|------|----------|
| `DBIO::AccessBroker::Static` | Static.pm | Single DSN, transaction-safe |
| `DBIO::AccessBroker::Vault` | Vault.pm | TTL-based credential rotation |
| `DBIO::AccessBroker::HostBound` | HostBound.pm | One credential pinned to one host (via `for_host`) |

### Storage Integration

Storage detects broker via `_is_access_broker_connect_info([$broker])` → true if single blessed element. Then:

1. `set_access_broker($broker)` — attaches broker to storage
2. `_current_dbi_connect_info` → `current_access_broker_connect_info`
3. `current_connect_info_for_storage($storage)` → `connect_info_for` (or storage-aware variant)
4. Broker returns HASHREF → Storage normalizes to internal format

`DBIO::Replicated` passes a broker (or a `for_host` view) through the master/replicant connect paths untouched — the per-backend `Storage::DBI` consumes it. The guard predicate is `DBIO::Util::is_access_broker($x)`.

## OOP

- Core: `Class::Accessor::Grouped` + `Class::C3::Componentised` → [[dbio-perl-class-patterns]]
- Pure-Perl style baseline → [[dbio-perl-syntax]]
- Drivers: Moo (PostgreSQL) or Moose (Replicated) — match existing driver
- `DBIO::Moo`/`DBIO::Moose` = optional bridges (`suggests`), FOREIGNBUILDARGS + lazy rules → [[dbio-moo-moose]]
