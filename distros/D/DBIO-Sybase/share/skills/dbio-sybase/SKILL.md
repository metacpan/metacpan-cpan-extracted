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
use DBIO Schema => -syb;
# or: use base 'DBIO::Schema'; __PACKAGE__->load_components('Sybase');
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

Then `ASE::_adapt_to_placeholder_support` decides once from the client library (`auto_cast`, or `::ASE::NoBindVars`), and `_init` mixes in the FreeTDS class. Storage layers survive the hook (core recomposes them over `::ASE`); under FreeTDS `_init` builds the trait over the base of the composition and composes the layers again over it, so the layers stay ahead of the FreeTDS methods and `composition_of` knows the class (`t/59-component-rebless.t`). The hook moves only the declared base: a private subclass, a pinned `::ASE::NoBindVars` or subclass of `::ASE`, and the writer/bulk storage (`(ref $self)->new`; their parent decided) pass through unchanged. A storage pinned to `::ASE` itself takes the same placeholder decision. Other DBD → stays the base, core reports it. Assert the class only after a first use.

### Key settings

Set on `DBIO::Sybase::Storage::ASE`, not on the base class (which `DBIO::MSSQL::Storage::Sybase` inherits):

```perl
__PACKAGE__->sql_maker_class('DBIO::Sybase::SQLMaker');
__PACKAGE__->sql_quote_char ([qw/[ ]/]);  # DDL/Diff write names through DBIO::Sybase::Quote
__PACKAGE__->datetime_parser_type('DBIO::Sybase::Storage::ASE::DateTime::Format');
```

### Escape Hatches

```perl
# maxConnect DSN patching (prevents connection exhaustion); the default is 256
$storage->_set_max_connect(512);

# FreeTDS version detection
my $ver = $storage->_using_freetds_version;  # e.g. "0.91" or 0/undef

# Ping (handles FreeTDS quirks)
$storage->_ping;  # returns 1 or 0
```

### Connection parameters without a DSN

`_connect_params_dsn` (core ADR 0057) turns `{ dbname, host, port }` — `DBIO::AccessBroker::Static`, or a connect-info hash without `dsn` — into a DBD::Sybase DSN. The DSN names the database with `database=`; DBD::Sybase does not read `dbname=`.

| Given | DSN |
|-------|-----|
| `dbname` + `host` + `port` | `dbi:Sybase:host=..;port=..;database=..` |
| `host` + `port` | `dbi:Sybase:host=..;port=..` (login's default database) |
| `dbname` | `dbi:Sybase:database=..` (server from `$DSQUERY`) |
| `host` without `port`, `port` without `host` | throws — DBD::Sybase ignores a lone one; no port assumed |

A server reached by name goes in as the whole DSN: `dsn`, or a `dbname` starting with `dbi:`. `DBIO::MSSQL::Storage::Sybase` inherits this seam ahead of `DBIO::MSSQL::Storage`, so the form must stay the one dbio-mssql's `t/59-connect-params-dsn.t` expects. Pinned live against ASE with DBD::Sybase on FreeTDS (`t/60-connect-params-live.t`); Open Client is untested. Under FreeTDS the `host=..;port=..` form cannot run a second statement while a cursor is open; the `dbname`-alone form can.

### Sth caching

The driver sets `disable_sth_caching(1)` itself in two cases: FreeTDS <= 0.82, whose statement caching is buggy (`Storage::ASE::_init`, with a warning), and `Storage::ASE::NoBindVars`, where binds are interpolated into the SQL.

## SQLMaker

`DBIO::Sybase::SQLMaker` extends `DBIO::SQLMaker` and overrides `apply_limit` to use the `GenericSubQ` limit dialect — ASE has no single limit construct that works across all query shapes, so pagination is sliced via a correlated `WHERE (SELECT COUNT(*) ...) BETWEEN ? AND ?` over a stable main-source order; a resultset with an offset but without an `order_by`, or with one based on sources other than the main one, throws. Wired via `sql_maker_class` on `DBIO::Sybase::Storage::ASE` (not the base, which `DBIO::MSSQL::Storage::Sybase` inherits). The rows-only case (no offset) does not reach `apply_limit`: `Storage::ASE::_prep_for_execute` takes the limit out and wraps the statement in `SET ROWCOUNT n` / `SET ROWCOUNT 0`.

## Identifier quoting

`DBIO::Sybase::Quote::quote_ident` is the one place `DBIO::Sybase::DDL` and the `Diff::*` operations write a name: bare when it matches `/^[a-z_][a-z0-9_]*$/i` and is not an ASE keyword, `[name]` otherwise (a `]` doubled). ASE refuses `"name"` without `set quoted_identifier on` (Msg 102). A name starting with `#` or `@`, or containing a dot, is refused with a `DBIO::Exception`. The keyword list is fixed in the code; `t/96-quote-ident-live.t` compares it with the server's catalog.

## Introspection

`DBIO::Sybase::Introspect` extends `DBIO::Introspect::Base` — reads the ASE system catalog (`sysobjects`, `syscolumns`/`systypes`, `syscomments`, `sysindexes` + `index_col()`, `sysreferences`). ASE has no `INFORMATION_SCHEMA` views.

Model shape: `{ tables, columns, indexes, foreign_keys, views }`. A view is in `tables` (`kind => 'view'`) with its columns, and in `views` as `{ view_name, definition, depends_on }`: `definition` is the text after `AS` (the `syscomments` rows in order, the `CREATE VIEW` head stripped), `depends_on` the views it reads from (`sysdepends`).

### Sub-modules

| Sub-module | Fetches |
|------------|---------|
| `DBIO::Sybase::Introspect::Tables` | table list |
| `DBIO::Sybase::Introspect::Columns` | column defs per table |
| `DBIO::Sybase::Introspect::Indexes` | index defs per table |
| `DBIO::Sybase::Introspect::ForeignKeys` | FK defs per table |
| `DBIO::Sybase::Introspect::Views` | view definitions + dependencies |

## Deploy

`DBIO::Sybase::Deploy` — test-deploy-and-compare via temporary database.

Sybase ASE does not support `:memory:` databases like DuckDB/SQLite.
Deploy creates a temp DB: `CREATE DATABASE _dbio_tmp_<pid>_<minutes>_<serial>` (at most 30 characters, ASE's limit),
deploys the desired schema there, introspects both, diffs, then drops.
The temp DB gets `abort tran on log full` (`sp_dboption`, from `master`) before
the deploy: without it ASE suspends the session that finds the database full
(`LOG SUSPEND`) and `diff` never returns; with it a schema too large for the
temp DB dies of Msg 1105. The temp DB is created `ON default = 'NNM'` with a
size calculated from the schema: (2 * tables + other indexes) * 8 pages plus
reserve plus the pages `model` uses, in the server's page size, rounded up to
the next 4 MB; `Deploy->new(schema => ..., temp_db_size => '64M')` replaces the
calculation (no minimum).
The drop is repeated on Msg 3702 ("currently in use"), and on no other error:
40 tries, 0.25 s apart. A database still in use after that stays on the
server, and nothing reports it.

`install` is inherited from `DBIO::Deploy::Base` and executes the statements of `DBIO::Sybase::DDL->install_ddl($schema)`.

`upgrade` calls `diff` then `apply`; both are those of `DBIO::Deploy::Base` (`allow_destructive`, `dry_run`): a diff with a drop or a lossy column change runs only with `allow_destructive => 1`.

## Diff

`DBIO::Sybase::Diff` extends `DBIO::Diff::Base`. Operations in dependency order: FK drops → view drops (removed and changed) → tables → PK drops → index drops → columns → PK adds → index creates/alters → FK adds → view creates (new and changed). Views on views are ordered by `depends_on`; a cycle throws a `DBIO::Exception`.

### Sub-modules

| Sub-module | Compares |
|------------|----------|
| `DBIO::Sybase::Diff::Table` | tables + primary keys |
| `DBIO::Sybase::Diff::Column` | columns |
| `DBIO::Sybase::Diff::Index` | indexes |
| `DBIO::Sybase::Diff::ForeignKey` | FK constraints (create/drop) |
| `DBIO::Sybase::Diff::View` | views: create, drop, drop + create when the definition changed |

## FK Behavior

FKs are **read from `sysreferences`** and **emitted in diff output**.
ASE has no declarative `ON DELETE/UPDATE` actions (Msg 156 on 16.0); both rules
introspect as `NO ACTION`. A relationship that becomes a constraint and declares an `on_delete`/`on_update` other than `NO ACTION` (undef and `''` mean none) is refused with a `DBIO::Exception` by `DBIO::Sybase::DDL` (`install`, `diff`, `upgrade`) and by `Diff::ForeignKey::Create->as_sql` (`t/76-ddl-fk-actions.t`, live `t/77-fk-actions-live.t`).

## Live testing

Live files (`t/*-live.t`) `skip_all` unless `DBIO_TEST_SYBASE_DSN`, `_USER` and `_PASS` are set; `TDSVER=5.0` is required for ASE. Every suite runs through `maint/capped-test`; live ones after `maint/live-preflight` (skill `dbio-driver-development`, `references/live-testing.md`).

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::Sybase` | Schema component |
| `DBIO::Sybase::Storage` | DBI storage + escape hatches |
| `DBIO::Sybase::SQLMaker` | SQL generation (GenericSubQ pagination) |
| `DBIO::Sybase::Quote` | identifier quoting for DDL/Diff |
| `DBIO::Sybase::Deploy` | test-deploy-and-compare |
| `DBIO::Sybase::Diff` | Compare introspected models |
| `DBIO::Sybase::Introspect` | Read live DB |
