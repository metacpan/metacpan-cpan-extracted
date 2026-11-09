---
name: dbio-duckdb-database
description: Use when you need DuckDB specifics for driver work — DBD module, SQL dialect, types, sequences, transactions, pagination.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DuckDB for Perl DB driver development. The database counterpart to the
`dbio-duckdb` driver skill. DuckDB is an embedded, columnar, analytical
(OLAP) DB — single-process, no server. SQL dialect is PostgreSQL-flavored.

## DBD::DuckDB

Pure-FFI DBI driver — no XS compile, only `libduckdb` needed at runtime
(via `Alien::DuckDB`, or `DUCKDB_NO_ALIEN=1` + `LD_LIBRARY_PATH`).
Synchronous only — no async path.

```perl
DBI->connect('dbi:DuckDB:dbname=app.duckdb');   # file-backed
DBI->connect('dbi:DuckDB:dbname=:memory:');     # in-memory (tests use this)
```

No user/pass — pass empty strings. DBD::DuckDB picks the bind function from
the value (any number-looking scalar binds as DOUBLE), so
`DBIO::DuckDB::Storage::bind_attribute_by_data_type` returns `SQL_BIGINT` for
the wide types (bigint, hugeint, decimal, numeric, money, ...) to force the
exact string-cast route, and `undef` for integer and narrower.

## Version Notes

`$storage->duckdb_version` → e.g. `v1.5.3`. Alien::DuckDB 0.04 bundles
libduckdb 1.5.3 (0.03 shipped 1.2.2). The Quack client-server RPC extension
needs libduckdb >= 1.5, so 0.04 provides it out of the box.
FK constraints are enforced (an insert without a parent fails).

## Type System

DuckDB has a rich type set. The driver's DDL maps DBIO/foreign types onto
DuckDB types (`DBIO::DuckDB::DDL::_duckdb_column_type`):

| Logical | DuckDB |
|---------|--------|
| int/integer/serial | INTEGER |
| bigint/bigserial | BIGINT |
| tinyint, smallint, hugeint | TINYINT, SMALLINT, HUGEINT |
| numeric/decimal/money | DECIMAL (money → DECIMAL(19,4)) |
| float/double/real | FLOAT/DOUBLE/REAL |
| text/varchar/char/clob | VARCHAR |
| boolean/bool | BOOLEAN |
| blob/bytea/binary | BLOB |
| date/time | DATE/TIME |
| datetime/timestamp | TIMESTAMP |
| timestamptz | TIMESTAMPTZ |
| interval | INTERVAL |
| uuid/guid | UUID |
| json | JSON |

Native nested types also exist (LIST, STRUCT, MAP, UNION, ARRAY) — not
mapped by the DDL layer; reach them via raw SQL / escape hatches.
`datetime_parser_type` is **inherited** (`DateTime::Format::MySQL`) — not
overridden in `DBIO::DuckDB::Storage`. `sqlt_type` returns the DBI driver
name, `DuckDB`.

## Identity / Sequences

DuckDB has no AUTO_INCREMENT/IDENTITY emitted by this driver. Auto-increment
columns get a real `CREATE SEQUENCE` + `DEFAULT nextval('<table>_<col>_seq')`.
Sequences start at `1000000` so manual small-ID inserts don't collide
(DuckDB sequences do **not** auto-advance on explicit inserts the way PG
IDENTITY does). UUID/GUID auto columns default via `uuid()` instead — no
sequence. Introspection detects `nextval(...)` defaults to recover
`is_auto_increment` + sequence name.

## Transactions & MVCC

DuckDB is ACID with MVCC (single-writer, optimistic). Standard
`BEGIN/COMMIT/ROLLBACK`. **No savepoints**: `SAVEPOINT` /
`RELEASE SAVEPOINT` / `ROLLBACK TO SAVEPOINT` are each a Parser Error
(libduckdb 1.5.3), so Storage defines no `_exec_svp_*` and core refuses
`svp_*` itself. With `auto_savepoint => 1` every nested `txn_do` /
`txn_scope_guard` throws "doesn't support savepoints" — leave it off.
`SELECT ... FOR UPDATE` is **not** supported — SQLMaker disables
`_lock_select`. `CHECKPOINT` flushes the WAL.

## Pagination

Standard `LIMIT ? OFFSET ?` — inherited unchanged from `DBIO::SQLMaker`,
no DuckDB override.

## Identifier Quoting & Case Folding

Double-quote identifiers (`sql_quote_char '"'`), PostgreSQL-style. Unquoted
identifiers fold to lowercase; comparisons are case-insensitive for unquoted
names. The driver quotes all identifiers via `DBIO::SQL::Util::_quote_ident`.

## Unicode

DuckDB is UTF-8 native throughout (VARCHAR is UTF-8); no charset/collation
connection setup needed, unlike MySQL.

## Introspection Catalog

`DBIO::DuckDB::Introspect` reads standard `information_schema` views plus
DuckDB system views: `duckdb_tables()`, `duckdb_columns()`,
`duckdb_indexes()`, `duckdb_constraints()`. View bodies come from
`information_schema.views`. Only the `main` schema by default; pass
`catalog` for attached file/DuckLake catalogs. Quack RPC remote catalogs
are **opaque** to these views — use `PRAGMA table_info('remote.tbl')`.

## FK Handling

FKs are enforced by DuckDB and written in install DDL: columns in the parent
PK/unique order (DuckDB validates the referenced tuple in that order), tables
after their parents. `ON DELETE/UPDATE CASCADE`, `SET NULL` and `SET DEFAULT`
are refused with table and column; `RESTRICT`/`NO ACTION` pass. A FK added or
dropped on an existing table rebuilds the table (`Diff::Rebuild`, ADR 0010).
Introspected FKs carry the live name as `constraint_name` (ADR 0021).

## Testing Env Vars

`DBIO_TEST_DUCKDB_DSN`, `DBIO_TEST_DUCKDB_DBUSER`, `DBIO_TEST_DUCKDB_DBPASS`
(`DBIO::DuckDB::Test`). If `DBIO_TEST_DUCKDB_DSN` is unset, tests default to
`dbi:DuckDB:dbname=:memory:` with no external credentials.
