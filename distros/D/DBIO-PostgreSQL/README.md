# DBIO::PostgreSQL

PostgreSQL driver for DBIO (fork of DBIx::Class::Storage::DBI::Pg).

## Supports

- desired-state deployment via test-deploy-and-compare ([DBIO::PostgreSQL::Deploy](https://metacpan.org/pod/DBIO::PostgreSQL::Deploy))
- native introspection via pg_catalog ([DBIO::PostgreSQL::Introspect](https://metacpan.org/pod/DBIO::PostgreSQL::Introspect))
- native diff ([DBIO::PostgreSQL::Diff](https://metacpan.org/pod/DBIO::PostgreSQL::Diff))
- native DDL generation ([DBIO::PostgreSQL::DDL](https://metacpan.org/pod/DBIO::PostgreSQL::DDL))
- async PostgreSQL via [EV::Pg](https://metacpan.org/pod/EV::Pg) ([DBIO::PostgreSQL::Async](https://metacpan.org/pod/DBIO::PostgreSQL::Async), no DBI)

## Usage

    package MyApp::DB;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL');

    my $schema = MyApp::DB->connect('dbi:Pg:database=myapp');

DBIO core autodetects `dbi:Pg:` DSNs and loads this storage automatically.

## PostgreSQL Features

The driver supports the full range of PostgreSQL features:

**Types**
- `SERIAL`, `BIGSERIAL` - auto-increment via sequences
- `UUID` - generate via `gen_random_uuid()` or `uuid_generate_v4()`
- `JSONB` - binary JSON with comparison operators
- `JSON` - text JSON
- `TEXT[]`, `INTEGER[]` - PostgreSQL arrays
- `HSTORE` - key-value store
- `TSVECTOR` - full-text search
- `VECTOR` - embedding vectors (pgvector extension)
- `ENUM` - user-defined enum types (auto-created on deploy)
- `INTERVAL`, `TIMESTAMPTZ`, `TIMETZ`, `ABSTIME` - temporal types

**Schema Support**
- Multiple schemas per database (namespace via `schema_name` in connect_info)
- Schema-qualified table references
- Public schema is default

**Row Level Security (RLS)**
- `row_security` attribute on result sources enables RLS policies
- Per-column `security_invoker` support
- `DBIO::PostgreSQL::Storage` handles `SET LOCAL ROLE` for RLS context

**Indexes**
- `PRIMARY KEY`, `UNIQUE` constraints create indexes
- `dbix_index` result source attribute for expression indexes
- `INCLUDE` columns for covering indexes (PostgreSQL 11+)
- `CONCURRENTLY` index creation option
- Partial indexes via `WHERE` clause in index definition
- `NULLS NOT DISTINCT` for unique indexes with NULL handling (PG15+)

**Full-Text Search**
- `TSVECTOR` column type with `to_tsvector`/`to_tsquery` helpers
- `tsvector_column` inflator for Result class attribute

**Foreign Data Wrappers**
- `postgres_fdw` remote table support
- `oracle_fdw`, `mysql_fdw` external tables

**PostgreSQL-Specific Features**
- `ON CONFLICT ... DO UPDATE` (upsert) via `insert_or_update`
- `RETURNING` clause for all INSERT/UPDATE/DELETE
- `FOR UPDATE SKIP LOCKED` for non-blocking row locking
- Advisory locks via `pg_advisory_lock`/`pg_try_advisory_lock`
- `COPY` bulk import/export support
- `LISTEN`/`NOTIFY` pub/sub via [DBIO::PostgreSQL::Async](https://metacpan.org/pod/DBIO::PostgreSQL::Async)

**Introspection (pg_catalog)**
- `pg_class`, `pg_attribute`, `pg_index` for tables/columns/indexes
- `pg_type`, `pg_enum` for type and enum introspection
- `pg_namespace` for schema listing
- `pg_constraint` for foreign keys and unique checks
- `pg_trigger` for trigger-based auto-increment detection
- Sequence detection via `pg_depend` and trigger inspection

## Deploy

[DBIO::PostgreSQL::Deploy](https://metacpan.org/pod/DBIO::PostgreSQL::Deploy) orchestrates test-deploy-and-compare:

1. Introspect live database via pg_catalog ([DBIO::PostgreSQL::Introspect](https://metacpan.org/pod/DBIO::PostgreSQL::Introspect))
2. Deploy desired schema to a temporary schema (`_dbio_tmp_<pid>_<time>`)
3. Introspect the temporary schema the same way
4. Diff source vs target ([DBIO::PostgreSQL::Diff](https://metacpan.org/pod/DBIO::PostgreSQL::Diff))
5. Drop the temporary schema

Install (`install_ddl`) creates fresh schema. Upgrade diffs live vs. desired.

## Testing

Requires a running PostgreSQL instance:

```bash
export DBIO_TEST_PG_DSN="dbi:Pg:database=myapp"
export DBIO_TEST_PG_USER=postgres
export DBIO_TEST_PG_PASS=secret
prove -l t/
```

Offline tests (`t/00-load.t`, SQLMaker tests) run without a database.

## Requirements

- Perl 5.36+
- [DBD::Pg](https://metacpan.org/pod/DBD::Pg)
- DBIO core

## See Also

[DBIO::Introspect::Base](https://metacpan.org/pod/DBIO::Introspect::Base), [DBIO::Diff::Base](https://metacpan.org/pod/DBIO::Diff::Base), [DBIO::Deploy](https://metacpan.org/pod/DBIO::Deploy)

## Repository

[https://codeberg.org/dbio/dbio-postgresql](https://codeberg.org/dbio/dbio-postgresql)