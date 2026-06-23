---
name: dbio-duckdb-database
description: "DuckDB knowledge for Perl driver development (DBD module, SQL dialect, types, sequences, transactions, pagination)"
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

No user/pass — pass empty strings. DBD::DuckDB binds via libduckdb's
strongly-typed prepared params, so the driver returns `undef` from
`bind_attribute_by_data_type` (no DBI bind-attr overrides).

## Version Notes

`$storage->duckdb_version` → e.g. `v1.0.0`. Alien::DuckDB 0.03 ships
1.3.0. The Quack client-server RPC extension needs libduckdb >= 1.5.
FK constraints are not enforced at runtime as of 1.x.

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
`BEGIN/COMMIT/ROLLBACK`. Savepoints supported: `SAVEPOINT` /
`RELEASE SAVEPOINT` / `ROLLBACK TO SAVEPOINT` (wired in Storage).
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

FKs are **readable but NOT emitted** in install DDL. DuckDB validates the
referenced column tuple against the parent PK/unique *in the same column
order* at CREATE TABLE time; DBIO FK condition hashes are alphabetically
sorted and often mismatch. Since FKs have no runtime effect in 1.x, install
DDL skips them; introspect/diff can still round-trip user-added FKs.

## Testing Env Vars

`DBIO_TEST_DUCKDB_DSN`, `DBIO_TEST_DUCKDB_DBUSER`, `DBIO_TEST_DUCKDB_DBPASS`
(`DBIO::DuckDB::Test`). If `DBIO_TEST_DUCKDB_DSN` is unset, tests default to
`dbi:DuckDB:dbname=:memory:` with no external credentials.
