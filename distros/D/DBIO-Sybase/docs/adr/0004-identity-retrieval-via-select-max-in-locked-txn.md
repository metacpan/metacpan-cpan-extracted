# ADR 0004 — Retrieve ASE identity with SELECT MAX(col) under a transaction

- Status: accepted
- Date: 2026-06-20
- Tags: storage, ase, identity, autoincrement, correctness

## Context

After an `INSERT` into a table with an `IDENTITY` column, DBIO must return the
generated value (`last_insert_id`). Most engines expose a cheap, scope-safe
primitive: PostgreSQL has `RETURNING`, SQLite/MySQL have a per-connection
`last_insert_rowid`/`LAST_INSERT_ID()`, MSSQL has `SCOPE_IDENTITY()`.

Sybase ASE has **no single-statement, scope-safe equivalent**. `@@IDENTITY`
exists but is last-statement-on-the-connection, not last-statement-in-scope, so
a trigger that inserts elsewhere corrupts it. ASE's safe answer is to read the
value back, which is what `Storage::ASE::IdentityRetrieval` does:

```
SELECT MAX(<identity_col>) FROM <table>
```

appended to the insert SQL (`_prep_for_execute` → `_fetch_identity_sql`) and
captured in `_execute` into `_identity`, which `last_insert_id` returns. This
"dumb last insert id" path is taken whenever an identity must be retrieved and
`_identity_method` is not `@@IDENTITY`.

## Decision

Keep `SELECT MAX(col)` as the identity-retrieval mechanism, and keep it gated
behind the writer-storage transaction (ADR 0002) whenever the insert is not
already inside a transaction.

## Rationale

`SELECT MAX(col)` is only correct if no *other* row can be inserted between our
`INSERT` and our `SELECT MAX`. That is exactly why `Storage::ASE::insert`
routes a bare identity insert through `_writer_storage->txn_scope_guard`: the
insert and the max-read run atomically on a connection nobody else is using
(ADR 0002), so the maximum we read is the value we just generated. Without the
dedicated transaction this would be a race; with it, it is correct for the
single-row case.

`@@IDENTITY` is deliberately *not* the default: it is connection-global and
trigger-unsafe. It is only honoured when a caller has explicitly set
`_identity_method`.

## Consequences

- This is a **documented compromise, not a bug** — do not "fix" it by switching
  to `@@IDENTITY` for speed; that reintroduces the trigger-unsafety this avoids.
- The bulk path inherits a sharper caveat: when back-filling identities for
  blob columns after a multi-row insert, `BulkInsert` computes the range as
  `(max - rowcount + 1 .. max)` and carries an explicit
  `XXX This assumes identities always increase by 1` comment. That assumption
  can break with non-unit identity increments; any change to ASE identity
  handling must revisit that arithmetic.
- The retrieval depends on the row still being the maximum at read time, which
  the writer-storage transaction guarantees for the row just inserted. Multi-row
  bulk inserts rely on the same transaction boundary.
- Coverage is live-DB only (`t/20-sybase-core.t`); there is no offline test for
  the identity round-trip.
