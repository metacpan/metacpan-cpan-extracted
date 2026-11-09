# ADR 0049 — Async pool replays `on_connect_do` / `on_connect_call` on every pooled connection

- Status: accepted
- Date: 2026-09-09
- Tags: async, pool, connect-info, extension, cross-driver, family-policy

> Accepted with the implementation committed in karr k68 (2026-07-07).
> Sibling of k66 / ADR 0048, which closes the attribute-strip half of the
> same sync/async divergence.

## Context

`on_connect_do` / `on_connect_call` (and their `on_disconnect_*` twins) are
session-setup hooks: the user declares "on every connection this storage
opens, run these statements." A typical payload: a `SET TIME ZONE`, a
`SET search_path` for PostgreSQL extensions, a `LOAD 'age'` for Apache AGE,
an engine-specific session variable.

The sync path runs the hooks — `_determine_driver` → `_run_connection_actions`
after each real `DBI->connect`. Every physical connection the user ever
holds has been through the hooks.

The async path did not. `DBIO::Storage::Async` pool spawn →
`_create_pool_connection` (adapter's `DBI->connect` or native client) →
connection goes straight into the pool. **No hook, no warning.**

Two consequences:

1. **Silent divergence on the same instance.** A user with session setup in
   `on_connect_*` got different session semantics between
   `$schema->resultset(...)` (sync, configured) and `*_async` (pool,
   unconfigured) on the **same** storage. The fail-loud rule (house rule
   10) was being violated — the user did not opt into the difference, the
   system imposed it silently.

2. **Hard blocker for extension async.** Apache AGE needs
   `LOAD 'age'` + a `SET search_path` per connection (the
   `connect_call_load_age` hook in `dbio-postgresql-age`). With no pool
   hook, an AGE async adapter is structurally impossible — the session
   state it requires cannot be established on a pooled connection.

ADR 0030 named this as a "tracked seam": the explicit per-connection mode
that future async work has to land on. The seam was tracked but the
*contract* — "the same `on_connect_*` runs on every pooled connection" —
was never recorded. This ADR records it.

## Decision

The async pool runs the **same** `on_connect_do` / `on_connect_call` the
sync storage got, on **every** pooled connection, at spawn time, in
**one** central place.

Concretely:

- The hook lives in core, at pool-spawn time:
  `DBIO::Storage::PoolBase::_spawn_connection` runs it through
  `DBIO::Storage::Async::_setup_pool_connection` on the storage the pool was
  built with (its `storage` back-reference) — after the pool's
  `_create_connection` (on a `future_io` adapter, its
  `_create_pool_connection`) returns the connection, **before** it is handed
  to a caller. One place for every backend (`future_io` PG/MySQL,
  `ev`). A driver with its own pool integrates at this seam; there is no
  per-driver copy of the hook.

- The actions arrive via `connect_info` `storage_options` — and **stay**
  there. ADR 0048's central strip keeps them out of `DBI->connect` while
  retaining them for this hook. A user configures the instance once; every
  physical connection, pooled or not, runs the same actions.

- The replay is best-effort with the connect-action failure rule of ADR
  0047: if the replay fails, the connection is retired (not counted against
  `max_size`) and the failure surfaces as a failed Future. The hook never
  throws past the Future seam.

- `on_disconnect_*` is the symmetric concern and is **out of scope here**:
  ADR 0047 records that retirement does not run them, and a future ADR
  will land the policy for the teardown path. Until that lands, drivers
  that need teardown semantics override `_retire_connection` themselves
  and document the override in their ADR list. (The shutdown half was never
  open — see the addendum of 2026-10-04.)

## Rationale

The naive design — "the user opts into async and configures session hooks
separately for async" — looks symmetric but it isn't. The user already
configures session hooks; making them repeat the configuration for async
is a second source of truth, which is exactly what this ADR exists to
remove. The hooks must follow the storage, not the mode.

The "one central place, every backend" rule is non-negotiable: a hook that
lives in each backend is the same bug k66 was for attributes. The async
backend is pluggable (AnyEvent, IO::Async, native), and each pluggable
backend carries its own `_create_pool_connection`; the hook must live
above that, not next to it. `DBIO::Storage::Async` is the right layer —
it is the layer that knows the pool, not the layer that knows the
transport.

The "retire on failure" rule (ADR 0047) is the precondition. Without it,
the hook's failure mode is the leak: a connection that fails the replay
sits in `_connections` and counts against `max_size`. ADR 0047 is the
fix; this ADR assumes it.

The `on_disconnect_*` deferral is intentional. The connect-side hook has
one obvious policy (run on every spawn); the disconnect-side hook has two
sensible policies (run on graceful retire, run on every release) and the
right answer depends on what the actions *do* — a `RESET ALL` is fine on
every release, a `UNLISTEN *` is not. The split is deliberate: land the
connect side with a clear rule, leave the disconnect side for a future ADR
when the policy can be stated without speculation.

## Consequences

- A user with `on_connect_do` / `on_connect_call` configured on a storage
  gets the same session semantics on every connection the storage ever
  opens — sync, async-pooled, async-released-and-reused, extension async.
  No second configuration surface; no silent divergence.

- `dbio-postgresql-age`'s `connect_call_load_age` works against an async
  pool. The AGE adapter ticket on the age board unblocks.

- A driver with its own pool that wants to bypass the central hook has to
  override `_retire_connection` (or its connect-side counterpart) and
  document the override. The default is "the central hook ran, the
  connection is part of the storage's session contract."

- `t/storage/pool_connect_actions.t` (introduced with ADR 0047) and the
  follow-ups in each async backend's test surface pin the contract: the
  hook ran, the hook ran once per spawn, the hook's failure retires the
  connection and returns a failed Future.

- `on_disconnect_*` policy is **not** settled by this ADR. Drivers that
  need a specific teardown semantic say so in their own docs and override
  the base behaviour, until a follow-up ADR lands the policy. (What the base
  behaviour is: the addendum of 2026-10-04.)

## Future architecture work (tracked cross-repo, not here)

- `dbio-postgresql-age` karr: AGE async adapter that depends on the
  `connect_call_load_age` hook. Owned by that repo; this ADR unblocks it.
- `dbio-async` karr: tests pinning "the hook ran on every spawn" against
  the `AnyEvent`/`IO::Async` backends. Owned by that repo; this ADR
  defines the rule.

## Companion

ADR 0048 — the attribute strip that keeps `on_connect_*` actions out of
`DBI->connect` while retaining them for this hook. They are siblings: the
strip without the hook would leak the actions silently; the hook without
the strip would crash the DBD on the leaked `async` attr.

## Addendum 2026-10-04 — `on_disconnect_*` do run, at pool shutdown (karr k280)

The Decision and the Consequences above call the disconnect side out of scope
and its policy unsettled. For the shutdown path that was never so: the change
this ADR records (karr k68) shipped the teardown half together with the replay,
and ADR 0030 §5 (the amendment of 2026-09-15) states its rule. What holds:

- **At pool shutdown they run.** `DBIO::Storage::PoolBase::shutdown` runs the
  owning storage's `on_disconnect_call`, then its `on_disconnect_do`, through
  `DBIO::Storage::Async::_teardown_pool_connection`, against every connection
  that reached readiness — while it is live, before `_shutdown_connection`
  closes it. Both steps are best-effort: an action that fails does not stop the
  close. `t/storage/pool_connect_actions.t` pins it.
- **Not against a connection still coming up.** It is retired and closed once,
  without disconnect actions (ADR 0030 §5; for a readiness Future the transport
  made itself, karr k262, `t/storage/pool_shutdown_coming_up.t`). Global
  destruction is the exception the `shutdown` POD names.
- **Not on retirement.** `_retire_connection` — a connect action refused, a
  connection reported dead, a readiness failure — runs none (ADR 0047).
- **Not on `release`.** A connection that goes back to the idle list keeps its
  session.

So no driver has to override `_retire_connection` to get its teardown at
shutdown; that override is only for a driver that wants the actions on
retirement as well (ADR 0047, Consequences). Neither of the two policies the
Rationale weighs — on graceful retire, on every release — is what the code
does: a connection's disconnect actions run once, when its pool is shut down.

## Addendum 2026-10-10 — the seam is `_create_connection`, not `_create_pool_connection` (karr k290)

The Context and the Decision above name `_create_pool_connection` as what
the spawn path calls before the hook, and the Rationale says every backend
"carries its own `_create_pool_connection`". That is the name of one
transport's seam, not of the pool's:

- `DBIO::Storage::PoolBase::_spawn_connection` calls the pool's
  **`_create_connection`** (`_transform_conninfo` before it, the hook
  after). That is the seam every pool fills.
- On `future_io`, `DBIO::Async::Pool::_create_connection` delegates to the
  owning storage's `_create_pool_connection`
  (`DBIO::Async::Storage`, filled by `DBIO::<Driver>::Storage::Async`).
- The `ev` pools (`DBIO::PostgreSQL::EV::Pool`, `DBIO::MySQL::EV::Pool`)
  implement `_create_connection` themselves and have no
  `_create_pool_connection`; they take the same hook because it lives in
  `_spawn_connection`.

The decision is unchanged: one hook, in `_spawn_connection`, after the
connection exists and before it is handed to a caller. Read
`_create_pool_connection` in the text above as "the pool's
`_create_connection`" and, on `future_io`, "its adapter's
`_create_pool_connection`". A driver with a pool of its own implements
`_create_connection` (and `_shutdown_connection`); nothing else is needed
for the hook to reach it.

## Addendum 2026-10-24 — a connect action reads rows through the runner (karr k358)

A connect action may read as well as write. The runner
`_run_pool_connect_statement($conn, $sql, $attrs, @bind)` returns the rows of
the statement when `$attrs` carries the reserved key `dbio_rows`: an array
reference of rows (array references, as `selectall_arrayref` without a slice).
Without the key it executes the statement and returns nothing. The default
runner reads with `$dbh->selectall_arrayref($sql, undef, @bind)` and does not
pass the key to DBI; a backend that overrides the runner honours the key the
same way.

`DBIO::Storage::DBI::_pool_connect_rows($sql, @bind)` is the one read a
`connect_call_*` makes. Inside the pool replay it asks the runner with
`{ dbio_rows => 1 }`; on the sync connection it reads through `dbh_do` on the
storage's own handle. Both paths mask the statement's secrets in a failure as
`_do_query` does.
