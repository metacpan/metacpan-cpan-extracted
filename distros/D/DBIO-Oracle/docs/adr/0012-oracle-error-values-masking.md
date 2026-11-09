# ADR 0012 — The text Oracle writes into an error carries no values

- Status: accepted (coordinator decision of 2026-11-02, under the maintainer's order to check every driver for values in error texts; core ADR 0075)
- Date: 2026-11-02
- Tags: storage, errors, security, core-adr-0075

## Context

Core ADR 0075 (addendum of 2026-11-02): an error message names keys, columns
and options, never values, passwords or bind contents. The core masks the bound
values of the running statement in the engine's text (`_mask_error_values`,
values of at least four characters), and a driver adds the forms its engine
writes. From 23ai on Oracle writes values into its own text, also when the
value was a bind; older servers do not for the same errors. Measured live
(Oracle 23ai Free, DBD::Oracle 1.95):

| Server text | Value in it |
|---|---|
| `ORA-01722: unable to convert string value containing 'g' to a number` | the first character |
| `ORA-03302: (ORA-01722 details) invalid string value: X` (no quotes; may span lines, up to the `Help:` line or the end) | the value |
| `ORA-03301: (ORA-00001 details) row with column values (ID:1, EMAIL:'X') already exists` | the key values, with column names |
| `ORA-01438: value X greater than specified precision (4, 1) for column` | the value |
| `ORA-61800: invalid boolean literal: X` | the value |
| `ORA-01428: Argument X is out of range.` | the value |

Without a value: ORA-12899 (lengths only), ORA-02290, ORA-02291, ORA-02292,
ORA-01400, ORA-01407, the date and time errors (ORA-01847, 01861, 01867, 01873
and the like), ORA-01465, JSON (ORA-40441), ORA-06502, ORA-24381 (the head; the
single errors in `ArrayTupleStatus` carry the forms above).

## Decision

1. `DBIO::Oracle::Util::mask_error_details($text, \@binds, $statement)` holds
   the form rules: each form above has the value replaced by `***`; the error
   code, the type, the table, the column, the constraint and the position stay.
   Values of any length are caught where the server writes them. A text of no
   known form is returned as it is.
2. The key text of ORA-03301 keeps its column names only where they can be read
   in one way: they are taken from the `columns (...)` list of the error before
   it, and each `, NAME:` must occur once and in that order. Oracle escapes
   nothing, so a value holding `, B:` or `)` could pass for a column; then the
   whole parenthesis becomes `(***)`. A doubt masks more.
3. The `(DBD ERROR: error possibly near <*> indicator at char N in '...')`
   that DBD::Oracle appends holds the statement with `:pN` placeholders, not
   values, and stays; it is told apart from a value by its form (it ends the
   text, the indicator stands at char N, the statement is the one that ran).
   Otherwise it counts as plain text.
4. `DBIO::Oracle::Storage::_mask_error_values` applies the form rules and
   **then** calls `next::method`, which masks the bound values of four
   characters or more as they were written and as the handle quotes them. The
   order matters: the form rules read the key text, which the core's masking
   would break up. The method is on the storage class that `Storage::WhereJoins`
   inherits.
5. Not masked: names of tables, columns and constraints; the literals of the
   statement; texts the application writes itself (`ORA-20000` and up);
   `$dbh->errstr`, which is a DBI attribute and stays raw.

## Consequences

- No other path in this driver carries engine text into an exception: there is
  no async storage and no own `DBIO::Exception::Server`; the handler, the
  statement execution, the connection actions and the populate and bulk
  reports are core's and call the hook, each single `ArrayTupleStatus` text
  separately. `Deploy` masks passwords by its own means and writes only names.
- Limits: a new server sentence that quotes a value is not masked until a rule
  for it is added (or the value is a bind of four characters or more). A bind
  equal to a column or constraint name (four characters or more) is replaced
  there as well. A short value whose own text ends in `\nORA-06512: at line 1`
  can leave that tail behind. Servers before 23ai write no values for these
  errors; the rules then find nothing and leave the text alone.
- Pinned offline in `t/100-error-values-mask.t` with the measured texts, live
  in `t/101-error-values-live.t`.
