# ADR 0030 — Async is an explicit, per-connection mode over one core orchestration

- Status: accepted
- Date: 2026-06-30
- Tags: async, future, storage, drivers, pluggable, per-instance-mode, supersedes-0014, replaces-0028, replaces-0029

## Context

ADRs 0014, 0028 and 0029 grew the async story in three layers that, taken
together, became hard to reason about:

- **0014** made `*_async` universal: every storage answers it, degrading on sync
  storage to an immediately-resolved `DBIO::Future::Immediate`. The degrade is *silent*
  and *always on*.
- **0028** made a real non-blocking driver a pluggable **embedded backend**,
  selected by an `async_backend` **class-data** accessor declared per driver.
- **0029** added a universal **auto-fallback**: `async_fallback`, defaulting to
  `DBIO::Forked::Storage`, so any driver gains fork-based async automatically once
  `dbio-forked` is installed.

Three problems surfaced once the real drivers (`dbio-async` via Future::IO,
`dbio-postgresql-ev`/`dbio-mysql-ev` via EV) existed side by side:

1. **Async is not a transparent feature — it is an execution model.** A
   connection-based backend (Future::IO, EV) requires the application to run an
   event loop; `forked` requires none (fork + blocking `waitpid`); the degrade
   requires none and isn't async at all. These are three different runtime
   contracts with the application. Whichever one answers is a property of the
   *application's architecture*, not of the set of installed packages. Under 0029,
   `cpanm DBIO::Forked` silently turns `select_async` from "immediate" into "forks
   a process" — spooky action at a distance, exactly the footgun an execution-model
   choice must not be.

2. **Three selection mechanisms for one decision.** `async_backend` (class
   default, native), `async_fallback` (auto chain, forked) and the silent degrade
   overlap and interact. A schema is *either* sync *or* a single class-chosen async
   flavour; you cannot hold a forked schema and an EV schema of the same class at
   once.

3. **The Model-B orchestration is written three times.** `dbio-async`,
   `dbio-postgresql-ev` and `dbio-mysql-ev` each re-implement the same
   loop-agnostic machinery — connect-info normalisation, pool wiring, `_run_crud`
   and its runners, `txn_do_async`, the pipeline scaffold, the TransactionContext.
   The only genuinely different part is the **query transport** (`_query_async`:
   Future::IO vs EV::Pg vs EV::MariaDB) plus a little DB-specific SQL. `dbio-async`
   already generalised that machinery behind seam hooks, but no driver inherits it.

The shaping requirement: async must be a thing the application **declares
explicitly, per connection**, and the same schema class must be runnable in
several async modes at once (one forked instance, one Future::IO instance, one EV
instance — all alive together). And the shared orchestration must live in exactly
one place.

## Decision

### 1. Async is an explicit, per-connection mode

The async backend is chosen **at `connect` time, per instance**, by a named
string and is fixed for the life of that instance:

```perl
my $sync   = MyApp::Schema->connect($dsn, $u, $p);                          # sync
my $forked = MyApp::Schema->connect($dsn, $u, $p, { async => 'forked'    });
my $futio  = MyApp::Schema->connect($dsn, $u, $p, { async => 'future_io' });
my $pgev   = MyApp::Schema->connect($dsn, $u, $p, { async => 'ev'        });
```

All four instances live in parallel, each with its own connection/pool. The
**schema class carries no async declaration** — the choice is a runtime/deployment
concern, where it belongs. There is no runtime mode-switch on a live instance
(thin value, fat complexity around in-flight transactions and open pools); to run
another mode you `connect` another instance.

### 2. Modes are named, registered against the driver

A small **mode registry** maps a name to a backend class. Generic modes register
themselves globally; native modes are registered by the driver:

| mode | provider | scope | loop |
|---|---|---|---|
| `forked` | `dbio-forked` (`DBIO::Forked::Storage`) | any driver | none |
| `future_io` | `dbio-async`: abstract `DBIO::Async::Storage` base + a per-driver `DBIO::X::Storage::Async` adapter (convention-resolved) | any driver that exposes its own async binding (`DBD::Pg`, `DBD::mysql`) | yes |
| `ev` | the per-driver EV add-on, **driver-resolved** | one DB | yes |
| `immediate` | core (`DBIO::Future::Immediate`) | any | none |

`ev` is a *logical* name resolved through the driver: on a PostgreSQL schema it
binds `DBIO::PostgreSQL::EV::Storage`, on MySQL `DBIO::MySQL::EV::Storage`. The
same `async => 'ev'` works on both schemas; each driver declares what its `ev`
maps to. `immediate` is the former silent degrade, now a deliberately-named mode
(the mock `DBIO::Test::Storage` defaults to it so mock tests run with no loop).

**`future_io` resolves its transport class by convention, not by a generic
registry entry** (refined post-acceptance, k65). `dbio-async` ships only the
abstract `DBIO::Async::Storage` base — the loop-agnostic Future::IO machinery with
croaking DB-seams — and registers *no* generic `future_io` mode. Because a storage
is always driver-specific, the core resolver derives each driver's transport
adapter deterministically from the concrete storage class: `ref($storage) .
'::Async'`, i.e. `DBIO::PostgreSQL::Storage` → `DBIO::PostgreSQL::Storage::Async`,
loaded on demand, with an early, clear croak (`driver ... does not support
future_io — no ...::Async`) when a driver ships none. An explicit per-driver
`register_async_mode('future_io' => ...)` still wins as an override; a *generic*
base-class registration is deliberately ignored (so merely loading `dbio-async`
can no longer claim `future_io` for every driver and then die deep in the abstract
base's `_submit_query` seam). The *mode* stays explicit; only the *class* is
discovered — this is not the banned 0029 mode auto-fallback.

**Second refinement (k67): the convention walks the storage MRO.** An
extension component that sets `storage_type` to a storage *subclass*
(`DBIO::PostgreSQL::Age::Storage`, `DBIO::PostgreSQL::PostGIS::Storage`) left
the single-candidate rule with no adapter — `...Age::Storage::Async` does not
exist — so loading an extension killed `future_io` outright, plain CRUD
included, while `ev` on the same schema kept working (the mode *registry*
already walks `mro::get_linear_isa`; the convention did not). The convention
therefore probes `$pkg . '::Async'` for each class in the concrete storage's
linearised ISA, most-specific first, stopping *before* the generic bases
(`DBIO::Storage::DBI` and up) — a generic `::Async` claiming every driver is
exactly what the first refinement banned, and the walk must not reopen that
hole. The first candidate that loads wins; a candidate that loads but is not a
`DBIO::Storage::Async` croaks loudly, naming the class (a broken extension
adapter must not silently degrade to its parent's feature set — §3); an
explicit per-driver registration still wins over the whole walk. The payoff is
mirror-symmetry with sync inheritance: an extension that ships no adapter gets
async CRUD through the nearest parent adapter, and one that does ship its own
(e.g. `DBIO::PostgreSQL::Age::Storage::Async`, dbio-postgresql-age k5) is picked up
automatically because its exact name is probed first.

The three real-async modes differ in *what they require of the driver*. `forked`
needs nothing but the ordinary sync driver — it forks per query — so it is truly
universal. `future_io` drives the driver's **own** async binding (the non-blocking
interface `DBD::Pg`/`DBD::mysql` expose themselves) through `Future::IO`: available
only for drivers that offer one, but pulling in no extra client library — it rides
the DBD you already have. `ev` uses a separate, event-loop-bound native client
(`EV::Pg`/`EV::MariaDB`) shipped by the per-driver add-on. `immediate` is not async
at all — the explicit shim.

### 3. No auto-fallback, no silent degrade — explicit or it croaks

- A mode that is requested but not installed/registered **croaks** loudly
  (`async => 'ev'` without the EV add-on → "async mode 'ev' is not available —
  install DBIO::PostgreSQL::EV"). The request was explicit; the failure is too.
- A registered target is lazy-loaded before its type is checked. Only the
  literal `immediate` mode may resolve to a non-`DBIO::Storage::Async` class:
  its `DBIO::Future::Immediate` target intentionally supplies the synchronous
  shim. Any other loaded wrong-type target is a backend-contract error and
  croaks naming the mode and class; it never silently dispatches through the
  synchronous storage.
- This target check is distinct from async storage-layer mirroring (k159). An
  absent convention `<layer>::Async` sibling still marks a layer sync-only and
  skips that layer during composition; it is not an unloaded or wrong-type
  transport target.
- `*_async` on a **sync** instance (no `async` chosen) **croaks** ("not an async
  connection — connect with `{ async => ... }`"). The `*_async` API still exists
  everywhere (so portable code can name it), but it only *does* async when a mode
  was chosen; otherwise it refuses rather than pretending.
- `async_fallback` and its auto-chain are removed entirely.

### 4. One core orchestration, pluggable transports

The shared Model-B machinery is lifted into core `DBIO::Storage::Async`, which
becomes **concrete** (no longer all-croaking): connect-info normalisation, pool
wiring, `_run_crud` and runners, `txn_do_async`, the pipeline scaffold, and a
generic TransactionContext — all driven by seam hooks. A connection-based backend
then overrides only its **transport seam** (`_query_async` / pinned variant) and
its **DB-specifics** (RETURNING vs LAST_INSERT_ID, conninfo format, LISTEN/NOTIFY,
COPY). `dbio-async`, `dbio-postgresql-ev` and `dbio-mysql-ev` collapse to thin
transport layers over this one orchestration. Pool readiness-gating becomes a
`PoolBase` default (it was PG-only, a latent cold-pool race elsewhere).

`forked` stays the **Model-A special case**: it has no async connection and no
pool, so it does not share the orchestration — it inherits only the
`DBIO::Storage::Async` contract and runs the ordinary sync storage inside a
`fork()`. Its transaction-semantics limit (a whole `txn_do_async` block runs sync
inside one fork, not statement-by-statement non-blocking) is intrinsic to Model A
and is documented on the front page of `DBIO::Forked` as well as here.

### 5. Pool shutdown is terminal per instance (2026-09-15 amendment)

`DBIO::Storage::Async::disconnect` already calls `pool->shutdown`; this
amendment makes the semantics of that existing pool contract explicit without
adding a new runtime hook. Shutdown marks the pool terminal before invoking
any Future settlement callback, detaches raw queue waiters, and fails both
queued and readiness-pending acquires with the stable diagnostic
`Connection pool has been shut down`. A readiness-pending cold handle is
retired and closed exactly once without disconnect actions. A ready handle
keeps the established ordering: disconnect actions while live, then one close.

The same pool object never resumes work. Later `acquire` and `acquire_txn` calls
return a failed Future with the stable shutdown diagnostic rather than throwing,
a late `release` is a no-op, and repeated `shutdown` is a no-op. Reconnection
remains the higher DBIO storage lifecycle's job: it detaches the old async
backend and lazily builds a fresh backend, ownership generation, and pool. It
does not revive the terminal instance. Pool restart, acquire cancellation, and
public timeout APIs are not introduced by this amendment.

## Rationale

Explicit-per-connection makes the execution-model choice visible and local: the
code that connects says which runtime contract it wants, nothing installs a
different contract behind its back, and a mistake (`async` mode unavailable, or
`*_async` on a sync instance) is a loud error rather than a silent behaviour
change. It also collapses three selection mechanisms into one axis — a named mode
— and lifts the class→instance restriction so the same schema class runs several
async modes simultaneously. This is the natural completion of 0028's embedded
backend: 0028 already embedded the backend in the storage instance; 0030 moves the
*choice* from the class default to the connect call.

Lifting the orchestration into core is the orthogonal half: selection decides
*which* backend answers; the core orchestration ensures the Model-B machinery is
written once, not three times. The two together are "the new async architecture".

## Consequences

- **Removed:** `async_fallback` and its auto-chain (0029); `async_backend` as a
  per-class auto-default (0028); the always-on silent degrade as the default
  behaviour of `*_async` (0014) — it survives only as the explicit `immediate`
  mode.
- **Kept:** the universal `*_async` API surface (0014); the `DBIO::Storage::Async`
  contract and `DBIO::Future` duck-type; `PoolBase`; the embedded-backend concept
  (0028). `future_class` still comes from the live backend.
- **Core changes:** a mode registry + per-connection resolver on
  `DBIO::Storage::DBI` (reading `{ async => ... }`); `DBIO::Storage::Async` made
  concrete with seam hooks; `PoolBase` readiness-gating default. No event-loop
  dependency added to core. Fully mock-testable (`DBIO::Test::Storage` extends
  `DBIO::Storage::DBI`): registry resolution, three modes side by side under mock,
  unavailable-mode croak, `*_async`-on-sync croak.
- **Driver/add-on changes (thin):** `dbio-async` provides only the abstract
  Future::IO base `DBIO::Async::Storage` — `future_io` is convention-resolved per
  driver (`DBIO::X::Storage::Async`), not registered generically (k65);
  `dbio-postgresql-ev`/`dbio-mysql-ev`
  keep only EV transport seams + DB-specifics;
  `dbio-postgresql`/`dbio-mysql` register the `ev` mapping (no auto-default);
  `dbio-forked` registers `forked`. The MySQL-EV `connection()`/`storage_type`
  hijack is removed (it contradicts the inert-component model).
- **Extension storage classes** (schema components that set `storage_type` to a
  driver-storage subclass: AGE, PostGIS) run `future_io` through the nearest
  parent adapter found by the convention's MRO walk (k67). Extension-
  *specific* async API (e.g. AGE `cypher_async`) lives in the extension dist as
  a conventionally-named adapter subclass and additionally requires connection
  actions (`on_connect_do`/`on_connect_call`) to fire on pool connections —
  a core seam tracked as k68; until it lands, pool connections silently
  skip session setup, which is also a sync/async divergence for ordinary
  users of `on_connect_*`.
- **`dbio-ev` is deliberately NOT created** (YAGNI). After the core lift, too
  little shared EV code remains to justify its own dist; revisit if that changes.
- **Migration:** `async_backend('DBIO::Foo::Async::Storage')` on a storage class →
  `connect(..., { async => '<mode>' })` at the call site. Driver-specific
  async-only features (`listen`/`notify`/`pipeline`/`copy_in`) remain reached via
  `$schema->storage->async->...` on the chosen instance.
- **Scope boundary — storage-level only (this increment).** Only the six
  *storage-level* `$storage->*_async` are made explicit (croak on a sync
  instance). The *ResultSet/Row* `*_async` (`all_async`/`first_async`/
  `single_async`/`count_async`/`create_async`) are NOT touched: they still run the
  sync op and wrap it in `future_class`, degrading silently even on a sync
  instance. So after this increment `$storage->select_async` croaks on a sync
  instance while `$rs->all_async` does not — a deliberate, temporary asymmetry
  that the RS/Row real-async work (below) closes by routing RS `*_async` through
  the storage backend.

## Future architecture work (tracked cross-repo, not here)

This section is a **snapshot of the cross-repo plan as it stood when this ADR
was accepted**, kept for the record. It is deliberately not maintained against
the implementation and does not describe today's code; where the two disagree,
the Decision and Consequences above are authoritative. The first item is the
known instance: it still assigns mode registration to the EV dists, whereas
what was actually built has the *sync* drivers `dbio-postgresql` and
`dbio-mysql` call `register_async_mode` for `ev` while the EV dists register
nothing (verified at the implementation, karr k157/k162 — Consequences was
corrected, this snapshot is not).

- **dbio-async / dbio-postgresql-ev / dbio-mysql-ev**: collapse to transport-only
  over the core orchestration; register their mode. karr tickets on their boards.
- **dbio-postgresql / dbio-mysql**: register the `ev` mode mapping; drop the
  MySQL-EV `connection()` hijack; reach parity (`deploy_async`, pool readiness).
- **Naming cleanup**: stale `::Async` / `DBIO::EV::Pg` names in core POD and
  `DBIO::Manual::Heritage`; `Changes`/README staleness in the add-ons.
- **ResultSet/Row real async** (carried over from the earlier async ADRs): route RS `*_async`
  through the storage backend with async row inflation and prefetch/collapse
  parity. Its own ADR when taken up.
- **dbio-postgresql-age**: `DBIO::PostgreSQL::Age::Storage::Async` with
  `cypher_async` (dbio-postgresql-age k5) — blocked on core k68 (pool on_connect seam).

## Relationship to other ADRs

- **0028 (class-declared embedded backend) and 0029 (forked auto-fallback) —
  removed.** Both are fully replaced by this ADR and have been deleted from
  `docs/adr/`; their still-relevant rationale is folded into the Context and
  Decision above (why an auto-fallback is a footgun → §Context.1; why the embedded
  backend belongs in the storage instance, now chosen per connection rather than
  per class → §Decision.1). Git history preserves the originals.
- **0014 — binding/degrade superseded, API kept.** `*_async` stays universal and
  the contract/`PoolBase` tier stand; the always-on silent degrade becomes the
  explicit `immediate` mode, and `*_async` on a sync instance now croaks instead
  of degrading silently. The `DBIO::Test::Future` production-default smell is now
  doubly resolved: the class is renamed to `DBIO::Future::Immediate`, and it is
  reached only via the named `immediate` mode. 0014's Status is
  updated to "superseded in part by 0030".

## Addendum 2026-09-27 — the mode of a broker-backed connection is given beside the broker (karr k240)

§1 puts the choice of mode at the connect call: `connect($dsn, $u, $p, { async
=> $mode })`. A connection whose details come from a `DBIO::AccessBroker` (ADR
0013) had no such slot. `DBIO::Storage::DBI::connect_info` took broker form only
as `[ $broker ]`, and read the mode out of the broker's *answer*
(`_normalize_connect_info` on it): the `async` attribute of a DBI-form answer,
as `DBIO::AccessBroker::Vault` can give through `dbi_attrs`. A broker answering
a hash of connection parameters -- `DBIO::AccessBroker::Static`, five fixed keys
-- could not name a mode at all, and `connect($broker, { async => $mode })`
was not broker form: the broker object became the DSN, no broker was attached,
and nothing was thrown (found in dbio-postgresql k80).

### Decision

Broker form is `[ $broker ]` or `[ $broker, \%call ]`, where the hash beside
the broker is the connect call's own and takes **`async` and nothing else**
(`DBIO::Storage::DBI::AccessBroker::_access_broker_async_mode`; the predicate
`_is_access_broker_connect_info` accepts both shapes).

- The mode given there is the connection's mode. A DBI-form answer may still
  carry `async` among its attributes; given both ways, they must name the same
  mode, or `connect_info` throws naming both.
- Any other key beside the broker throws, naming it. Everything else about the
  connection -- DSN, user, password, attributes -- is the broker's answer.
- The embedded async backend is handed the broker alone (`_async_storage`),
  the form every backend already takes a broker in: the mode was consumed by the
  owning storage, and the backend is the one built for it.
- `pool_size` in a broker's answer stays out of the owner's `DBI->connect` when
  the mode was given beside the broker, on `connect_info` and in `_connect`, as
  karr k211 keeps it out when the mode is an attribute.

### Rationale

- **The mode belongs to the call, not to the credential source.** §1 chose the
  connect call as the place for an execution-model choice; ADR 0013 made the
  broker a CredentialSource, not an options bag. Giving Static an `async`
  argument would have put a connection option into the source, and a hash
  answer with an `async` key reaches the `future_io` transports as a
  connection parameter (dbio-postgresql's `_async_broker_conninfo` turns every
  key of a libpq hash into a DSN part).
- **Only `async`, for now.** The async backend never sees the hash beside the
  broker, so a DBI attribute or a pool setting there would reach the sync
  connection and silently miss every pooled one -- the sync/async divergence
  ADR 0048 closed. Taking more keys needs the backends to receive them too; a
  refusal now can be widened later without breaking anyone.

### Consequences

- `connect($broker, { async => $mode })` selects the mode for every broker. No
  driver or transport changes: backends still receive `[ $broker ]`, and
  whether a transport can connect from a given broker's answer stays that
  transport's matter (dbio-postgresql k80 made its `future_io` adapter take
  every built-in shape).
- A Static-backed connection still has no way to set connection attributes,
  `quote_names` or `on_connect_*` -- they would come from the broker's answer,
  and Static answers none. That is a separate question from the mode.
- Documented in `DBIO::Storage::DBI` (`connect_info`) and the
  `DBIO::AccessBroker` synopsis. Pinned by
  `t/access_broker/08-async-mode-beside-broker.t`.

## Addendum 2026-09-27 (II) — the hash beside the broker takes the connect options (karr k243)

The k240 addendum above let the hash beside a broker carry `async` and nothing
else, and said why: the async backend was handed the broker alone, so any other
setting there would reach the owning sync connection and silently miss every
pooled one — the divergence ADR 0048 closed. A connection whose details come
from `DBIO::AccessBroker::Static` was left with no way at all to set DBI
attributes, `quote_names`, `on_connect_do`/`on_connect_call` or `pool_size`:
Static answers five fixed keys, and there was no other slot.

### What a backend reads today

Before widening anything, who applies each setting when it comes with a DSN.
There the owner hands its backend `_connect_info` as given
(`DBIO::Storage::DBI::_async_storage`), and the backend strips the private
keys centrally (`DBIO::Storage::Async::_strip_private_connect_attrs`, ADR 0048):

| setting | applied by | reaches pooled connections |
|---|---|---|
| storage options (`on_connect_do`, `on_connect_call`, `on_disconnect_*`, `disable_sth_caching`, `unsafe`, `auto_savepoint`, `cursor_class`) | the owner | connection actions are replayed **from the owner** (`_setup_pool_connection` via `_owner_storage`, ADR 0049); the backend reads none of them from its own connect info |
| SQL maker options (`quote_names`, `quote_char`, `name_sep`) | the owner's SQL maker | every backend drops them and quotes from its own `_sql_maker_args` — in every connect form, not a broker matter |
| `ignore_version`, `async` | the owner | not a backend setting |
| DBD attributes | the owner's `DBI->connect`, **and the backend's** | `future_io` adapters (dbio-postgresql, dbio-mysql) pass them to every pooled `DBI->connect`; the `ev` backends drop them (`dbi_to_conninfo` keeps only `pool_size`), as their clients are not DBI |
| `pool_size` | **the backend** | sizes the pool; kept out of the owner's `DBI->connect` once there is a mode (karr k211) |
| `forked`, `immediate` | — | run on the owner itself, so they see everything the owner has |

So only two kinds of setting are the backend's own: DBD attributes and
`pool_size`. Everything else is the owner's in every connect form.

### Decision

1. **Which keys.** The hash beside the broker takes what the attribute hash of
   every other connect form takes — DBI attributes, the DBIO connection
   attributes, `async`, `pool_size` — except the ones naming the connection
   itself: `dsn`, `user`, `password`, `dbh_maker` and the connection parameters
   `dbname`, `host`, `port`. Which database, and as whom, is the broker's answer
   (ADR 0013); naming it beside the broker throws, naming the keys
   (`DBIO::Storage::DBI::AccessBroker::_access_broker_call_info`, which replaces
   k240's `_access_broker_async_mode`). The owner normalises the hash exactly
   like any other attribute hash (`_normalize_connect_info`), so every option
   lands where it lands with a DSN. (Except a key the owner would not apply to
   its own connection — a parameter of the database client: since karr k307 it
   stops that connection instead of reaching `DBI->connect`. See ADR 0057,
   addendum of 2026-10-06 (III).)

2. **Merging with the answer.** A DBI-form answer (Vault's `dbi_attrs`) may
   carry some of the same settings. A setting given in both places must have
   the same value — the same plain value, both undef, or the very same
   reference — or the connect throws naming the setting, never its values
   (`DBIO::Storage::_merge_access_broker_settings`, used through
   `_merge_access_broker_call_info`). The async mode keeps k240's message naming
   both modes. The merge runs when the storage is configured (`connect_info`)
   **and on every connect** (`_connect`): the broker is asked anew for each
   connection, so the settings beside it must join each answer, and an answer
   that changes to a conflicting value throws there. `pool_size` leaves the
   owner's DBI attributes once the connection has a mode, whichever hash gave
   the mode.

   Not "call wins", not "broker wins": either would pick one of two values the
   application wrote down for the same thing, silently. k240 already refused two
   different modes; one rule for every setting.

3. **What the backend receives.** If the hash holds only settings the owner
   applies — mode, storage options, SQL maker options, `ignore_version` — the
   backend gets the broker alone, `[ $broker ]`, as since k240: it reads none of
   those from its own connect info in any form, and the pooled connections
   replay `on_connect_*` from the owner. That is exact parity with a DSN
   connect, with no backend change.

   If the hash holds DBD attributes or `pool_size`
   (`_access_broker_backend_settings`), the backend gets the connect info as
   given, `[ $broker, \%options ]` — the same thing a DSN connect hands it —
   **only if its transport declares `broker_connect_options`** in
   `transport_capabilities`. Otherwise `_async_storage` throws at the backend's
   resolution (the first async use), naming the transport, the settings and the
   capability. The sync connection keeps them either way.

4. **Core's half of taking that form.** `DBIO::Storage::Async::connect_info`
   takes `[ $broker, \%options ]` for a declaring transport
   (`_access_broker_call_options`): the options go through the one central strip,
   `pool_size` among them sizes the pool, the DBD attributes are kept as
   `_access_broker_call_attributes` for the transport to merge into each
   connection it opens — with `_merge_access_broker_settings`, the same rule as
   the owner. A transport that does not declare it refuses non-empty options
   there too. `_is_access_broker_connect_info` on the async side stays
   single-element, so a transport that overrides `connect_info` (the `ev`
   backends) keeps treating the two-element form as it does today instead of
   quietly taking it for the bare broker.

### Rationale

- **The declaration is the backend's promise, and it is needed.** Every
  existing backend ignores anything beside the broker: the `future_io` adapters
  build each pooled connection from the broker's answer alone
  (`_async_broker_conninfo`), the `ev` backends override `connect_info` and read
  only `[0]`. Handing them `[ $broker, \%options ]` unannounced would size no
  pool and open every pooled connection without the DBD attributes — the silent
  divergence k240 refused. Core cannot fold the attributes into the answer for
  them: a hash answer has no transport-neutral slot for DBI attributes (the
  PostgreSQL `future_io` adapter reads extra keys of a hash as libpq parameters,
  the `ev` backends as client parameters), so the merge has to be the
  transport's. `transport_capabilities` is where a transport already says what
  it supports, and core already gates on names there (`listen`, `notify`).
- **Owner-applied settings need no declaration.** They are the owner's in every
  connect form; a backend handed a DSN strips and ignores them too. Refusing
  them beside a broker would buy nothing.
- **Backward compatible.** A backend that does not declare the capability is
  handed exactly what it got since k240, or nothing is built at all. No backend
  breaks; the settings that would need one are refused loudly until it is ready,
  one transport at a time, without another core change.

### Consequences

- A Static-backed sync connection can set DBI attributes, `quote_names`,
  `on_connect_do`/`on_connect_call` and the rest. With an async mode it can set
  everything but DBD attributes and `pool_size` on every transport today; those
  two work on a transport once it declares `broker_connect_options`.
- Per transport, to declare it:
  - **dbio-forked**: declare only — its child runs on the owner, which already
    applies everything; its `connect_info` is informational.
  - **dbio-postgresql**, **dbio-mysql** (`future_io` adapters): merge
    `_access_broker_call_attributes` into the `attrs` of every conninfo built
    from the broker (`_async_broker_conninfo`, used for pool and listen
    connections) with `_merge_access_broker_settings`, then declare. dbio-mysql
    first needs a broker path at all (its karr k62).
  - **dbio-postgresql-ev**, **dbio-mysql-ev**: read `pool_size` from
    `[ $broker, \%options ]` in their `connect_info` override
    (`_access_broker_call_options` does the stripping), drop the DBD attributes
    as `dbi_to_conninfo` does for a DSN, then declare.
  - **dbio-async**: nothing required — its base runs core's `connect_info`.
    Its base `_async_broker_conninfo` is what the dbio-mysql adapter inherits,
    so the merge for MySQL may land there instead (its karr k27 reworks that
    method).
- `t/access_broker/08-async-mode-beside-broker.t` changed its claim 4 from "any
  other key throws" to "the connection itself throws";
  `t/access_broker/09-connect-options-beside-broker.t` pins the rest.

## Addendum 2026-10-10 — global destruction is the exception to section 5 (karr k290)

Section 5 (the amendment of 2026-09-15) states the shutdown rule without
qualification: queued and readiness-pending acquires fail with
`Connection pool has been shut down`, a ready handle gets its disconnect
actions while live and then one close. That holds for every shutdown a
caller or `disconnect` asks for. It does not hold for the one `DESTROY`
runs when a process exits with the pool still alive (global destruction),
and the section did not say so.

What `DBIO::Storage::PoolBase::shutdown` does there (karr k254, k234):

- **It settles no Future.** Queued waiters and pending readiness Futures
  are dropped, not failed, and a hand-over chain is not cancelled. Perl
  frees objects in no particular order in that phase, so a waiter, or the
  Future its caller holds, may already be gone -- failing one whose
  derived Future was freed first only makes Future.pm warn -- and no event
  loop runs any more to tell anybody.
- **Connections are still closed**, as far as they are still there: a slot
  already freed is skipped.
- **The disconnect actions can run against a connection still coming up.**
  What tells a cold connection from one that came up -- its readiness
  Future, the hand-over of the acquire waiting for it -- may have been
  freed ahead of the pool, so the rule "a connection still coming up is
  closed without disconnect actions" is not reliable there.
- **A forked child's teardown** drops the inherited state without closing
  the parent's connections, as at any other time (`_verify_pid`).

Section 5's wording is authoritative everywhere else. The same exception
is stated in the `shutdown` POD of `DBIO::Storage::PoolBase` and in the
2026-10-04 addenda of ADR 0047 and ADR 0049.

## Addendum 2026-10-30 — the embedded backend lives as long as its sync storage (karr k406)

The embedded async storage belongs to the sync storage that built it, and
its connections end with that storage. `DBIO::Storage::DBI::DESTROY`
disconnects the embedded backend the way `disconnect` does: the ownership
token is reset, then the backend is deleted and disconnected, so its pool
shuts down by the rule of section 5 and a connection in its session reset is
closed with its reset cancelled. This does not wait for the event loop.

- It runs in the process that owns the connections (`_conn_pid` undefined or
  the current pid). A forked child drops the inherited state as at any other
  time (`_verify_pid`).
- It does not run in global destruction, where the pool follows the rules of
  the addendum of 2026-10-10.
- It tears down only a backend that was built. `DESTROY` never resolves one,
  and a schema without an async mode has none.
- A failing teardown is reported as a warning and `DESTROY` continues to
  release the storage's own handle.
