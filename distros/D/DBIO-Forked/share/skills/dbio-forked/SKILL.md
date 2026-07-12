---
name: dbio-forked
description: "DBIO::Forked — generic fork-per-query async backend: make any sync DBIO driver async without an async client or event loop, via fork() + pipe + Storable"
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

## Activation — the `forked` async mode (ADR 0030/0031)

Loading `DBIO::Forked` registers the `forked` async mode on core
(`DBIO::Storage::DBI->register_async_mode(forked => 'DBIO::Forked::Storage')`).
A user then selects it per connection: `connect(..., { async => 'forked' })`.
The core resolver builds the backend for that instance (`->new($schema)` →
`->connect_info(...)`); `forked` works for **any** sync driver (it needs only
the DBI-form connect info). There is no auto-fallback — async is an explicit,
per-connection choice (ADR 0030); requesting `forked` without `dbio-forked`
installed croaks loudly.

## How a query runs (Model A)

`select_async`/`insert_async`/… → `_run_forked($op, @args)`:

1. `pipe` + `fork`.
2. **Child** runs the *inherited primary sync storage's* ordinary sync CRUD —
   `$self->{schema}->storage->$op(@args)`. It re-implements **no** SQL and
   touches no DBI handle: the sync storage's inherited DBIx::Class fork handling
   (`_verify_pid` sets `InactiveDestroy` on PID change, `_get_dbh` reconnects
   fresh — through the AccessBroker too) does the safe reconnect itself. It calls
   the **sync** method, never `*_async` (no re-fork — sync does not route to the
   backend, ADR 0028). Then `Storable::freeze` the rows (or error) over the pipe
   and `POSIX::_exit`.
3. **Parent** returns a `DBIO::Forked::Future` bound to the pipe read fd.

## The loop-free Future

`DBIO::Forked::Future` provides the FULL `DBIO::Future::Immediate`-compatible
`future_class` surface, not just the minimal `DBIO::Future` contract — because
in the `forked` mode it IS the live `future_class`, and core's ResultSet/Row
async (`all_async`/`first_async`/`single_async`/`count_async`/`create_async`/
`Row::insert_async`) routes through this backend and inflates in the Future's
`then` (ADR 0031). So its `then` must auto-wrap plain returns (ADR 0031 §4), and
`done`/`fail` back the immediate/degrade paths. Surface:

- `is_ready` — EOF-clean non-blocking drain (accumulate across calls; ready only
  at EOF; a bare `can_read(0)` peek would be premature, it goes true as soon as
  the child writes anything).
- `get` — block to EOF, `Storable`-thaw, `waitpid`-reap, re-throw on error;
  idempotent; wantarray-aware (scalar context → first value, like Test::Future).
- `then`/`catch`/`and_then` — lazy compose, loop-free; resolve synchronously at
  first force (no loop, so the callback must run at first force). Flatten a
  single returned future for chaining.
- `done`/`fail`/`needs_all` — immediate CLASS constructors (no fork). `needs_all`
  blocks on each input via `get` in turn (children already run in parallel;
  serial collection is subject to the pipe-buffer ceiling, ADR 0003).
- `DESTROY` reaps an un-collected child (no zombies).

## Limits (Model A)

- **Pipe-buffer ceiling**: a result blob larger than the pipe buffer (~64 KB on
  Linux) blocks the child in the write until the parent reads. Fine for "one
  query → `->get`"; for "fire many `*_async`, collect later" with large results
  the children stall. Argument for a future Model B (worker pool + streaming, as
  in QuickORM's `STH::Fork`).
- No connection pool, and no transaction pinning *across separate* `*_async`
  calls (each call = its own child = its own connection). `txn_do_async` runs a
  whole transaction in ONE child, so BEGIN/body/COMMIT share that child's
  connection — but the body (a) must **return Storable-serializable data** (plain
  scalars / array/hash refs, not live `Row`/`ResultSet` objects, which drag a
  live DB handle along — caught and surfaced as a failed Future), and (b) must be
  **sync-only** (a `*_async` call inside the body would re-fork from the child).
- Unix fork model; Windows fork emulation is out of scope.

## Boundary

Ships **no** DB-specific code, re-implements **no** SQL — the real driver does it
in the child. Must load and work with any sync driver. `share_skill = dbio-forked`
only; the family skills belong to core.

## ADRs

- 0001 — generic fork-per-query async backend (+ activation via core ADR 0028)
- 0002 — the forked child reuses the inherited sync storage (no SQL rebuild, no
  connect_info replay; fork-safety + AccessBroker for free)
- 0003 — loop-free pipe-backed Future, EOF-framed, and its size limit

## Version policy

`$VERSION` only in `lib/DBIO/Forked.pm` (`[@DBIO]` VersionFromMainModule);
sub-modules unversioned. **No `heritage`** in dist.ini — new code, not
DBIx::Class-derived (like `dbio-postgresql-async` / `dbio-mysql-async`).
