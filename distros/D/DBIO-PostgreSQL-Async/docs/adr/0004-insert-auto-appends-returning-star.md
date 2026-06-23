# ADR 0004 — INSERT auto-appends `RETURNING *`

- Status: accepted
- Date: 2026-06-21
- Tags: async, insert, returning, dml, drivers

## Context

DBIO's higher layers expect an `insert` to give back the row as actually stored,
including server-assigned values — serial/identity primary keys, column defaults,
trigger-populated fields. On a DBI-based synchronous driver this is solved with
`last_insert_id` round-trips and `RETURNING` handling in the storage's insert
path. The async driver speaks libpq directly and returns rows straight from the
query result: whatever the `INSERT` statement returns is what resolves on the
Future. An `INSERT` without a `RETURNING` clause returns no rows, so the async
`insert` would resolve empty and the caller would never see the generated key or
defaulted columns.

## Decision

After generating the `INSERT` SQL via the SQLMaker, `insert_async` appends
`RETURNING *` unless the statement already contains a `RETURNING` clause
(`Storage.pm:249-252`):

    my ($sql, @bind) = $self->sql_maker->insert($source, $to_insert);
    $sql .= ' RETURNING *' unless $sql =~ /RETURNING/i;

The append is guarded by a case-insensitive `RETURNING` match, so a statement
that already specifies a tailored `RETURNING` list is left untouched and not
double-clausing. The synchronous `insert` inherits this behaviour for free, since
it is `insert_async(...)->get` (ADR 0001).

## Rationale

PostgreSQL's `RETURNING` is the native, single-round-trip way to get the stored
row back; appending `RETURNING *` makes the async `insert` resolve with the
complete persisted row — generated keys, defaults and all — which is exactly what
the layers above an `insert` expect and what the sync DBI drivers reconstruct by
other means. Doing it in one statement is also the fastest option: no separate
`last_insert_id` query, no second round-trip, which matters most for the async
driver whose whole reason to exist is round-trip economy. The `unless /RETURNING/i`
guard keeps the convenience from fighting an explicit caller who already asked for
a specific `RETURNING` projection.

This is shipped and integration-tested, hence **accepted**, not proposed.

## Consequences

- `insert_async` (and therefore sync `insert`) resolves with the full inserted
  row by default, including server-generated columns, in a single round-trip.
- The guard is a textual `/RETURNING/i` match on the generated SQL, not a parse.
  An expression elsewhere in the statement that contained the substring
  "returning" would suppress the auto-append; in practice SQLMaker-generated
  `INSERT`s do not, but a future change to insert SQL generation that could emit
  that substring must keep this in mind.
- `RETURNING *` returns every column. Callers wanting a narrower projection must
  supply their own `RETURNING` clause (which the guard then respects); there is no
  column-list trimming here.
- This is a deliberate divergence from a vanilla DML insert path and from the
  generic base async storage: a driver author copying this driver as a template
  must keep the `RETURNING` append, or async inserts will resolve empty.
