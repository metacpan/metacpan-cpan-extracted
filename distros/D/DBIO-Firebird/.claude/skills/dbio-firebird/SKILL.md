---
name: dbio-firebird
description: Load when working on the DBIO::Firebird driver — storage, rdb$ introspection, deploy-and-compare, generators.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Firebird

Firebird RDBMS driver. Built on DBD::Firebird (closely modeled on DBD::InterBase).

## Component Loading

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('Firebird');
# → sets storage_type to +DBIO::Firebird::Storage automatically
```

## Storage

`DBIO::Firebird::Storage` extends `DBIO::Firebird::Storage::InterBase`. Key settings:

```perl
# on DBIO::Firebird::Storage::Common (all three transports)
__PACKAGE__->sql_maker_class('DBIO::Firebird::SQLMaker');
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->_use_insert_returning (1);   # RETURNING support

# on each transport class (Storage, Storage::InterBase, Storage::ODBC)
__PACKAGE__->datetime_parser_type('DBIO::Firebird::DateTime::Format');
```

### Sequences / Generators

Firebird uses I<generators> (sequence equivalent). Access via `GEN_ID(name, delta)`:

```perl
my $val = $storage->_sequence_fetch('nextval', 'my_sequence');
```

`auto_nextval` is mapped in `_dbh_get_autoinc_seq` by parsing trigger source
for `gen_id()` or `NEXT VALUE FOR` expressions.

### Escape Hatches

- `$storage->_sequence_fetch('nextval', $seq_name)` — fetch next generator value
- `$storage->_exec_svp_begin/$release/$rollback($name)` — savepoint management

## SQLMaker

`DBIO::Firebird::SQLMaker` — inherits from `DBIO::SQLMaker` with Firebird-specific
LIMIT/OFFSET via `apply_limit`. SQL dialect 3 is forced on connect.

## Introspection

`DBIO::Firebird::Introspect` extends `DBIO::Introspect::Base` — reads via `rdb$*`
system tables.

Model shape: `{ tables, columns, indexes, unique_constraints, foreign_keys }`.

Sources:
- `rdb$relations` — tables and views (kind: table/view)
- `rdb$relation_fields` + `rdb$fields` — column type, size, default, PK membership
- `rdb$indices` + `rdb$index_segments` — user indexes (excludes PK/UNIQUE constraints)
- `rdb$relation_constraints` (UNIQUE) + `rdb$index_segments` — unique constraints
- `rdb$relation_constraints` + `rdb$indices` — FK constraints (composite, grouped by constraint name)

## Deploy

`DBIO::Firebird::Deploy` — test-deploy-and-compare via temporary database:
1. Introspect live DB
2. Create temp DB via `DBD::Firebird->create_database` (DSQL cannot prepare CREATE DATABASE; the file is placed beside the live db file)
3. Deploy desired schema to temp
4. Introspect temp DB
5. Diff the two models
6. Drop temp DB via `func('ib_drop_database')` on a separate handle connected to the temp DB (never the live handle)

Uses `DBIO::Firebird::DDL` for DDL generation (hand-rolled emitter built on `DBIO::Firebird::Type`; every identifier is double-quoted via `_firebird_quote_ident`, because Firebird folds bare names to upper case).

## FK Behavior

Firebird supports `MATCH FULL` / `SIMPLE` and `ON UPDATE/DELETE` actions.
Introspector groups composite FK columns by constraint name. `install_ddl` and
`Diff::Constraint` write FKs and unique constraints as `ALTER TABLE ... ADD
CONSTRAINT` after all CREATE TABLE statements (not inline; karr k34).

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::Firebird` | Schema component |
| `DBIO::Firebird::Storage` | Firebird driver (inherits InterBase) |
| `DBIO::Firebird::Storage::Common` | seq, datetime, insert_returning |
| `DBIO::Firebird::Storage::InterBase` | InterBase driver via DBD::InterBase |
| `DBIO::Firebird::Deploy` | test-deploy-and-compare |
| `DBIO::Firebird::Diff` | Compare introspected models |
| `DBIO::Firebird::Introspect` | Read live DB via rdb$ tables |
