---
name: dbio-informix
description: Load when working on the DBIO::Informix driver — storage, SQLMaker, sys* catalog introspection, types, and the deploy/diff triad with its throwaway database.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Informix

Informix is IBM's enterprise RDBMS. DBIO::Informix sits on DBD::Informix (requires IDS or ESA client libraries). Synchronous only; there is no async path.

## Component Loading

```perl
package MyApp::DB;
use DBIO Schema => -ix;
# → sets storage_type to DBIO::Informix::Storage at compile time
```

`-ix` is `DBIO::Shortcut::ix` (`t/08-shortcut.t`); `DBIO::Informix` as a schema
component (`load_components('Informix')`) pins the same storage in `connection`.

## Storage

`DBIO::Informix::Storage` extends `DBIO::Storage::DBI`:

```perl
my $schema = MyApp::DB->connect('dbi:Informix:myapp');
```

The DSN is `dbi:Informix:database[@server]`; the part after `@` is a DBSERVERNAME
of the sqlhosts file, not a host name. `database=myapp` is SQL -354. Built from
connection parameters, `dbname` is the database, `host` the DBSERVERNAME, and a
`port` is refused (`_connect_params_dsn`, `_bind_host_into_dsn`; ADR 0057, 0013).

### Key settings

```perl
__PACKAGE__->sql_maker_class('DBIO::Informix::SQLMaker');
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->datetime_parser_type('DBIO::Informix::Storage::DateTime::Format');
```

### Auto-increment

Auto-increment is the `SERIAL` type. The new value comes from
`$sth->{ix_sqlerrd}[1]` after the INSERT (`_execute`, `last_insert_id`).

### Environment setup

`_connect` sets `DELIMIDENT=y` for the duration of the connect: the storage quotes
with `"`, and Informix reads a double-quoted token as an identifier only then
(`t/12-delimident.t`). It also pins `DBDATE=MDY4/` (hiding `DBCENTURY`, `GL_DATE`) for the connect,
so a DATE roundtrips under any caller `DBDATE` (`t/31-date-client-env.t`);
`GL_DATETIME` is set via `connect_call_datetime_setup` (`t/14-datetime-setup.t`).

### Class facts

- `transactional_ddl` is 1: DDL in a logged database is rolled back with the
  transaction (ADR 0026; `t/65-transactional-ddl.t`).
- `INTERSECT ALL` / `EXCEPT ALL` are refused (SQL -201, ADR 0039); the distinct
  forms work. `$rs->rand` throws (no random function, ADR 0011). `_explain_query`
  throws (no EXPLAIN statement, ADR 0040). `t/62`–`t/64`.
- `_exists_value_sql` reads `FROM systables WHERE tabid = 1` (ADR 0037).
- Savepoints cannot be released (`_exec_svp_release` is a no-op);
  `with_deferred_fk_checks` uses `SET CONSTRAINTS ALL DEFERRED` (`t/13-deferred-fk.t`).

## SQLMaker

`DBIO::Informix::SQLMaker` — no `FOR UPDATE`, `"` quoting.

## Introspection

`DBIO::Informix::Introspect` extends `DBIO::Introspect::Base` — reads the lowercase `sys*` catalog under owner `informix`: `informix.systables`, `informix.syscolumns`, `informix.sysindexes`, `informix.sysconstraints` joined with `informix.sysreferences` for FKs.

Model shape: `{ tables, columns, indexes, foreign_keys, unique_constraints }`. The per-entity readers are `DBIO::Informix::Introspect::{Tables,Columns,Indexes,ForeignKeys,UniqueConstraints}` with `Introspect::Util`.

## Deploy

`DBIO::Informix::Deploy` — test-deploy-and-compare on `DBIO::Deploy::Base::TempDatabase`. Informix has no `:memory:` mode, so `diff` creates a throwaway database `WITH LOG` (on a connection to no database: `CREATE DATABASE` is refused on a connection to a database, -759), deploys the plain install DDL there on a second connection, introspects it and drops it in every case (`CLOSE DATABASE`, then `DROP DATABASE`). The live DSN must be `dbi:Informix:database[@server]` (`t/56-deploy-compare-tempdb.t`).

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::Informix` | Schema component |
| `DBIO::Informix::Storage` | DBI storage, `ix_sqlerrd` auto-increment |
| `DBIO::Informix::SQLMaker` | SQL generation |
| `DBIO::Informix::Deploy` | test-deploy-and-compare |
| `DBIO::Informix::Diff` | Compare introspected models (`Diff::{Table,Column,Index,ForeignKey,PrimaryKey,UniqueConstraint}`) |
| `DBIO::Informix::Introspect` | Read live DB via `informix.sys*` catalog |
| `DBIO::Informix::DDL` | Generate CREATE statements |
| `DBIO::Informix::Types` | Type vocabulary: `coltype` ↔ logical name ↔ DDL string |
| `DBIO::Informix::ColumnDef` | Column definition rendering |
| `DBIO::Informix::Util` | Shared helpers |
| `DBIO::Informix::Test::Conformance` | Driver conformance suite (live, `DBIO_TEST_INFORMIX_*`) |

Live tests: every suite runs through `maint/capped-test` (see `dbio-driver-development`, `references/live-testing.md`); `maint/k8s/informix.yaml` is the test pod.
