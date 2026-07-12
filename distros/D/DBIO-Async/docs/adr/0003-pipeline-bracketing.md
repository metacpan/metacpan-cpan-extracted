# ADR 0003 — Pipeline mode as a generic bracketing method over driver seam hooks

- Status: accepted
- Date: 2026-06-28
- Tags: async, pipeline, performance, generic, capability-gated
- Origin: re-homed and generalized from `dbio-postgresql-async` ADR 0007. The
  original framed pipeline around EV::Pg's libpq primitives
  (`enter_pipeline` / `pipeline_sync` / `exit_pipeline`); here the *bracketing
  decision* is generic and those primitives are a **driver-seam example**, not a
  contract.

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
- **Run the batch.** Invoke the user coderef. Inside it the caller issues the
  usual `*_async` calls — which queue onto the pipelined connection — and is
  expected to hand back an aggregate Future (e.g. `Future->needs_all(@futures)`).
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
ticket #21, decision D1).

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

- Many queries issued inside the `pipeline` coderef are sent without per-query
  round-trip waits and their results gathered in one sync — the intended
  throughput win over issuing the same `*_async` calls outside a pipeline, *for
  drivers that supply the seam hooks*.
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
  adds it (tracked in #21, decision D1).
