---
name: dbio-mysql
description: Load when working on the DBIO::MySQL driver — storage registration, SQLMaker, capabilities, deploy, introspect, async wiring.
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

`DBIO::MySQL::Storage->register_driver('mysql' => __PACKAGE__)` binds the DBD name. The driver is declared (ADR 0059/0067): the schema component picks the storage by pinning `storage_type`.

- `DBIO::MySQL` (and the `-mysql` shortcut) pins `+DBIO::MySQL::Storage`.
- `DBIO::MySQL::MariaDB` pins `+DBIO::MySQL::Storage::MariaDB`, which registers `'MariaDB'` for DBD::MariaDB.

## Async Wiring

Per core ADR 0030, async is an explicit per-connection mode resolved through the core mode registry:

- **`ev` mode:** this storage registers `ev => DBIO::MySQL::EV::Storage` on `DBIO::MySQL::Storage`. MariaDB subclass inherits via MRO. Backend lives in the optional `dbio-mysql-ev` dist; loaded lazily on first `*_async` call. Absent → canonical `install DBIO::MySQL::EV::Storage` croak.
- **`future_io` mode (ADR 0030/0031):** NOT registered — resolved by CONVENTION, `ref($storage).'::Async'`. `DBIO::MySQL::Storage::Async` subclasses `DBIO::Async::Storage` and fills only the DB transport seams; Model-B orchestration is inherited. `DBIO::MySQL::Storage::MariaDB::Async` is its empty convention partner. The class does NOT select the DBD binding (`mysql_*` vs `mariadb_*`): that is chosen per connection — from the DSN before the connect, from `$dbh->{Driver}{Name}` after — via `DBIO::MySQL::Storage::_dbd_attribute` (ADR 0007 addendum). DBD primitives stay in the parent storage, one implementation for both bindings.
- Reach: `connect(..., { async => 'ev' })` or `{ async => 'future_io' }`. The mode is chosen at connect; the schema loads `MySQL` or `MySQL::MariaDB` only.

See `docs/adr/0030-async-mode-registration.md`.

## `?` placeholder seam (future_io)

`DBIO::MySQL::Storage::Async::_transform_sql` is **identity** — MySQL keeps standard `?` placeholders (unlike PostgreSQL's `?`→`$N` rewrite). Shaping happens exactly ONCE, internally, inside the inherited `DBIO::Async::Storage::_query_async`; the adapter does NOT override `_query_async`. No caller-side `_transform_sql` — a layer/extension issues `?` SQL through `_query_async` and never shapes SQL itself. MySQL has no `RETURNING`, so `_post_insert_sql` is empty and INSERT returned-columns are assembled from the captured `mysql_insertid`/`mariadb_insertid`.

## Storage-layer composition

Extensions are plain storage **LAYERS**, not `storage_type` subclasses. `storage_type` is written ONLY by the driver Schema components — `DBIO::MySQL` (`+DBIO::MySQL::Storage`) and `DBIO::MySQL::MariaDB` (`+DBIO::MySQL::Storage::MariaDB`); choosing the base storage stays the driver's job. An extension registers a plain method package via `$schema->register_storage_layer('DBIO::MySQL::Ext::Storage')`; core composes it (C3) OVER the driver storage via `DBIO::Storage::Composed`. Its async mirror `...::Ext::Storage::Async` composes OVER the resolved `future_io` transport (found by convention off the driver, NOT the layer). The `ev`/`future_io` map does not grow per extension. Transport capabilities: the future_io transport inherits `on_connect_replay` and declares `listen` + `notify` (LISTEN/NOTIFY is EMULATED over a notify table, ADR 0008 — MySQL has no native one) and `broker_connect_options` (connect options beside an AccessBroker). No COPY (PostgreSQL wire feature). No pipelining on either backend: `pipeline` returns a failed Future (core `_pipeline_refusal`), and the `ev` backend declines it too (dbio-mysql-ev ADR 0009). MySQL ships no extension today, but this reference driver honours the mechanism (offline `t/56-storage-layer-composition.t`, live `t/57-*-live.t`).

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
| `_dbh_last_insert_id` | `$dbh->{mysql_insertid}` / `$dbh->{mariadb_insertid}` — named by the handle's DBD (`_dbd_attribute`), not by the storage class |
| `_random_function` | `'RAND()'` |
| `connect_call_set_zero_date_permissive` | `on_connect_call => 'set_zero_date_permissive'` drops `NO_ZERO_DATE`/`NO_ZERO_IN_DATE` for the session; `deploy_setup` calls it |
| `_lock_dialect` | per server: `FOR SHARE` plus `OF`/`NOWAIT`/`SKIP LOCKED` on MySQL 8.0.1+; `LOCK IN SHARE MODE` on older MySQL and on MariaDB, with `NOWAIT` from MariaDB 10.3 and `SKIP LOCKED` from 10.6; the SQLMaker refuses a modifier the server lacks |
| `_use_set_operator_intersect_except`, `_use_set_operator_all_family` | class-level declarations, default `1`; a deployment whose server lacks INTERSECT/EXCEPT (or their ALL forms) sets them to `0` and the storage refuses the operator locally |

## Auto-Reconnect

Disabled by default (silent transaction loss). Override: pass `mysql_auto_reconnect => 1` (DBD::mysql) or `mariadb_auto_reconnect => 1` (DBD::MariaDB) in connect attrs — the attribute is named by the handle's DBD (`DBIO::MySQL::Storage::_dbd_attribute`), not by the storage class.

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

MySQL prohibits referencing the modification target in a subquery. The rewrite lives in `DBIO::MySQL::SQLMaker`: `update` and `delete` take the target's name with `_extract_target_name` and pass the generated SQL to `_wrap_self_referencing_subquery`, which re-wraps a subquery `SELECT` that reads from the target as ``( SELECT * FROM (...) `_forced_double_subquery` )`` (ADR 0003).

## Insert with no columns

MySQL uses `INSERT INTO t () VALUES ()` — not `DEFAULT VALUES`.

## Identifier quoting in DDL

Every name written into generated DDL — `DBIO::MySQL::DDL`, all `DBIO::MySQL::Diff::*` ops, the temp database of `DBIO::MySQL::Deploy` — goes through `DBIO::MySQL::Identifier::quote_ident`: always backticks, an embedded backtick doubled. This helper is the one quoting path in DDL, in place of core's ANSI `DBIO::SQL::Util::_quote_ident` (bare or `"..."`, a reserved-word syntax error or a string literal on MySQL) and of raw `` `%s` `` interpolation. One identifier per call: a dot is part of the name, not a `db.table` separator. Queries are the SQLMaker's (`sql_quote_char`), not this helper's.

## Server version and product

`_get_server_version` is overridden to use `SELECT VERSION()`, NOT the inherited
`get_info(SQL_DBMS_VER)`: DBD::MariaDB reports that packed and zero-padded
(`08.00.4600` for MySQL 8.0.46, `11.08.0800` for MariaDB 11.8.8), and core's
normalizer stops at the first dotted part above 999, so 8.0.46 became 8.0.0 and
no gate below the minor version could be trusted. `SELECT VERSION()` carries the
true numbers AND the product name.

Product detection has exactly one home:

```perl
$storage->_is_mariadb   # server product, from the version string
```

It comes from the server's version string (this dist's ADR 0001), whatever the storage class or the DBD name.
`DBIO::MySQL::Storage::MariaDB` is the **DBD::MariaDB binding**, not the MariaDB
engine — DBD::MariaDB talks to MySQL servers, DBD::mysql talks to MariaDB ones,
and `DBIO::MySQL::Storage` has no `_rebless`, so a MariaDB server under
`load_components('MySQL')` stays in the parent class. Every product-dependent
SQL decision therefore lives in the parent, keyed on `_is_mariadb`.

## Capabilities that differ by server

| Capability | Gate |
|---|---|
| `supports_upsert` | flat 1 — ON DUPLICATE KEY UPDATE exists everywhere |
| `insert_returning` | `_is_mariadb` and >= 10.005 — MySQL has none |
| upsert row alias (`AS new`) | not MariaDB, and >= 8.000020 |

MariaDB 10.5+ accepts `INSERT ... ON DUPLICATE KEY UPDATE ... RETURNING` and returns the written row on both branches; the `LAST_INSERT_ID(pk)` idiom is skipped there.
The conflict clause is rendered BEFORE `RETURNING`, and `$options->{returning}`
must be restored after the base call — core reads it again after `_execute`.

## Testing

`DBIO_TEST_MYSQL_DSN`, `DBIO_TEST_MYSQL_USER`, `DBIO_TEST_MYSQL_PASS`.
SQLMaker tests: `DBIO::Test->init_schema(storage_type => 'DBIO::MySQL::Storage')`.

Every suite, offline and live, runs through `../dbio/maint/capped-test`, e.g. `../dbio/maint/capped-test prove -lr t/` (live-testing rule 9 in `dbio-driver-development`, `references/live-testing.md`). For a live run on the maintainer's database, `dbio-db env mysql` or `dbio-db env mariadb` hands over the variables, one run per server (same reference), after `maint/live-preflight` in core.

`DBIO::MySQL::Test::Conformance` answers the shared case table of `DBIO::Test::Conformance` (core ADR 0060) for this driver (`t/156` to `t/161`, `t/168`). It needs an account that may create databases and runs once against MySQL and once against MariaDB.
