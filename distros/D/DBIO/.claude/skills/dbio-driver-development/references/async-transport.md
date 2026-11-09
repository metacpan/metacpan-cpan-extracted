# Async transport and AccessBroker seams

Reference for `dbio-driver-development`. Load when a driver ships an async adapter/backend or must answer a broker.

## AccessBroker

All drivers support AccessBroker. Pass broker to `Schema->connect($broker)` instead of raw DSN. **Broker interface and connect forms live in the dbio-core skill.**

- **Sync storage:** `DBIO::Storage::DBI` takes `[ $broker ]` / `[ $broker, \%options ]`, asks the broker on every connect, and builds the DSN of a connection-parameter answer (Static) for the DBD your storage class registered (`register_driver`). The schema declares your driver (ADR 0059, 0067), so the storage that builds it is yours.
- **`_connect_params_dsn($driver, \%params)`** (ADR 0057): override it when your DBD does not take the default form `dbi:<DBD>:dbname=…;host=…;port=…`. It gets your registered DBD name and only the parts given (`dbname`/`host`/`port`, defined and non-empty, no `;`) and returns the DSN string — nothing else: core removes the parts from the DBI attributes, resolves the driver, refuses `;` and takes a `dbi:…` dbname as the DSN before asking. A DBD with no form these parts can fill throws here, naming what it needs (core's ODBC storage does).
- **`_async_broker_conninfo($mode)`** (async transport; a direct `DBIO::Storage::Async` subclass such as an ev backend must provide it, the base croaks; `DBIO::Async::Storage` already provides it — a `future_io` adapter fills only `_normalize_conninfo`): turn the broker's current answer into one connection's conninfo. Core asks it anew for each new connection via `_conninfo_provider`, so rotated credentials reach the next one. The built-in brokers answer two shapes — connection parameters (Static, HostBound over it) and DBI form `[ $dsn, $user, $password, \%attrs ]` (Vault, HostBound over it). Take both; strip a DBI-form answer's attrs with `_strip_private_connect_attrs` (Vault selects the mode with `async` there, no DBD attribute); croak naming the shape, never the values. An empty answer is refused: read the answer through `current_access_broker_connect_info` (or `_current_async_connect_info`), which throws on `undef`, `{}`, `[]` or a false value, naming the broker class — never fall back to the conninfo `connect_info` stored.
- **`broker_connect_options`** in `transport_capabilities`: declare it once the transport applies the options an owner hands it beside the broker, `[ $broker, \%options ]` — `pool_size` sizes the pool (core `connect_info` does this; a transport overriding `connect_info` reads them via `_access_broker_call_options`), and the DBD attributes (`_access_broker_call_attributes`) are merged into every conninfo built from the broker with `_merge_access_broker_settings`. Undeclared, a broker connection whose options carry DBD attributes or `pool_size` refuses the transport at first async use. Core's async `_is_access_broker_connect_info` stays single-element, so an overriding `connect_info` never takes `[ $broker, \%options ]` for the bare form.
- **A broker comes and goes in one place** (karr core k273, k283, k293): `set_access_broker` attaches it on an async storage -- `_setup_access_broker` is the same call -- and forgets what the connect info before left (stored conninfo, pool size, options, what stood beside a broker). `clear_access_broker` detaches it and what came with it; the provider stays and refuses from then on, on the storage and in a pool built with it: the next spawn fails `<class> has no AccessBroker attached to ask for connect info`, and so does a listen connection opened through the provider. `_clear_access_broker` forgets the provider and the static slots too -- the state of a storage never given connect info. A transport overriding `connect_info` calls one of the two **before** it reads the new connect info, so a call that throws leaves nothing of the call before (ADR 0050). A detach on the owning sync storage detaches the embedded backend too; a backend not built yet is refused.

## Async Drivers (ADR 0030/0031)

Async is an explicit, **per-connection mode** (ADR 0030), not a separate storage
class chosen at schema-author time. A schema connected with
`connect(..., { async => $mode })` answers the six `*_async` storage methods and
the ResultSet/Row `*_async` helpers through an embedded async backend; without
`{ async => ... }` it stays sync (`*_async` croaks — no auto-fallback). An add-on
registers its mode on the core base storage:

    DBIO::Storage::DBI->register_async_mode( $mode => 'DBIO::SomeDriver::Backend::Storage' );

`forked` (and the core `immediate`) register generically on the base class; a
native `ev` mode is registered by the concrete *sync* driver storage, so
`{ async => 'ev' }` resolves DB-specifically. `future_io` is **not registered** —
the core resolver walks the concrete storage's linearised ISA, most specific first,
takes the first loadable `<class>::Async` (`DBIO::X::Storage` → `DBIO::X::Storage::Async`)
and stops before `DBIO::Storage::DBI`; an extension subclass without an adapter of its own
inherits its nearest parent's. An explicit `register_async_mode(future_io => ...)` on a
concrete class wins; a same-named class that is no `DBIO::Storage::Async` croaks; a driver
that ships none croaks early (ADR 0030 refinement, karr core k65).

**Async rides the same layers.** When a layered schema connects
`{ async => $mode }`, core (1) resolves the transport off the composition
**BASE** — the driver, never the layers (`_async_resolution_class` strips the
layers back out of the linearised ISA, so a sync layer's plain `<Layer>::Async`
mixin is never mistaken for the transport, karr core k70/k67) — then (2) mirrors each
registered sync layer `L` onto its async counterpart: if `L` *defines*
`async_layer_class($mode)`, its return value decides — a class name is loaded, `undef`
**states** "deliberately sync-only" (ADR 0032 addendum 2026-09-25, karr core k159);
if `L` does not define the method, the convention sibling `${L}::Async` is used. A sync-only
layer must declare itself that way — a layer with neither method nor sibling is refused
(karr core k159, no silent skip). Core composes the mirrors **on top of** the transport. One behaviour, one transport: an extension's async behaviour
rides every transport exactly as its sync behaviour rides every driver, with no
hand-written extension×transport matrix. An async mirror that declares
`required_transport_capabilities` the transport does not advertise croaks at
compose time naming the gap — and so does one that declares *nothing* onto a
transport without the default query seam (see the capability table below).

| Aspect | DBI | Async |
|--------|-----|-------|
| Base | `DBIO::Storage::DBI` | `DBIO::Storage::Async` |
| Protocol | DBD | native (EV::Pg/libpq, EV::MariaDB) |
| Returns | blocking | Future |
| Connection | single DBH | pool |
| Batching | no | pipeline (multi queries/round-trip) |

A `future_io` adapter (convention name `DBIO::X::Storage::Async`) subclasses the
shared `DBIO::Async::Storage` base (dist `dbio-async`) and overrides **only** the
DB-specific transport seams — the Model-B orchestration (CRUD runner, txn pinning,
pipeline, LISTEN/NOTIFY, `*_async`) is inherited from core `DBIO::Storage::Async` (ADR 0030 §4):

```perl
package DBIO::DriverName::Storage::Async;   # convention: ref($storage).'::Async'
use base 'DBIO::Async::Storage';             # shared Future::IO base

sub sql_maker_class     { 'DBIO::DriverName::SQLMaker' }
sub _transform_sql      { ... }   # '?' -> the DB's positional placeholder (see below)
sub _submit_query       { ... }   # send query bytes on the DBD's async binding
sub _collect_result     { ... }   # read the ready result
sub _conn_fileno        { ... }   # socket fd for the Future::IO watcher
sub _normalize_conninfo { ... }   # DBD conninfo shape
sub _create_pool_connection { ... }   # open one pooled connection
sub _shutdown_pool_connection { ... }
sub _conn_ready { ... }           # is the connection usable
sub _conn_error_is_fatal { ... }  # classify a dead connection (default 0)
# optional, LISTEN/NOTIFY (see below): _listen_open, _listen_close, _listen_subscribe,
# _listen_unsubscribe, _listen_probe, _listen_drain, _notify_sql
```

#### The `?` placeholder seam — shaped once, in the transport

The SQLMaker is **shared with the sync DBI driver**, which needs SQL-standard
`?` placeholders, so the maker MUST keep emitting `?`. Any per-DB placeholder
rewrite (PostgreSQL `?` → `$N`, Oracle `?` → `:N`, …) lives in the transport's
`_transform_sql` seam, which the inherited `DBIO::Storage::Async::_query_async` /
`_query_async_pinned` invoke **once, internally**, on the maker's output before
it reaches the wire. **Callers never shape** — no code path outside the transport
touches placeholders, and there is no second/double shaping. `_transform_sql` is
a required seam (the base croaks until provided): a DB whose wire already takes
`?` overrides it to identity; a DB that needs positional placeholders rewrites
there (and only there). Test the seam directly (`$Adapter->_transform_sql($sql)`)
— that *is* the contract; do not re-add caller-side shaping in tests.

An `ev` backend (`DBIO::X::EV::Storage`) does the same over its native
event-loop client. Both must honour the resolution-shape contracts (ADR 0031 §3)
so the core
RS/Row helpers inflate uniformly: `select_async` → raw row arrayrefs (cursor
`->all` shape), `select_single_async` → a single arrayref, `insert_async` → the
returned-columns hashref sync `insert` returns; the Future's `then` must
auto-wrap plain returns (ADR 0031 §4).

#### LISTEN / NOTIFY — core contract, transport seams (ADR 0056)

`listen($channel, $cb)`, `unlisten`, `notify($channel, $payload)`, `listen_alive` and
`listen_reconnect` are core async API on `DBIO::Storage::Async`, one contract on every
transport; a callback gets `($channel, $payload, $sender_pid)`. Core owns the machinery:
one dedicated listen connection outside the pool, the channel registry, one channel
operation in flight per connection, self-healing (`on_listen_error` → close → backoff
`listen_backoff_initial`/`listen_backoff_max` → reopen → re-subscribe **every** channel →
re-arm → `on_listen_reconnect`), and the fork guard (only the opener pid touches the
connection). The public methods are gated by capability **name**: `listen` in
`transport_capabilities` for the listen side, `notify` for `notify`; without it they throw
`LISTEN/NOTIFY not supported by this storage driver` before any state is touched.

A transport fills the seams; each croaks until provided, and a Future-returning seam may
return a plain value when its work is already done:

| Seam | Obligation |
|---|---|
| `_listen_open` → Future of `$conn` | a **new** connection, never pooled, current connect info (fresh broker creds), fork-safe (DBD: `AutoInactiveDestroy => 1`) |
| `_listen_close($conn)` | close; tolerate an already-dead connection |
| `_listen_subscribe` / `_listen_unsubscribe($conn, $channel)` → Future | quote or validate the channel here (ADR 0017 §3); may be local bookkeeping for an emulation |
| `_listen_watch` / `_listen_unwatch($conn)` | start / stop delivery; watched from the moment `_listen_watch` is called, so callbacks may fire from inside it; a throw counts as death |
| `_listen_probe($conn)` | synchronous liveness; false or a throw = dead |
| `_listen_delay($seconds)` → Future | the backoff timer (core has no loop); must resolve asynchronously, from the loop |
| `_notify_send($channel, $payload)` → Future | payload as a bind value only; any connection, typically pooled |

The transport calls back: `_listen_dispatch($channel, $payload, $sender_pid)` per
notification in arrival order, `_listen_lost($conn, $error)` on death,
`_listen_error($error)` for a non-fatal error (a failed cleanup) — never a reporter of its
own. A **pending** Future a listen seam returns must answer `->new` on the instance: core
makes the caller's Future from it, so `listen(...)->get` runs the transport's loop.

Watching is the transport's choice: **socket-driven** (watch the socket, drain, watch
again — PostgreSQL, `$sender_pid` = backend pid) or **timer-driven** emulation (poll a
notify table past a high-water mark — MySQL/MariaDB, `$sender_pid` = `CONNECTION_ID()`).
An emulation may declare `listen`/`notify` if its POD states the poll-interval latency and
on-commit delivery; core has no poll mode of its own. On `future_io`,
`DBIO::Async::Storage` already fills `_listen_delay`, the watch loop
(`_listen_watch`/`_listen_unwatch`) and the pooled `_notify_send`; the adapter adds
`_listen_open`/`_close`/`_subscribe`/`_unsubscribe`/`_probe`, `_listen_drain` (pending
notifications, never blocking) and `_notify_sql` (SQL + binds), optionally
`_listen_poll_interval` (seconds ⇒ timer mode), then appends `qw(listen notify)` (and `broker_connect_options`, once it applies broker call options) to
`transport_capabilities`. Overriding `listen`/`unlisten`/`notify` wholesale bypasses all
of this and leaves `listen_alive`/`listen_reconnect` blind — not a supported design.

#### Transport capabilities

A transport advertises what it supports via the `transport_capabilities` class
method; an async layer gates on it with `required_transport_capabilities`, and a
shortfall croaks at compose time (a transport gap becomes *that transport's*
ticket, never a silent feature loss).

**Declaring nothing is not the unchecked case** (ADR 0032 addendum, karr core k118).
A layer with no `required_transport_capabilities` is taken to require the
default async query seam `_query_async`, and a transport that does not provide
it refuses the composition. Otherwise the protection worked by declaration
rather than by seam: the well-behaved layer was stopped, the silent one was
not — and a layer composed onto a transport owning no query path (Model A,
`DBIO::Forked::Storage`) would load, compose and then do nothing. A layer that
genuinely needs nothing says so with an explicit empty list; that is an
assertion its author owns, whereas silence carries no information.

The seam is probed by comparing the resolved `_query_async` against the
abstract stub on `DBIO::Storage::Async` — not `can()` alone (the stub makes it
true everywhere) and not as a capability *name* (no transport advertises a
seam in `transport_capabilities`, so a name check would refuse every existing
composition).

The two async transports for a driver carry different capability sets:

| Feature | `future_io` (`DBIO::Async::Storage` base) | `ev` (`DBIO::X::EV::Storage`) |
|---|---|---|
| `on_connect_replay` (on_connect_do/call on pooled conns, karr core k68) | ✅ advertised | ✅ |
| pooled CRUD + `txn_do_async` pinning | ✅ | ✅ |
| LISTEN / NOTIFY (`listen`, `notify`) | ✅ Pg (native), MySQL (emulated) — declared by the adapter | ✅ Pg (native), MySQL (emulated) |
| COPY | ❌ | ✅ Pg only |
| pipeline (batch queries/round-trip) | ❌ (core `pipeline` refuses with a failed Future) | ✅ Pg; ❌ MySQL (EV::MariaDB has no pipeline mode to bracket) |

The generic `future_io` base advertises exactly `on_connect_replay`; an adapter
adds `listen`, `notify` and `broker_connect_options` once it fills the driver half of the listen seams
(above). COPY and pipelining ride only the PostgreSQL `ev` backend. An add-on
needing those must select that mode (or the transport's dist grows the
capability). `listen`/`notify` also gate core's own public methods; `pipeline`
does not — core's `pipeline` works iff the transport overrides `_pipeline_enter`
(seam probe, karr core k218), and the name matters only to layers.

Implemented:
- **DBIO::PostgreSQL::EV** (EV::Pg, libpq): the `ev` mode — native event-loop client: LISTEN/NOTIFY (native, on core's listen seams), COPY, pipeline (libpq pipeline mode), txn pinning. Sync methods block via `->get`.
- **DBIO::MySQL::EV** (EV::MariaDB): the `ev` mode — native event-loop client: LISTEN/NOTIFY emulated (notify table polled on an EV timer, shared `DBIO::MySQL::NotifyTable`), txn pinning; no COPY, no `pipeline` (EV::MariaDB exposes no pipeline mode). Sync methods block via `->get`.
- **DBIO::Forked** (fork + pipe, any driver): the `forked` mode — no event loop, works for every driver (ADR 0030).
- **DBIO::Async** (Future::IO): the `future_io` mode — the abstract `DBIO::Async::Storage` base over a driver's own async binding (`pg_async`/`mysql_async`); each driver supplies a convention-resolved adapter `DBIO::X::Storage::Async` that fills the transport seams. No adapter yet ⇒ `future_io` croaks early for that driver. LISTEN/NOTIFY: `DBIO::PostgreSQL::Storage::Async` (socket-driven, `pg_notifies`), `DBIO::MySQL::Storage::Async` (emulated, notify table).
