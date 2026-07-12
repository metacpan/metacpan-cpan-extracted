---
name: dbio-mysql
description: "DBIO::MySQL driver — MySQL/MariaDB storage, SQLMaker, capabilities, deploy, introspect"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO MySQL/MariaDB driver. Follows dbio-driver-development conventions.

## Components

| Component | Class |
|-----------|-------|
| MySQL schema | `DBIO::MySQL` |
| MariaDB schema | `DBIO::MySQL::MariaDB` |
| MySQL storage | `DBIO::MySQL::Storage` |
| MariaDB storage | `DBIO::MySQL::Storage::MariaDB` |
| SQLMaker | `DBIO::MySQL::SQLMaker` |
| Deploy | `DBIO::MySQL::Deploy` |

## Storage Registration

`DBIO::MySQL::Storage->register_driver('mysql' => __PACKAGE__)` — DBD auto-detect.

`DBIO::MySQL::MariaDB` sets `storage_type('+DBIO::MySQL::Storage::MariaDB')`.

## Async Wiring

Per core ADR 0030, async is an explicit per-connection mode resolved through the core mode registry:

- **`ev` mode:** this storage registers `ev => DBIO::MySQL::EV::Storage` on `DBIO::MySQL::Storage`. MariaDB subclass inherits via MRO. Backend lives in the optional `dbio-mysql-ev` dist; loaded lazily on first `*_async` call. Absent → canonical `install DBIO::MySQL::EV::Storage` croak.
- **`future_io` mode (ADR 0030/0031):** NOT registered — resolved by CONVENTION, `ref($storage).'::Async'`. `DBIO::MySQL::Storage::Async` (DBD::mysql binding) / `DBIO::MySQL::Storage::MariaDB::Async` (DBD::MariaDB `mariadb_*` binding) subclass `DBIO::Async::Storage` and fill only the DB transport seams; Model-B orchestration is inherited.
- Reach: `connect(..., { async => 'ev' })` or `{ async => 'future_io' }`. `async_backend()` and `load_components('MySQL::EV')` are OBSOLETE patterns from before ADR 0030.

See `docs/adr/0030-async-mode-registration.md`.

## `?` placeholder seam (future_io)

`DBIO::MySQL::Storage::Async::_transform_sql` is **identity** — MySQL keeps standard `?` placeholders (unlike PostgreSQL's `?`→`$N` rewrite). Shaping happens exactly ONCE, internally, inside the inherited `DBIO::Async::Storage::_query_async`; the adapter does NOT override `_query_async`. No caller-side `_transform_sql` — a layer/extension issues `?` SQL through `_query_async` and never shapes SQL itself. MySQL has no `RETURNING`, so `_post_insert_sql` is empty and INSERT returned-columns are assembled from the captured `mysql_insertid`/`mariadb_insertid`.

## Storage-layer composition (core karr #70)

Extensions are plain storage **LAYERS**, not `storage_type` subclasses. `storage_type` is written ONLY by the driver Schema components — `DBIO::MySQL` (`+DBIO::MySQL::Storage`) and `DBIO::MySQL::MariaDB` (`+DBIO::MySQL::Storage::MariaDB`); choosing the base storage stays the driver's job. An extension registers a plain method package via `$schema->register_storage_layer('DBIO::MySQL::Ext::Storage')`; core composes it (C3) OVER the driver storage via `DBIO::Storage::Composed`. Its async mirror `...::Ext::Storage::Async` composes OVER the resolved `future_io` transport (found by convention off the driver, NOT the layer). The `ev`/`future_io` map does not grow per extension. Transport capabilities: the future_io transport inherits `transport_capabilities => (on_connect_replay)` and declares nothing extra; MySQL has no LISTEN/NOTIFY/COPY (PostgreSQL features); pipelining lives on the `ev` backend. MySQL ships no extension today, but this reference driver honours the mechanism (offline `t/56-storage-layer-composition.t`, live `t/57-*-live.t`).

## Key Storage Methods

| Method | Description |
|--------|-------------|
| `dbio_deploy_class` | Returns `DBIO::MySQL::Deploy` |
| `sql_maker_class` | `DBIO::MySQL::SQLMaker` |
| `sql_quote_char` | `` ` `` (backtick) |
| `datetime_parser_type` | `DateTime::Format::MySQL` |
| `_use_multicolumn_in(1)` | Multi-column IN supported |
| `sqlt_type` | `'MySQL'` |
| `deploy_defaults` | `add_drop_table => 1` (MySQL no transactional DDL) |
| `deploy_setup` | Strip `NO_ZERO_DATE`/`NO_ZERO_IN_DATE` from sql_mode |
| `with_deferred_fk_checks` | `SET FOREIGN_KEY_CHECKS = 0/1` |
| `_dbh_last_insert_id` | `$dbh->{mysql_insertid}` |
| `_random_function` | `'RAND()'` |

## Auto-Reconnect

Disabled by default (silent transaction loss). Override: pass `mysql_auto_reconnect => 1` in connect attrs.

## Strict Mode

```perl
$schema->connect($dsn, $user, $pass, { on_connect_call => 'set_strict_mode' });
```
Sets `ANSI,TRADITIONAL,ONLY_FULL_GROUP_BY` sql_mode, disables `SQL_AUTO_IS_NULL`.

## SQLMaker: apply_limit

MySQL LIMIT syntax: `LIMIT offset, rows` (offset first, count second).

```sql
SELECT * FROM t LIMIT 20, 10  -- offset=20, rows=10
```

## Double-Subquery Hack

MySQL prohibits referencing the modification target in a subquery. `_prep_for_execute` detects UPDATE/DELETE self-reference and wraps in double subquery via `_modification_target_referenced_re`.

## Insert with no columns

MySQL uses `INSERT INTO t () VALUES ()` — not `DEFAULT VALUES`.

## MariaDB Detection

```perl
my $is_mariadb = ($version =~ /MariaDB/i);
```

## Testing

`DBIO_TEST_MYSQL_DSN`, `DBIO_TEST_MYSQL_USER`, `DBIO_TEST_MYSQL_PASS`.
SQLMaker tests: `DBIO::Test->init_schema(storage_type => 'DBIO::MySQL::Storage')`.
