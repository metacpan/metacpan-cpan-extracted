# ADR 0003 — Pipeline mode as a generic bracketing method over driver seam hooks

- Status: accepted
- Date: 2026-06-28
- Tags: async, pipeline, performance, generic, capability-gated
- Origin: re-homed and generalized from `dbio-postgresql-async` ADR 0007. The
  original framed pipeline around EV::Pg's libpq primitives
  (`enter_pipeline` / `pipeline_sync` / `exit_pipeline`); here the *bracketing
  decision* is generic and those primitives are a **driver-seam example**, not a
  contract.

## Amendment (2026-08-05, karr k7 / k6) — the scaffold pins the batch; it is no longer a driver's job to remember

The bracketing decision below stands unchanged. What was wrong is the sentence
in *Run the batch* claiming the `*_async` calls inside the block "queue onto the
pipelined connection": **nothing made that true.** The scaffold called
`$coderef->($self)` and set no pinned state, so an in-block call went through
the pooled path (`_query_async` → `pool->acquire`) and took a *different*
connection — running outside the bracket, unbatched, and at `pool_size => 1`
only once the pipeline had released, i.e. strictly after `_pipeline_exit`. The
statements still executed, which is why this failed silently: the only symptom
was that the round trips the batch was written to save were still paid. Pinning
was in truth an unwritten obligation on each driver's `_pipeline_enter` — one no
test could catch a driver for forgetting.

The choice was between writing the obligation down (**a**) and making it
structural (**b**); **(b)** was decided. The reason is the neighbouring ADR:
ADR 0002 already pins a connection for the duration of a transaction through a
context object, and a property that is structural for transactions but advisory
for pipelines — with a silent failure mode, across four drivers — is not a
property. So:

- `pipeline()` builds a **`DBIO::Storage::Async::PipelineContext`** around the
  bracketed connection and hands **that** to the coderef, not the storage. Its
  five CRUD methods route through `_run_crud_pinned` → `_query_async_pinned`
  with that connection, exactly as `TransactionContext` does for the pinned
  transaction connection. `_pipeline_context_class` is the seam for a transport
  that needs a different one. This is core's code
  (`DBIO::Storage::Async`, dist `dbio`), not this dist's.
- **What the bracket now guarantees:** every call made *on the object the block
  is handed* is sent on the one connection that is in pipeline mode. That is the
  whole guarantee, and it is now a property of the scaffold rather than of each
  driver's good behaviour.
- **What it does not guarantee**, stated because the old wording implied
  otherwise:
  - A call made on the **storage** inside the block (rather than on the handed
    context) still goes through the pooled path and is *not* batched. It works —
    which is exactly what made the old bug invisible.
  - Only queries issued during the **synchronous** run of the coderef can be
    batched. One chained onto an in-block Future (`->then(sub { ... })`) fires
    after the sync; the context must not be used for it.
  - The **ResultSet/Row async layer** (`$rs->all_async` and friends) resolves
    its backend from the schema's storage, not from the context, so those calls
    are not batched even inside the block — unless the result set is bound to
    the context. `$rs->with_context($ctx)` (and the mirrors on Row and
    ResultSetColumn) binds the RS layer to the pinned context: `$rs->all_async`
    then runs on the pinned connection and composes with the context, inside
    `pipeline()` and `txn_do_async` alike; the context propagates through
    `search_rs` clones and is inherited by derived rows and result set columns.
    The PipelineContext self-invalidates as soon as the batch coderef returns,
    so a bound result set used *after* the block throws loudly rather than
    silently falling back to the pool — the old "it works, which made the bug
    invisible" failure is closed for the bound path. The unbound path (calling
    on the storage rather than via `with_context`) still goes pooled, as above.
    Batch through the context's own CRUD methods, or bind the result set with
    `with_context`.
  - `pipeline()` called on a `TransactionContext` acquires its own connection,
    so the batch runs **outside** the surrounding transaction.
  - Blocking CRUD (`->select`, `->insert`, …) is deliberately **not** available
    on the batch context: a batched statement resolves at the sync, which runs
    after the coderef returns, so `->get` inside the block would wait on a
    result whose delivery waits on it. It refuses with that reason instead.

**Driver impact: none required.** The pinned query seam every Model-B transport
already implements for transactions (`_query_async_pinned`) is the one the batch
uses; sending on a connection that is in pipeline mode is what queues the
statement, and that is the client library's own behaviour. Two notes for driver
authors:

- A driver that recorded the bracketed connection in `_pipeline_enter` and
  consulted it in `_query_async` can drop that: core no longer routes in-batch
  queries through `_query_async` at all, and a `_query_async` that consults
  pipeline state is now wrong (it would batch a query the caller issued on the
  storage, which the scaffold deliberately does not).
- The one obligation that remains on the driver, previously unwritten (found in
  the same review, karr k6): **`_pipeline_sync` must not resolve before the
  individual batched result Futures have been resolved off the connection.**
  `pipeline()` exits pipeline mode and releases the connection *in that Future's
  completion* and only then hands back the batch's aggregate Future — so a sync
  that resolves early puts the connection back in the pool while results are
  still being read off it.

## Amendment (2026-08-29, k145) — the RS/Row async layer composes with a pinned context

Core changed the seam (k145 / ADR 0045, core commit 7279bfb3, 2026-08-29):
`with_context($ctx)` on `DBIO::ResultSet` / `Row` / `ResultSetColumn` binds the
RS layer to the pinned context, and the PipelineContext self-invalidates once
the batch coderef returns. The ResultSet/Row bullet in the 2026-08-05 amendment
above is updated accordingly; the old "core's to change if it ever should be"
no longer applies — it has changed.

## Amendment (2026-09-05, k14) — there is no sequential degrade, and the bracketing is core's

The bracketing lifecycle and both amendments above stand. Two statements below
them do not.

**"Sequential degrade" never existed, and must not.** The *Decision* ends its
seam-hook paragraph with "a capability-gated croak / sequential degrade", and
the fourth consequence repeats it as "the capability-gated degrade". There is no
sequential path anywhere in the scaffold, and there was none when this was
written. Core's `_pipeline_enter` is a croaking stub;
`DBIO::Storage::Async::pipeline` catches that croak, releases the connection
*without* calling `_pipeline_exit` — nothing was entered — and **fails the
returned Future**. That is not merely what the code happens to do: core ADR 0030
§3 makes it the required behaviour. A silent fall-back to sequential execution
is precisely what "explicit or it croaks" forbids — the caller asked for a
batch, would pay every round trip the batch was written to save, and would get
no signal that it had. Read both places as "capability-gated croak", and the
fourth consequence's "degrade" as "loud refusal".

**The bracketing is core's code.** The *Decision* places `pipeline(\&coderef)`
"on `DBIO::Async::Storage`". Core ADR 0030 §4 lifted it: `pipeline`, the
`_pipeline_context_class` seam and the three croaking stubs
`_pipeline_enter` / `_pipeline_sync` / `_pipeline_exit` all live in
`DBIO::Storage::Async`, and `DBIO::Async::Storage` overrides none of them. The
sentence therefore reads as "on the class a `future_io` adapter inherits from" —
the same re-homing the 2026-09-05 addenda on ADRs 0001 and 0002 record. The one
obligation the 2026-08-05 amendment left on drivers — `_pipeline_sync` must not
resolve before the batched results have been read off the connection — is
unchanged and is still the driver's.

For this transport in particular: `DBIO::Async::Storage` supplies no pipeline
seams and names none in `transport_capabilities`, and neither shipping
`future_io` adapter (`DBIO::PostgreSQL::Storage::Async`,
`DBIO::MySQL::Storage::Async`) supplies them either — so `pipeline()` on
`future_io` refuses. Batching is the `ev` transports' capability (core ADR 0030
§2), not this one's. That is the loud refusal working as designed, not a gap to
be closed by degrading.

## Context

The throughput reason a driver bypasses the sync DBI path is round-trip
economy. Even with async, the default request/response loop pays one network
round-trip per query: the client sends a statement and waits for its result
before sending the next. A database whose client library exposes a *pipeline
mode* removes that wait — the client streams many statements without blocking
on each result, then collects all the results in one synchronisation,
collapsing N round-trips into one. The driver needs to wrap that in something a
caller can use without managing pipeline state by hand, but the concrete
primitives are database-specific (libpq's `enter_pipeline` /
`pipeline_sync` / `exit_pipeline`; other clients have none, or a different
shape).

## Decision

Expose pipeline batching through a single generic `pipeline(\&coderef)` method
on `DBIO::Async::Storage` that brackets the user's batch with three driver-seam
hooks on one pooled connection: `_pipeline_enter($conn)`,
`_pipeline_sync($conn)`, `_pipeline_exit($conn)`.

- **Enter.** Acquire a pooled connection and put it into pipeline mode via
  `_pipeline_enter($conn)`.
- **Run the batch.** Invoke the user coderef with a **batch context pinned to
  the bracketed connection** (see the amendment above). The calls the caller
  makes on that context queue onto the pipelined connection; the caller is
  expected to hand back an aggregate Future (e.g.
  `Future->needs_all(@futures)`).
- **Sync.** Drive the pipeline to completion with `_pipeline_sync($conn)`; the
  sync completion fires once all batched results are in.
- **Exit + release, exactly once, in the sync completion.** On completion call
  `_pipeline_exit($conn)` and release the connection, then resolve the outer
  Future from the batch's aggregate result.
- **Fail-safe on a synchronous throw.** If the coderef throws before sync, exit
  pipeline mode, release the connection, and fail immediately — the connection
  is never left in pipeline mode.

The seam hooks default to a **capability-gated croak / sequential degrade**: a
driver whose client library has no pipeline binding (e.g. DBD::Pg 3.18 has no
libpq pipeline binding) leaves the hooks unimplemented and `pipeline()` either
croaks "pipeline not supported" or degrades to sequential execution. The
capability lights up automatically when a driver supplies the hooks (or when a
future DBD::Pg release adds pipeline support — see the PostgreSQL re-engine
ticket dbio-postgresql k21, decision D1).

## Rationale

Pipeline mode is the single biggest throughput lever a pipelined client offers,
and it is inherently stateful: a connection is either in pipeline mode or not,
entering and exiting must be balanced, and the sync step is what flushes and
gathers the batch. Wrapping enter / sync / exit in one bracketing method makes
that lifecycle impossible for the caller to get half-right — they hand in a
batch coderef and get a Future back; the entering, syncing, exiting and
releasing are handled around them. Pinning the batch to one acquired connection
is required (pipeline state is per-connection), and releasing it only inside the
sync completion guarantees the connection is never returned to the pool while
still mid-pipeline. The synchronous-throw branch exists so a die in the batch
builder cannot strand a connection stuck in pipeline mode.

Putting the concrete primitives behind seam hooks (rather than hard-coding
libpq's names) keeps the skeleton DB-agnostic: the original PostgreSQL
implementation supplies `_pipeline_enter`/`_pipeline_sync`/`_pipeline_exit`
mapping to libpq; a driver whose client has no pipeline support declines
cleanly. The bracketing lifecycle itself — one connection, balanced
enter/exit, release-in-sync — is the generic, reusable decision.

## Consequences

- Many queries issued **on the batch context** inside the `pipeline` coderef
  (see the amendment) are sent without per-query round-trip waits and their
  results gathered in one sync — the intended throughput win over issuing the
  same `*_async` calls outside a pipeline, *for drivers that supply the seam
  hooks*.
- One connection is held out of the pool for the whole batch and released
  exactly once, in the sync completion — or, on a synchronous throw, in the
  error branch. Both paths must keep calling `_pipeline_exit` before release, or
  a connection re-enters the pool still in pipeline mode and poisons the next
  user.
- The caller is responsible for returning an aggregate Future from the coderef
  so the outer Future resolves with the batch's combined result; a plain value
  is also accepted and passed straight through.
- Pipeline support is an *optional capability* in the core async contract
  (ADR 0014 lists `pipeline` among the optional ops a driver may implement or
  decline). A driver that does not override the seam hooks gets the
  capability-gated degrade; one that does gets the bracketing lifecycle for
  free.
- DBD::Pg 3.18 has no libpq pipeline binding, so the PostgreSQL driver's
  `pipeline()` is capability-gated to degrade/croak until a DBD::Pg release
  adds it (tracked in dbio-postgresql k21, decision D1).
