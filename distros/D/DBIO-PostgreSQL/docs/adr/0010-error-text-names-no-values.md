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
