---
name: dbio-firebird
description: "DBIO::Firebird driver — Firebird/InterBase storage, rdb$ introspection, test-deploy-and-compare, sequence/generator handling"
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
__PACKAGE__->sql_maker_class('DBIO::Firebird::SQLMaker');
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->datetime_parser_type('DBIO::Firebird::Storage::InterBase::DateTime::Format');
__PACKAGE__->_use_insert_returning (1);   # RETURNING support
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

Model shape: `{ tables, columns, indexes, foreign_keys }`.

Sources:
- `rdb$relations` — tables and views (kind: table/view)
- `rdb$relation_fields` + `rdb$fields` — column type, size, default, PK membership
- `rdb$indices` + `rdb$index_segments` — user indexes (excludes PK/UNIQUE constraints)
- `rdb$relation_constraints` + `rdb$indices` — FK constraints (composite, grouped by constraint name)

## Deploy

`DBIO::Firebird::Deploy` — test-deploy-and-compare via temporary database:
1. Introspect live DB
2. CREATE DATABASE temp DB
3. Deploy desired schema to temp
4. Introspect temp DB
5. Diff the two models
6. DROP DATABASE temp

Uses `DBIO::Firebird::DDL` for DDL generation (wraps SQL::Translator).

## FK Behavior

Firebird supports `MATCH FULL` / `SIMPLE` and `ON UPDATE/DELETE` actions.
Introspector groups composite FK columns by constraint name. FK diff ops emit
`FOREIGN KEY (...) REFERENCES ...(...)` inline within CREATE TABLE.

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
