# ADR 0004 — INSERT auto-appends `RETURNING *`

- Status: accepted
- Date: 2026-06-21
- Tags: async, insert, returning, dml, drivers
- Superseded in part: the *place* of the append -- an `insert_async` in this
  dist's `Storage.pm` -- is superseded by core ADR 0030 §4 (see the Amendment);
  the append itself and its guard stand

## Amendment (2026-10-05, karr k69) — the append is core's, this dist declares the suffix

The decision this ADR records is in force and unchanged: an `INSERT` gets
` RETURNING *` appended unless the statement already carries a `RETURNING`
clause, and the sync `insert` has it too, being `insert_async(...)->get`. What
is superseded is *where the append happens*.

With the thin-transport refactor (karr k22, commit `f4c527d`; core ADR 0030 §4)
`insert_async` and the CRUD runner behind it became core's.
`DBIO::Storage::Async::_run_crud` appends what the transport's
`_post_insert_sql` returns, under the same case-insensitive `RETURNING` match,
and `DBIO::PostgreSQL::EV::Storage` declares exactly that suffix:
`_post_insert_sql` returns `' RETURNING *'`. The pooled path and the pinned one
(a transaction's or a pipeline's context) share that one builder, so the append
is the same on both.

Read as superseded, therefore:

- **The two quoted lines are no longer in this dist.** There is no
  `insert_async` in `Storage.pm`, and `Storage.pm:249-252` no longer points at
  an append; the reference is left as written.
- **What `insert_async` resolves with is the returned-columns hashref**, not
  the `RETURNING` row as it comes off the wire (karr k18, core ADR 0031 §3):
  the supplied data overlaid with the first returned row, mapped by core's
  `_insert_returned_columns`. `RETURNING *` is still what supplies the
  server-assigned columns.
- **The append is not a divergence from the base async storage any more, and a
  transport does not keep it by copying it.** It is the base's seam: core's
  `_post_insert_sql` croaks until a transport overrides it, and a transport
  whose engine has no `RETURNING` answers with an empty suffix. The last
  *Consequences* bullet reads accordingly -- what a driver author must keep is
  the declaration, not the append.

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
