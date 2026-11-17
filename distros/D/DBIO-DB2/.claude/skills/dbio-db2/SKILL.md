---
name: dbio-db2
description: Load when working on the DBIO::DB2 driver — storage, SYSCAT introspection, deploy-and-compare, identity retrieval.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::DB2

IBM Db2 (LUW) driver for DBIO with native Introspect, Diff, DDL and Deploy classes.

## Component Loading

```perl
package MyApp::DB;
use DBIO Schema => -db2;   # DBIO::Shortcut::db2
# → sets storage_type to +DBIO::DB2::Storage automatically
```

The shortcut is the standard way; `__PACKAGE__->load_components('DB2')` on a
`DBIO::Schema` subclass is the same declaration spelled out.

## Storage

`DBIO::DB2::Storage` extends `DBIO::Storage::DBI`:

```perl
__PACKAGE__->datetime_parser_type('DateTime::Format::DB2');
__PACKAGE__->sql_quote_char('"');
__PACKAGE__->sql_maker_class('DBIO::DB2::SQLMaker');

sub dbio_deploy_class { 'DBIO::DB2::Deploy' }
```

### Key methods

| Method | Description |
|--------|-------------|
| `sql_name_sep` | Queries `SQL_QUALIFIER_NAME_SEPARATOR` (default `.`) |
| `_dbh_last_insert_id` | `IDENTITY_VAL_LOCAL()` for auto-increment |
| `deploy_setup` | Empty hook (nothing to pre-allocate) |
| `_connect_params_dsn` | DSN form for connection parameters without a DSN (core ADR 0057): `dbname` alone is the cataloged alias `dbi:DB2:<dbname>`; `dbname`+`host`+`port` the uncataloged `dbi:DB2:DATABASE=..;HOSTNAME=..;PORT=..;PROTOCOL=TCPIP`; anything else throws |
| `sqlt_type` | Returns `'DB2'` for SQL::Translator |

## Introspection

`DBIO::DB2::Introspect` extends `DBIO::Introspect::Base`.

Sources: `SYSCAT.TABLES`, `SYSCAT.COLUMNS`, `SYSCAT.INDEXES`, `SYSCAT.INDEXCOLUSE`, `SYSCAT.TABCONST`, `SYSCAT.KEYCOLUSE`, `SYSCAT.REFERENCES`.

Model shape: `{ tables, columns, indexes, unique_constraints, foreign_keys }`. Views are entries of `tables` (kind `view`). One class per section under `DBIO::DB2::Introspect::*` (`Tables`, `Columns`, `Indexes`, `UniqueConstraints`, `ForeignKeys`); unique constraints are `SYSCAT.TABCONST` rows of type `U` (ADR 0009).

## Diff

`DBIO::DB2::Diff` extends `DBIO::Diff::Base`. Operations run in this order (`_build_operations`): view drops → tables → columns → `REORG` → indexes → unique constraints → foreign keys → view creates. Views are no tables (ADR 0011): a view drop at the head lets the table it reads go, a view create at the end sees every table, column and key. The FK pass comes after the tables, so a referenced table or column already exists. The `REORG` per reorg-pending table sits before the first statement such a table refuses (ADR 0008).

## Deploy

`DBIO::DB2::Deploy` — test-deploy-and-compare via temporary schema.

1. Introspect live DB (source)
2. Deploy desired to temp schema in same DB
3. Introspect temp schema (target)
4. Diff source vs target

Supports: `install`, `diff`, `apply`, `upgrade`.

## DDL

`DBIO::DB2::DDL` — generates DB2 DDL. Handles `GENERATED ALWAYS AS IDENTITY`, inline FK, topo sort for table deps, and `CREATE VIEW <quoted name> AS <view_definition>` for every non-virtual `DBIO::ResultSource::View` source with a non-empty `view_definition`, emitted after all table and index statements.

## FK Handling

DB2 enforces referential integrity. FK constraints are inline in CREATE TABLE for new tables; ALTER TABLE for existing.

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::DB2` | Schema component |
| `DBIO::DB2::Storage` | DBI storage + driver registration |
| `DBIO::DB2::Deploy` | test-deploy-and-compare |
| `DBIO::DB2::Diff` | Compare introspected models |
| `DBIO::DB2::Diff::{Table,Column,Index,UniqueConstraint,ForeignKey,View}` | One diff pass each; ForeignKey is ADD/DROP/drop-then-add |
| `DBIO::DB2::Diff::Reorg` | `REORG` operation after the column pass (ADR 0008) |
| `DBIO::DB2::Introspect` (+ `Introspect::*`) | Read live DB via SYSCAT |
| `DBIO::DB2::DDL` | Generate DB2 DDL |
| `DBIO::DB2::SQLMaker` | DB2 SQL dialect (apply_limit: RowNumberOver / FetchFirst) |
| `DBIO::DB2::Type` | DB2 column type mapping |
| `DBIO::DB2::Storage::Cursor` | Reads character columns of a result as characters |
| `DBIO::DB2::Test::Conformance` | Answers the shared conformance case table |
| `DBIO::Shortcut::db2` | The `-db2` shortcut |

Type mapping details, live-test setup and server facts: skill `dbio-db2-database`. Driver layout and testing rules: core skill `dbio-driver-development`.
