---
name: dbio-duckdb
description: "DBIO::DuckDB driver — DuckDB storage, SQL generation, test-deploy-and-compare, native escape hatches"
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
$app->append_int64($row->{id});
$app->append_varchar($row->{name});
$app->end_row;
$app->flush;

# Table function reads
my $csv = $storage->duckdb_read_csv('/path/to/file.csv');
my $pq  = $storage->duckdb_read_parquet('/path/to/file.parquet');
my $js  = $storage->duckdb_read_json('/path/to/file.json');

# Arrow fetch (experimental)
my $rows = $storage->duckdb_arrow_fetch('SELECT * FROM t WHERE id = ?', [42]);
```

### Sth caching

`disable_sth_caching { 1 }` — DBD::DuckDB bug with RETURNING + cached sth.

## SQLMaker

`DBIO::DuckDB::SQLMaker` — no FOR UPDATE, `"` quoting.

## Introspection

`DBIO::DuckDB::Introspect` extends `DBIO::Introspect::Base` — reads via `information_schema` + DuckDB system views.

Model shape: `{ tables, columns, indexes, foreign_keys }`.

## Deploy

`DBIO::DuckDB::Deploy` — test-deploy-and-compare via `:memory:` DuckDB.

## FK Limitation

FKs are **readable but NOT emitted in DDL**. DuckDB enforces exact column ordering at CREATE TABLE time; DBIO FK hashes are alphabetically sorted. Runtime enforcement is also missing (1.x).

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::DuckDB` | Schema component |
| `DBIO::DuckDB::Storage` | DBI storage + escape hatches |
| `DBIO::DuckDB::SQLMaker` | SQL generation |
| `DBIO::DuckDB::Deploy` | test-deploy-and-compare |
| `DBIO::DuckDB::Diff` | Compare introspected models |
| `DBIO::DuckDB::Introspect` | Read live DB |
