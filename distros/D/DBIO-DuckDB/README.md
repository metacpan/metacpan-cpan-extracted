# DBIO::DuckDB

DuckDB driver for DBIO (modern embedded analytical database).

## Supports

- desired-state deployment via test-deploy-and-compare ([DBIO::DuckDB::Deploy](https://metacpan.org/pod/DBIO::DuckDB::Deploy))
- native introspection ([DBIO::DuckDB::Introspect](https://metacpan.org/pod/DBIO::DuckDB::Introspect))
- native diff ([DBIO::DuckDB::Diff](https://metacpan.org/pod/DBIO::DuckDB::Diff))
- native DDL generation ([DBIO::DuckDB::DDL](https://metacpan.org/pod/DBIO::DuckDB::DDL))
- **Quack client-server RPC** (libduckdb >= 1.5): `quack_serve`, `quack_attach`, `quack_detach`

## Usage

    package MyApp::DB;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('DuckDB');

    my $schema = MyApp::DB->connect('dbi:duckdb:myapp.db');

For in-memory database:

```perl
my $schema = MyApp::DB->connect('dbi:duckdb:');
```

DBIO core autodetects `dbi:duckdb:` DSNs and loads this storage automatically.

## DuckDB Features

**Types**
- `INTEGER`, `BIGINT`, `SMALLINT`, `TINYINT` - signed integers
- `UINTEGER`, `UBIGINT`, `USMALLINT`, `UTINYINT` - unsigned integers
- `FLOAT`, `DOUBLE`, `DECIMAL` - numeric types
- `VARCHAR`, `CHAR`, `TEXT` - string types
- `BLOB` - binary data
- `DATE`, `TIME`, `TIMESTAMP`, `TIMESTAMP WITH TIME ZONE` - temporal types
- `INTERVAL` - time intervals
- `JSON` / `JSONB` - JSON data (stored as VARCHAR but with JSON operators)
- `ARRAY`, `STRUCT`, `MAP` - complex types
- `HUGEINT` - 128-bit integer
- `BIT` - fixed-length bit string

**Arrow Integration**
- Direct import/export of Apache Arrow tables
- `duckdb_append_arrow` for high-speed data ingestion
- Read from and write to Parquet files directly via SQL

**Parquet Support**
- `SELECT * FROM 'file.parquet'` - read Parquet files as tables
- `COPY ... TO 'file.parquet' (FORMAT PARQUET)` - export to Parquet
- Automatic Parquet file detection and reading
- Directory-based Parquet tables (read all files in folder)

**DuckDB-Specific Features**
- `INSERT ... ON CONFLICT ... DO UPDATE` (upsert)
- `RETURNING` clause for all INSERT/UPDATE/DELETE
- `COPY ... FROM STDIN` for bulk import (CSV, Parquet, JSON)
- `SUMMARIZE` for automatic statistics on tables
- `EXPORT DATABASE` to recreate schema and data
- `IMPORT DATABASE` to load exported data
- In-database LLM support via `ai_hint_create` / `ai_query`

**Introspection**
- `duckdb_tables()` information schema function
- `duckdb_columns()` for column metadata
- `duckdb_indexes()` for index information
- `duckdb_constraints()` for constraint details

## Deploy

[DBIO::DuckDB::Deploy](https://metacpan.org/pod/DBIO::DuckDB::Deploy) orchestrates test-deploy-and-compare:

1. Introspect live database via DuckDB information schema ([DBIO::DuckDB::Introspect](https://metacpan.org/pod/DBIO::DuckDB::Introspect))
2. Deploy desired schema to a temporary in-memory database
3. Introspect the temporary database the same way
4. Diff source vs target ([DBIO::DuckDB::Diff](https://metacpan.org/pod/DBIO::DuckDB::Diff))

DuckDB's speed makes deploy-and-compare very fast even for large schemas.

Install (`install_ddl`) creates fresh schema. Upgrade diffs live vs. desired.

## Testing

```bash
export DBIO_TEST_DUCKDB_DSN="dbi:duckdb:"
prove -l t/
```

DuckDB in-memory mode requires no external process - perfect for testing.

## Requirements

- Perl 5.36+
- [DBD::DuckDB](https://metacpan.org/pod/DBD::DuckDB)
- DBIO core

## See Also

[DBIO::Introspect::Base](https://metacpan.org/pod/DBIO::Introspect::Base), [DBIO::Diff::Base](https://metacpan.org/pod/DBIO::Diff::Base), [DBIO::Deploy](https://metacpan.org/pod/DBIO::Deploy)

## Repository

[https://codeberg.org/dbio/dbio-duckdb](https://codeberg.org/dbio/dbio-duckdb)
