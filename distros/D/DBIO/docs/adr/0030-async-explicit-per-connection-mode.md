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
registry entry** (refined post-acceptance, karr #65). `dbio-async` ships only the
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

**Second refinement (karr #67): the convention walks the storage MRO.** An
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
(e.g. `DBIO::PostgreSQL::Age::Storage::Async`, age board #5) is picked up
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
  driver (`DBIO::X::Storage::Async`), not registered generically (karr #65);
  `dbio-postgresql-ev`/`dbio-mysql-ev`
  keep only EV transport seams + DB-specifics + register `ev`;
  `dbio-postgresql`/`dbio-mysql` register the `ev` mapping (no auto-default);
  `dbio-forked` registers `forked`. The MySQL-EV `connection()`/`storage_type`
  hijack is removed (it contradicts the inert-component model).
- **Extension storage classes** (schema components that set `storage_type` to a
  driver-storage subclass: AGE, PostGIS) run `future_io` through the nearest
  parent adapter found by the convention's MRO walk (karr #67). Extension-
  *specific* async API (e.g. AGE `cypher_async`) lives in the extension dist as
  a conventionally-named adapter subclass and additionally requires connection
  actions (`on_connect_do`/`on_connect_call`) to fire on pool connections —
  a core seam tracked as karr #68; until it lands, pool connections silently
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
  `cypher_async` (age board #5) — blocked on core #68 (pool on_connect seam).

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
