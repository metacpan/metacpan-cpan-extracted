# ADR 0010 — The error text of a refused statement names no values

- Status: accepted (coordinator decision of 2026-11-02, under the maintainer's order to check every driver for values in error texts; core ADR 0075)
- Date: 2026-11-02
- Tags: storage, exceptions, bind-values, async

## Context

Core ADR 0075 fixes that an error text names keys, columns and options, never
values, and gives the storage the hook `_mask_error_values($text, \@values,
$statement)`; the base class replaces each bound value of four characters or
more by `***`. PostgreSQL writes values into its text in many forms of its
own, also when the value was a bind: the quoted value of the main message
(`invalid input syntax for type integer: "x"`, `value "3000000000" is out of
range for type smallint`, enum, array, record, range, tsvector, an invalid
byte sequence), the `DETAIL` (`Key (a, b)=(…)`, `Failing row contains (…)`,
the JSON token, the exclusion conflict, the partition key), and the `CONTEXT`
(`unnamed portal parameter $1 = '…'` with
`log_parameter_max_length_on_error`, the JSON excerpt, a COPY line). Values
shorter than four characters pass the base net.

## Decision

- **The rules of the forms are one function**, `DBIO::PostgreSQL::Util::
  mask_error_details` (and `mask_detail_values` for a bare `detail`). They
  need no bound values, so they hold for every length, and the transports
  (future_io, dbio-postgresql-ev) use the same function.
- **future_io has the same net.** The bound values of a statement are no
  property of the statement beyond its dispatch (ADR 0044), but its error
  needs them: `_submit_query` puts a copy at the database handle
  (`private_dbio_binds`), the `HandleError` reads it from the handle the error
  occurred on, takes the values out (`DBIO::Util::mask_bound_values`, with
  `$dbh->quote` as the quote form) and then runs the rules of the forms, the
  order of the sync storage. The values and the statement handle that holds
  them leave the connection when the statement ends, by result, error or
  failed send; the next submit clears it as well. A
  statement without binds and the connect have nothing to take out and get the
  rules alone.
- **The sync storage overrides `_mask_error_values`**: the core's net first
  (it finds the value in whatever form the quoting makes of it, also where the
  rules would have cut the text), then the rules of the forms. This replaces
  the former `_dbi_handle_error` override.
- **Kept**: type, column, constraint, table, SQLSTATE and the position
  (`LINE n` with its excerpt, which is the statement text). Not masked:
  relation, function and column names the statement wrote itself; a name that
  came from a bound value of four characters or more reads `***`.
- **Ambiguous keys**: the column list of `Key (…)=(…)` stays where it reads in
  one way (plain identifiers, or an expression of names and brackets); else the
  whole key text is `***`.
- **`$dbh->errstr` stays raw**, as a DBI attribute.

## Consequences

- A value that itself holds a line beginning with `DETAIL:  `, `CONTEXT:  `
  or `HINT:  ` can place a field boundary wrongly; with four characters or more
  the core's net has replaced it before the rules run.
- A value of fewer than four characters that the server reads as a name
  (`relation "abc" does not exist`) stays: no rule can tell it from a name the
  statement itself wrote. The same holds on every transport.
- A new sentence of the server that quotes a value needs a rule in
  `mask_error_details` and a case in `t/140-mask-error-values.t`; the live
  forms are in `t/141-error-values-live.t`.
- DDL run through a plain handle (`Deploy`) has no binds and its text is not
  passed through the hook.

## Addendum 2026-11-09

Maintainer decision: no bound or quoted value appears in a message, in
whatever language the server reports. PostgreSQL words its text by
`lc_messages`, and the rules above knew only the English sentences, so on a
German or French server a short value and every value the server quotes
(`Schlüssel »(name)=(ab)« existiert bereits.`, `ungültige Eingabesyntax für
Typ integer: »xy«`) stood in the message.

- **The masking holds on the SQLSTATE and the quoting marks, not on the
  wording.** `mask_error_details($message, $state)` and
  `mask_detail_values($text, $state)` take the SQLSTATE of the error as an
  optional second argument; without it, or with a state of another class, the
  English rules are all there is, as before.
- **The extra stage runs only where the English rules read nothing in a
  field**, so the English result is untouched. Class 22 (data exception): the
  primary text has the span from its first quoting mark to its last (`"…"`,
  `»…«`, `« … »`, `„…“`, `“…”`, `「…」`) replaced by `***`, the marks and the
  blanks inside them kept, else what follows its last colon. Class 22 and 23
  (integrity constraint violation): the detail keeps the columns of a
  `(cols)=(value)` key, masks a bracketed row as `(***)`, else the quoted span;
  a detail with a bracket or a mark left over after masking is `***` whole. A
  portal parameter (`$1 = '…'`) is masked in any field but the statement's, a
  context line `words N: rest` of another language keeps its words.
- **A message with the severity label in English** (`ERROR:  `; for the
  `detail` field of the exception the severity DBD::Pg reports) is read by the
  English rules alone: a sentence of an English server that no rule knows
  (`Array value must start with "{" …`) is not taken for a foreign one.
- **A label of any language starts a field** (capital letters, an optional
  number, an optional blank before the colon: `ZEILE 1:`, `DÉTAIL :  `). A
  label with a number is the statement excerpt and stays; an unknown label is
  read as a context or a detail. This applies with a state of class 22 or 23
  only.
- **Where the state comes from**: `DBIO::PostgreSQL::Util::error_sqlstate`
  reads it from the database handle the error happened on (the statement
  handle's `Database`): the sync storage in `_mask_error_values` and
  `_dbi_error_fields`, the future_io transport in `_pg_raise`. Core is not
  changed.
- **Not covered**: a text of a class other than 22 and 23 that quotes a value
  (such a text is a name in practice, and a name stays).

`t/142-error-values-language-live.t` holds it live for German and French on
both transports; `t/140-mask-error-values.t` holds the texts offline.
