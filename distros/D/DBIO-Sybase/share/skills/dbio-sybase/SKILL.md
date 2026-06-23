---
name: dbio-sybase
description: "DBIO::Sybase driver — Sybase ASE storage, test-deploy-and-compare, native escape hatches"
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
# → reblesses to DBIO::Sybase::Storage::ASE after first use
my $v = $schema->storage->syb_oc_version;   # FreeTDS version or undef
```

### Key settings

```perl
__PACKAGE__->sql_maker_class('DBIO::Sybase::SQLMaker');  # TBD — falls back to DBIO::SQLMaker
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->datetime_parser_type('DateTime::Format::Pg');
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

### Sth caching

`disable_sth_caching { 1 }` may be needed when using RETURNING clauses with cached sth.

## SQLMaker

`DBIO::Sybase::SQLMaker` is not yet implemented — falls back to `DBIO::SQLMaker` (SQL::Abstract). A native SQLMaker will be added when `DBIO::Sybase::DDL` is implemented.

## Introspection

`DBIO::Sybase::Introspect` extends `DBIO::Introspect::Base` — reads via `INFORMATION_SCHEMA` views.

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

`install` currently falls back to `storage->deploy` (SQL::Translator path).

`upgrade` calls `diff` then `apply`.

## Diff

`DBIO::Sybase::Diff` extends `DBIO::Diff::Base`. Operations in dependency order: tables → columns → indexes.

### Sub-modules

| Sub-module | Compares |
|------------|----------|
| `DBIO::Sybase::Diff::Table` | tables + FK constraints |
| `DBIO::Sybase::Diff::Column` | columns |
| `DBIO::Sybase::Diff::Index` | indexes |

## FK Behavior

FKs are **readable via `INFORMATION_SCHEMA`** and **emitted in DDL**.
Sybase supports `FOREIGN KEY` constraints with `ON DELETE/UPDATE` actions.

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::Sybase` | Schema component |
| `DBIO::Sybase::Storage` | DBI storage + escape hatches |
| `DBIO::Sybase::SQLMaker` | SQL generation (TBD) |
| `DBIO::Sybase::Deploy` | test-deploy-and-compare |
| `DBIO::Sybase::Diff` | Compare introspected models |
| `DBIO::Sybase::Introspect` | Read live DB |
