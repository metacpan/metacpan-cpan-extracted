---
name: dbio-mssql
description: Load when working on the DBIO::MSSQL driver — storage, SQLMaker, deploy, datetime types, bulk operations.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO MSSQL driver — driver for Microsoft SQL Server.

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

## Connection parameters without a DSN

`_connect_params_dsn` (core ADR 0057) turns `{ dbname, host, port }` — `DBIO::AccessBroker::Static`, or a connect-info hash without `dsn` — into a DBD::Sybase DSN; the registered name `MSSQL` is no DBD.

| Given | DSN |
|-------|-----|
| `dbname` + `host` + `port` | `dbi:Sybase:host=..;port=..;database=..` |
| `host` + `port` | `dbi:Sybase:host=..;port=..` (login's default database) |
| `dbname` | `dbi:Sybase:database=..` (server from `$DSQUERY`) |
| `host` without `port`, `port` without `host` | throws — DBD::Sybase ignores a lone one; no 1433 assumed |

ODBC has no form these parts can fill (`DBIO::MSSQL::Storage::ODBC` keeps core's refusal): pass the whole DSN as `dsn`, or as a `dbname` starting with `dbi:`. Live-verified over DBD::Sybase (`t/60-connect-params-live.t`). The seam is asked at `connect_info`, on the declared base and before the storage adapts to its access path — so connection parameters always lead to DBD::Sybase.

## Access path — which class a storage becomes

The component and `-ms` pin `DBIO::MSSQL::Storage` (the declaration, core ADR 0059). At the first use that needs the driver — not at `connect` — `_adapt_to_access_path($dbd)` moves the storage into this driver's class for the DBD:

| DSN | Storage after the first use |
|-----|-----------------------------|
| `dbi:ODBC:` | `DBIO::MSSQL::Storage::ODBC` (decided from the DSN, no connection) |
| `dbi:Sybase:` | `DBIO::MSSQL::Storage::Sybase`, `…::NoBindVars` without placeholders, `…::FreeTDS` mixed in over FreeTDS — needs DBIO::Sybase, throws without it |
| connection coderef | the hook runs it and reads the DBD off the handle |
| no connect info | stays `DBIO::MSSQL::Storage` |
| another driver's DBD | stays; core warns (`driver_strict(1)` throws, `driver_warnings(0)` silences) |

- Only the declared base moves: a private subclass pinned through `storage_type` stays what it is. Over DBD::ODBC core warns; **over DBD::Sybase the hook throws** (k42, k43; ADR 0008), naming `DBIO::MSSQL::Storage::Sybase`. Derive from `::ODBC` or `::Sybase` instead.
- The hook never calls `_rebless` or the connector registry and never asks the server what it is — that is the generic DSN detection (schema without a declared driver), which ends in the same classes.
- `DBIO::MSSQL::Storage::Sybase` has its own hook and does not call `next::method` (`DBIO::Sybase::Storage` is ahead of the MSSQL base in its MRO).
- Over DBD::Sybase + FreeTDS the key of a new row is `SCOPE_IDENTITY()` as in the base class (k39: the old `@@identity` workaround returned the trigger's key; only FreeTDS 1.3.17 measured) and the class brings `SET TEXTSIZE` = `LongReadLen` (long values cut at 32768 by default).
- Over DBD::Sybase a bind value of more than 4000 bytes goes into the statement as a literal (k40): FreeTDS declares every placeholder `varchar(4000)` and the server cuts a bound value silently. Plain literal for ASCII, `N'...'` otherwise; the trace keeps the placeholder; void-context `populate` goes row by row. Only `DBIO::MSSQL::Storage::Sybase` does this; a private subclass of the base is refused over DBD::Sybase. `t/63-long-bind-values.t` (offline), `t/60` part D (live).
- A value for a binary column (`binary`, `varbinary`, `image`, and the names the DDL makes one of them: `blob`, `bytea`, …) is bound in the way each DBD carries one (k50), decided by the data type of the bind, in conditions too. DBD::ODBC: `SQL_LONGVARBINARY` (`SQL_VARBINARY` cuts at 8000 bytes silently). DBD::Sybase: the hex form, in pieces of 1999 bytes, to `CONVERT(VARBINARY(MAX), ?, 1)` — never a literal; at most 2099 placeholders per statement (about 4 MB), an `EXEC` with such a value throws, void-context `populate` goes row by row. A value is the bytes of the string whatever its UTF-8 flag; a character above 255 throws. Not covered: NoBindVars. `t/64-binary-bind-values.t` (offline), `t/65-binary-values-live.t` (live).
- Reading a binary column over DBD::Sybase (k56): the DBD hands back hex digits for `BINARY(n)`/`VARBINARY(n)`/`IMAGE` and **drops every row with a value in a `VARBINARY(MAX)` column, without an error** (a buffer of one byte). `DBIO::MSSQL::Storage::Sybase::_select` therefore asks for a column of a result source whose `data_type` is a binary one as `CAST(<col> AS IMAGE)`, with `syb_binary_images` on for that execute alone (`_execute_sth`), and the bytes come back. Only a select-list entry that is the column itself — not a function, an expression, literal SQL, a column without a declared `data_type`; not in a subquery (`as_query`, `count`, `-in`), where an `IMAGE` could not be compared. A `VARBINARY(MAX)` result column that was not rewritten throws after the execute (decided by how the handle describes it: `TYPE` -2, `PRECISION` 2147483647), whatever the rows hold; the way out is `CONVERT(VARCHAR(MAX), <expr>, 2)`. Sized binary values that are not the column itself stay hex digits. A value is cut silently at the session's `TEXTSIZE` (= `LongReadLen`, 32768 by default; k47) — connect with `LongReadLen` for more; an empty value costs `TEXTSIZE` bytes of memory. NoBindVars reads the same way; `dbh_do` is not reached. DBD::ODBC reads bytes, up to `LongReadLen` (DBI's default 80), and throws beyond. `t/66-binary-read-values.t` (offline), `t/65-binary-values-live.t` (live).
- Connect before asserting a class in a test. `t/62-adapt-access-path.t` (offline; the only proof of the ODBC branch), `t/60`, `t/61` (live, DBD::Sybase).

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

## MONEY

MONEY columns require special DBI binding (CAST to MONEY in queries). The Storage `_prep_for_execute` hook handles this automatically. SMALLMONEY is not cast.

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
# Offline: `../dbio/maint/capped-test prove -lr t/` runs the SQLMaker, diff,
# introspect-contract, DDL and storage-wiring tests without a server.
# Live (house rules; `dbio-db env mssql`, then `../dbio/maint/live-preflight`
# before the same command), per access path:
#   DBIO_TEST_MSSQL_DSN=dbi:Sybase:...        (DBD::Sybase)
#   DBIO_TEST_MSSQL_ODBC_DSN=dbi:ODBC:...     (DBD::ODBC)
```
