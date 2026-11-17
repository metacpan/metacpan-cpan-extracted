---
name: dbio-firebird
description: Use when working on the DBIO::Firebird driver — its three storage transports, rdb$ introspection, deploy-and-diff, generators.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Firebird

Firebird RDBMS driver. Three transports: DBD::Firebird (closely modeled on
DBD::InterBase), DBD::InterBase and DBD::ODBC.

## Component Loading

```perl
package MyApp::DB;
use DBIO Schema => -fb;     # DBIO::Shortcut::fb
# or: use base 'DBIO::Schema'; __PACKAGE__->load_components('Firebird');
# → both declare storage_type +DBIO::Firebird::Storage
```

An ODBC DSN is reached by declaring `storage_type '+DBIO::Firebird::Storage::ODBC'`
(ADR 0010); the component and the shortcut declare the DBD::Firebird storage.

## Storage

`DBIO::Firebird::Storage` extends `DBIO::Firebird::Storage::InterBase`;
`Storage::ODBC` branches off `Storage::Common` (ADR 0010). Key settings:

```perl
# on DBIO::Firebird::Storage::Common (all three transports)
__PACKAGE__->sql_maker_class('DBIO::Firebird::SQLMaker');
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->_use_insert_returning (1);   # RETURNING support
__PACKAGE__->_use_supports_exists_query (1);
__PACKAGE__->_use_transactional_ddl (0);

# on each transport class (Storage, Storage::InterBase, Storage::ODBC)
__PACKAGE__->datetime_parser_type('DBIO::Firebird::DateTime::Format');
```

Capability facts on `Storage::Common`: `_random_function` is `RAND()`; the
EXISTS query is rendered with `FROM RDB$DATABASE`; set operations are `UNION` /
`UNION ALL` only — `INTERSECT` and `EXCEPT` are refused (ADR 0039).

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
`FIRST n SKIP m` limits via `apply_limit`. SQL dialect 3 is forced on connect.

## Introspection

`DBIO::Firebird::Introspect` extends `DBIO::Introspect::Base` — reads via `rdb$*`
system tables.

Model shape: `{ tables, columns, indexes, unique_constraints, foreign_keys }`.

Sources:
- `rdb$relations` — tables and views (kind: table/view)
- `rdb$relation_fields` + `rdb$fields` — column type, size, default, PK membership
- `rdb$indices` + `rdb$index_segments` — user indexes (excludes PK/UNIQUE constraints)
- `rdb$relation_constraints` (UNIQUE) + `rdb$index_segments` — unique constraints
- `rdb$relation_constraints` + `rdb$indices` + `rdb$index_segments` + `rdb$ref_constraints` — FK constraints (composite, grouped by constraint name; update/delete rule, match option)

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

The introspector groups composite FK columns by constraint name. `install_ddl` and
`Diff::Constraint` write FKs and unique constraints as `ALTER TABLE ... ADD
CONSTRAINT` after all CREATE TABLE statements (not inline). Engine facts
(`MATCH`, actions): `dbio-firebird-database`.

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::Firebird` | Schema component |
| `DBIO::Shortcut::fb` | `-fb` shortcut |
| `DBIO::Firebird::Storage` | Firebird driver (inherits InterBase) |
| `DBIO::Firebird::Storage::Common` | seq, savepoints, insert_returning, quote char, exists query, set-op refusal |
| `DBIO::Firebird::Storage::InterBase` | DBD::Firebird / DBD::InterBase transport |
| `DBIO::Firebird::Storage::ODBC` | DBD::ODBC transport, branch off Common (ADR 0010) |
| `DBIO::Firebird::DateTime::Format` | datetime parser of all transports |
| `DBIO::Firebird::Type` | type mapping, DDL type rendering |
| `DBIO::Firebird::Util` | `mask_error_details` (ADR 0014) |
| `DBIO::Firebird::DDL` | DDL emitter |
| `DBIO::Firebird::Deploy` | test-deploy-and-compare |
| `DBIO::Firebird::Diff` (+ `Diff::*`) | Compare introspected models |
| `DBIO::Firebird::Introspect` (+ `Introspect::*`) | Read live DB via rdb$ tables |
| `DBIO::Firebird::Test::Conformance` | driver half of core's shared case table |
