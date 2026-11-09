# ADR 0014 — The text of an error names the type, the column and the constraint, never a value

- Status: accepted (follows core ADR 0075)
- Date: 2026-11-02
- Tags: storage, errors, privacy, relates-core-0075

## Context

Core ADR 0075 sets the rule that an error message names keys, columns and
options and never values, passwords or bind contents, and gives every storage
one seam, `_mask_error_values($text, \@values, $statement)`. The base
implementation replaces each bound value of four characters or more.

The Firebird server writes values into two sentences, measured on Firebird
5.0.4 through DBD::Firebird 1.39, also when the value was bound:

- `Problematic key value is ("A" = 987654321, "B" = 'x')` on a PRIMARY KEY,
  UNIQUE or FOREIGN KEY violation. The server does not double a `'` in the
  value, so the sentence cannot always be taken apart.
- `conversion error from string "x"` on a date, timestamp or time column.

The other errors measured hold no value: string right truncation (only the
lengths), CHECK, NOT NULL (`value "*** null ***"`), `Malformed string`,
`Cannot transliterate character between character sets`, `numeric value is out
of range`, `value exceeds the range for valid dates`, syntax errors. The
driver's own refusals for a boolean and a numeric column quoted the value too.

## Decision

1. `DBIO::Firebird::Util::mask_error_details` replaces the values of those two
   sentences (and of `validation error ... value "x"`, except the server's
   NULL marker) with `***`. The quoted column names of a key stay, but only
   when the text has one reading: as many `" = ` as columns found, no bound
   value holding `, "` or `)`. Otherwise everything behind `is ` is `***`.
2. `Storage::Common::_mask_error_values` applies it and then calls
   `next::method`, so the base net for bound values still runs. It sits on
   `Common` and reaches all three transports.
3. The refusals of `_adjust_bind_values` (boolean, numeric) name the column and
   no longer the value.
4. `$dbh->errstr` stays as the server wrote it; it is a DBI attribute.
5. A column, table or constraint name is never masked.

## Consequences

The paths where engine text becomes an exception all go through core's
`_dbi_handle_error`, `_dbh_execute` and the populate paths, which call the
hook; the commit refused after `CREATE UNIQUE INDEX` reaches it through
`_exec_txn_commit` -> `_dbi_handle_error`. There is no async storage in this
distribution. A value inside a literal of the statement is not a bound value;
it stays in the `[for Statement ...]` part, and the key sentence of such an
error is masked all the same.
