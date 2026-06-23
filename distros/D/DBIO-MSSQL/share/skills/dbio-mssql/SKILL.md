---
name: dbio-mssql
description: "DBIO::MSSQL driver: storage, SQLMaker, deploy, datetime types, bulk operations"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO MSSQL driver — fork of DBIx::Class::SQLite.

## Components

| Class | Role |
|-------|------|
| `DBIO::MSSQL` | Schema entry point |
| `DBIO::MSSQL::Storage` | DBI storage (SCOPE_IDENTITY, MONEY, ordered subselects) |
| `DBIO::MSSQL::SQLMaker` | SQL dialect (SELECT TOP, no OVER() empty clause) |
| `DBIO::MSSQL::Deploy` | Native deploy (test-and-compare via temp DB) |
| `DBIO::MSSQL::Introspect` | Schema introspection via INFORMATION_SCHEMA |
| `DBIO::MSSQL::Diff` | Diff two introspected models |
| `DBIO::MSSQL::DDL` | DDL generation from DBIO classes |

## Connection

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('MSSQL');
__PACKAGE__->connect("dbi:ODBC:Driver={SQL Server};Server=...;Database=...", $user, $pass);
```

## Storage Setup

```perl
__PACKAGE__->connection($dsn, $user, $pass, {
  LongReadLen => 100_000,  # for MONEY/blob columns
});
```

## Deploy

Uses native `DBIO::MSSQL::Deploy` — introspect live DB, deploy desired schema to a temp DB (`CREATE DATABASE _dbio_tmp_<pid>_<time>`), introspect that, diff the two. No SQL::Translator needed.

```perl
$schema->deploy;  # uses DBIO::MSSQL::Deploy
```

## Datetime Types

MSSQL ships multiple datetime flavours with different precision/range tradeoffs:

| Type | Range | Precision |
|------|-------|-----------|
| `datetime` | 1753-01-01 to 9999-12-31 | 3.33ms |
| `datetime2` | 0001-01-01 to 9999-12-31 | 100ns |
| `datetimeoffset` | 0001-01-01 to 9999-12-31 | 100ns + timezone |
| `smalldatetime` | 1900-01-01 to 2079-06-06 | 1 min |

Storage uses `DBIO::MSSQL::Storage::DateTime::Format` for parsing/formatting.

## MONEY / SMALLMONEY

MONEY columns require special DBI binding (CAST to MONEY in queries). The Storage `_prep_for_execute` hook handles this automatically.

## Identity / Auto-Increment

MSSQL uses `IDENTITY(1,1)` syntax. `last_insert_id` retrieves via `SCOPE_IDENTITY()` within statement scope. Fallback: `_identity_method` (e.g., `@@IDENTITY`, `SCOPE_IDENTITY()` outside try block).

## Ordered Subselects

MSSQL does not allow `SELECT ... ORDER BY` in subqueries without `TOP`. The `_select_args_to_query` method intercepts ordered subselects and wraps them with `SELECT TOP <max_int>` to satisfy the engine.

## Temp DB Strategy (Deploy/Diff)

```perl
# Temp DB naming: _dbio_tmp_<pid>_<time>
# Created: CREATE DATABASE _dbio_tmp_<pid>_<time>
# Dropped: DROP DATABASE _dbio_tmp_<pid>_<time>
# Temp DB connection: replaces Database= in DSN (supports HASH connect_info)
```

## Bulk Operations

MSSQL supports `BULK INSERT` via direct API, but DBIO uses standard DBI. For bulk copy, use direct `INSERT ... OUTPUT ...` or the native `BULK INSERT` via `$dbh->do`.

## Capabilities

- `last_insert_id`: via `SCOPE_IDENTITY()`
- `insert_returning`: NOT supported (use OUTPUT clause instead)
- ` multicolumn_in`: supported
- `for_update`: NOT supported

## Testing

```perl
# Offline (no DB) — not applicable for MSSQL since no in-memory option
# Integration (real DB) via env var:
#   DBIO_TEST_MSSQL_DSN=dbi:ODBC:...
```
