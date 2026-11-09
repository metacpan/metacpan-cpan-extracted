# ADR 0075 — Error texts carry no bind values

- Status: accepted (coordinator decision of 2026-10-30, karr k386, under the maintainer's order to resolve the security findings before the release); confirmed by the maintainer on 2026-11-02
- Date: 2026-10-30
- Tags: storage, exceptions, bind-values, tracing

## Context

A failed statement is thrown as `DBIO::Exception::Server` through the
`HandleError` handler of the storage. Its text is read by logs, by
applications and, when an application passes it on, by clients. ADR 0025
fixes what the trace shows of a bind value; this ADR fixes what an error text
shows.

## Decision

1. **`ShowErrorStatement` is off on every handle the storage opens**, also
   when connect_info sets it to a true value, and on handles supplied by a
   coderef unless `unsafe` is set.
2. **`_dbi_handle_error` appends the statement itself**:
   `[for Statement "..." with N bind values]`. The statement is the one being
   executed (`_dbh_execute`, `_do_query`, or the statement of the handle);
   `N` is the number of its binds. A value, a fingerprint of a value or a
   mask of a value is never part of the text.
3. **Statements of connect actions stay masked** (karr k343): the statement
   text in the appendix passes `mask_statement_secrets` like the message.
4. **What the caller writes as a literal into the SQL is part of the
   statement text.** Bind values are the way to keep a value out of it.
5. **The text the server writes about the error** (`DBIO::Exception::Server`
   `detail`) is the driver's business.
6. **Exceptions go to logs.** A client is shown a message of the
   application's own.

## Rationale

The number of binds tells what the statement did without carrying what the
caller handed to it; the values are in the caller's hands when they are
needed.

## Consequences

- A test or tool that looks for `with ParamValues` in an error text reads
  `with N bind values` instead.
- `redact_bind_value` (ADR 0025) concerns the trace only; the error text has
  nothing to redact.

## Addendum — the core masks bound values in the text of the engine

- Status: accepted (coordinator decision of 2026-11-02, under the maintainer's order to check every driver for values in error texts)
- Date: 2026-11-02

### Decision

7. **The core masks the bound values of the running statement in the text of
   the engine** with `***` wherever that text becomes part of an exception
   (`_dbi_handle_error`, the populate reports, `_do_query`). A value is masked
   when it has at least 4 characters, in the form it was written and in the
   form the quoting of the connection makes of it.
8. **The hook is `_mask_error_values($text, \@values, $statement)`.** The base
   class masks through `DBIO::Util::mask_bound_values`; a driver overrides
   the method, applies the forms its engine writes (a key value, a converted
   value) and calls `next::method`. The method never connects and never
   throws.
9. **A statement of a storage that interpolates its values (NoBindVars) is
   named in placeholder form** with the number of its values, like every
   other statement.
10. **A populate report names the row (its position in the data, from 1) and
    the column names**, not the values. The same holds for the message of a
    failed inflation: column and class, not the value.
11. **`$dbh->errstr` and `$sth->errstr` keep the raw text of the engine** as
    DBI attributes. What DBIO throws is masked.

### Consequences

- Values shorter than 4 characters stay in the text of the engine; the form
  rules of the drivers catch what the engine writes around them.
- The populate report of ADR 0027 names the failing row by its position and
  its columns; the dump of the row is no longer part of it.

## Addendum — masking comes before the cut of the DBI appendix

- Status: accepted (coordinator decision of 2026-11-02, under the maintainer's order to check every driver for values in error texts)
- Date: 2026-11-02

### Decision

12. **The text of the engine passes through `_mask_error_values` whole, and
    the appendix DBI writes for a handle with ShowErrorStatement is cut off
    afterwards.** A bound value that holds the marker of that appendix is
    masked as one value; the statement and the count that DBIO appends follow.

