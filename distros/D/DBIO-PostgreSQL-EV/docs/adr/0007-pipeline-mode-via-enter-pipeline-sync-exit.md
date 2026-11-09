# ADR 0007 — Pipeline mode via enter_pipeline / pipeline_sync / exit_pipeline

- Status: accepted
- Date: 2026-06-21
- Tags: async, pipeline, ev-pg, performance, drivers
- Re-homed: the generic bracketing decision now lives in `dbio-async`
  ADR 0003 (this ADR is its origin); the scaffold itself is core's
  (`DBIO::Storage::Async::pipeline`), and this driver supplies only the three
  seams.

## Amendment (2026-08-05, karr k27) — the batch coderef receives a pinned context, not the storage

One sentence in *Run the batch* below was never true: that the `*_async` calls
the caller issues inside the block "queue onto the pipelined connection".
Nothing made it true. The scaffold called `$coderef->($self)` and set no pinned
state, so an in-block call went through the pooled seam (`_query_async` →
`pool->acquire`), took a **different** connection and ran outside the bracket —
unbatched, and at `pool_size => 1` only after `_pipeline_exit`. The statements
still executed; the only symptom was that the round trips this ADR exists to
save were still paid.

Core fixed that structurally (dbio-async karr k7/k6, amended into `dbio-async`
ADR 0003, core `DBIO` >= 0.900004): `pipeline()` now builds a
`DBIO::Storage::Async::PipelineContext` around the bracketed connection and
hands **that** to the coderef. Its CRUD methods route through
`_run_crud_pinned` → `_query_async_pinned`, i.e. through the pinned seam this
driver already implements for transactions — and `query_params` on a connection
in libpq pipeline mode is exactly what queues a statement. See ADR 0003 for the
mechanism and for what the bracket does *not* guarantee (storage-level and
ResultSet-level calls inside the block are not batched; a query chained onto an
in-batch Future fires after the sync).

**No code change in this driver.** `_pipeline_enter` / `_pipeline_sync` /
`_pipeline_exit` are unchanged and correct; the driver must not record the
bracketed connection or make `_query_async` consult pipeline state (core no
longer routes in-batch queries through the pooled seam at all). The one
obligation this puts on the driver, previously unwritten: `_pipeline_sync` must
not resolve before the individual batched result Futures have been read off the
connection, because the scaffold exits pipeline mode and returns the connection
to the pool in that Future's completion. Ours resolves when EV::Pg acks the
libpq sync point.

The line references below point at the pre-thin-transport `Storage.pm` that
still carried its own `pipeline()`; the bracketing lifecycle they describe is
now core's, unchanged in shape.

## Context

The whole reason this driver bypasses DBI and speaks libpq directly is
round-trip economy. Even with async, the default request/response loop pays one
network round-trip per query: the client sends a statement and waits for its
result before sending the next. libpq's *pipeline mode* removes that wait — the
client streams many statements without blocking on each result, then collects all
the results in one synchronisation, collapsing N round-trips into one. EV::Pg
exposes the libpq pipeline primitives (`enter_pipeline`, `pipeline_sync`,
`exit_pipeline`), and the driver needs to wrap them in something a caller can use
without managing pipeline state by hand.

## Decision

Expose pipeline batching through a single `pipeline(\&coderef)` method that brackets
the user's batch with EV::Pg's three pipeline primitives on one pooled connection
(`Storage.pm:447-476`).

- **Enter.** Acquire a pooled connection and put it into pipeline mode:
  `$pg->enter_pipeline` (`Storage.pm:450-451`).
- **Run the batch.** Invoke the user coderef with a batch context pinned to the
  bracketed connection (see the amendment above; originally: with the storage
  itself, `Storage.pm:453`). The calls the caller makes on that context queue
  onto the pipelined connection, and the caller is expected to hand back an
  aggregate Future (e.g. `Future->needs_all(@futures)`).
- **Sync.** Drive the pipeline to completion with
  `$pg->pipeline_sync(\&on_complete)` (`Storage.pm:464`); the callback fires once
  all batched results are in.
- **Exit + release, exactly once, in the sync callback.** On completion call
  `$pg->exit_pipeline` and release the connection (`Storage.pm:465-466`), then
  resolve the outer Future from the batch's aggregate result
  (`Storage.pm:467-472`).
- **Fail-safe on a synchronous throw.** If the coderef throws before sync, exit
  pipeline mode, release the connection, and fail immediately
  (`Storage.pm:456-460`) — the connection is never left in pipeline mode.

## Rationale

Pipeline mode is the single biggest throughput lever EV::Pg offers, and it is
inherently stateful: a connection is either in pipeline mode or not, entering and
exiting must be balanced, and `pipeline_sync` is what flushes and gathers the
batch. Wrapping `enter` / `pipeline_sync` / `exit` in one bracketing method makes
that lifecycle impossible for the caller to get half-right — they hand in a batch
coderef and get a Future back; the entering, syncing, exiting and releasing are
handled around them. Pinning the batch to one acquired connection is required
(pipeline state is per-connection), and releasing it only inside the sync callback
guarantees the connection is never returned to the pool while still mid-pipeline.
The synchronous-throw branch exists so a die in the batch builder cannot strand a
connection stuck in pipeline mode.

This is shipped, hence **accepted**, not proposed.

## Consequences

- Many queries issued **on the batch context** inside the `pipeline` coderef
  (see the amendment) are sent without per-query round-trip waits and their
  results gathered in one sync — the intended throughput win over issuing the
  same `*_async` calls outside a pipeline.
- One connection is held out of the pool for the whole batch and released exactly
  once, in the `pipeline_sync` callback (`Storage.pm:465-466`) — or, on a
  synchronous throw, in the error branch (`Storage.pm:456-460`). Both paths must
  keep calling `exit_pipeline` before release, or a connection re-enters the pool
  still in pipeline mode and poisons the next user.
- The caller is responsible for returning an aggregate Future from the coderef so
  the outer Future resolves with the batch's combined result; a plain value is
  also accepted and passed straight through (`Storage.pm:467-472`).
- Pipeline support is an *optional* capability in the core async contract
  (ADR 0014 lists `pipeline` among the optional ops a driver may implement or
  decline); this driver implements it. The decision builds on that contract and
  does not restate the optional-capability framing.
