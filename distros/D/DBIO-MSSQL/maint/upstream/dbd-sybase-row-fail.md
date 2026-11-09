# Draft for DBD::Sybase, not sent: a row whose fetch fails (CS_ROW_FAIL) is dropped without an error

Origin: dbio-mssql karr k56, k59 (measured 2026-10-08 and 2026-10-17, SQL Server
2022 16.0.4295.3, DBD::Sybase 1.27 against FreeTDS 1.3.17, TDS 7.4; pinned in
dbio-mssql t/65, t/66, t/77).

## What happens

`syb_st_fetch` (`dbdimp.c`) calls `ct_fetch`. When a value does not fit the
buffer the DBD made for its column, the client library answers `CS_ROW_FAIL`
(-203) for that row. Unless `LongTruncOk` is on, the DBD goes back for the next
row (`goto TryAgain`) and says nothing: the row seems never to have existed. A
caller sees a result set with a row missing -- `fetchrow_array` returns the next
row, or an empty list when it was the last -- and `$sth->err` is undef.

With `LongTruncOk` on the row is returned instead, with a truncated value (one
hex digit in the cases below). Neither is an error.

## Where it was measured (plain DBI, no wrapper)

| Column / read | Result |
|---------------|--------|
| `VARBINARY(MAX)`, any value of 1 byte or more | row dropped. The client library describes the column as `CS_BINARY_TYPE` of length 2147483647, `get_cwidth` makes room for the hex digits (`2 * maxlength + 2`), which is 0 in 32 bits, plus one: a buffer of one byte |
| `IMAGE` read as hex digits (no `syb_binary_images`), value above `TEXTSIZE / 2` bytes | row dropped (at `TEXTSIZE` 32768: from 16385 bytes) |
| `SQL_VARIANT` (described as `TYPE` 1, `PRECISION` 8009) holding a binary base type | the row is dropped when it is the first of the result; when other rows were fetched before it, it is returned as the hex digits of the value, as text; two binary variants and nothing else: both dropped. Which of the two cannot be told from the description |

`SELECT id FROM t WHERE id = 3` finds the row; adding the `SQL_VARIANT` column to
the select list makes it vanish.

## Recommendation

A row that cannot be fetched is an error, not an absence. In `syb_st_fetch`,
where `CS_ROW_FAIL` is met and `LongTruncOk` is off, set the handle's error
(`DBIc_err`, a message naming the column and the buffer size) and return
failure instead of `goto TryAgain`. A caller that wants rows with truncated
values already has `LongTruncOk`.

Independently: the buffer of a `VARBINARY(MAX)` / `VARCHAR(MAX)` /
`NVARCHAR(MAX)` column must not be computed as `2 * maxlength + 2` in an `int`
(`get_cwidth`); for a column described with the maximum length the DBD should
use `LongReadLen`/`TEXTSIZE` as it does for `TEXT`/`IMAGE`.

## What dbio-mssql does meanwhile

`VARBINARY(MAX)` and the other binary columns of a result source are asked for
as `CAST(col AS IMAGE)` with `syb_binary_images` (k56); `SQL_VARIANT` and any
`VARBINARY(MAX)` result column the storage did not rewrite make the statement
fail after the execute, before a fetch (k59). The `IMAGE` hex case and reading
on the handle directly (`dbh_do`) are documented limits.
