# ADR 0045 — ResultSet/Row/ResultSetColumn async binds to a pinned context, explicitly

- Status: accepted — error precedence of a failed ROLLBACK (§7) superseded by [ADR 0055](0055-immediate-txn-do-async-callback-context-and-future-adoption.md) (addendum 2026-09-27)
- Date: 2026-08-29
- Tags: async, resultset, transactions, pipeline, driver-contract

> Accepted by maintainer decision in karr k145 (2026-08-28, option b — explicit
> context, no ambient state). Successor to ADR 0030 (async as an explicit
> per-connection mode) and ADR 0031 (ResultSet/Row real async). Generation-scoped
> ownership was added by karr k196 on 2026-09-15. Propagation to the remaining
> relationship, prefetch and cache derivations was completed by karr k195 on
> 2026-09-21. The cache-then-bind grandchild edge k195 left flat was deepened by
> karr k203 on 2026-09-22 (`Row::with_context` cascades the pin through cached
> prefetched children by clone-and-rebind, non-mutating). The derivations that
> build a fresh resultset — set operations, `bare`, `correlate`, `count_rs` —
> followed with karr k281 on 2026-10-07 (addendum). What a bound row and a
> directly bound column hand out followed with karr k325 on 2026-10-08
> (addendum). The `immediate` mode's context and the single-statement rule for
> `insert_async` followed with karr k282 on 2026-10-08 (addendum). The
> overrides of `insert` / `update` / `delete` that the `*_async` methods
> bypassed, and the `prepare_*` hooks, followed with karr k331 on 2026-10-09
> (addendum). Set operations over operands bound differently — left open by
> k281 — are refused, by maintainer decision in karr k324 on 2026-10-10
> (addendum).

## Context

ADR 0031 gave `DBIO::ResultSet`, `DBIO::Row` and `DBIO::ResultSetColumn` real
`*_async` methods. Each resolves its backend the same way, in
`_rs_run_async` / `_row_run_async` / `_rsc_run_async`:

    my $storage = $self->result_source->storage;
    if (my $backend = $storage->_async_storage) { return $backend_build->($backend, $fc) }

`$storage->_async_storage` is the **pooled** embedded backend. That is correct
for a bare `$rs->all_async`, but wrong inside a pinned scope. Both
`DBIO::Storage::Async::txn_do_async` and `pipeline` hand their coderef a
**context** object (`TransactionContext` / `PipelineContext`) whose CRUD is
pinned — `select_async` etc. route through `_run_crud_pinned` onto the one
connection that ran `BEGIN`, or the one the pipeline bracketed. The
storage-level CRUD is therefore pinned correctly; the ResultSet/Row layer above
it was not. A `$rs->all_async` inside a `txn_do_async` body resolved
`_async_storage` and took a **sibling** pool connection — outside the
transaction, seeing pre-`BEGIN` state (and at `pool_size => 1`, only after the
transaction released). Nothing warned. A read inside a transaction that does not
see the transaction is a correctness bug, not a missed optimisation; the
pipeline half was the same shape, one layer up, already documented as a
limitation but never fixed.

The fix needs the RS/Row async path to run on the pinned context when one is
active. The rejected shape was an ambient "current async context" on the
storage: an async program can have two transactions in flight on one storage at
once, so a storage-level attribute would be wrong under concurrency (the
pipeline pin is safe only because the batch coderef runs synchronously).

## Decision

**The context is threaded explicitly, never resolved backwards from ambient
state.** A resultset already knows its source and schema, so it only needs to
*carry* the context — it never reaches back into storage to discover a "current"
one, because there is none to discover safely.

1. **`$rs->with_context($ctx)` is the primitive**, mirrored as
   `$row->with_context($ctx)` and `$rsc->with_context($ctx)`. It returns a bound
   clone; the binding lives in a dedicated object slot `{_async_context}`,
   deliberately **not** in `{attrs}` (attrs are copied, merged and serialized —
   a live connection pin has no business there).

2. **`_rs_run_async` / `_row_run_async` / `_rsc_run_async` consult the carried
   context before `$storage->_async_storage`.** With a context bound, the
   context *is* the backend passed to the op's builder closure — it already
   answers the whole CRUD surface the closures use (`select_async`,
   `select_single_async`, `insert_async`, `update_async`, `delete_async`,
   `_query_async`). **No context bound ⇒ the historical pooled path, bit for
   bit.**

3. **The context propagates.** `search_rs` copies `{_async_context}` onto every
   clone, so `with_context($ctx)->search({...})` stays bound. Rows built from a
   bound resultset inherit it — `_construct_results` stamps it onto each core Row
   it inflates, and `new_result` stamps it onto the row it builds — so
   `with_context($ctx)->first_async->then(sub { $_[0]->update_async })` writes
   back on the *same* pinned connection. `get_column` on a bound resultset passes
   it to the new `ResultSetColumn`.

   **The propagation rule is uniform (karr k195).** *Every* derivation that
   produces a fresh `ResultSet`, `Row` or `ResultSetColumn` from a context-bound
   source carries `{_async_context}` onto the derived object; the context-first
   dispatch in `_rs_run_async` / `_row_run_async` / `_rsc_run_async` then
   guarantees the derived async op runs on the pinned connection — and refuses
   loudly (consequence 4/5) when the context is terminal or belongs to another
   generation, never silently falling back to the pool. Beyond the k145 set
   (`search_rs`, top-level rows, `get_column`), the derivations that carry the pin
   are:

   - `ResultSet::page` and `ResultSet::as_subselect_rs` (fresh clones of a bound
     resultset);
   - `related_resultset` / `search_related` in **both** their `ResultSet`- and
     `Row`-level forms, and therefore the generated relationship accessors that
     route through them (`${rel}_rs`, and the single-accessor `${rel}_async`);
   - **prefetched children** — `_construct_results` cascades the pin, via the
     recursive `Row::_bind_async_context`, into each row's cached related
     resultsets and the child rows in their caches, so a prefetched child fetched
     off a bound parent stays pinned with no extra query;
   - a **bound resultset carrying a pre-filled row cache** — `with_context`
     rebinds the cached rows onto the context in a *fresh* cache, so cache-served
     rows carry the pin without mutating the unbound source's shared rows. The
     rebind runs through `Row::with_context`, the **clone-and-rebind** sibling of
     `_construct_results`' in-place `_bind_async_context`: it clones the row, then
     rebuilds its `related_resultsets` map from bound clones of each child
     resultset (each via `ResultSet::with_context`, which recurses back for the
     grandchildren). So a cached row that itself carries eagerly-prefetched
     children keeps the pin cascaded through those grandchildren too (karr k203),
     while the unbound source's shared rows and related resultsets stay untouched
     — `_bind_async_context` may mutate in place only because
     `_construct_results` owns the rows it just built, whereas cache-served rows
     may be shared with the unbound source and must be cloned instead;
   - the `Row` refetch/copy helpers `get_from_storage_async`,
     `discard_changes_async` (which refetches through the former), and the flat
     single-row path of `copy_async`.

   `copy_async` on a source with a `cascade_copy` relationship is a multi-row
   cascade, not one pinned statement, so under a bound context it refuses per
   consequence 6 rather than running the synchronous copy outside the pinned
   scope.

4. **Context ownership is scoped to one concrete backend/pool generation.** Each
   `DBIO::Storage::Async` backend creates an opaque reference token and rotates
   it on every truthy `connect_info` setter and every `disconnect`, including
   reconfiguration before a pool has been materialised. The owning
   `DBIO::Storage::DBI` object mirrors the current token. When DBI `connect_info`
   rebuilds the embedded backend, or DBI `disconnect` detaches it, the owner
   clears that mirror before dropping the cache. A detached old backend may
   still reach its own shutdown path and rotate, but the owner adopts a token
   only from the backend object currently stored in its `_async_storage_obj`
   slot, so the old generation cannot overwrite the new one's proof.

   `TransactionContext` and `PipelineContext` snapshot the token at construction;
   they never derive it later from `context->storage->pool`, because the same
   backend object can lazily create a new pool generation after disconnect.
   `with_context` validates the snapshot before binding, and each ORM dispatcher
   validates it again immediately before dispatch, closing both manual-slot and
   bind-then-rebuild paths. Direct Core-context raw-query/CRUD entry points use
   the same owning-storage validator after their active check. Missing tokens
   fail closed: a context-shaped external object cannot be pinned in this
   increment because its ownership cannot be proven.

   Composition changes no identity rule. A synthesised sync or async class may
   be identical for two independent connections; each composed backend mirrors
   its token onto the concrete sync storage object that actually owns it. Class,
   context shape, schema name and DSN equality prove nothing. Conversely, a
   backend and context belonging to that concrete owner and current generation
   work through the composed classes unchanged.

   Core can observe pool replacement only through its concrete `connect_info`
   and `disconnect` lifecycle. The abstract `pool` method is a subclass seam and
   cannot intercept arbitrary assignments a backend makes to its own pool slot;
   concrete backends must therefore replace an existing pool through those
   lifecycle paths if they want Core's generation guarantee.

5. **A carried-but-expired context refuses loudly; it never falls back to the
   pool.** A `PipelineContext` is valid only for the *synchronous* run of its
   batch coderef (dbio-async ADR 0003): statements are batched during that run
   and synced immediately after, then the connection returns to the pool. The
   `pipeline` scaffold invalidates the context the instant the coderef returns
   (`_invalidate`), and the RS/Row/RSC async path asserts
   `$ctx->_context_active` before routing onto it — a bound resultset used after
   the batch throws, rather than silently re-issuing on a pooled connection
   outside the bracket. A `TransactionContext` stays active while its callback
   Future is pending and throughout that Future's own `then` chain. Every
   terminal transaction path after a successful acquire converges on one
   finalizer. Once a context has been constructed, failed `BEGIN`, `COMMIT` and
   `ROLLBACK` paths call `_invalidate` before the exactly one pool release. If
   the context constructor itself throws before `BEGIN`, there is no context to
   invalidate; the same finalizer still releases once and reports the
   constructor error through a failed Future, keeping it primary if release
   also throws. A failed acquire has no context or connection to release. Once
   terminal, direct context raw-query / CRUD and nested-transaction entry
   points refuse too, `in_txn` is false, and a bound RS/Row/RSC refuses by the
   same active-context boundary.

6. **An operation that is not a single pinned statement refuses, named, rather
   than silently redirecting.** The context CRUD surface is exactly
   select / select_single / insert / update / delete. The RS/Row async methods
   that cannot be expressed as one such statement — `Row::insert_async`'s
   related-object multi-create, `update_async`'s OnColumnChange/`cascade_update`,
   `delete_async`'s `cascade_delete`, `upsert_async`'s cascade/fallback/count —
   historically punt to the *synchronous* method and resolve immediately. Under a
   bound context that sync fallback would run on a pooled sync connection
   **outside** the pinned transaction/pipeline. The shared helper
   `_async_ctx_or_sync_punt` therefore **throws a named exception** when a context
   is bound, and only performs the historical sync-and-resolve punt when none is.
   What is not mappable is named, not quietly re-routed.

7. **Terminal cleanup does not change transaction error precedence.** A failed
   `BEGIN` Future keeps the `BEGIN failed: ...` prefix and a failed `COMMIT`
   Future keeps `COMMIT failed: ...`. After a callback failure, successful
   rollback restores the callback error; a rollback failure replaces it with the
   raw rollback error. A synchronous throw from any of those three query seams
   after acquire is converted into a failed Future with the original diagnostic,
   not thrown from `txn_do_async`. A release throw replaces a successful result,
   but remains secondary when a transaction error already exists.

## Scope — what this ADR deliberately does not add

`$ctx->resultset($moniker)` as a convenience is **out of scope**. It would need a
schema back-reference on `DBIO::Storage::Async`, which does not exist today;
introducing one is a second design and belongs in its own ticket. `with_context`
is the whole mechanism here: the caller already holds the resultset and only
needs to bind the context onto it.

## Consequences

- RS/Row/RSC async inside `txn_do_async` / `pipeline` is correct **only when the
  resultset is explicitly bound** with `with_context`. An unbound `$rs->all_async`
  inside a transaction body still runs on the pool — by design: without ambient
  state there is nothing for it to pick up, and silently guessing would
  reintroduce the concurrency hazard the explicit design exists to avoid. This is
  documented in `DBIO::Manual::AsyncStorage`.
- The unbound path is untouched: `_async_context` is undef, every new guard is
  skipped, and the pooled/sync behaviour is bit-for-bit what ADR 0031 shipped.
- `PipelineContext` and `TransactionContext` expose `_context_active` /
  `_invalidate`. These are internal; a transport with a custom context class that
  omits `_context_active` keeps the pre-existing always-active treatment only
  after current-generation ownership has been proved. A custom or external
  context without Core's `_context_owner_token` snapshot is not pinning-capable
  and fails closed. The token/validator methods are private lifecycle seams on
  existing core bases, so they add no public driver contract or contract-version
  bump. The generic contexts guard all direct pinned raw-query/CRUD entry points;
  `TransactionContext` also guards nested `txn_do_async` and makes `in_txn`
  mirror `_context_active`.
- Reapplying DBI `connect_info`, calling DBI or backend `disconnect`, or lazily
  creating a pool after backend disconnect makes every context from the prior
  generation stale. Such a context is refused before query dispatch even if its
  backend object, class and DSN otherwise look unchanged.
- Every terminal path after a transaction connection was acquired owns one
  release in `_finalize_txn_async`; branch-local commit/rollback releases no
  longer exist. If construction completed, the context is invalid before that
  release callback can observe it; a constructor throw reaches the same
  finalizer without attempting impossible context invalidation.
- The stable refusal claims (`no longer active`, `cannot run on a bound async
  context`, `ownership cannot be proven`, `does not belong to this storage
  generation`) are sampled by `t/resultset/with_context.t`; explanatory suffixes
  are not a complete error-string API.

## Future architecture work (tracked cross-repo, not here)

dbio-async ADR 0003 currently says core would only change "if it ever should be".
Core has now changed: the pipeline context self-invalidates and the RS layer
composes with it. That amendment belongs in **dbio-async**, not here — filed as a
karr ticket on the dbio-async board (see the k145 handoff). Do not edit dbio-async
from this repo.

## Addendum (2026-09-25, karr core k213) — the context's last two delegations

Consequence "TransactionContext also guards nested `txn_do_async`" read as if a
nested call were legitimate while the context is active. It was not: the
context's `pipeline` and `txn_do_async` were the two remaining plain
delegations to the storage (dbio-async ADR 0002 amendment lists them), and both
took a **second** connection from the pool — the exact escape this ADR and
dbio-async ADR 0002 exist to prevent.

- `$ctx->pipeline` now runs on the pinned `txn_conn`. The scaffold was extracted
  into `DBIO::Storage::Async::_pipeline_on_conn($conn, $coderef, $release)`;
  the pooled `pipeline` passes a release, the transaction context passes none,
  so the connection stays pinned until the transaction boundary releases it once.
- `$ctx->txn_do_async` refuses with a `DBIO::Exception`. A correct nested
  transaction is a savepoint on the pinned connection, and the async layer has
  no savepoint seam; the only other thing it could do is an independent
  transaction on a second connection, which commits past an outer rollback and
  deadlocks on the outer transaction's locks. That stays reachable when named:
  `$ctx->storage->txn_do_async`. Async savepoints, if wanted, are their own
  ticket.

Claims pinned by `t/test/36_async_txn_context_pins_nested.t`. The pipeline half
changes what the wire sees (pipeline mode inside an open transaction), so it is
mock-verified only until a live pg-ev run confirms it.

## Addendum (2026-10-07, karr core k281) — the derivations that build a fresh resultset

§3 states the rule for *every* derivation, and four of them did not follow it.
They do not clone the resultset they are called on, they build a fresh one from
its result source — and a fresh resultset has no `{_async_context}`:

- the set operations `union`, `union_all`, `intersect`, `intersect_all`,
  `except`, `except_all` (one path, `_set_operation`);
- `bare`;
- `correlate`;
- `count_rs`, on both its paths (`_count_rs`, and `_count_subq_rs` for a
  resultset with `group_by`, `rows`, `offset` or a collapsing prefetch).

A `*_async` on the result was therefore not refused. It took a connection from
the pool and ran outside the transaction or pipeline — `BEGIN`, the statement
on a pool connection, `COMMIT` — and a result held past its context ran there
too instead of throwing. All four now carry the pin of the resultset they are
called on, in the idiom of `as_subselect_rs`: the fresh resultset is stamped
before the `search` / `get_column` that follows, which passes it on.

`bare` stays bound. It discards search conditions and attributes; the binding
is a connection pin and lives outside `{attrs}` for exactly that reason (§1).

**A set operation takes the binding of the resultset it is called on.** That is
the rule of §3 read literally, and it settles a bound resultset combined with
operands bound to the same context or not bound at all. What the operands' own
bindings mean was left **open on karr k324** when k281 landed; it is decided in
the addendum of 2026-10-10 below, and the two cases k281 held as IST
assertions — an unbound resultset combined with a bound operand (result
unbound, ran on the pool), and two contexts combined (result bound to the
first, nothing refused) — are refused now.

Claims pinned by `t/resultset/with_context_fresh_derivations.t`.

## Addendum (2026-10-08, karr core k325) — what a bound row and a bound column hand out

k281 closed the derivations of a bound *resultset*. The same fault sat one
level down, where the bound object is a row or a column: the derived object
was built from the result source (or by hand), not from the bound object, so
it had no `{_async_context}`. A `*_async` on it ran on a pool connection
between the transaction's `BEGIN` and `COMMIT`, and was not refused once the
context had ended. Found by reading every place in `lib/` that constructs a
`ResultSet`, a `Row` or a `ResultSetColumn`, and by running each:

- **Row**: `self_rs`, `clean_rs`; the row `get_from_storage` returns; the copy
  `copy` returns; the row a many-to-many `add_to_<name>` finds or creates.
- **`discard_changes`** took the binding off the very row it was called on: it
  replaces the row's contents with those of the refetched copy, and that copy
  was unbound. It follows from `get_from_storage` and is fixed with it.
- **`DBIO::Ordered`**: `siblings`, `previous_siblings`, `next_siblings` and the
  rows `previous_sibling`, `first_sibling`, `next_sibling`, `last_sibling`
  return — all through `_group_rs`, which is where the pin is handed on.
- **`DBIO::ChangeLog`**: `changelog`.
- **ResultSetColumn bound directly** with `with_context`: `func_rs` (and
  `min_rs` / `max_rs` / `sum_rs`) and `_resultset`. A column made by
  `get_column` on a bound resultset was right, because its parent resultset was
  bound; a column bound afterwards kept an unbound parent. `with_context` now
  gives the clone a bound clone of the parent and drops the cached inner
  resultset, so both kinds of bound column are the same object shape and no
  method of the column has to stamp anything. The column it was cloned from
  keeps its own parent.
- **Rows of a result class with its own `inflate_result`**: §3 says
  `_construct_results` stamps "each core Row". The gate was the inflator, not
  the object — it was meant to leave out `HashRefInflator`'s hashrefs and also
  left out every `Row` a result class's own `inflate_result` builds (the
  documented way to rebless a row into a subclass). The stamp now goes onto
  whatever came back that is a `Row`.

**The synchronous helpers are in.** `get_from_storage`, `discard_changes`,
`copy`, `add_to_<name>` and the single-row sibling methods are synchronous:
their own statements go through the synchronous storage and never read the
pin. What they hand back is still a derivation in the sense of §3, and the
`*_async` called on it next has to run pinned or be refused. So the returned
object carries the pin; where the helper's own work runs is unchanged.

**No single choke point exists, and none was built.** A fresh resultset is
made by `ResultSource::resultset` or `ResultSet->new`, and neither sees the
object it is being made for. Letting them see it means either ambient state
(rejected in the Decision above) or an argument on `resultset`, which is
public and refuses arguments today. The fix therefore stays in the idiom of
k195 and k281 — stamp the fresh object where it is built — and uses the
narrowest point each class offers: `with_context` for a column, `_group_rs`
for Ordered, `_construct_results` for rows, `get_from_storage` for
`discard_changes`.

**Not covered — the related rows of a multi-create.**
`$rs->new_result({ ..., artist => { name => ... } })` builds the nested rows
inside `Row::new`, from an unbound resultset of the related source, before
`new_result` has stamped the row they are nested in. They stay unbound
(measured: `insert_async` on such a nested row runs on the pool). Carrying the
pin there needs the context inside `Row::new`, which today learns nothing
about it — a constructor argument beside `-result_source`, or a pass over the
finished row that tells the rows it built from the row objects the caller
passed in. That is a decision of its own and is left open; `insert_async` on
the outer row refuses a multi-create under a bound context anyway (§6).

**Where two bindings meet**, k325 decided nothing for the row case: a row
object passed to `add_to_<name>` is handed back as it came, whatever it is
bound to. The set operations, the other place two bindings meet, are decided in
the addendum of 2026-10-10 (karr k324).

Claims pinned by `t/resultset/with_context_row_column_derivations.t`; the
multi-create case is held there as an assertion marked IST, so that the
decision changes a visible test.

## Addendum (2026-10-08, karr core k282) — the `immediate` context, and what one INSERT is

Two places where a bound object refused what it should have run.

### §4 — the `immediate` mode's context is the storage

§1 has `with_context` take the object handed to a `txn_do_async` coderef; §4
proves that object by a token. In the `immediate` mode that object is the
storage itself (ADR 0055) and carries none, so `with_context` refused the one
context that mode has. `_assert_async_context_owner` now accepts the storage
asked as its own context while its mode is literally `immediate`; the proof is
identity there. For every real backend §4 is unchanged — its own sync storage
is not a context, nor is any other storage. What a bound object does in that
mode, and what stays particular to it, is in ADR 0055 (addendum 2026-10-08).

### §6 — a row that carries an inflated value is not a multi-create

§6 lists "`Row::insert_async`'s related-object multi-create" among what is not
one pinned statement. `insert_async` decided that by asking whether
`_relationship_data` or `_inflated_column` held anything. Both hold more than
multi-create data:

- an object for a column with an inflator sits in `_inflated_column` until
  `get_columns` deflates it;
- a related row that was in storage when the row was built is flagged
  `_rel_in_storage` and only lends its key.

So a plain insert with a `DateTime`, or with a stored row for a `belongs_to`,
went the cascade's way: synchronously on an unbound row, and on a bound one
into the refusal — with a message naming a multi-create that was not there.

`insert_async` now asks what `insert` does: `_insert_cascade_reason` walks the
two slots the way `insert`'s own two loops do and answers why the insert would
send more than one statement, or that it would not. It is a cascade when a
related row our foreign key depends on is not flagged (`insert` looks it up,
and inserts it if needed, **before** this row), or when related rows depend on
this one (inserted **after** it). Everything else goes out as the one
`INSERT`, through the backend — on the pool unbound, on the context bound —
with the foreign key set and the value deflated at the point `insert` does
both. The refusal of a real cascade names the relationship and the direction.

The rule is "one statement where `insert` sends one", deliberately no wider.
Two things follow from that and are **not decided**; both are held as IST
assertions:

- **A stored row put on a row after it was built** (accessor,
  `set_inflated_columns`) is not flagged, and `insert` looks it up again
  before inserting (measured: `SELECT`, `INSERT`). `insert_async` treats it as
  the cascade `insert` makes of it. Treating "in storage" as "key is known"
  would make it one `INSERT`, at the price of not refreshing the related row
  the way `insert` does — on unbound rows too, where today's punt keeps
  `insert`'s behaviour exactly.
- **A `belongs_to` given as a hashref is looked up while the row is built.**
  `Row::new` asks an unbound resultset of the related source, synchronously,
  before `insert_async` is reached (measured on a bound resultset: one
  `SELECT` through the synchronous storage, then the refusal). This is the
  same place as the open decision of the k325 addendum — `Row::new` learns
  nothing of the context — and is settled with it.

Claims pinned by `t/row/insert_async_inflated.t`: the `INSERT` and the state
of the row afterwards are compared with the synchronous insert's, unbound,
bound to a real backend's transaction and bound in the `immediate` mode.

## Addendum (2026-10-09, karr core k331) — the overrides of insert / update / delete, and the `prepare_*` hooks

Maintainer decision of 2026-10-09 (strict gate and hook interface, both).

`insert_async`, `update_async` and `delete_async` send their statement
through the backend. They are a new method name beside `insert` / `update` /
`delete`, so an override of the synchronous method on the class's MRO was not
on their way: a row written asynchronously got no `DBIO::Timestamp` stamp, no
`DBIO::UUIDColumns` key, no `DBIO::FilterColumn` filtering, no
`DBIO::Ordered` position, no `DBIO::ChangeLog` entry, and none of what a result
class or a Moo `around` did. Only `cascade_*` and `OnColumnChange` were
caught, by their own predicates (§6).

### §8 — work before the write has a hook; the rest is gated

`DBIO::Row` has three public hooks, `prepare_insert`, `prepare_update($upd)`
and `prepare_delete`, empty in `Row`. The synchronous methods and the
`*_async` methods each call the one hook once, before the columns are read
(`prepare_update` gets the hashref before it is applied and may take keys out
of it). Where a `*_async` method punts to the full synchronous method (§6), it
is that method that calls the hook, so it runs exactly once. `DBIO::Timestamp`,
`DBIO::UUIDColumns` and `DBIO::FilterColumn` do their work there and no longer
override `insert` / `update`.

The gate: if a package on the MRO before `DBIO::Row` defines `insert`,
`update` or `delete` itself and does not define the `*_async` sibling in that
same package, the `*_async` method goes through the full synchronous method by
the same route as the §6 punts. Unbound, the Future is returned settled with
the synchronous result. Bound to a context — in the `immediate` mode too —
it throws, naming class and method, rather than write past the override. This
reaches result classes and Moo `around` as much as components. Only
`DBIO::Relationship::CascadeActions` is exempt: its predicates are finer and
punt only where it cascades.

### What the interface carries

- Carried: `Timestamp`, `UUIDColumns`, `FilterColumn` — their work is a
  change of the row's own columns before the write.
- Not carried: `DBIO::Ordered` reads siblings with synchronous statements and
  moves them in a transaction; `DBIO::ChangeLog` writes further rows around
  the write. On a bound row those would run outside the pinned context. They
  stay overrides without a sibling and meet the gate. Giving them a real
  `*_async` is a separate piece of work and not decided here.

Claims pinned by `t/row/async_overrides.t`.

## Addendum (2026-10-10, karr core k324) — set operations over operands bound differently

Maintainer decision of 2026-10-10, option (c) of the three k281 left open.

A set operation is one statement. The k281 addendum fixed that it carries the
binding of the resultset it is called on and left the operands' own bindings
unlooked-at — which meant an unbound resultset united with a bound one ran on
the pool, outside the transaction the operand was bound to, and two resultsets
bound to two transactions ran entirely in the first's. Either the operand's
binding was silently dropped or one of two pins was silently preferred; both
are the "silently falls back" that §1 exists to prevent.

**The operands of a set operation must be bound alike.** `union`,
`union_all`, `intersect`, `intersect_all`, `except` and `except_all` take
operands that are either all unbound or all bound to the same context, compared
by identity of the context object. Anything else throws when the operation is
built (`throw_exception`), for the three mixtures: the caller unbound and an
operand bound, the caller bound and an operand unbound, and operands bound to
two different contexts. The message names the operation and the operands that
differ from operand 0 (the resultset the operation is called on), each as
unbound or bound to its context. All operands unbound, or all on the one
context, are unchanged, and the result carries that binding as under k281.

- **Where it is checked.** First in `_set_operation`, before the storage is
  asked for the keyword and before any operand SQL is rendered. ADR 0039 asks
  that the keyword be resolved before operand SQL; the check precedes both, so
  it does not depend on what a driver's `_set_operation_keyword` answers, and
  a refused call has asked no one and sent nothing.
- **The synchronous use of the result is refused too.** This is deliberate and
  not softened: the check is on the binding of the operands, not on how the
  result is used afterwards. A statement that mixes a transaction's resultset
  with a free one has no single connection it could mean, and a program that
  builds it and only runs it synchronously has still written an operation
  whose operands disagree about where they live. Bind every operand to the
  context, or none.
- **There is no `*_async` form of the operations.** `union_async` and its
  siblings do not exist; the `*_async` that follows runs on the result of the
  one construction, so this is the only place that decides.
- **No new public interface.** Nothing is added; a program that already used
  equal bindings is unaffected.

Claims pinned by `t/resultset/with_context_fresh_derivations.t`, which replaces
the two IST assertions of k281 with refusals, and covers every combination for
all six operations and that a refused call sends nothing.

## Addendum (2026-10-30, karr core k407) — a Future that waits on the pool holds itself

Maintainer decision of 2026-10-30.

A Future that waits for a connection of the pool and goes to a caller is a
sequence of the pool's acquire Future. The rule is the one the statements of a
context already follow (k292, k331): **the Future derived from the wait on the
pool holds itself until it is ready** — done, failed or cancelled — by being
retained (`_hold_derived`, asked through `can('retain')`, so a Future class
without `retain` is left as it is).

- **Where it applies.** `pipeline`, the pooled (non-transactional) branch of
  `deploy_async`, and the pooled branch of a DDL run (`_start_ddl_run_async`).
  The transactional branches go through `txn_do_async`, which holds already.
- **What a caller sees.** Nothing changes for one that holds the Future. One that
  does not — a call in void context, a statement dropped inside a batch — has
  the body run when a connection is free, the connection handed back, and no
  warning.
- **Transports.** The `_query_async` seam contract states the same rule for the
  Future a transport derives from `pool->acquire`, and for every further seam
  that waits on the pool and hands that Future to a caller.

Claims pinned by `t/test/84_async_pool_wait_held.t`.
