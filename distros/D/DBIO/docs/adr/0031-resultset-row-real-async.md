# ADR 0031 — ResultSet/Row `*_async` route through the storage backend (real async)

- Status: accepted
- Date: 2026-06-30
- Tags: async, future, storage, resultset, row, prefetch, collapse, builds-on-0030

## Context

ADR 0030 made async an explicit per-connection mode and rebuilt the six
*storage-level* `$storage->*_async` around it (route to the embedded backend,
degrade in `immediate`, croak on a sync instance). It deliberately left the
*ResultSet/Row* `*_async` (`all_async`/`first_async`/`single_async`/`count_async`/
`create_async`) untouched — they still ran the sync op and wrapped it in
`future_class`. That left a real asymmetry: `$storage->select_async` croaked on a
sync instance and did real async on a backend, but `$rs->all_async` did neither —
it silently degraded even on a live async backend, so the chosen backend was never
actually exercised by the ResultSet API (the API users actually call).

This ADR closes that gap: the ResultSet/Row async methods must be genuinely
non-blocking on a real backend, with **full parity** to their synchronous
counterparts (prefetch, collapse, count adjustment, insert column store-back).

## Decision

### 1. RS/Row `*_async` route through the storage backend and inflate in `then`

`all_async`/`first_async`/`single_async`/`count_async` (`DBIO::ResultSet`) and
`insert_async` (`DBIO::Row`, with `create_async` = `new_result->insert_async`)
mirror the storage-level `_run_async` three-way contract one tier up, via shared
helpers `_rs_run_async` / `_row_run_async`:

- **live embedded backend** → issue the read/write through the storage's `*_async`
  op and inflate the raw result in the Future's `then` (real async);
- **`immediate` mode** → run the ordinary sync method, wrap the result in an
  immediately-resolved Future via `future_class`;
- **sync instance (no mode)** → croak (`"not an async connection -- connect with
  { async => ... } to use <name>_async"`).

### 2. Inflation/collapse parity by reusing the sync path, not duplicating it

`_construct_results('fetch_all')` does exactly one cursor read (`$self->cursor->all`)
to slurp the raw rows, then runs the whole collapser/inflator over that in-memory
array. So the async path reuses it verbatim: `_inflate_fetched_rows(\@raw)`
`local`-injects a `DBIO::ResultSet::_PrefetchedCursor` (whose `->all` returns the
already-fetched rows) and calls `_construct_results('fetch_all')` unchanged.
Prefetch/collapse therefore go through the identical code path as sync `all` —
no collapse logic is duplicated. `single_async` reuses the factored-out
`_single_select_args` (shared with `single`); `count_async` reuses
`_count_rs`/`_count_subq_rs` and the same software-side `rows`/`offset`
adjustment; `insert_async` reuses the factored-out `Row::_store_inserted_columns`
(shared with `insert`).

### 3. Backend `*_async` resolution-shape contract (binding on every driver)

For the RS/Row layer to inflate uniformly, each backend's `*_async` must resolve
the **same shape its synchronous counterpart returns**:

| backend method | must resolve with | consumed by |
|---|---|---|
| `select_async` | raw row arrayrefs (cursor `->all` shape) | `_inflate_fetched_rows` → `_construct_results` |
| `select_single_async` | a single raw row arrayref | `single_async` / `count_async` |
| `insert_async($rsrc, \%rowdata)` | the **returned-columns hashref** (autoinc PK + retrieve-on-insert cols), exactly what sync `$storage->insert` returns | `_store_inserted_columns` |

`select_async`/`select_single_async` already match the sync cursor shapes. The
`insert_async` **hashref** shape is the one that needs enforcing: at least
`dbio-postgresql-ev` currently resolves `insert_async` with RETURNING arrayref
rows, which `create_async`/`Row::insert_async` cannot consume. Drivers must align
— tracked as a cross-repo karr ticket (below).

### 4. `then` callbacks may return plain values (auto-wrap)

All RS/Row `then` callbacks return plain values, not Futures. The default family
behaviour (`DBIO::Future::Immediate->then` and the real backends) auto-wraps a plain
return into a resolved Future. `DBIO::Future`'s POD — which said a `then` callback
"must return a new Future" — is corrected to state that a plain value is accepted
and wrapped. This is a binding part of the `DBIO::Future` duck-type: every backend
Future's `then` must auto-wrap plain returns, or these callbacks break on it.

## Consequences

- Storage-level and ResultSet/Row async are now consistent: both croak on a sync
  instance, both do real async on a backend, both degrade under `immediate`.
- `DBIO::ResultSet` gains `_rs_run_async`, `_inflate_fetched_rows`,
  `_single_select_args`, and the small `_PrefetchedCursor` package; the five RS
  `*_async` are rewritten. `DBIO::Row` gains `insert_async`, `_row_run_async`, and
  the factored-out `_store_inserted_columns` (sync `insert` unchanged in
  behaviour). Mock-tested in `t/resultset/async_backend.t` (a registered mock
  backend that delegates row production to sync `DBIO::Test::Storage`, so
  async↔sync parity is exercised by construction, including a prefetch/collapse
  case).
- **Deferred, documented in-method:**
  - *Async multi-create.* `create_async`/`insert_async` for a row with a
    related-object multi-create cascade (pre/post-insert + txn guard) runs the
    synchronous `Row::insert` and resolves immediately; a recursive async cascade
    over an async transaction is a larger surface, deferred.
  - *`first_async` over-fetch.* The backend path fetches and collapses the full
    result set (the only collapse-correct way to get the first object under a
    prefetch); identical result to sync `first`, but not lazier. An early-stop
    needs async cursor iteration, which does not exist yet.
  - *Row-level `update_async`/`delete_async`.* Not added (no caller); only
    `Row::insert_async` was needed (by `create_async`). Same pattern when wanted.
- No event-loop dependency added to core; all of it is mock-tested with no real DB.

## Future architecture work (tracked cross-repo, not here)

- **Driver `insert_async` shape (karr ticket to `dbio-async` / `dbio-postgresql-ev`
  / `dbio-mysql-ev` / `dbio-forked`).** Each backend's `insert_async` must resolve
  the returned-columns **hashref** (§Decision.3), not a RETURNING arrayref, so
  `create_async`/`Row::insert_async` work on a real backend. `dbio-forked` (which
  runs the sync `insert` in the child) returns the hashref naturally; the
  connection-based backends need to map RETURNING → hashref.
- **`then` auto-wrap conformance.** Verify every backend Future's `then`
  (`DBIO::Forked::Future`, `dbio-async`, EV add-ons) auto-wraps a plain return,
  per §Decision.4.

## Relationship to other ADRs

- **ADR 0030** — this builds directly on it. 0030 made async an explicit
  per-connection mode and did the storage level; 0031 lifts the same model to the
  ResultSet/Row tier and closes 0030's documented storage↔RS asymmetry.
