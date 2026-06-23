---
name: dbio-db2
description: "DBIO::DB2 driver — DB2 storage, SYSCAT introspection, test-deploy-and-compare, identity retrieval"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::DB2

IBM DB2 driver for DBIO. Extracted from DBIx::Class, modernized with native Introspect/Diff/DDL/Deploy classes.

## Component Loading

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('DB2');
# → sets storage_type to +DBIO::DB2::Storage automatically
```

## Storage

`DBIO::DB2::Storage` extends `DBIO::Storage::DBI`:

```perl
__PACKAGE__->datetime_parser_type('DateTime::Format::DB2');
__PACKAGE__->sql_quote_char('"');
__PACKAGE__->dbio_deploy_class('DBIO::DB2::Deploy');
```

### Key methods

| Method | Description |
|--------|-------------|
| `sql_name_sep` | Queries `SQL_QUALIFIER_NAME_SEPARATOR` (default `.`) |
| `_dbh_last_insert_id` | `IDENTITY_VAL_LOCAL()` for auto-increment |
| `deploy_setup` | No-op (DB2 does not need tablespace pre-allocation) |
| `sqlt_type` | Returns `'DB2'` for SQL::Translator |

## Introspection

`DBIO::DB2::Introspect` extends `DBIO::Introspect::Base`.

Sources: `SYSCAT.TABLES`, `SYSCAT.COLUMNS`, `SYSCAT.INDEXES`, `SYSCAT.INDEXCOLUSE`, `SYSCAT.TABCONST`, `SYSCAT.KEYCOLUSE`, `SYSCAT.REFERENCES`.

Model shape: `{ tables, columns, indexes, foreign_keys }`.

## Diff

`DBIO::DB2::Diff` extends `DBIO::Diff::Base`. Operations: tables → columns → indexes (drops last).

## Deploy

`DBIO::DB2::Deploy` — test-deploy-and-compare via temporary schema.

1. Introspect live DB (source)
2. Deploy desired to temp schema in same DB
3. Introspect temp schema (target)
4. Diff source vs target

Supports: `install`, `diff`, `apply`, `upgrade`.

## DDL

`DBIO::DB2::DDL` — generates DB2 DDL. Handles `GENERATED ALWAYS AS IDENTITY`, inline FK, topo sort for table deps.

## FK Handling

DB2 enforces referential integrity. FK constraints are inline in CREATE TABLE for new tables; ALTER TABLE for existing.

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::DB2` | Schema component |
| `DBIO::DB2::Storage` | DBI storage + driver registration |
| `DBIO::DB2::Deploy` | test-deploy-and-compare |
| `DBIO::DB2::Diff` | Compare introspected models |
| `DBIO::DB2::Introspect` | Read live DB via SYSCAT |
| `DBIO::DB2::DDL` | Generate DB2 DDL |
