---
name: dbio-informix
description: Load when working on the DBIO::Informix driver — storage, sys* catalog introspection, deploy-and-compare, the native deploy triad.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Informix

Informix is IBM's enterprise RDBMS. DBIO::Informix sits on DBD::Informix (requires IDS or ESA client libraries). Synchronous only — no async path like dbio-postgresql-async.

## Component Loading

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('Informix');
# → sets storage_type to DBIO::Informix::Storage automatically
```

## Storage

`DBIO::Informix::Storage` extends `DBIO::Storage::DBI`:

```perl
my $schema = MyApp::DB->connect('dbi:Informix:database=myapp');
```

### Key settings

```perl
__PACKAGE__->sql_maker_class('DBIO::Informix::SQLMaker');
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->datetime_parser_type('DateTime::Format::Pg');
```

### Sequence support

Informix uses `GENERATE_SERIAL()` / `NEXT_SERIAL()` for auto-increment.
Storage provides `next_serial($table, $col)` helper.

### Environment setup

`GL_DATE` / `GL_DATETIME` environment variables are set via `connect_call_datetime_setup`.

## SQLMaker

`DBIO::Informix::SQLMaker` — no `FOR UPDATE`, `"` quoting.

## Introspection

`DBIO::Informix::Introspect` extends `DBIO::Introspect::Base` — reads the lowercase `sys*` catalog under owner `informix` (NOT DB2-style `SYSCAT`): `informix.systables`, `informix.syscolumns`, `informix.sysindexes`, `informix.sysconstraints` joined with `informix.sysreferences` for FKs.

Model shape: `{ tables, columns, indexes, foreign_keys }`.

## Deploy

`DBIO::Informix::Deploy` — test-deploy-and-compare. Note: Informix has no `:memory:` mode like SQLite/DuckDB, so the throwaway deploy introspects the live DB twice (temp DB future work).

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::Informix` | Schema component |
| `DBIO::Informix::Storage` | DBI storage + sequences |
| `DBIO::Informix::SQLMaker` | SQL generation |
| `DBIO::Informix::Deploy` | test-deploy-and-compare |
| `DBIO::Informix::Diff` | Compare introspected models |
| `DBIO::Informix::Introspect` | Read live DB via `informix.sys*` catalog |
| `DBIO::Informix::DDL` | Generate CREATE statements |
