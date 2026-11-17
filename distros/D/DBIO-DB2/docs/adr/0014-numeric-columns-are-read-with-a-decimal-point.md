# ADR 0014 — Numeric columns are read with a decimal point

- Status: proposed
- Date: 2026-11-11
- Tags: storage, cursor, locale, types

## Context

Under a German client locale (`LC_ALL`, `LC_CTYPE` or `LANG` = `de_DE.*`, set when the
process starts) the Db2 CLI delivers numeric values as text with a comma: `DECIMAL`
`1234567890,12`, `REAL` `1,500000E+00`, `DOUBLE` `1,50000000000000E+000`, `DECFLOAT`
`1,25` (the types DBD::DB2 reports: `DECIMAL` 3, `NUMERIC` 2, `FLOAT` 6, `REAL` 7,
`DOUBLE` 8, `DECFLOAT` -360). Perl reads `1234567890,12` as `1234567890`: the fraction is
dropped, silently.

## Measurement (live Db2 LUW)

- The trigger is `LC_CTYPE` (so `LC_ALL` and `LANG`), not `LC_NUMERIC`.
- `LANGUAGE`, `DB2TERRITORY`, `DB2CODEPAGE`, `DB2LOCALE`, `DBDATE`, `NLS_LANG` and the keys
  of the DSN have no effect.
- What counts is the locale at `CONNECT`, and only when the libc environment and the libc
  global locale are both switched; Perl's `%ENV` and `POSIX::setlocale` do not reach the CLI.
  Only an FFI `setenv` plus `setlocale` around the connect changed it.
- The write direction is fine: a bound `'1.5'` or `1.5` arrives as 1.5 under de_DE
  (`cast(? as decimal(12,2))*100` is 150).

There is therefore no connection setting that keeps the CLI from formatting the text.

## Decision

`DBIO::DB2::Storage::Cursor::decode_rows`, which the cursor (`next`, `all`),
`DBIO::DB2::Storage::select_single` and the plan rows of `_explain_query` go through,
normalizes the columns of the numeric types with a fraction (TYPE 2, 3, 6, 7, 8, -360): a
value matching `/\A[-+]?\d*,\d*(?:[Ee][-+]?\d+)?\z/` (exactly one comma, optional exponent,
no grouping) gets `,` replaced by `.`. Everything else is left as it comes: integers,
character and binary columns, `NULL`, a value without a comma. It runs whether or not the
database is UTF-8; the character decoding is unchanged.

## Alternatives considered

- **`setenv` and `setlocale` around the connect through FFI**: the only thing measured to
  change the CLI. Rejected: a new dependency, and an intervention in the process locale,
  which is not DBIO's to change.
- **A connection or session setting**: none exists (see the measurement).
- **Document it and leave it to the user** (start the process under `C`): the failure is
  silent and wrong data, so a documented trap is not enough.

## Consequences

- A numeric column of a fraction type comes back as text with a point in every locale;
  under a locale without the problem nothing changes.
- A `DECIMAL` is delivered as the string the CLI writes (`1234.50`), not as a number; the
  exact value is kept for big `DECIMAL` and `DECFLOAT` values.
- Raw `$dbh` reads (`dbh_do`, `selectrow_array`) are the user's own handle and are not
  repaired.
- Tests: `t/100-numeric-decimal-point.t` (offline), `t/101-numeric-decimal-point-live.t`
  (child processes under the C locale, `de_DE.utf8` and `de_DE.iso88591`).
