# Draft for DBD::ODBC, not sent: a LOB value at the LongReadLen boundary comes back with its last character replaced by a NUL

Origin: dbio-mssql karr k61 (measured 2026-10-17, SQL Server 2022 16.0.4295.3,
DBD::ODBC 1.61 built without Unicode support, FreeTDS ODBC driver 1.3.17; pinned
as TODO tests in dbio-mssql t/77). Which of the two (DBD::ODBC, tdsodbc) is at
fault was not narrowed down; reported against DBD::ODBC because its
`LongTruncOk` / "long truncated" check is the one that does not fire.

## What happens

With `LongReadLen` = N (`LongTruncOk` off), a value longer than the buffer makes
the fetch fail with "long truncated DBI attribute LongTruncOk not set and/or
LongReadLen too small". At the boundary it does not, and the value is wrong:

| Column | Value of | Result |
|--------|----------|--------|
| `VARCHAR(MAX)`, `TEXT`, `NTEXT` | N + 1 characters | length N + 1, **the last character is "\0"** (N + 2: error, as it should) |
| `NVARCHAR(MAX)` | N characters | length N, the last character is "\0" (N + 1: error) |
| `VARBINARY(MAX)`, `IMAGE` | N + 1 bytes | error; N bytes are whole |

Example, `LongReadLen` 10, `SELECT CAST('0123456789A' AS VARCHAR(MAX))`: returns
`0123456789\0` and `$sth->err` is false. The same at 80 and at 32768.

The buffer for a character column is N + 1 bytes (room for the terminating NUL).
A value of N + 1 characters is reported as truncated by `SQLGetData`
(`SQL_SUCCESS_WITH_INFO`, 01004) but is not treated as such; its last byte is
overwritten by the terminator. For `NVARCHAR(MAX)` the same happens one
character earlier.

## Recommendation

Treat 01004 from `SQLGetData` for a LOB column as truncation when the returned
length indicator is larger than the number of bytes copied, whatever the
terminator accounting. A test: `LongReadLen` N, values of N-1, N, N+1, N+2
characters of each LOB type, expecting either the whole value or an error.

## What dbio-mssql does meanwhile

`DBIO::MSSQL::Storage::ODBC` sets `LongReadLen` to 1073741824 on every
connection unless the connect info names one (DBI's 80 made a schema with a
LOB column unreadable beyond 80 bytes; measured: no memory or time price for the
large value, 5 MB values read whole), which puts the boundary out of reach. A
caller who sets a small `LongReadLen` himself still meets it: t/77 holds that as
TODO tests.
