---
name: dbio-sybase
description: Load when working on the DBIO::Sybase driver — storage, deploy-and-compare, native escape hatches.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Sybase

Sybase ASE database driver for DBIO. Sits on DBD::Sybase (requires FreeTDS or Sybase OpenClient). Supports native introspection, diff, and deploy via test-deploy-and-compare.

## Component Loading

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('Sybase');
# → sets storage_type to +DBIO::Sybase::Storage automatically
```

## Storage

`DBIO::Sybase::Storage` extends `DBIO::Storage::DBI`:

```perl
my $schema = MyApp::DB->connect('dbi:Sybase:server=myserver;database=mydb', 'user', 'pass');
# → the storage is DBIO::Sybase::Storage::ASE after the first use
my $v = $schema->storage->dbh->{syb_oc_version};   # DBD::Sybase handle attribute (client library string), not a storage method
```

One way to the ASE class, lazy (first use, not `connect`): the schema declares the driver (component or `-syb`), and `_adapt_to_access_path` (core ADR 0059) moves the declared base to `::ASE` without asking `sp_server_info`. A server DBD::Sybase found to be Microsoft SQL Server goes to `_driver_mismatch`; the storage stays ASE. A schema for Microsoft SQL Server declares `DBIO::MSSQL`. A schema without a declared driver is refused by core (ADR 0067).

Then `ASE::_adapt_to_placeholder_support` decides once from the client library (`auto_cast`, or `::ASE::NoBindVars`), and `_init` mixes in the FreeTDS class. Storage layers survive the hook (core recomposes them over `::ASE`); under FreeTDS `_init` builds the trait over the base of the composition and composes the layers again over it, so the layers stay ahead of the FreeTDS methods and `composition_of` knows the class (`t/59-component-rebless.t`). The hook moves only the declared base: a private subclass, a pinned `::ASE::NoBindVars` or subclass of `::ASE`, and the writer/bulk storage (`(ref $self)->new`; their parent decided) pass through unchanged. A storage pinned to `::ASE` itself takes the same placeholder decision (karr k78). Other DBD → stays the base, core reports it. Assert the class only after a first use.

### Key settings

Set on `DBIO::Sybase::Storage::ASE`, not on the base class (which `DBIO::MSSQL::Storage::Sybase` inherits):

```perl
__PACKAGE__->sql_maker_class('DBIO::Sybase::SQLMaker');
__PACKAGE__->sql_quote_char ([qw/[ ]/]);  # DDL/Diff quote with "
__PACKAGE__->datetime_parser_type('DBIO::Sybase::Storage::ASE::DateTime::Format');
```

### Escape Hatches

```perl
# maxConnect DSN patching (prevents connection exhaustion)
$storage->_set_max_connect(512);

# FreeTDS version detection
my $ver = $storage->_using_freetds_version;  # e.g. "0.91" or 0/undef

# Ping (handles FreeTDS quirks)
$storage->_ping;  # returns 1 or 0
```

### Connection parameters without a DSN

`_connect_params_dsn` (core ADR 0057) turns `{ dbname, host, port }` — `DBIO::AccessBroker::Static`, or a connect-info hash without `dsn` — into a DBD::Sybase DSN. Core's default wrote `dbname=`, which DBD::Sybase does not read.

| Given | DSN |
|-------|-----|
| `dbname` + `host` + `port` | `dbi:Sybase:host=..;port=..;database=..` |
| `host` + `port` | `dbi:Sybase:host=..;port=..` (login's default database) |
| `dbname` | `dbi:Sybase:database=..` (server from `$DSQUERY`) |
| `host` without `port`, `port` without `host` | throws — DBD::Sybase ignores a lone one; no port assumed |

A server reached by name goes in as the whole DSN: `dsn`, or a `dbname` starting with `dbi:`. `DBIO::MSSQL::Storage::Sybase` inherits this seam ahead of `DBIO::MSSQL::Storage`, so the form must stay the one dbio-mssql's `t/59-connect-params-dsn.t` expects. Live-verified 2026-10-05 against ASE 16.0 SP02, DBD::Sybase 1.27 on FreeTDS 1.3.17 (`t/60-connect-params-live.t`); not with Open Client. Under FreeTDS the `host=..;port=..` form cannot run a second statement while a cursor is open; the `dbname`-alone form can.

### Sth caching

The driver sets `disable_sth_caching(1)` itself in two cases: FreeTDS <= 0.82, whose statement caching is buggy (`Storage::ASE::_init`, with a warning), and `Storage::ASE::NoBindVars`, where binds are interpolated into the SQL.

## SQLMaker

`DBIO::Sybase::SQLMaker` extends `DBIO::SQLMaker` and overrides `apply_limit` to use the `GenericSubQ` limit dialect — ASE has no single limit construct that works across all query shapes, so pagination is sliced via a correlated `WHERE (SELECT COUNT(*) ...) BETWEEN ? AND ?` over a stable main-source order; a resultset with an offset but without an `order_by`, or with one based on sources other than the main one, throws. Wired via `sql_maker_class` on `DBIO::Sybase::Storage::ASE` (not the base, which `DBIO::MSSQL::Storage::Sybase` inherits). The rows-only case (no offset) does not reach `apply_limit`: `Storage::ASE::_prep_for_execute` takes the limit out and wraps the statement in `SET ROWCOUNT n` / `SET ROWCOUNT 0`.

## Introspection

`DBIO::Sybase::Introspect` extends `DBIO::Introspect::Base` — reads the ASE system catalog (`sysobjects`, `syscolumns`/`systypes`, `syscomments`, `sysindexes` + `index_col()`, `sysreferences`). ASE has no `INFORMATION_SCHEMA` views.

Model shape: `{ tables, columns, indexes, foreign_keys }`.

### Sub-modules

| Sub-module | Fetches |
|------------|---------|
| `DBIO::Sybase::Introspect::Tables` | table list |
| `DBIO::Sybase::Introspect::Columns` | column defs per table |
| `DBIO::Sybase::Introspect::Indexes` | index defs per table |
| `DBIO::Sybase::Introspect::ForeignKeys` | FK defs per table |

## Deploy

`DBIO::Sybase::Deploy` — test-deploy-and-compare via temporary database.

Sybase ASE does not support `:memory:` databases like DuckDB/SQLite.
Deploy creates a temp DB: `CREATE DATABASE _dbio_tmp_<pid>_<time>`,
deploys the desired schema there, introspects both, diffs, then drops.
The temp DB gets `abort tran on log full` (`sp_dboption`, from `master`) before
the deploy: without it ASE suspends the session that finds the database full
(`LOG SUSPEND`) and `diff` never returns; with it a schema too large for the
temp DB too small for the schema dies of Msg 1105 (karr k69). The temp DB is
created `ON default = 'NNM'` with a size calculated from the schema, (2 * tables
+ other indexes) * 8 pages plus reserve plus the pages `model` uses, in the
server's page size, up to 4 MB; `Deploy->new(schema => ..., temp_db_size =>
'64M')` replaces the calculation (no minimum).
The drop is repeated on Msg 3702 ("currently in use"), and on no other error:
40 tries, 0.25 s apart. A database still in use after that stays on the
server, and nothing reports it.

`install` is inherited from `DBIO::Deploy::Base` and executes the statements of `DBIO::Sybase::DDL->install_ddl($schema)`.

`upgrade` calls `diff` then `apply`.

## Diff

`DBIO::Sybase::Diff` extends `DBIO::Diff::Base`. Operations in dependency order: FK drops → tables → PK drops → index drops → columns → PK adds → index creates/alters → FK adds.

### Sub-modules

| Sub-module | Compares |
|------------|----------|
| `DBIO::Sybase::Diff::Table` | tables + primary keys |
| `DBIO::Sybase::Diff::Column` | columns |
| `DBIO::Sybase::Diff::Index` | indexes |
| `DBIO::Sybase::Diff::ForeignKey` | FK constraints (create/drop) |

## FK Behavior

FKs are **read from `sysreferences`** and **emitted in diff output**.
ASE has no declarative `ON DELETE/UPDATE` actions (Msg 156 on 16.0); both rules
introspect as `NO ACTION`.

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::Sybase` | Schema component |
| `DBIO::Sybase::Storage` | DBI storage + escape hatches |
| `DBIO::Sybase::SQLMaker` | SQL generation (GenericSubQ pagination) |
| `DBIO::Sybase::Deploy` | test-deploy-and-compare |
| `DBIO::Sybase::Diff` | Compare introspected models |
| `DBIO::Sybase::Introspect` | Read live DB |
