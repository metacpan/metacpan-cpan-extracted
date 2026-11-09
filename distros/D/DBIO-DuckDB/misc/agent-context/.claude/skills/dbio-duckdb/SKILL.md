---
name: dbio-duckdb
description: Load when working on the DBIO::DuckDB driver — storage, SQL generation, deploy-and-compare, native escape hatches.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::DuckDB

DuckDB is an embedded analytical OLAP DB. DBIO::DuckDB sits on DBD::DuckDB (FFI, no XS compile). Synchronous only — no async path like dbio-postgresql-async.

## Component Loading

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('DuckDB');
# → sets storage_type to +DBIO::DuckDB::Storage automatically
```

## Storage

`DBIO::DuckDB::Storage` extends `DBIO::Storage::DBI`:

```perl
my $schema = MyApp::DB->connect('dbi:DuckDB:dbname=app.duckdb');
my $v = $schema->storage->duckdb_version;   # e.g. v1.0.0
```

### Key settings

```perl
__PACKAGE__->sql_maker_class('DBIO::DuckDB::SQLMaker');
__PACKAGE__->sql_quote_char ('"');
```

`datetime_parser_type` is **not** set by the driver — it inherits the
`DateTime::Format::MySQL` default from `DBIO::Storage::DBI`.

### Escape Hatches

```perl
# Bulk insert via DuckDB Appender API
my $app = $storage->duckdb_appender($table);
$app->append_row(id => $row->{id}, name => $row->{name});
$app->flush;

# Table function reads
my $csv = $storage->duckdb_read_csv('/path/to/file.csv');
my $pq  = $storage->duckdb_read_parquet('/path/to/file.parquet');
my $js  = $storage->duckdb_read_json('/path/to/file.json');

# Arrow fetch: the result as columns, read through libduckdb's Arrow interface
my $t = $storage->duckdb_arrow_fetch('SELECT id, name FROM t WHERE id > ?', [42]);
# $t->{names}   ['id', 'name']     $t->{formats} ['i', 'u']  (Arrow format per column)
# $t->{columns} [ [43, 44], ['a', 'b'] ]  one array per column, NULL = undef
# $t->{rows}    2
# values as selectall_arrayref, except DATE, TIME, TIMESTAMP and INTERVAL, which are
# DuckDB's own text (CAST(v AS VARCHAR)), and TIMESTAMPTZ (UTC); UNION, BIT, BIGNUM,
# TIME WITH TIME ZONE and a MAP with a nested key throw
```

### Statement handles

DBD::DuckDB 0.16 never frees prepared statements. The storage releases its
own connection's statements through DBI `ChildCallbacks`
(`_duckdb_release_statements`, ADR 0006), so disconnect gives the database
file back.

A DBD::DuckDB 0.16 handle cannot be used twice either: `finish` destroys the
statement, `execute` never sets `Active`, and a handle executed again before
it was read to the end returns rows of the previous result. So the storage
takes no handle from DBI's statement cache -- `disable_sth_caching` is
overridden to always answer true, `=> 0` changes nothing (ADR 0007,
`t/49-statement-reuse.t`). In driver code: `$dbh->prepare`, never
`prepare_cached`, and one execution per handle.

Its `finish` also segfaults on a handle without a result -- never executed,
only refused executes, finished before -- and core finishes the handle of a
bulk insert whatever happened to it. The same ADR 0006 callback gives such a
handle an empty `duckdb_result` first, so a void-context `populate` whose
first row is refused throws (karr k38, ADR 0006 addendum 2026-10-08,
`t/51-finish-without-result.t`). A plain DBI handle outside the storage still
crashes: a test that needs the crash runs it in a child process.

## SQLMaker

`DBIO::DuckDB::SQLMaker` — no FOR UPDATE, `"` quoting.

## Introspection

`DBIO::DuckDB::Introspect` extends `DBIO::Introspect::Base` — reads via `information_schema` + DuckDB system views.

Model shape: `{ tables, columns, indexes, foreign_keys }`.

## Deploy

`DBIO::DuckDB::Deploy` — test-deploy-and-compare via `:memory:` DuckDB.

## Foreign keys and table rebuild

FKs are **enforced by DuckDB and written in install DDL**, columns in the parent PK/unique order, tables after their parents. `ON DELETE/UPDATE CASCADE`, `SET NULL`, `SET DEFAULT` are refused loudly (DuckDB rejects them at parse time); `RESTRICT`/`NO ACTION` pass.

What DuckDB cannot ALTER -- a column dropped under an index/UNIQUE, a dropped UNIQUE, an FK added or dropped on an existing table -- is done by a table rebuild (`DBIO::DuckDB::Diff::Rebuild`, ADR 0010, karr k50): new table under a temporary name, common columns copied, old dropped, renamed, indexes recreated, all in the apply's one transaction. Refused before the first statement: a table another table has an FK to, and a self-referencing table.

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::DuckDB` | Schema component |
| `DBIO::DuckDB::Storage` | DBI storage + escape hatches |
| `DBIO::DuckDB::SQLMaker` | SQL generation |
| `DBIO::DuckDB::Deploy` | test-deploy-and-compare |
| `DBIO::DuckDB::Diff` | Compare introspected models |
| `DBIO::DuckDB::Introspect` | Read live DB |
