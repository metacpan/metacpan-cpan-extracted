# ADR 0003 — MONEY binds are cast via CAST(? AS MONEY)

- Status: accepted
- Date: 2026-06-20
- Tags: storage, types, money, bind

## Context

DBI/DBD drivers, when binding a Perl scalar to a MSSQL `MONEY` column without
type information, can truncate the value to four decimal places (or otherwise
mishandle scale) before it reaches the server. `MONEY` has fixed scale-4
semantics that the plain placeholder path does not reliably preserve.

DBIO inserts and updates pass bind values as plain placeholders by default;
there is no per-type bind attribute path in this driver that fixes `MONEY`
scale on its own.

## Decision

In `DBIO::MSSQL::Storage::_prep_for_execute`, for `insert` and `update` ops,
inspect the result source's column info for each supplied field
(`Storage.pm:55-85`). When a column's `data_type` matches `/^money\z/i`,
rewrite its bind to an explicit cast:

- For a lone bind literal value (`is_literal_value` whose first element is
  `'?'`), wrap as `\[ 'CAST(? AS MONEY)', @binds ]` (`Storage.pm:68-78`).
- For an ordinary non-literal value, wrap as
  `\['CAST(? AS MONEY)', [ $col => $value ]]` (`Storage.pm:79-82`).

This mutates the in-place `$fields` hashref of the args before delegation to
`next::method`.

## Rationale

Casting on the SQL side (`CAST(? AS MONEY)`) hands the server the exact type
it needs and side-steps any DBD-level scale truncation, regardless of which
DBD (ODBC or Sybase) is in play — the fix lives at SQL-generation time, above
the driver. Handling the lone-`?` literal case explicitly preserves the
existing bind list for the unambiguous case while declining to touch literals
we cannot safely rewrite.

## Consequences

- `MONEY` values round-trip at full scale-4 precision on insert/update.
- `_prep_for_execute` mutates the caller's bind/field structure; this is the
  established DBIx::Class idiom for this driver and other callers expect it.
- Detection is keyed on the exact `data_type` `money` (case-insensitive).
  `smallmoney` is not covered by this regex; add it here if a `smallmoney`
  truncation case surfaces.
