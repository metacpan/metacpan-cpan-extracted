# ADR 0002 — The forked child reuses the inherited sync storage

- Status: accepted
- Date: 2026-06-28
- Tags: async, fork, storage, fork-safety, access-broker

## Context

A fork-based backend has to run a real DB operation in the child. The naive
route is for `DBIO::Forked` to do everything itself: build SQL (its own
SQLMaker), reconnect fresh from `connect_info`, and handle the fork trap (a
child must not destroy the parent's shared DBI socket).

But DBIO is a DBIx::Class fork and inherited its **fork handling**:
`_verify_pid` in `DBIO::Storage::DBI` sets `InactiveDestroy` on the inherited
handle when the PID changes and `_get_dbh` reconnects fresh — run automatically
before every CRUD / transaction op.

## Decision

The child calls the **ordinary sync CRUD of the inherited primary sync storage**
— `$self->{schema}->storage->$op(@args)`. It re-implements no SQL, touches no
DBI handle, sets no `InactiveDestroy`, and replays no `connect_info`.

- The inherited `_verify_pid` fork handling does the `InactiveDestroy` + fresh
  reconnect in the child by itself.
- That reconnect runs through the sync storage's normal connect path, so a
  configured **AccessBroker** is honoured too — each child reconnects with fresh
  credentials, for free.
- **Anti-recursion**: the child calls the *sync* method (`select`), never
  `select_async` — sync does not route to the async backend (ADR 0028), so there
  is no re-fork.

## Consequences

- Forked is extremely thin: `fork` → inherited sync CRUD → `Storable::freeze` →
  `_exit`. All the heavy lifting (SQL, reconnect, fork-safety, broker) is the
  real driver's, done once in the child.
- The `connect_info` the core resolver hands Forked is **dead weight in Model A**
  — never consumed. It is stored verbatim as latent diagnostics / raw material
  for a possible future "fresh storage" variant, and the POD marks it as
  informational.
- This relies on the inherited sync storage surviving the `fork()` in the
  child's memory (a strong schema ref exists at call time). For Model A's
  short-lived child this holds.

## Addendum 2026-07-26 — connection actions re-run in the child

The decision above notes that fork-safety and the AccessBroker come for free
because the child reconnects through the inherited sync storage. One more thing
comes with them, unnamed until now: the schema's **connection actions**.

`_verify_pid` sees the new PID and lets `_get_dbh` reconnect; that reconnect is
the ordinary `DBIO::Storage::DBI::_connect`, and `_connect` calls
`_run_connection_actions`, which dispatches `on_connect_call` and the parsed
`on_connect_do`. So every forked child starts from a connection configured
exactly like the parent's — session settings, encodings, `SET search_path`,
`ALTER SESSION`, a `connect_call_*` method — with no code in `DBIO::Forked` and
nothing for the caller to enable. It is not a feature this dist implements; it
is a property of Model A, and it is now documented (`DBIO::Forked::Storage`,
"CONNECTION ACTIONS IN THE CHILD") and tested rather than merely read out of the
core sources.

Verified by `t/05-sqlite-live.t`: the schema connects with an `on_connect_do`
that creates a SQLite **temporary** table and stamps the connecting process's
pid into it. A temp table belongs to one connection, so reading that table from
inside a `txn_do_async` body proves both halves at once — the child really runs
on its own fresh connection (not the parent's handle), and the connection
actions ran on *that* connection, because the pid it finds is the child's own.

### Deliberately not the `on_connect_replay` capability

This property must not be advertised as the `on_connect_replay` transport
capability, and `DBIO::Forked::Storage` advertises it as little as anything else
— it declares no transport capabilities at all. Two reasons:

- **The name promises something else.** `on_connect_replay` exists for **pool**
  transports, which open connections outside the sync connect path and therefore
  have to replay the actions themselves (`_run_pool_connect_actions`, core
  karr k68). Model A has no pool and never had that problem, so the name would
  describe the wrong mechanism even though the observable effect matches.
- **Family-wide it is de facto the switch that lets an async layer compose.** A
  layer that composed onto Model A would not run: it hooks `_query_async`, which
  this backend does not have, because the child executes the driver's sync CRUD
  (`_forked_child_run`). Declaring the capability would buy exactly the silent
  feature loss the capability gate exists to prevent, in exchange for a croak
  that is currently correct (core ADR 0032 §5).

The general form of that limit — Forked is capability-free by intent, because no
async layer can compose onto Model A's seam — is recorded in
`DBIO::Forked::Storage` under "TRANSPORT CAPABILITIES AND ASYNC LAYERS" and in
the "Known limits" lists in `CLAUDE.md` and the `dbio-forked` skill. Should a
forked-aware layer ever be wanted, it needs its own capability axis (a name for
"sync CRUD in the child"); that is a core / family decision, not one this ADR
makes.

## Addendum 2026-10-04 — one capability, read by core: `broker_connect_options`

The first addendum says `DBIO::Forked::Storage` "declares no transport
capabilities at all". Since karr k12 it declares exactly one,
`broker_connect_options` (core karr k243, core ADR 0030 addendum II). The
sentence is left as written; this is what changed and what did not.

Core takes connect options beside an AccessBroker —
`connect($broker, { async => 'forked', AutoCommit => 1, … })`. The ones a
backend applies itself, DBD attributes and `pool_size`, it hands to the
embedded backend as `[ $broker, \%options ]`, but only to a transport declaring
`broker_connect_options`; any other is refused at first async use, because its
own connections would be opened without settings the sync connection has. That
refusal protects pooled transports. Under Model A it had nothing to protect and
only kept a broker-backed connection from carrying a single DBD attribute in
the `forked` mode.

The declaration is kept by the decision of this ADR, with no code beside it:
the only connection a query runs on is the one the inherited sync storage
opens in the child, and that storage asks the broker again and joins the
options beside it into the answer on every connect. `pool_size` sizes nothing —
there is no pool — and stays out of the child's `DBI->connect`, with a broker
as with a DSN. The `connect_info` the resolver hands over stays dead weight,
now possibly in the form `[ $broker, \%options ]`. Verified by
`t/06-broker-connect-options.t` (what the owner storage hands to `DBI->connect`
in the child, no DBD involved) and section 7 of `t/05-sqlite-live.t` (a real
DBD handle in the child).

What stands unchanged: `broker_connect_options` is read by core, not by async
layers, and names no query path. Forked still declares no capability a layer
could require and has no `_query_async` seam, so both reasons under
"Deliberately not the `on_connect_replay` capability" hold as written, and so
does the rule never to silence the layer gate by advertising a capability.
"Capability-free by intent" now reads: free of layer capabilities.

## Addendum 2026-10-30: the backend holds no access data

The `connect_info` the core resolver hands to the backend is not read on any
path: the child's connection is the owner storage's own. The backend therefore
keeps the form of it only — broker or not, and the number of elements,
answered as `{ broker => 0|1, elements => N }` — and no DSN, user, password,
attribute, broker object or options hash. The decision of this ADR stands;
`t/13-no-credentials.t` pins that a dump of the backend holds none of it
(karr k28).
