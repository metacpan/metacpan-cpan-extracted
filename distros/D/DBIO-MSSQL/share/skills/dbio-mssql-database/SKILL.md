---
name: dbio-mssql-database
description: "Microsoft SQL Server knowledge for Perl driver development (DBD::ODBC/Sybase, SQL dialect, types, IDENTITY, transactions, pagination)"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

Microsoft SQL Server for Perl DB driver development. When generic knowledge
conflicts with the driver code, the driver wins.

## DBD modules + connection paths

Two connection paths, both reach MSSQL:

| Path | Storage class | DSN |
|------|---------------|-----|
| ODBC | `DBIO::MSSQL::Storage` | `dbi:ODBC:Driver={SQL Server};Server=...;Database=...` |
| Sybase/FreeTDS | `DBIO::MSSQL::Storage::Sybase` | `dbi:Sybase:server=...` |

ODBC is the primary path. `DBD::Sybase` (incl. FreeTDS builds) reblesses to
`...::Sybase::NoBindVars` if placeholders are unsupported. FreeTDS > 0.82 has
broken stmt caching → driver disables caching, forces `_identity_method` to
`@@identity`, and sets `_no_scope_identity_query(1)`. Set tds version 8.0/7.0
in `freetds.conf` to keep placeholders.

## Version notes

`apply_limit` uses `ROW_NUMBER() OVER()` windowing (SQL Server 2005+) — the
broadly compatible dialect. The native `OFFSET ... FETCH` (2012+) and bare
`TOP` are NOT used by the limit dialect. `TOP` *is* used to make ordered
subselects legal (see Pagination). Server version retrieved via
`master.dbo.xp_msver ProductVersion`.

## Type system

DDL type mapping in `DBIO::MSSQL::DDL::_mssql_column_type`. Base types go
through `DBIO::MSSQL::Adapter`; alias map:

| Cross-engine | MSSQL native |
|--------------|--------------|
| string, varchar | `nvarchar` |
| decimal | `numeric` |
| bool | `bit` |
| bytea, *blob | `varbinary` |
| serial / bigserial | `int` / `bigint` |
| timestamptz | `datetimeoffset` |

Length appended for `n?char`/`n?varchar`/`binary`/`varbinary` only when
`size > 0` (MSSQL reports `nvarchar(max)`/`varbinary(max)` as size -1).

Datetime flavours: `datetime` (1753+, 3.33ms), `datetime2` (0001+, 100ns),
`datetimeoffset` (+tz), `smalldatetime` (1900–2079, 1 min). Parsed by
`DBIO::MSSQL::Storage::DateTime::Format` (Sybase path:
`...::Sybase::DateTime::Format`, ISO_strict via `syb_date_fmt`).

`MONEY`/`SMALLMONEY`: Storage `_prep_for_execute` wraps inserts/updates as
`CAST(? AS MONEY)`. Use `LongReadLen` for MONEY/blob reads.

## Identity / auto-increment

DDL emits `IDENTITY(1,1)` for `is_auto_increment` columns. Retrieval: driver
appends `SELECT SCOPE_IDENTITY()` to the insert statement (only correct method
under concurrency). Fallback if that fails/disabled: `_identity_method`
(`@@IDENTITY` or `SCOPE_IDENTITY()` standalone). `last_insert_id` returns the
cached `_identity`. `UNIQUEIDENTIFIER` autoinc columns are populated by
`NEWID()`, not IDENTITY — driver suppresses `SET IDENTITY_INSERT` for them.

## Transactions, locking, isolation

Savepoints use Sybase syntax: `SAVE TRANSACTION name` / `ROLLBACK TRANSACTION
name`; a same-named `SAVE TRANSACTION` releases the prior (release is a no-op).
Deferred FK checks via `with_deferred_fk_checks`: `EXEC sp_msforeachtable
"ALTER TABLE ? NOCHECK CONSTRAINT ALL"` then re-`CHECK` (MSSQL does not
re-validate on enable, so driver runs `WITH CHECK CHECK CONSTRAINT ALL`
explicitly). `for_update` NOT supported. Default isolation READ COMMITTED;
RCSI/snapshot are DB-level settings, not set by the driver.

## Pagination — be exact

`SELECT ... ORDER BY` is illegal in a subquery without `TOP`.
`_select_args_to_query` rewrites an ordered subselect's leading `(SELECT` to
`(SELECT TOP <max_int>` (cannot use `TOP 100 PERCENT`); throws on ordered
subselect unless `unsafe_subselect_ok`. Limit/offset itself is
`ROW_NUMBER() OVER(...)` sliced by `WHERE rno BETWEEN offset+1 AND offset+rows`
with `(SELECT(1))` as the default order (empty `OVER()` is illegal in MSSQL).

## Identifier quoting + case

`sql_quote_char([qw/[ ]/])` → bracket quoting: `[column name]`. Default schema
`dbo`. Case/accent sensitivity follows the server/DB collation (e.g.
`SQL_Latin1_General_CP1_CI_AS` = case-insensitive); the driver does not force
collation.

## Unicode

`nvarchar`/`nchar`/`ntext` are Unicode (UCS-2/UTF-16). Unicode string literals
need the `N''` prefix. `varchar` is single-byte per the DB collation. DDL maps
generic `string`/`varchar` → `nvarchar` to stay Unicode-safe.

## Introspection catalog

`DBIO::MSSQL::Introspect::*` mixes INFORMATION_SCHEMA and `sys.*`:

| What | Source |
|------|--------|
| Tables/views | `INFORMATION_SCHEMA.TABLES` (table_type) |
| Columns | `INFORMATION_SCHEMA.COLUMNS` |
| PK | `INFORMATION_SCHEMA.TABLE_CONSTRAINTS` + `KEY_COLUMN_USAGE` |
| Identity flag | `sys.columns.is_identity` |
| FKs | `INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS` + KCU |
| Non-constraint indexes | `sys.indexes` + `sys.index_columns` |

`sqlt_type` = `SQLServer`. Deploy is native (`DBIO::MSSQL::Deploy`,
test-and-compare via temp DB) — no SQL::Translator.

## Testing env vars

`DBIO_TEST_MSSQL_DSN` / `_USER` / `_PASS` (Sybase path);
`DBIO_TEST_MSSQL_ODBC_DSN` / `_USER` / `_PASS` (ODBC path). User/pass names
by convention. `DBIO_MSSQL_FREETDS_LOWVER_NOWARN=1` silences the
no-placeholders warning. No in-memory mode — integration tests need a real
SQL Server (e.g. `mcr.microsoft.com/mssql/server`).
