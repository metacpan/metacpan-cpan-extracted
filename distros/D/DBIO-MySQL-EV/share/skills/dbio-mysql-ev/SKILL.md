---
name: dbio-mysql-ev
description: Load when working on the DBIO::MySQL::EV driver — the EV::MariaDB `ev` async transport, its Future API, Pool, transaction pinning, AccessBroker wiring, and why it has no pipeline mode.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::MySQL::EV

The native `ev` async transport for MySQL/MariaDB (core ADR 0030 / 0031). Speaks
MariaDB's C client library through EV::MariaDB — no DBI, no DBD::mysql.

## Namespace

| Class | Purpose |
|---|---|
| `DBIO::MySQL::EV` | Marker component: no methods, no `connection()` hook |
| `DBIO::MySQL::EV::Storage` | The transport — a `DBIO::Storage::Async` subclass |
| `DBIO::MySQL::EV::Pool` | EV::MariaDB connection pool — a `DBIO::Storage::PoolBase` subclass supplying the connection seam (`_create_connection` / `_new_connection` / `_shutdown_connection`), the fork guard (`_verify_pid`), the gone-connection check (`_mysql_connection_gone`) and its borrow-time use (`_idle_connection_alive`), the marked waiter (`_new_waiter`) and the held-by-callbacks check (`_mysql_held_by_callbacks`) |
| `DBIO::MySQL::EV::QueryExecutor` | Wire seam: EV::MariaDB `query` vs prepare/execute; settles Futures from an idle watcher (k51); knows per connection whether one of its settlings runs and whether a statement is in flight |
| `DBIO::MySQL::EV::Future` | The transport's `future_class` — a `Future` whose `await` runs the EV loop, and refuses a blocking wait that cannot end |
| `DBIO::MySQL::EV::TransactionContext` | Pinned connection for `txn_do_async` — thin subclass of core's `DBIO::Storage::Async::TransactionContext`, adds only the `txn_mdb` alias |
| `DBIO::MySQL::EV::ConnectInfo` | `dbi_to_conninfo` — DBI DSN → EV::MariaDB named params |
| `DBIO::MySQL::EV::TestHarness` | Installable live harness; ships under `lib/`, not `t/` — thin subclass of core's `DBIO::Test::AsyncHarness`, adds four declarations, `_tick_loop` and the default schema |

## Reaching the transport

Async is an explicit per-connection mode (ADR 0030). The `ev` mode is registered
by the **sync** driver — `DBIO::MySQL::Storage` calls
`register_async_mode( ev => 'DBIO::MySQL::EV::Storage' )` — and core resolves it
by walking the *storage* MRO. The schema's component list takes no part in it.

```perl
package MyApp::Schema;
use base 'DBIO::Schema';
__PACKAGE__->load_components('MySQL');   # the driver: picks the sync storage

my $schema = MyApp::Schema->connect(
    'dbi:MariaDB:database=myapp;host=localhost', $user, $pass,
    { async => 'ev' },
);
```

`load_components('MySQL::EV')` is a **no-op marker**. The component defines no
methods at all: it pins no `storage_type`, and it does not make the `ev` mode
resolvable — with or without it, `{ async => 'ev' }` is what activates the
backend. That inertness is the contract (ADR 0032 §7: an extension never decides
the driver; karr k14 was a `connection()`/`storage_type` hijack here, and
`t/00-load.t` now guards it mechanically).

`async_backend(...)` was removed from core. Any code or doc reaching the backend
that way is stale — the only opt-in is `{ async => 'ev' }` at connect.

The DBI DSN is translated to EV::MariaDB named parameters by
`ConnectInfo::dbi_to_conninfo` (`dbname` → `database`), which takes
`[$dsn, $user, $pass, \%attrs, \%extra_attributes]`. Of the two attribute
hashes only `pool_size` is read (default 5), the later one winning; DBI attributes
and the storage's own are dropped — there is no DBD here, and EV::MariaDB croaks on an
argument it does not know. A `mysql_*`/`mariadb_*` attribute EV::MariaDB has a
parameter for is read like the same DSN key (`mysql_enable_utf8mb4` is `charset =>
'utf8mb4'` + `utf8 => 1`; DBD::mysql only), any other is refused, named (karr k80).
Every handle is made with `found_rows => 1` (CLIENT_FOUND_ROWS, as the DBDs;
`mysql_client_found_rows=0` turns it off), `Pool::_mysql_new_handle`.

No message quotes a password (karr k76): every text that names connect info or
passes on the client library's goes through core's
`DBIO::Util::mask_connect_secrets` — the DSN `dbi_to_conninfo` does not read,
the croak of `EV::MariaDB->new` and every `on_error` text (both in
`Pool::_mysql_new_handle`, the one place every handle is made — pooled and the
listen connection, never `EV::MariaDB->new` directly), and the pool's warning.
A new message about a connection names shapes and keys, or is masked the same
way. Pinned by `t/40-no-password-in-messages-mock.t`.

A hash answer of a broker is this transport's shape, and a **schema's** sync
owner takes less of it (core's rules, held by
`t/41-access-broker-client-parameter-mock.t`): it needs a `dbname` (or `dsn`) —
without one `Schema->connect` throws — and it refuses a hash carrying a client
parameter (`charset`, …) when it opens its dbh (core k298), while the pool
connects with it. A test broker that answers a schema therefore answers
`dbname`, and a client parameter for a schema's pool comes from
`connect_info_for_storage`.

## AccessBroker

The connect options go beside the broker, or the broker goes to the transport
directly:

```perl
my $schema  = MyApp::Schema->connect($broker, { async => 'ev', pool_size => 10 });

my $storage = DBIO::MySQL::EV::Storage->new(undef);
$storage->connect_info([$broker]);                       # per-spawn credential provider gets wired
$storage->connect_info([$broker, { pool_size => 10 }]);  # with connect options beside it
```

The transport declares `broker_connect_options` (karr k59), so core hands it
the options beside a broker as `[ $broker, \%options ]` whenever they hold
something a backend applies (`pool_size`, DBD attributes); the owner's own
options alone leave it the bare `[ $broker ]`. The `connect_info` override
takes the two-element form only through core's seams — never a reading of its
own: `_strip_private_connect_attrs` + `_access_broker_call_options` split the
options, `_access_broker_pool_size($answer, $beside)` sizes the pool (answer
hash, DBI-form slots [3]/[4], beside the broker; answer and beside must agree
or it throws naming `pool_size`). DBD attributes beside the broker are dropped
like the same keys in DBI-form connect info. The declaration is a promise:
`t/30-access-broker-connect-options-mock.t` holds the behaviour behind it.

A connection parameter beside the broker (`charset`, `connect_timeout`,
`host`, any lowercase key that is no DBI attribute by core k298's measure:
uppercase first letter, `private_`, `dbi_`, `dbd_`, and here both `mysql_` and
`mariadb_`, since the transport is not told which DBD the owner uses) is
refused, never dropped (karr k78): `_mysql_refuse_parameters_beside_broker`
croaks naming the keys, no value, from `connect_info` and again from
`_async_broker_conninfo` for every connection, so a refused storage opens
nothing. Through a schema that is the first `->async`, not `connect`; the
owner refuses the same key for its own dbh (core k307). Such a parameter
belongs in the broker's answer. Pinned by
`t/39-access-broker-parameters-beside-mock.t` and its `-live.t`.

The broker is re-consulted per pooled connection through `_async_broker_conninfo`,
so rotating credentials reach new connections without a pool teardown. The
listen connection asks it the same way at every open.

`_async_broker_conninfo` reads every built-in broker's answer into EV::MariaDB
**named parameters** (karr k60) — EV::MariaDB parses no DSN and croaks on an
argument it does not know, so a string must never reach it:

| Answer | Broker | Read as |
|---|---|---|
| `[ 'dbi:mysql:…' \| 'dbi:MariaDB:…', $user, $pass, \%attrs ]` | Vault, HostBound over it | `dbi_to_conninfo`: DSN parts + user + password; of `\%attrs` (and a fifth-element hash) only `pool_size` |
| `{ host, port, dbname, user, password }` | Static, HostBound over it | as is, `dbname` → `database` |
| `[ \%conninfo, \%opts ]` | a custom broker | as is |

Anything else (a DSN for another driver, a plain string, a coderef) croaks via
`_mysql_broker_connect_info`, naming the **shape**, never a value — the answer
carries the password. So does an answer in one of these shapes that names
**neither `host` nor `user`**: `EV::MariaDB->new` starts a connect only when
given one of the two, and otherwise returns a handle that never connects and
never calls back, so the pool's `acquire` would never resolve. `connect_info`'s
broker branch reads the first answer through the same helper, so an unusable
broker is refused at attach. A Vault broker may pick this transport in its own
attributes: `dbi_attrs => { async => 'ev' }`.

**A whole DSN as the database name is refused, never read** (karr k63):
`Static->new(dbname => 'dbi:mysql:…')` is the form core's sync storage takes as
the DSN, but the broker still answers a hash — the DSN would become the
database name, no host would be given, and EV::MariaDB would connect to the
client library's default (the local server) with the broker's credentials. The
same helper refuses it (`dbi:` at the start of `dbname`/`database`/`db`), at
attach and for every connection, under a HostBound view too, saying nothing of
the DSN. Do not turn this into "read the DSN": the decision is to refuse. The
broker answers the DBI form, or `dbname` with `host`/`port` beside it.

**A broker connection is opened from the broker's current answer or not at
all** (karr k62, core k252). `connect_info([$broker])` — with or without
options beside the broker — reads the answer once —
to refuse an unusable one, and for its `pool_size` — and stores no conninfo:
`{_conninfo}` is `undef` with a broker attached, and `_conninfo_hash` returns
the *static* conninfo only. Nothing falls back to an earlier answer:

- `clear_access_broker` (public, on `DBIO::Storage`) leaves the per-spawn
  provider in place — on the storage and in a pool already built with it.
  `_async_broker_conninfo` croaks `no AccessBroker attached` there instead of
  reading core's `_current_async_connect_info`, which answers the *stored*
  conninfo when no broker is attached.
- After `_clear_access_broker` (broker and provider gone) a storage has nothing
  to connect from until `connect_info` is called again: `pool` croaks
  `conninfo or conninfo_provider required`, `_listen_open` croaks
  `the listen connection has no connect info`.

Never store a broker's answer, and never add a fallback to stored conninfo on a
path a broker connection takes. Pinned offline by
`t/29-access-broker-conninfo-mock.t`.

## Async API — signatures and resolution shapes

The six `*_async` methods are **inherited** from `DBIO::Storage::Async` and take
source/SQLMaker arguments, never raw SQL strings:

```perl
$storage->select_async($source, $select, $where, $attrs);   # → raw row arrayrefs
$storage->select_single_async($source, $select, $where, $attrs); # → one row arrayref
$storage->insert_async($source, \%vals);                    # → returned-columns hashref
$storage->update_async($source, \%vals, \%where);           # → affected-row count
$storage->delete_async($source, \%where);                   # → affected-row count
```

Those shapes are binding (ADR 0031 §3) — the core `create_async` /
`Row::insert_async` helpers fold `insert_async`'s hashref back via
`_store_inserted_columns`. MySQL has no `RETURNING`, so `_post_insert_sql` is
empty and the transport reads `SELECT LAST_INSERT_ID()` on the **same pinned
connection** as the INSERT to build that hashref.

`then` callbacks may `return` a plain value; Future.pm wraps it (ADR 0031 §4).

EV::MariaDB drives the EV loop, so this works under EV directly, AnyEvent (with
the EV backend), `IO::Async::Loop::EV` and `Mojo::Reactor::EV` — and only there.

## Blocking methods — `->get` runs the EV loop, and refuses a wait that cannot end

The sync methods (`select`, `insert`, `txn_do`, `deploy`, …) are core's
`X_async(@_)->get`, inherited. They block because `future_class` is
`DBIO::MySQL::EV::Future`, whose `await` runs `EV::run(EV::RUN_ONCE)` until the
Future is ready (ADR 0001). That works at top level, in a plain EV callback and
— since karr k51 — inside a `then` on the transport's own Futures and in a
`txn_do` / `txn_do_async` coderef, `$ctx->select` without binds included.

Why it works there (ADR 0001 addendum k51, option c): `QueryExecutor::_settle_cb`
does not settle a statement's Future inside the EV::MariaDB callback; it queues
the settling (`_defer`) and an `EV::idle` watcher (`_drain`) runs it, oldest
first, one watcher for all connections. What a `then` or the `txn_do` coderef
runs is therefore outside every callback of the handle (callback_depth 0), and
EV::MariaDB sends a statement at once instead of queueing it until the callback
returns. The k48 refusal and its `_hold` registry are gone. The wire work stays
in the callbacks (prepare → execute → `close_stmt`, k45); only the `IN_FLIGHT`
down-count, `done`/`fail` and `_start_next` move into the watcher, in that
order. Consequence: plain queries a coderef issues back to back are no longer
sent in one batch — the first goes out, EV::MariaDB sends the next ones after
reading its result (one more round trip each).

One wait still cannot end, and `await` refuses it with `Blocking wait refused: …`
instead of hanging:

| The blocking call | Why it cannot end | What the refusal does |
|---|---|---|
| is **queued for a pooled connection** while the settlings it runs inside hold every connection (`$storage->select` in a `txn_do` coderef with a pool of one, or under N nested transactions with a pool of N) — karr k53 | a transaction gives its connection back only after `COMMIT`/`ROLLBACK`, which core sends only after the coderef returned | the queued caller is taken out of the pool's queue and failed; the call **never runs** (a refused insert writes nothing) |

A `txn_do` coderef then fails, the transaction is rolled back and its
connection goes back to the pool. The answer for callers: in a transaction
coderef use the context (`$ctx->X_async` chained with `then`, or the blocking
`$ctx->X`, which now works) for a statement of the transaction; for a statement
outside it use `$storage->X_async` chained with `then`; or raise `pool_size`.

How k53 is decided — keep these three conditions together, each one alone
refuses waits that would have ended (`t/33-blocking-on-exhausted-pool-mock.t`
has a case per condition):

1. **The awaited Future is chained off a queued caller.** `Pool::_new_waiter`
   (core's waiter seam, core k256) marks the Future a queued caller waits on;
   `Future::new` called on an instance — how Future.pm makes the Future of every
   `then` — carries the mark along (as `udata`, never as a hash key of the
   instance). A queued call nobody blocks on is left alone and runs later.
2. **A settling of the connection is running** — the `%FRAME` `_drain` sets
   around every settling it runs (a `then` chain, a `txn_do` coderef; k51).
3. **No statement is in flight on it** — the executor's per-connection count of
   dispatched statements whose Future has not settled. A statement in flight
   may be what gives the connection back, so the wait goes on, and is asked
   about again after every loop iteration and when the loop runs dry.

`Pool::_mysql_held_by_callbacks` is 2 and 3 for every connection the pool holds,
with none idle. Not covered: a blocking wait on a Future that reaches a queued
caller without being chained off it (a `then` callback that *returned* a storage
call's Future), and a transaction whose coderef returns a Future that depends on
a call queued for the transaction's own connection — no blocking wait inside a
callback, so nothing refuses it.

Condition 3 is the executor's count, not EV::MariaDB's `pending_count`: what
gives a connection back is the chain that runs when a statement's *Future*
settles, so that is what is counted. The refusal settles the queued caller only
after `PoolBase::_withdraw_waiter` took it out of the queue.

## No pipeline mode (ADR 0009)

`$storage->pipeline(\&batch)` is **not usable here**. EV::MariaDB exposes no
bracketing primitive, so this transport overrides none of core's
`_pipeline_enter` / `_pipeline_sync` / `_pipeline_exit` seams and does not
declare the `pipeline` capability. The call is refused by core's
`_pipeline_refusal`: it returns a **failed Future** saying that
`DBIO::MySQL::EV::Storage` does not support `pipeline()` — no throw, no
connection taken from the pool, the batch never runs. `$ctx->pipeline` on a
transaction context gets the same answer and leaves the transaction's
connection alone. Pinned by `t/35-pipeline-refusal-mock.t` and
`t/txn-context-pipeline-mock.t`. An async layer that requires `pipeline` is
refused at compose time, naming the gap.

What the driver offers instead is **concurrency, not batching**: issue several
`*_async` calls without awaiting and gather them.

```perl
Future->needs_all(
    map { $storage->insert_async($source, { name => $_ }) } @names
)->then(sub { ... });
```

Each of those runs on **its own pooled connection**, so the statements overlap on
the wire. EV::MariaDB does batch consecutive queries on *one* connection (up to
64 in flight), but the pooled CRUD path takes a connection per call, so that is
not something this driver can promise. Want atomicity? Ask for it: `txn_do_async`.

## Thin transport — what lives here and what does not

`t/06-thin-transport-structure.t` freezes this. The Model-B orchestration (CRUD
runner, `txn_do_async`, `sql_maker`, sync `->get` fallbacks) is inherited
unchanged; adding a parallel reimplementation fails that test. Defined here:

- `sql_maker_class` / `_sql_maker_args` — the shared `DBIO::MySQL::SQLMaker`
- `_transform_sql` — **identity**. `?` is MySQL's native placeholder, so the seam
  exists only to honour the uniform `?`-in contract. Never shape SQL in a caller
  or a layer; shaping happens once, inside the transport.
- `_query_async` / `_query_async_pinned` — dispatch via `QueryExecutor`, both
  through `_mysql_execute`, which reports a failed statement's connection to
  the pool when it is gone (see *Dead connections* below); a pinned `ROLLBACK`
  goes through `_mysql_rollback` and a pinned `COMMIT` through `_mysql_commit`
  instead (*The end of a transaction* below)
- `_await_query_result` — the pooled dispatch `_query_async` hands to core's
  `_seam_future` by name; `insert_async` hands it `_run_crud_pinned` the same
  way. A dispatch that dies or returns no Future fails the call and still
  releases the pooled connection (`t/31-seam-returns-no-future-mock.t`)
- `insert_async` / `_run_crud_pinned` / `_insert_returned_columns` — the
  INSERT + `LAST_INSERT_ID()` path core's RETURNING-shaped runner cannot serve
- `_run_pool_connect_statement` — connect-action replay on a fresh pool connection
- `connect_info` / `_normalize_async_connect_info` / `_conninfo_hash` — conninfo shape
- `_txn_context_class` / `_txn_conn_accessor` (`'txn_conn'`, core's key) —
  transaction pinning. The context class is a **thin subclass** of core's
  `DBIO::Storage::Async::TransactionContext` (karr k31): the whole context
  surface, `_context_active`/`_invalidate` (ADR 0045) included, is inherited;
  only `txn_mdb` (an alias for the inherited `txn_conn`) is added here
- `_ddl_class` — `DBIO::MySQL::DDL`, so `deploy_async` emits the sync deploy's DDL

`transport_capabilities` is exactly `on_connect_replay listen notify
broker_connect_options`: `listen`/`notify` for the notify-table emulation (ADR
0010), `broker_connect_options` for the connect options beside an AccessBroker
(above; read by core, not by layers). MySQL has no COPY, and pipeline is
declined — so nothing else is advertised, and an async layer requiring more is
refused at compose time.

`deploy_async` runs statement-at-a-time and is **not** wrapped in a transaction:
MySQL implicitly commits each DDL statement (ADR 0026), so a half-way failure
leaves what already ran — re-run with `add_drop_table => 1`.

## Pool — opts into core's readiness gate, does not implement it

`DBIO::MySQL::EV::Pool` overrides six `PoolBase` methods (ADR 0003, karr k33;
ADR 0010 amendment k54 for the fourth; ADR 0001 addendum k53 for the fifth;
ADR 0010 amendment k58 for the sixth):

- `_create_connection($conninfo)` — shapes the already-normalized conninfo into
  named args and hands them to core's `_create_ready_connection`; arms the
  pool's fork watcher with the first connection
- `_new_connection(%args)` — the raw handle seam, made through
  `_mysql_new_handle` (`EV::MariaDB->new` with its croak and every `on_error`
  text masked, karr k76 — the listen connection's handle is made there too); the
  handle's `on_error` reports the connection when it is gone, then runs core's
- `_shutdown_connection($mdb)` — `close_async`, guarded against an undef slot
- `_verify_pid` — keeps a weak reference to the parent's connections before
  core drops them in a forked child, for the fork watcher to finish
- `_new_waiter` — core's waiter, marked with the pool that queued it
  (`Future::_queued_in`), so a blocking wait can tell it waits for a queued
  caller (*Blocking methods* above)
- `_idle_connection_alive($mdb)` — core's borrow-time seam (core k241): an idle
  connection is vouched for unless `_mysql_connection_gone` (*Dead connections*
  below)

and adds `_mysql_connection_gone` / `_mysql_report_if_gone` (*Dead connections*
below) and `_mysql_held_by_callbacks` (*Blocking methods* above). Everything else, **including the connection-readiness gate**, comes from
`DBIO::Storage::PoolBase`: `_create_ready_connection` wires `on_connect`/`on_error`
to a per-connection readiness Future and registers it, and the base's default
`_connection_ready_future` looks it back up, so `acquire` resolves only on a
connected handle and *fails* (never hangs) on a refused connect. There is no
`_connection_ready_future` and no `_new_ev_mariadb` here any more — core karr
k158 lifted that wiring out of this driver and dbio-postgresql-ev, which had
written it identically.

Opting in is still explicit, and that is the point: `_create_connection` remains a
required core hook because only a **callback-shaped** transport can use the
default. `EV::MariaDB->new` takes `on_connect`/`on_error` as constructor args and
installs them before it starts connecting — that is what qualifies this driver. A
**poll-shaped** transport (no connect callbacks; readiness established by probing,
as in `dbio-async`'s `future_io` adapter with `_conn_ready` + `Future::IO->poll`)
still overrides the seam itself. `t/08-pool-readiness.t` pins the opt-in offline
by subclassing the pool at `_new_connection` and firing the fake callbacks by hand.

## The end of a transaction — ROLLBACK waits, a failed ROLLBACK or COMMIT retires (karr k74)

EV::MariaDB takes no `query` while a `prepare` or an `execute` is in flight
(`cannot queue query: exclusive operation in progress`; `close_stmt` is never in
flight, its callback has run when it returns, and a query behind it is taken —
measured, `t/37-txn-rollback-refused-live.t` part R). A statement with bind
values is all three, so a `ROLLBACK` handed over at once while one is in flight
was refused: it never reached the server, and core gave the connection back with
the transaction open — the next `BEGIN` there committed it. This happens when a
statement of the transaction is cancelled, when the coderef dies and when the
coderef's Future fails, with a bound statement still on the wire.

- **Order per pinned connection.** `Storage::_query_async_pinned` sends a
  `ROLLBACK` through `_mysql_rollback` -> `QueryExecutor::execute_when_idle`:
  with nothing in flight it goes out at once; otherwise it is queued and handed
  to EV::MariaDB when the last statement in flight is settled by the idle
  watcher (after that Future was settled, k51). Several waiting statements start one after the
  other, and one that sends nothing when its turn comes (its Future was
  cancelled while it waited, its handle is gone, EV::MariaDB refused it) does
  not strand the ones behind it: `_start_next` goes on until one is in flight or
  none is left. Only `ROLLBACK` takes this path. `COMMIT` goes through
  `_mysql_commit` and is **not** queued: core sends it only after every
  statement of the context has settled.
- **Retire.** A `ROLLBACK` or a `COMMIT` that fails — refused at dispatch,
  failed by the server or the client library — reports its connection to the
  pool with `_mark_connection_dead` (`_mysql_end_transaction`): it is retired
  when core hands it back, never idle with a transaction possibly open. This is
  on top of the k55 gone-check, and applies whether or not the session is
  "gone". Nobody knows whether a failed `COMMIT` left the transaction open, so
  it is not asked: the caller still gets core's `COMMIT failed: ...`, and the
  next call runs on a newly opened connection.
- **Consequences for callers.** The transaction future settles later by the time
  the statement in flight takes (a `SLEEP(1.5)` cancelled in a transaction ends
  the transaction after those 1.5 s, not at the cancel). A dying coderef's
  `insert_async` still reads its `LAST_INSERT_ID()` inside the transaction before
  the `ROLLBACK`. The failed transaction's error is the cause, no longer
  `... Rollback failed: cannot queue query ...`.
- **Not covered.** A statement in flight whose callback never comes (handle
  dropped without a callback) keeps the `ROLLBACK` queued and the transaction
  open; EV::MariaDB calls pending callbacks with an error on error/finish, so the
  live paths end. A statement queued *behind* the transaction's end on the same
  connection still hits the refusal itself (k74 is about the ROLLBACK).

Pinned offline by `t/36-cancel-in-flight-mock.t` (9, 11, 12, 13), live by
`t/37-txn-rollback-refused-live.t`.

## Dead connections — the handle decides, the pool retires

The pool cannot see a connection die. Two things tell it, both by the same
check:

- **Before a borrow** (karr k58, ADR 0010 amendment k58): core asks
  `_idle_connection_alive` about every idle connection `acquire` is about to
  hand out (core k241). One that is gone is retired by core, and the caller
  gets the next idle connection that is still there, or a newly opened one. A
  session the server ended while its connection sat idle (`KILL`, a restart,
  `wait_timeout`) costs no caller a failed call.
- **After a failed statement** (karr k55, ADR 0010 amendment k55): a connection
  that is gone is reported to core's `PoolBase::_mark_connection_dead` (core
  k230), and the pool retires it instead of handing it out again: at once when
  it is idle, at the release when it is checked out or pinned; a caller queued
  for the slot gets a newly opened connection. This is what catches a session
  that ended after the pool looked, or without the server saying so.

**What "gone" means** is one method, `DBIO::MySQL::EV::Pool::_mysql_connection_gone($mdb)`
— local, no round trip, never blocks:

| Handle | Answer |
|---|---|
| `socket` is -1 (never connected, closed, or the client library gave it up when an operation found the server gone) | gone |
| `pending_count` > 0 (a reply is due on the socket) | not gone |
| idle, socket readable (a MySQL server never speaks unasked: it hung up) | gone |
| idle, nothing to read | not gone |

Never `is_connected` — it stays true after the server ended the session and
after an operation failed on it (ADR 0010, fact 3). Never the error text, and
no list of error numbers: once EV::MariaDB has dropped its client state
(`not connected`), `error_number` is 0.

**Who reports**, always before the release:

- `Storage::_mysql_execute` — every statement, pooled and pinned, goes through
  it. A statement that fails through its callback, or that EV::MariaDB refuses
  to dispatch, has its connection asked about. This is also what covers a
  transaction and `deploy_async`: core releases their connection, and core
  cannot be hooked there.
- the handle's `on_error` (`Pool::_new_connection`) — it **asks**, it does not
  assume: EV::MariaDB also sends the error of a secondary result set this way,
  on a session that is still there.

A statement that succeeds is never asked about, and a statement error the
session survives (syntax, duplicate key, a busy handle's refusal) leaves the
connection in the pool. Pinned offline by `t/32-pool-dead-connection-mock.t`.

**The borrow-time seam only answers.** `_idle_connection_alive` is
`!_mysql_connection_gone`: no report of its own (core retires what it asked
about), no operation on the handle, nothing sent, nothing read. It runs on
every borrow of an idle connection, so it must stay that cheap: never a
`ping`, never a statement. An idle connection with an operation in flight (a
caller that kept the handle; nothing of the transport leaves one) is vouched
for. Core asks only about connections of the process that owns the pool: a
forked child's first `acquire` drops the inherited ones first.

A session that is still there is taken for gone, at the cost of one reconnect,
when its idle socket has something to read. This was measured live with a
`CALL` sent **without bind values** over plain TCP (karr k58, k83): EV::MariaDB
0.08 calls back with the first result and reads the rest of the answer only
after that callback returned, with `pending_count` already 0 and nothing else
on the handle saying so, so the connection went back to the pool with the rest
unread (a reconnect on the next borrow, or `another operation is in progress` /
`Commands out of sync` for a statement with bind values). Fixed with karr k84:
the executor sends a `CALL` without bind values through prepare/execute, where
the whole answer is read before the Future settles; measured again 2026-10-22
(karr k75), the check said "gone" for no healthy connection in any section of
`t/32-pool-dead-connection-live.t`, MySQL 8.0.30 and MariaDB 11.8.9, plain TCP
and TLS. What is left is a decided, not built, limit (maintainer 2026-10-24,
karr k75): a statement a session prepared itself, `PREPARE h FROM 'CALL p()'`
then `EXECUTE h` sent through `query`, can over plain TCP make the check retire
the healthy idle connection once (one reconnect, no error). A `CALL` or any
statement the transport builds is not affected, nor is a `CALL` with bind values
or anything over TLS.

A test double that answers inside the dispatch call, or by hand, leaves the
Future pending until the loop's idle watcher runs (k51): the test calls
`EV::run(EV::RUN_NOWAIT())` after the answer before it looks at the Future.

A test double has to speak this surface: a fake handle under the real pool
answers `socket` and `pending_count` (a live session is a real socket with
nothing to read — `socketpair`) — without them every borrow of an idle
connection throws in the seam, and core retires the connection and reports
`Idle connection liveness check failed` — and a pool double that is not a
`DBIO::MySQL::EV::Pool` takes `_mysql_report_if_gone`.

## Testing

```bash
../dbio/maint/capped-test prove -lr t/          # offline; live files skip themselves

DBIO_TEST_MYSQL_DSN='dbi:mysql:database=dbio_async;host=127.0.0.1;port=3306' \
DBIO_TEST_MYSQL_USER=dbio DBIO_TEST_MYSQL_PASS=dbio \
  ../dbio/maint/capped-test prove -l t/10-integration.t
```

Live suites are serial and niced — one run at a time, never `prove -j`. A live
test that needs a real pooled backend goes through `DBIO::MySQL::EV::TestHarness`
(`skip_all_unless_live`, `warm_pool`, `run_on_each_pooled_connection`,
`query_on`): only that gives it a backend wired to an *owning sync storage*, so
`on_connect_do` / `on_connect_call` actually replay on each freshly spawned
connection. A directly-constructed storage has no owner and replays nothing.

That whole surface is **inherited from core's `DBIO::Test::AsyncHarness`** (karr
k33). This dist declares only `harness_env_prefix('DBIO_TEST_MYSQL')`,
`harness_async_mode('ev')`, `harness_required_modules([qw( EV EV::MariaDB )])`,
`harness_schema_class(...)`, plus `_tick_loop` (`EV::run(EV::RUN_ONCE())`) and the
default `_Schema`. Do not re-add a local `await`, `warm_pool` or a
`_await_connected` pre-check: `PoolBase::acquire` already gates on readiness on
all three of its paths, so an acquired handle is connected, and re-checking it
costs an override of two inherited methods for nothing. The default `_Schema`
loads `('MySQL', 'MySQL::EV')` on purpose — the EV component is an inert marker
and is *not* what makes the connection async, but loading it here exercises that
inertness against a real server.

## Related

`dbio-mysql` (the sync driver and the `ev` registration), `dbio-driver-development`
(async transport seams), `docs/adr/` in this repo — 0009 for pipeline, 0002 for
transaction pinning.
