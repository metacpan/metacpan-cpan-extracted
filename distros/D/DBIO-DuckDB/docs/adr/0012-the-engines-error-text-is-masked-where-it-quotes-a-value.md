# ADR 0012 — The engine's error text is masked where it quotes a value

- Status: accepted
- Date: 2026-11-02
- Tags: storage, errors, bind-values, family-rule

## Context

The family's rule is that a message names keys, columns and options, never
values; the text of the engine is the driver's to keep to it. DuckDB 1.5.3
writes the value into its error text, also when the value was a bind:
`Could not convert string 'x' to INT32`, `Duplicate key "email: x" violates
unique constraint.`, `Violates foreign key constraint because key "id: 4"
does not exist ...`, the input of a malformed JSON, a date, a timestamp, a
DECIMAL, a BLOB, a regular expression. Core's `_dbi_handle_error` puts that
text into the exception unchanged, and the bind values did not appear in the
appended `[for Statement ... with N bind values]` -- the engine's sentence
was the one place they did.

DuckDB reports no constraint, table or detail apart from the text
(DBD::DuckDB gives no `pg_error_field`; the `sqlstate` is empty), so there
is no field to mask, and a caller finds the cause in the words around the
value: the type, the column, the constraint, the table.

## Decision

1. `DBIO::DuckDB::Util::mask_error_details($message, \@binds, $statement)` replaces the
   value in each sentence of the engine that quotes one by `***`, one rule per
   sentence, and leaves the words around it. A sentence it does not know is
   left as it is; a message is not switched off.
2. The excerpt of the statement DuckDB appends (`\n\nLINE n: ...` and the caret
   line) is the caller's own statement text and is not touched -- only when it
   is DuckDB's: the masker is given the statement, and the text from `LINE n:`
   counts as the excerpt only if it ends the message, holds a piece of line n
   of that statement (cut with `...` at either end) and ends with the caret
   line. A bound value can imitate any marker, so anything else is message:
   the whole text is masked, the search for bound values included, and without
   a statement there is no excerpt. Core's `[for Statement ...]` is appended
   after the driver's handler (`DBIO::Storage::DBI::_dbi_handle_error`
   strips what DBI added and appends its own once the driver handler has
   returned), so it never reaches the masker and is no marker for it.
3. A key text (`"c1: v1, c2: v2"`) is read as pairs only where that is the one
   reading. It does not escape anything, so a value holding `, ` or `: ` can
   look like one more column; such a text, a column twice or a bound value
   with either in it makes the whole key text `***`.
4. The values bound to the statement are collected by the storage's
   `bind_param` callback (one slot per parameter, as given and as sent) and
   handed to the masker, which also replaces each one of four characters or
   more found elsewhere in the message (a sequence name or a file path taken
   from a bind). Without the callbacks (a DBD::DuckDB newer than the one they
   are bound to) the masker works on the sentences alone.
5. `DBIO::DuckDB::Storage::_dbi_handle_error` applies it to every text that
   reaches an exception through DBI: statements, the appender, the Arrow
   path's statement, table rebuilds, introspection. The failures
   `DBIO::DuckDB::Arrow` reads from libduckdb's Arrow conversion itself go
   through it as well.

## Consequences

- An exception does not carry a bound value; the type, column, constraint and
  table stay. A new sentence of a later libduckdb that quotes a value is not
  masked until a rule is added for it; `t/71-error-values-masked.t` measures
  the sentences of 1.5.3.
- The handle itself (`$dbh->errstr`, `$sth->errstr`) still holds the engine's
  text; masking applies to what DBIO throws.
- The throwaway target database of `Deploy` is a plain DBI connection without
  this handler; it runs the schema's own DDL on an empty database, so no data
  value reaches its errors.

## Addendum 2026-11-02 — the core hook instead of an override

Core gained one seam for this (core ADR 0075): `_mask_error_values($text,
\@values, $statement)`, called by `_dbi_handle_error` on the text before core's
appendix, by `_dbh_execute`, the connection actions and the populate paths. The
base class replaces every bound value of four characters or more, also in the
form `$dbh->quote` makes of it. Decisions 4 and 5 are replaced:

- `DBIO::DuckDB::Storage` overrides `_mask_error_values` instead of
  `_dbi_handle_error`: the excerpt DuckDB appends is cut off when it is DuckDB's
  own (`Util::_split_excerpt`), the head goes through `mask_error_details`
  (sentences, key ambiguity) and then `next::method` (core's net), the excerpt
  is put back. The core net never sees the excerpt, so a bound value cannot
  change the caller's statement text in it.
- The `bind_param` callback no longer collects values
  (`private_dbio_duckdb_bound` is gone); the masking no longer depends on the
  reader callbacks of DBD::DuckDB <= 0.16. Core hands the values in.
- Kept because core does not cover it: the UTF-8 byte form of a value with
  non-ASCII characters (the engine echoes the bytes it was sent). The hook adds
  it to the values it passes on.
- The Arrow path (`DBIO::DuckDB::Arrow`, the two failures libduckdb reports
  itself) calls the same method through a masker `duckdb_arrow_fetch` hands in.
  The appender has no values the storage knows; it gets the sentence forms
  through the handle's error path.
- `mask_error_details` stays public with its own bound-value search (pinned by
  `t/72`); in the storage path it overlaps with core's net.

Order in core: `_dbi_handle_error` applies the hook to the whole engine text
first and cuts DBI's appendix afterwards (core ADR 0075, addendum; the
coordinator's decision). A bound value that holds the appendix marker
(`ab [for Statement "x`) is at least 16 characters long, so core's net masks it
whole before anything is cut, and the constraint sentence stays. `t/71` holds
the case ("core's appendix marker").
