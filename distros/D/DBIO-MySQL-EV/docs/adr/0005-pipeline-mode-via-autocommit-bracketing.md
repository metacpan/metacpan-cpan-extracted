# ADR 0005 — Pipeline mode brackets the batch with `SET autocommit=0` / COMMIT / `SET autocommit=1`

- Status: accepted
- Date: 2026-06-21
- Tags: async, pipeline, ev-mariadb, performance, drivers

## Context

The reason this driver bypasses DBI and speaks the MariaDB C client directly is
round-trip economy. Even async, the default request/response loop pays one network
round-trip per query. EV::MariaDB supports *pipelining* — up to 64 queries in
flight in a single round-trip — but, unlike libpq, it exposes no explicit
`enter_pipeline`/`pipeline_sync`/`exit_pipeline` primitives (the mechanism the Pg
sibling wraps in its ADR 0007). On the MariaDB client the batch has to be driven
through transaction/autocommit state instead: queries issued back-to-back inside a
single non-autocommit transaction are pipelined, and the COMMIT is the
synchronisation point that flushes and gathers them.

## Decision

Expose pipeline batching through a single `pipeline(\&coderef)` method that runs the
user's batch on one pooled connection, bracketing it with MariaDB transaction-mode
statements rather than libpq pipeline primitives (`Storage.pm:442-471`).

- **Enter.** Acquire a pooled connection and switch it to explicit transaction
  mode: `$mdb->query('SET autocommit=0')` (`Storage.pm:445-446`), with the inline
  comment "MariaDB pipelining needs explicit tx mode".
- **Run the batch.** Invoke the user coderef (`Storage.pm:448`). Inside it the
  caller issues the usual `*_async` calls — which queue onto the connection — and is
  expected to hand back an aggregate Future (e.g. `Future->needs_all(@futures)`),
  per the method's POD example (`Storage.pm:426-440`).
- **Sync via COMMIT.** Drive the pipeline to completion with
  `$mdb->query('COMMIT', \&on_complete)` (`Storage.pm:459`); the callback fires
  once all batched results are in.
- **Reset, release, resolve — in the COMMIT callback.** On completion issue
  `SET autocommit=1` to restore the connection's default mode, release it, and
  resolve the outer Future from the batch's aggregate result
  (`Storage.pm:460-468`).
- **Fail-safe on a synchronous throw.** If the coderef throws before COMMIT, issue
  `ROLLBACK`, release the connection, and fail immediately (`Storage.pm:451-455`).

## Rationale

EV::MariaDB does not give the caller libpq-style explicit pipeline primitives, so
the batch is expressed in the terms the MariaDB client *does* offer: a single
non-autocommit transaction whose COMMIT is the flush/gather point. Wrapping
`SET autocommit=0` / the batch / `COMMIT` / `SET autocommit=1` in one bracketing
method makes that lifecycle impossible for the caller to get half-right — they hand
in a batch coderef and get a Future back; entering tx mode, committing, restoring
autocommit and releasing are handled around them. Pinning the batch to one acquired
connection is required (pipeline/transaction state is per-connection), and doing the
`SET autocommit=1` reset *before* release guarantees the connection never re-enters
the pool stuck in non-autocommit mode, which would silently change the transaction
semantics of the next unrelated caller. The synchronous-throw branch rolls back and
restores so a die in the batch builder cannot strand a connection mid-transaction.

This is the MySQL counterpart of the Pg sibling's pipeline ADR (its ADR 0007): same
goal — collapse N round-trips into one on a pinned connection, exactly once — but a
genuinely different mechanism, because the underlying client offers a different
batching primitive. The decision is owned here; the Pg ADR is referenced only to
mark the divergence, not to share mechanism.

This is shipped, hence **accepted**, not proposed.

## Consequences

- Queries issued inside the `pipeline` coderef are batched within one
  non-autocommit transaction and gathered at COMMIT — the intended throughput win
  over issuing the same `*_async` calls outside a pipeline. EV::MariaDB caps
  in-flight queries at 64.
- One connection is held out of the pool for the whole batch and released exactly
  once, in the COMMIT callback (`Storage.pm:461`) — or, on a synchronous throw, in
  the ROLLBACK branch (`Storage.pm:452-453`). Both paths must restore
  `autocommit=1` before release, or a connection re-enters the pool in
  non-autocommit mode and changes the next user's transaction behaviour.
- Because the batch *is* a transaction (autocommit off until COMMIT), `pipeline`
  has transactional semantics as a side effect of the batching mechanism — a
  failure mid-batch rolls the whole batch back. This differs from the Pg pipeline,
  whose batching is not inherently a transaction; callers porting between the two
  drivers must not assume identical atomicity.
- The caller is responsible for returning an aggregate Future from the coderef so
  the outer Future resolves with the batch's combined result; a plain value is also
  accepted and passed straight through (`Storage.pm:462-467`).
