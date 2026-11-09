# ADR 0051 — A primary async backend self-provisions its select/ownership owner

- Status: accepted
- Date: 2026-09-21
- Tags: async, storage, ownership, select-args, karr-k204

## Context

An async backend (`DBIO::Storage::Async` and its subclasses — the `ev` and
`future_io` transports) does not carry its own SELECT-argument preparation. By
the k193 contract it delegates arg-prep to an **owning sync storage** whose
`_select_args` applies the exact validation, join pruning and complex-prefetch
rewrite the sync cursor path uses, so the async SELECT SQL is byte-identical to
what a real cursor would have executed (the mock-cursor / real-cursor parity
invariant, karr core k55 / ADR 0046). By the k196 contract, async transaction
and pipeline contexts prove ownership against that same owner's context-owner
token before routing pinned work.

That owner is wired in exactly one place: `_async_storage` in
`lib/DBIO/Storage/DBI.pm` calls `$async->_owner_storage($self)` when it builds
the **embedded** async backend for a schema connected `{ async => $mode }`. In
that shape the primary storage is a sync `DBIO::Storage::DBI` and the async
backend is embedded beneath it — the owner is the primary.

The native `ev` backends are also usable as a **primary** storage, constructed
directly at the driver level with no embedding sync storage:

    my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
    $storage->connect_info([ \%conninfo, {} ]);
    $storage->select_async(...);

Nothing on this path ever calls `_owner_storage`, so it stayed unset. INSERT
does not route through `_select_args`, so `insert_async` worked and every mock
suite — which wires `_owner_storage` by hand — stayed green. The gap only
surfaced on the first **live** run against a real database (karr k204):

- `_prepare_select_args_async` in `lib/DBIO/Storage/Async.pm` threw
  *"async SELECT requires its owning sync storage"* on the first `select_async`;
- `_assert_context_active` in
  `lib/DBIO/Storage/Async/TransactionContext.pm` (and the identical guard in
  `PipelineContext.pm`) threw *"async context ownership cannot be proven"* on
  the first `txn_do_async`.

`dbio-postgresql-ev`'s `t/13-cold-pool-live.t` and `t/14-txn-live.t` construct
the backend exactly this way, so they were the first to hit it.

## Decision

A `DBIO::Storage::Async` backend that has **no externally-wired owner** provisions
and owns a private sync sibling to serve as its owner. Introduced in
`lib/DBIO/Storage/Async.pm`:

- `_effective_owner_storage` returns the wired `_owner_storage` when present
  (the embedded path, unchanged), else lazily builds and caches the sibling.
- `_build_self_owner_storage` builds a plain `DBIO::Storage::DBI` — `_select_args`
  is core-only, no driver overrides it — that **shares this backend's already
  configured `sql_maker`** (via the private `_sql_maker` slot) and carries this
  backend's current context-owner token. It is held **strongly** (unlike the
  weak `_owner_storage` back-reference) because nothing else keeps it alive. No
  connection is opened: `_select_args` and the token machinery never touch a dbh.

The three consumers now ask for the effective owner: `_prepare_select_args_async`
in `Async.pm`, and `_assert_context_active` in both `TransactionContext.pm` and
`PipelineContext.pm`. `_rotate_context_owner_token` in `Async.pm` seeds a built
sibling's token directly on every rotation (the sibling caches no backend of its
own, so the stale-backend guard in `_adopt_async_context_owner_token` would
otherwise refuse it). Setting an external owner via `_owner_storage($x)` drops
any self-provisioned sibling, so there is always exactly one owner.

This is option (a) of the k204 design: a primary async backend is effectively
its own owner, realised by holding a private sync sibling rather than by
duplicating `DBIO::Storage::DBI`'s `_select_args` onto the async base.

## Rationale

- **Core-only, driver-agnostic.** The sibling is a generic `DBIO::Storage::DBI`,
  not the driver's sync storage class, so core needs no async→sync class map and
  no EV-driver change. Parity holds because `_select_args` is unoverridden core
  logic and all dialect specifics live in the shared `sql_maker` — the same
  maker the async path already uses in `_run_crud`.
- **Parity preserved (ADR 0046).** Because the sibling shares the backend's
  `sql_maker`, the args it prepares — and therefore the emitted SQL and bind —
  are byte-identical to what the async maker produces directly. `t/test/32_async_standalone_owner.t`
  asserts this equality, not merely that the call survives.
- **The k193/k196 contracts are kept, not weakened.** SELECT still prepares
  through a real `_select_args`; contexts still prove ownership against a real
  token holder. The only change is that a primary backend now *has* such an owner
  instead of throwing for lack of one.
- **No composition-seam change.** No `@ISA`, `use base`, `storage_type`, role or
  layer change. The sibling is a held instance, not an inheritance edge; the
  async transport's linearised ISA is untouched, so driver resolution
  (ADR 0030/0032) is unaffected.
- **No contract-version bump (ADR 0024).** The five contract-versioned base
  classes are `Introspect::Base`, `Diff::Base`, `Deploy::Base`, `SQLMaker` and
  `Storage::DBI::Capabilities`. `DBIO::Storage::Async` is not among them, and the
  change is purely additive (a new private method and a private fallback slot),
  so `$CONTRACT_VERSION` and `t/test/12_contract_version.t` are unchanged.

## Consequences

- The embedded `{ async => $mode }` connect path is byte-for-byte unchanged: an
  external owner short-circuits `_effective_owner_storage` before any sibling is
  built, so every existing mock suite (which wires the owner by hand) behaves
  exactly as before.
- A primary/standalone async backend now costs one extra lightweight,
  connection-less `DBIO::Storage::DBI` object the first time it prepares a SELECT
  or enters a context. It is registered in the storage global-destructor registry
  like any storage but owns no dbh, so its DESTROY is a no-op.
- `DBIO::Storage::Async` now `use`s `DBIO::Storage::DBI` at compile time. This is
  not circular: `DBIO::Storage::DBI` references `DBIO::Storage::Async` only at
  runtime (a `->can` probe inside `_async_storage`), never in its own `use`/`base`
  list.
- New offline coverage `t/test/32_async_standalone_owner.t` drives the primary
  wiring path through a synchronous fake transport and never sets `_owner_storage`
  by hand — the coverage the existing manual-wiring suites structurally could not
  provide.

### Backward compatibility (addendum, karr k204)

Storages that fulfil only the older `_owner_storage` contract remain valid. Some
driver test suites use a **bare mock** as the backend a context runs over — one
that sets `_owner_storage` (often to itself) and never subclasses
`DBIO::Storage::Async`, so it has no `_effective_owner_storage` (e.g.
`dbio-postgresql-ev`'s `MockStorage27`). Rather than touch every such mock, the
core call-sites resolve the owner through one helper,
`_effective_owner_of($storage)` in `lib/DBIO/Storage/Async.pm`: it uses
`_effective_owner_storage` when the storage has it (a real async storage, full
self-provisioning) and falls back to `_owner_storage` otherwise. It is a plain
function, not a method, because the invocant may lack the method entirely. This
is semantically identical for a mock — a wired `_owner_storage` always wins over
a self-provisioned sibling, so it *is* the effective owner, and an ownerless
storage still yields undef so the caller throws the same
"requires its owning sync storage" / "ownership cannot be proven" error. The
three call-sites (`_prepare_select_args_async` in `Async.pm`,
`_assert_context_active` in `TransactionContext.pm` and `PipelineContext.pm`)
all route through the one helper so they cannot drift.

## Future architecture work (tracked cross-repo, not here)

The live regression tests that exercise this against real databases live in the
transport dists. Their sign-off is tracked on the driver boards, not here:
`dbio-postgresql-ev` (`t/13-cold-pool-live.t`, `t/14-txn-live.t`,
`t/15-pipeline-facade`, `t/17-concurrency`, `t/18`/`t/19-copy-in`,
`t/26-upsert-inherit-live.t`) and the mirror confirmation on `dbio-mysql-ev`.
No EV-driver code change is required by this ADR — the fix is entirely in core.
