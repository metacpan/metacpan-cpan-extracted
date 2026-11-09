# ADR 0009 — No explicit pipeline mode: EV::MariaDB has none to bracket, so the capability is declined

- Status: accepted
- Date: 2026-08-05
- Tags: async, pipeline, ev-mariadb, capability, drivers
- Supersedes: [ADR 0005](0005-pipeline-mode-via-autocommit-bracketing.md)
- Corrected: what a refused `pipeline()` call does — the text below says it
  croaks from inside core's scaffold; it returns a failed Future naming this
  transport, before anything is touched (see the Addendum); the decision itself
  stands

## Addendum (2026-10-04, karr k52) — a refused `pipeline()` is a failed Future naming the transport

The decision stands, unchanged: this transport overrides none of
`_pipeline_enter` / `_pipeline_sync` / `_pipeline_exit`, defines no `pipeline()`
of its own and does not declare the `pipeline` capability. What changed is
core's answer to the call (core k218), and with it three statements below. They
are left as written; this is how to read them.

- **Decision — "reaches core's scaffold and croaks (`Subclass must override
  _pipeline_enter`)"**, and Context — "the scaffold croaks on the first seam it
  touches". The call no longer reaches the scaffold. `DBIO::Storage::Async::pipeline`
  asks `_pipeline_refusal` first, and for a transport that does not override
  `_pipeline_enter` that is a failed Future carrying a `DBIO::Exception`:
  `DBIO::MySQL::EV::Storage does not support pipeline() (no _pipeline_enter):
  this async transport cannot batch statements. …`. Nothing is thrown; the
  Future is the transport's `future_class`, already failed when it is returned;
  the batch coderef never runs.
- **Consequences — "a refused `pipeline()` call also loses that connection"**
  (core k146). It takes none: the refusal is decided before `pool->acquire`.
- **`$ctx->pipeline` on a transaction context** is refused the same way, by the
  same `_pipeline_refusal`, before core's `_pipeline_on_conn` is entered: no
  second connection is taken, and the transaction's connection is neither used
  nor released for it.

What declines the call is the **seam**, not the capability name:
`_pipeline_refusal` compares the resolved `_pipeline_enter` with core's stub
and does not read `transport_capabilities`. The undeclared `pipeline` name is
what an async layer's `required_transport_capabilities` is checked against at
compose time. The last Consequence — implement the three seams, add `pipeline`
to `transport_capabilities` — therefore still names both steps, for two
different readers.

One more sentence of the Context has moved on without touching this decision:
`transport_capabilities` is `on_connect_replay`, `listen`, `notify` and
`broker_connect_options` (ADR 0010, ADR 0006 addendum k59) — still not
`pipeline`, and not `copy`.

`t/35-pipeline-refusal-mock.t` holds the answer for `$storage->pipeline`,
`t/txn-context-pipeline-mock.t` for `$ctx->pipeline`,
`t/06-thin-transport-structure.t` the capability list.

## Context

Core exposes pipeline batching as a generic bracketing method,
`DBIO::Storage::Async::pipeline(\&batch)`, over three transport seams:
`_pipeline_enter($conn)` / `_pipeline_sync($conn)` / `_pipeline_exit($conn)`
(dbio-async ADR 0003, core ADR 0014's optional-capability list). A transport
whose client library has the primitives fills the seams and declares the
`pipeline` transport capability; one that does not overrides nothing — the
scaffold croaks on the first seam it touches. Declining is the documented
default, not a gap.

EV::MariaDB has no such primitives. It has no `enter_pipeline` /
`pipeline_sync` / `exit_pipeline` equivalent, and no other API that brackets a
batch and gives back one synchronisation point. What it does have is automatic
wire-level batching of consecutive queries issued on the same connection (up to
64 in flight) — behaviour of the client, with nothing for a caller to open or
close.

ADR 0005 nevertheless shipped a `pipeline()` on this driver, built out of what
MariaDB *does* offer: `SET autocommit=0` → run the batch → `COMMIT` →
`SET autocommit=1`, on one pooled connection. The thin-transport refactor
(karr k19 / k18, core k70 / core ADR 0032, commits 3f975ef and c35eab8) removed
every locally duplicated piece of Model-B machinery from this storage;
`pipeline()` went with it and was deliberately not re-implemented against the
core seams. `t/06-thin-transport-structure.t` asserts both halves of that: the
method is not defined in this class, and `transport_capabilities` is
`on_connect_replay` only.

## Decision

This transport implements **no** pipeline mode. It overrides none of
`_pipeline_enter` / `_pipeline_sync` / `_pipeline_exit`, defines no
`pipeline()` of its own, and does not declare the `pipeline` transport
capability. `$storage->pipeline(...)` therefore reaches core's scaffold and
croaks (`Subclass must override _pipeline_enter`) instead of pretending.

ADR 0005's autocommit bracket is not resurrected, because it was not a
pipeline. It was a transaction: the "flush and gather" it attributed to
`COMMIT` is the MariaDB client's automatic batching, which happens with or
without the bracket, while the bracket's actual effect was to give the batch
transactional semantics — ADR 0005 says so itself, listing rollback-the-whole-
batch as a divergence from the PostgreSQL pipeline. Core already brackets a
transaction on a pinned connection (`txn_do_async`, ADR 0002), so keeping the
method would mean a second name for `txn_do_async` sitting under a name that
promises round-trip economy it does not deliver — the same class of silent
false promise that dbio-async karr k7 had to unwind on the PostgreSQL side.

Callers batch here by issuing several `*_async` calls without awaiting between
them and gathering with `Future->needs_all(...)`; each runs on its own pooled
connection, so the statements overlap on the wire without a single
synchronisation point. Callers who want atomicity ask for it explicitly, with
`txn_do_async`.

## Consequences

- `pipeline()` remains inherited public API that can only fail on this
  transport. That is the family-wide shape for a declined optional capability
  (core ADR 0014), and it is now documented in the README, in
  `DBIO::MySQL::EV`'s POD, in `DBIO::MySQL::EV::Storage`'s
  `transport_capabilities` POD, and here — rather than discoverable only by
  calling it.
- Core's scaffold acquires a pool connection *before* it touches the croaking
  seam, so today a refused `pipeline()` call also loses that connection. That
  is core's to fix (core karr k146); it is a reason to keep the method
  documented as unavailable, not a reason to implement it here.
- An async extension layer that declares `pipeline` in
  `required_transport_capabilities` is refused at compose time, naming this
  transport and the missing capability (core ADR 0032 §5) — never silently
  composed with the feature dropped.
- Nothing about this is permanent. If EV::MariaDB ever grows real pipeline
  primitives, lighting the capability is: implement the three seams, add
  `pipeline` to `transport_capabilities`. Note for whoever does it — core
  hands the batch coderef a `DBIO::Storage::Async::PipelineContext` pinned to
  the bracketed connection, not the storage (core `DBIO` >= 0.900004,
  dbio-async ADR 0003 amendment), and the seam obligation is that
  `_pipeline_sync` must not resolve before the batched result Futures have been
  read off the connection.
- Porting note for callers coming from `DBIO::PostgreSQL::EV`: that driver's
  `pipeline()` works, but a ResultSet-level call (`$rs->create_async`) inside
  the block is not batched there either — batching goes through the handed
  context's own CRUD methods.
