---
name: dbio-forked
description: Load when using DBIO::Forked or making a sync driver async without an event loop — fork plus pipe plus Storable, and its limits.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Forked

Generic, **fork-per-query** async backend (Model A) that makes *any* sync DBIO
driver async — no async-capable client, no event loop. It is a **sibling** of
`dbio-async`: both fulfil the core `DBIO::Storage::Async` contract, but
`dbio-async` = Future::IO + async client (PG/MySQL native async), `dbio-forked`
= `fork()` + pipe + the ordinary sync driver run in a child. Forked is the only
async backend that is genuinely generic — it needs nothing but the DBI-form
connect info every sync driver already has, so it covers the ~13 drivers that
will never get a native async client (Oracle, db2, Sybase, SQLite, …).

**Dependency-free**: only core Perl (`fork`, `pipe`, `Storable`, `IO::Select`)
plus DBIO core. No `Future`, no `Future::IO`, no event loop.

## Namespace

| Class | Purpose |
|-------|---------|
| `DBIO::Forked` | Dist entry point (loadable, no behaviour) |
| `DBIO::Forked::Storage` | Fork-per-query async backend (extends core `DBIO::Storage::Async`) |
| `DBIO::Forked::Future` | Loop-free, pipe-backed Future fulfilling the core `DBIO::Future` contract |

## Activation — the `forked` async mode (core ADR 0030)

Loading `DBIO::Forked` registers the `forked` async mode on core
(`DBIO::Storage::DBI->register_async_mode(forked => 'DBIO::Forked::Storage')`).
A user then selects it per connection: `connect(..., { async => 'forked' })`.
The core resolver builds the backend for that instance (`->new($schema)` →
`->connect_info(...)`); `forked` works for **any** sync driver (it needs only
the DBI-form connect info). There is no auto-fallback — async is an explicit,
per-connection choice (ADR 0030); requesting `forked` without `dbio-forked`
installed croaks loudly.

## What a query does

`*_async` forks one child per query; the child runs the driver's ordinary sync
CRUD and sends the rows back over a pipe; the caller gets a `DBIO::Forked::Future`.
The child reconnects through the sync storage, so `on_connect_do` /
`on_connect_call` re-run in every child, and an AccessBroker works as usual.
Mechanics and invariants for changing the code: skill `dbio-forked-core`.

## The Future

`DBIO::Forked::Future` has the full `DBIO::Future::Immediate`-compatible
`future_class` surface; core's `all_async`/`first_async`/`count_async`/`create_async`
route through it.

- `is_ready` / `is_failed` — non-blocking; ready once the child has finished.
- `get` — blocks, returns the rows or re-throws the child's error; idempotent.
- `then`/`catch`/`and_then` — lazy, loop-free; they run at first force.
- `done`/`fail`/`needs_all` — class constructors, no fork.
- A dropped Future is reaped (no zombies); the destructor blocks until the child ends.
- A child that dies without a result fails the Future with
  `child killed by signal N` / `child exited with status N`.

## Limits (Model A)

- **Pipe buffer (~64 KB)**: a larger result blocks its child until the parent reads.
  Fine for "one query, `->get`"; "fire many, collect later" with large results stalls.
- No connection pool, no transaction pinning across separate `*_async` calls (each
  call is its own child and connection). `txn_do_async` runs a whole transaction in
  one child; its body returns serializable data (plain scalars / array / hash refs,
  not live Row or ResultSet objects; those fail the Future) and uses sync operations
  only (a `*_async` inside would fork again).
- `deploy_async` and `pool` croak; deploy through `$schema->deploy` on the sync owner.
- Broker options beside an AccessBroker work: `connect($broker, { async => 'forked',
  AutoCommit => 1 })`; `pool_size` sizes nothing.
- With a rotating broker and an expired lease in the parent, every forked query
  refreshes in its child; the parent's broker changes only when it reconnects.
- Unix fork only.

## Boundary

Ships **no** DB-specific code, re-implements **no** SQL — the real driver does it in
the child. `share_skill = dbio-forked` only; the family skills belong to core.
