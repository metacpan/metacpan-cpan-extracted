# ADR 0009 — The text SQL Server writes into an error carries no values

- Status: accepted
- Date: 2026-11-02
- Tags: storage, errors, security, core-adr-0075

## Context

Core ADR 0075 (addendum of 2026-11-02): an error message names keys, columns
and options, never values, passwords or bind contents. The core masks the bound
values of the running statement in the engine's text (`_mask_error_values`,
values of at least four characters), and a driver adds the forms its engine
writes. SQL Server writes values into its own text, also when the value was a
bind. Measured live (SQL Server 2022; DBD::ODBC over FreeTDS and DBD::Sybase
give the same server text, DBD::ODBC with `[FreeTDS][SQL Server]` in front and
`(SQL-xxxxx)` behind, DBD::Sybase with `Server message number=...  text=` in
front):

| Server text | Value in it |
|---|---|
| `Conversion failed when converting the varchar value 'X' to data type int.` (also nvarchar, bit) | the value |
| `The conversion of the varchar value 'X' overflowed an INT1 column.` | the value |
| `The duplicate key value is (X, Y).` (primary key, unique, unique index, MERGE, multi-row insert) | the key values, no column names |
| `Truncated value: 'gehei'.` | the start of the value |
| `Incorrect syntax near 'X'.` | the token; on the NoBindVars class an interpolated value |
| `Unexpected character 'g' is found at position 1.` (JSON) | one character |

Without a value: foreign key, check and not-null violations, identity insert,
`Arithmetic overflow error ...`, `Error converting data type varchar to
numeric`, operand type clash, uniqueidentifier and date conversion failures,
`Incorrect syntax near the keyword '...'`.

## Decision

1. `DBIO::MSSQL::Util::mask_error_details` holds the form rules: each form
   above has the value replaced by `***`, the words around it (type, table,
   column, constraint, error position) stay. The key text of SQL Server names
   no columns, so the whole parenthesis is masked. A text of no known form is
   returned as it is.
2. `DBIO::MSSQL::Storage::_mask_error_values` applies those rules and then
   calls `next::method`, which masks the bound values of four characters or
   more. It sits on the transport-neutral base, so `::ODBC`, `::Sybase` and
   the NoBindVars class have it.
3. The form rules also catch short values (`7`, `ab`) where the server quotes
   them; elsewhere a short value stays, as in core.
4. Not masked: names of tables, columns and constraints; texts the application
   writes itself with `RAISERROR`/`THROW`; `$dbh->errstr`, which is a DBI
   attribute and stays raw.

## Consequences

- There is no other path in this driver that carries engine text into an
  exception: no async storage, no own `DBIO::Exception::Server`; the handler
  and the populate reports are core's and call the hook.
- A new server sentence that quotes a value is not masked until a rule for it
  is added (or the value is a bind of four characters or more).
