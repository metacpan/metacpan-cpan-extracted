# ADR 0053 — The storage-level `*_async` result form is backend-independent

- Status: accepted
- Date: 2026-09-22
- Tags: async, future, storage, immediate, contract, builds-on-0030, refines-0031

## Context

ADR 0030 made async an explicit per-connection mode and rebuilt the six
storage-level `$storage->*_async` methods around a three-way dispatch
(`_run_async` in `lib/DBIO/Storage.pm`): route to the embedded backend on a
live async connection, croak on a sync instance, and — in the `immediate` mode
(a mode is chosen but no event-loop backend exists) — run the ordinary
synchronous op in-process and wrap its return in an immediately-resolved
`future_class`.

ADR 0031 §Decision.3 then fixed the *shape* each backend's `*_async` must
resolve with, so the ResultSet/Row tier can inflate uniformly:

| method | resolves with |
|---|---|
| `select_async` | raw row arrayrefs (the cursor `->all` shape) |
| `select_single_async` | a single raw row arrayref, or `undef` |
| `insert_async` | the returned-columns hashref |
| `update_async` / `delete_async` | the affected-row count |

That table is the *transport form* — the raw form the ORM inflation consumes.
Real `DBIO::Storage::Async` backends honour it (`_run_crud` in
`lib/DBIO/Storage/Async.pm`). ADR 0031 asserted `select_async` /
`select_single_async` "already match the sync cursor shapes", but that was only
true of the real backends. The `immediate` branch of `_run_async` did
`$fc->done($self->$op(@args))` — it passed the *synchronous return* through
unchanged, and for the two reads the synchronous return is **not** the transport
form:

- `DBIO::Storage::DBI::select` returns a **cursor object**, so `immediate`
  `select_async(...)->get` resolved with a `FakeCursor` / `DBIO::Cursor`, whereas
  a real backend resolves with a **list of raw row arrayrefs**.
- `DBIO::Storage::DBI::select_single` returns a **flat list** of column values
  `(7, 'seven')`, whereas a real backend resolves with a **single arrayref**
  `[7, 'seven']` (or `undef`).

So the direct storage-level `select_async` / `select_single_async` contract was
**not substitutable** between `immediate` and a real backend — the exact API a
user writing portable async code against the storage facade
(`$schema->storage->select_async(...)`, see `lib/DBIO/Manual/AsyncStorage.pod`)
depends on. The gap stayed latent because the ResultSet/Row tier never exercised
it: `_rs_run_async` (`lib/DBIO/ResultSet.pm`) routes to `$backend->select_async`
only when a live backend or a bound pinned context exists; in `immediate` mode it
takes its own synchronous fallback (`$sync_run`, e.g. `$self->all`) and never
touches the storage-level `select_async`. ORM parity therefore masked the
storage-level divergence rather than depending on it.

`insert`/`update`/`delete` were checked and are **not** affected: the sync
returns already are the transport form (returned-columns hashref, affected-row
count), so they pass through `immediate` unchanged and match a real backend by
construction.

## Decision

The value a storage-level `*_async` method resolves with is
**backend-independent**: it is the transport form of ADR 0031 §Decision.3, the
same across every async mode including `immediate`. `immediate` is a faithful
stand-in of a real backend at the storage level; it must not leak the synchronous
method's convenience return shape.

`_run_async` (`lib/DBIO/Storage.pm`) routes the `immediate` branch through a new
`_run_immediate($op, @args)` helper that runs the synchronous op in-process and
shapes its result to the canonical transport form:

- `select` → `$self->select(@args)->all` — the list of raw row arrayrefs a
  cursor's `->all` yields;
- `select_single` → `my @row = $self->select_single(@args); @row ? [ @row ] : undef`
  — a single arrayref, or `undef` when there is no row;
- every other op (`insert`, `update`, `delete`, `txn_do`) → the
  synchronous return unchanged, because it already is the transport form.
  (`txn_do` has since left this list — see the addendum of 2026-10-04.)

This mirrors the reference delegating backend in `t/resultset/async_backend.t`
(`My::Mock::RowBackend`) by construction: that backend produces the transport
form by delegating the same two reads to the sync storage
(`$self->_sync->select(@args)->all`, `$self->_sync->select_single(@args)` then
`[ @row ]`), which is now exactly what `immediate` does.

## Consequences

- `$storage->select_async(...)->get` and `$storage->select_single_async(...)->get`
  return the same form in `immediate` mode as against any real backend — raw row
  arrayrefs and a single arrayref (or `undef`). Portable async code written
  against the storage facade behaves identically across modes.
- The change is confined to `_run_async` / the new `_run_immediate` in
  `lib/DBIO/Storage.pm`. No `@ISA` change, no capability, no driver touch.
- ResultSet/Row ORM parity is unchanged: `immediate` at the RS tier still runs
  its own synchronous fallback and never routed through the storage-level
  `select_async`, so nothing at that tier moved. Verified green.
- New offline regression `t/test/33_async_immediate_select_contract.t` pins the
  property by comparing `immediate` against a fake-real delegating backend on
  identical mock rows, and by asserting the concrete raw-arrayref structure (so a
  regression to a cursor or a flat list cannot pass by merely matching a
  same-shaped real backend). RED before the fix, GREEN after.

## Scope boundary — the confirmed incompatibility only

Only the two direct storage-level read methods were confirmed incompatible and
are addressed here. `insert`/`update`/`delete` already matched (above). The
ResultSet tier was deliberately not touched — it is insulated by its own
`immediate` fallback.

## `txn_do_async` — audited, incompatible, deferred to its own ticket

The same audit found `txn_do_async` (`lib/DBIO/Storage.pm`, real form in
`DBIO::Storage::Async::txn_do_async` / `_txn_terminal_chain`) is **also**
incompatible between `immediate` and a real backend, along two axes a repro
confirmed:

1. **Callback signature.** A real backend calls `$coderef->($txn_ctx, @args)` —
   the coderef's first argument is a `DBIO::Storage::Async::TransactionContext`
   pinned to the transaction connection. `immediate` runs the synchronous
   `txn_do($coderef, @args)`, which (via `DBIO::Storage::BlockRunner`) calls
   `$coderef->(@args)` — **no context object**. The documented portable pattern
   `sub { my ($ctx) = @_; $ctx->insert_async(...) }` therefore dies in `immediate`
   mode ("Can't call method \"insert_async\" on an undefined value").
2. **Returned-Future adoption.** A real backend's `_txn_terminal_chain` adopts a
   Future returned by the coderef (sequences into it). `immediate` does not: a
   returned inner Future is wrapped as the resolved *value*, so `->get` yields the
   Future object rather than its resolved value.

This is a distinct contract decision from the read-result form above: it concerns
the callback's *input* (what context it is handed) and *return adoption*, not the
resolved read shape. A correct fix must choose the `immediate` context object
(the storage itself is the natural candidate, since `$self->*_async` runs
in-process there) **and** flatten a returned Future — a larger, separable design
that warrants its own ADR. It is therefore **reported, not changed here**, and
filed as a follow-up karr ticket (below).

## Future architecture work (tracked, not here)

- **`txn_do_async` callback parity (karr k207, core).** Make `immediate`
  `txn_do_async` hand its coderef a context object and adopt a returned Future,
  so the documented `sub { my ($ctx) = @_; $ctx->*_async(...) }` pattern is
  substitutable across modes. Repro and analysis above. Closed by ADR 0055 —
  see the addendum of 2026-10-04.

## Relationship to other ADRs

- **ADR 0030** — established the `immediate` mode and the storage-level
  three-way dispatch this refines.
- **ADR 0031** — fixed the per-backend resolution-shape contract (§Decision.3);
  this ADR makes the `immediate` mode honour that same contract at the storage
  level, which 0031's "already match" wording had assumed without covering the
  `immediate` pass-through.

## Addendum 2026-10-04 — the `txn_do_async` gap is closed by ADR 0055 (karr k207)

The follow-up this ADR deferred landed as ADR 0055. `_run_immediate` no longer
passes `txn_do` through unchanged: it routes it to `_run_immediate_txn`
(`lib/DBIO/Storage.pm`), which hands the coderef a context — the storage
itself — and adopts a Future the coderef returns. `insert`, `update` and
`delete` still pass through as the Decision says.
