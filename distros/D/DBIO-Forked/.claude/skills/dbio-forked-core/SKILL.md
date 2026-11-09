---
name: dbio-forked-core
description: Load before changing DBIO::Forked::Storage, DBIO::Forked::Future or their tests — child mechanics, invariants, capability stance, test layout, ADRs.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Forked — core knowledge for implementers

For the dist's purpose, activation (`{ async => 'forked' }`), the Future surface as
users see it, and the limits users hit: skill `dbio-forked`. This skill holds what only
someone changing the code needs.

## Vocabulary

| Term | Meaning |
|------|---------|
| Model A | One `fork()` per query; the child runs the sync driver. This dist. |
| Model B | Worker pool with streaming. Future work; not built. |
| owner storage | The driver's sync storage, `$schema->storage`; reachable from the backend via `_owner_storage`. |
| leaf Future | A Future bound to a pipe read fd and a child pid. |
| derived Future | A Future made by `then`/`catch`/`and_then`; it resolves from its source on first force. |
| blob | The `Storable`-frozen result (or error) the child writes to the pipe. |

## Class map

- `DBIO::Forked::Storage` — extends core `DBIO::Storage::Async`. Overrides the six
  `*_async` methods plus `txn_do_async` directly; each calls `_run_forked($op, @args)`.
  `future_class` is `DBIO::Forked::Future`. `deploy_async` and `pool` croak with a message
  naming DBIO::Forked.
- `DBIO::Forked::Future` — loop-free, pipe-backed; the full `DBIO::Future::Immediate`
  `future_class` surface (`done`/`fail`/`needs_all`/`and_then` plus the minimal
  `DBIO::Future` contract), because core's ResultSet/Row async helpers inflate in its
  `then` once the mode is active (ADR 0003 addendum). Never trim it to the minimal contract.
- `DBIO::Forked` — loadable entry point; loading registers the `forked` mode on core
  `DBIO::Storage::DBI` (`register_async_mode`). The registry and resolver live in core.

## How a query runs

`_run_forked` does `pipe` + `fork`.

- **Child** (`_forked_child_run`): calls `$schema->storage->$op(@args)` — the owner
  storage's ordinary **sync** CRUD, never a `*_async` method (that would re-fork). The
  inherited `_verify_pid` reconnects fresh, through the AccessBroker too. It freezes rows
  or error with `Storable`, writes the blob and leaves with `POSIX::_exit(0)` — `exit`
  would run DESTROY/END and tear down the parent's state.
- **Parent**: closes the write end and returns a leaf Future on the read end.

`_forked_child_run` shapes returns to the async contract (ADR 0031): `select` drains the
cursor with `->all` into raw rows, `select_single` wraps the column list into one row
arrayref, `insert` passes the returned-columns hashref through, `update`/`delete` ask for
the scalar count (the statement handle would not freeze), `txn_do` passes through.

Consequences kept without code here: `on_connect_do`/`on_connect_call` re-run in every
child (the reconnect is the ordinary `_connect`); the options beside a broker reach the
child through the owner storage (`broker_connect_options`).

## Invariants

1. Ship no DB-specific code and rebuild no SQL: the real driver does it in the child.
2. Touch no DBI handle and replay no `connect_info` — the reconnect belongs to the owner
   storage (ADR 0002). `connect_info` stores the form verbatim and reads nothing from it.
3. Dependency-free: core Perl (`fork`, `pipe`, `Storable`, `IO::Select`, `POSIX`) plus
   DBIO core. No `Future`, no `Future::IO`, no event loop.
4. `is_ready` is an EOF-clean non-blocking drain: accumulate across calls, ready only at
   EOF. A bare `can_read(0)` is true as soon as the child writes anything.
5. `get` blocks to EOF, thaws, reaps with `waitpid`, re-throws a stored error; it is
   idempotent and in scalar context returns the first value.
6. `then`/`catch`/`and_then` compose lazily and resolve synchronously at first force;
   `then` auto-wraps plain returns and flattens one returned future (core ADR 0031 §4).
7. `needs_all` calls `get` on each input in turn (children run in parallel already).
8. `DESTROY` closes the read end, then reaps with a blocking `waitpid`; no zombies. `$?`,
   `$!`, `$@` are localised; `${^CHILD_ERROR_NATIVE}` cannot be restored. A child that
   sent no blob fails the Future with `child killed by signal N` / `child exited with
   status N`, not `corrupt`.
9. Every shipped `.pm` under `lib/` carries a literal `our $VERSION`, all one value
   (`[@DBIO]` with `@Git::VersionManager`, `global = 1`, rewrites them in lockstep). Keep
   it in skeleton modules. dist.ini has no `heritage`: this is new code.

## Capabilities: exactly one, by intent

`transport_capabilities` returns `broker_connect_options` and nothing else (core k243).
Core hands DBD attributes and `pool_size` given beside a broker to the backend as
`[ $broker, \%options ]` only when the transport declares it. Model A keeps the promise
without code; `pool_size` sizes nothing.

Core's capability gate (`DBIO::Storage::DBI::_async_storage`) croaks for an async layer
that declares a requirement in `required_transport_capabilities` and for one that
declares nothing; only an explicit empty list exempts a layer. This is correct: layers
compose on the `_query_async` seam, Model A has none, so a composed layer would do
nothing. Advertise no capability to silence the croak — `on_connect_replay` least of all,
it names a pool-transport promise. A forked-aware layer needs its own capability axis, a
core/family decision. `broker_connect_options` describes no query path and is no
precedent. Engine capabilities belong to the owner storage, transport capabilities to the
backend. POD: `DBIO::Forked::Storage`, "TRANSPORT CAPABILITIES AND ASYNC LAYERS".

## Limits that shape the code

- Pipe buffer (~64 KB on Linux): a larger blob blocks the child until the parent reads;
  the argument for Model B (ADR 0003).
- No pool, no transaction pinning across `*_async` calls. `txn_do_async` runs one whole
  transaction in one child; its body returns serializable data (a live Row fails the
  Future via `_serialization_error`) and stays sync-only.
- Rotating broker with an expired lease in the parent: each forked query refreshes in its
  child and the refresh dies with it; the parent's broker changes only when the parent
  reconnects. The parent refreshing before the fork is not implemented
  (`t/09-broker-in-child.t` section 3; POD "ROTATING BROKERS AND AN EXPIRED LEASE").
- Unix fork only.

## Testing

Run recursively through the wrapper: `../dbio/maint/capped-test prove -lr t/` (from a
worktree: `~/dev/dbio-dev/dbio/maint/capped-test`). `prove -l t/` skips subdirectories.
Offline is the default; no database server, no event loop.

| File | Covers |
|------|--------|
| `t/00-load.t`, `t/01-fork-roundtrip.t`, `t/03-txn.t` | load, roundtrip via a mock sync storage, `txn_do_async` |
| `t/02-future.t`, `t/04-future-surface.t` | the Future contract, the full `future_class` surface |
| `t/05-sqlite-live.t` | real DBD::SQLite file database (skips without the driver) |
| `t/06-broker-connect-options.t` | options beside a broker, no DBD |
| `t/07-transport-paths.t` | all six `*_async`, `txn_do_async` failure modes |
| `t/08-fork-pipe-failure.t` | `fork()`/`pipe()` failure |
| `t/09-broker-in-child.t` | AccessBroker in the child, expired lease |
| `t/10-exit-status.t` | reaping leaves `$?`, `$!`, `$@` alone |
| `t/11-live-transport.t` | SQLite; PostgreSQL with `DBIO_TEST_PG_DSN` (+ `_USER`/`_PASS`) |

Live PostgreSQL uses this repo's database `dbio_forked`, never `dbio_test`; set it up per
the house rules' live-testing section (`maint/live-preflight` first).

## ADRs (docs/adr)

- 0001 — generic fork-per-query backend, sibling of `dbio-async`. Addendum: the
  activation model of core ADR 0028/0029 is superseded by the explicit `forked` mode of
  core ADR 0030; the decision stands.
- 0002 — the child reuses the inherited sync storage. Addenda: connection actions re-run
  in the child and why that is not `on_connect_replay`; the one capability
  `broker_connect_options`.
- 0003 — loop-free pipe-backed Future, EOF-framed, and its size limit. Addendum: the full
  `future_class` surface no longer rests on the withdrawn core ADR 0029 chain;
  `DBIO::Test::Future` is now `DBIO::Future::Immediate`.

Changing `@ISA`/`use base` of a component or storage class is an architecture change with
a ticket and an ADR.
