# ADR 0006 — AccessBroker credential rotation via a `_conninfo_provider` coderef

- Status: accepted
- Date: 2026-06-21
- Tags: async, accessbroker, credentials, rotation, pool, drivers
- Superseded in part: the broker *detection* and *provider construction*
  described below are superseded by core ADR 0014's "since promoted into core"
  amendment (see the Amendment); the rotation policy itself stands

## Amendment (2026-09-07, karr k36) — the provider machinery is core's; this driver answers one seam

The decision this ADR records is in force and unchanged: a broker-backed pool
must build *every* new connection from freshly-fetched credentials, never from a
snapshot taken when the schema first connected, and the way to get that is to
hand the pool a per-spawn *provider coderef* rather than a value. What is
superseded is *who owns the machinery* — and, with it, the direction in which
this driver participates.

Core lifted the async broker-consumption wiring into the abstract
`DBIO::Storage::Async`. Its `ACCESSBROKER CONSUMPTION` POD names exactly this
move — "the async consumption wiring that was previously re-implemented by every
async driver" — and core ADR 0014 carries the matching amendment, *Async storage
as a CredentialSource consumer — since promoted into core*, which names
`_setup_access_broker` / `_clear_access_broker` and the `_async_broker_conninfo`
per-pool-spawn `conninfo_provider` as the pieces that moved. The lift-into-core
question this ADR's Consequences deliberately left open to core has therefore
been decided, and decided in core's favour.

Read as superseded, therefore:

- **Five of the methods below are not this distribution's and never appear in
  it.** `_is_access_broker_connect_info`, `_setup_access_broker`,
  `_clear_access_broker`, `_current_async_connect_info` and `_conninfo_provider`
  are all defined in `DBIO::Storage::Async` and inherited here; the storage slot
  the accessor reads is initialised in that class's `new`. This driver defines
  none of them. A reader who takes the *Decision* bullets "Detect and attach" and
  "Install the provider" as describing a driver seam is looking for the seam in
  the wrong repo — and, worse, may build a second copy of it here instead of
  using core's, which is the duplication karr k33 has just finished removing from
  the pool and the harness.
- **The provider is built by core and *calls* this driver, not the other way
  round.** The *Decision* describes the driver installing a closure that itself
  runs `_current_async_connect_info` through `_normalize_async_connect_info`.
  Today core's `_setup_access_broker` installs the closure, and the closure calls
  a driver hook — `_async_broker_conninfo` — that did not exist when this ADR was
  written. That hook is `DBIO::MySQL::EV::Storage`'s only rotation-specific
  method: core asks the transport for one fresh, storage-native conninfo per new
  pool connection, and this driver answers with the EV::MariaDB named-parameter
  hash. The obligation the *Consequences* placed on the pool ("must keep calling
  the provider per connection") now has a second, local half: this hook must
  build a *fresh* value on every call. Returning a cached hash would silently
  defeat rotation with every test still green.
- **The PoolBase contract this ADR cites has been renamed under it.** "PoolBase
  then invokes the provider for each `_create_connection`" describes an invariant
  that still holds, at a seam that no longer has that name: the provider is
  invoked in `_spawn_connection`, whose result passes through
  `_transform_conninfo` before reaching `_create_connection`.
- **The *Context* paragraph's "not yet lifted into the abstract
  `DBIO::Storage::Async`" is a statement about 2026-06-21, not about today.** So
  is the closing *Consequences* bullet's "open question of lifting broker
  consumption into the core abstract `DBIO::Storage::Async` … does not pre-empt
  that core decision". Both were accurate when written; both were closed by the
  lift.

Not superseded, and deliberately named so this amendment is not over-read:

- **`_normalize_async_connect_info` is still overridden here** — the one entry on
  karr k36's list of six that does *not* resolve wholly to core. Core ships a base
  that strips `pool_size`; `DBIO::MySQL::EV::Storage` overrides it to also map the
  DBI-style `dbname` key to EV::MariaDB's `database`. Deleting the override on the
  strength of a flat "lifted to core" reading would drop that mapping. (The
  sibling's list is accurate for the sibling: `dbio-postgresql-ev` defines only
  `_async_broker_conninfo` and inherits this method unchanged.)
- **`_conninfo_hash` has no core counterpart at all** and remains wholly this
  driver's, as does the *Decision*'s "Normalize once, at the seam" bullet and the
  *Consequences* bullet that follows from it.
- **The pool wiring is still local.** `DBIO::MySQL::EV::Storage`'s `pool` still
  makes the choice this ADR records — provider coderef when `_conninfo_provider`
  is set, static conninfo otherwise.
- **`connect_info` is still overridden here**, but for one reason only, and not
  the one below: the embedded path, where the sync storage feeds DBI-form connect
  info that `DBIO::MySQL::EV::ConnectInfo::dbi_to_conninfo` folds into the async
  `[ \%conninfo, \%opts ]` shape before any broker logic runs. Core's own
  `connect_info` now carries the identical broker branch.

The sibling `dbio-postgresql-ev` reached the same finding independently and
recorded it in its ADR 0009, *AccessBroker credential rotation via a per-spawn
conninfo seam* (2026-09-06), under the heading "The correction: most of that ADR
is now core's, not the driver's" — naming this ADR and the same six methods. That
ADR closes with the note that amending ADR 0006 is this repo's call, which it
could only read; this amendment is that call, and closes the loop.

The line-numbered `Storage.pm:NN` references below are pre-house-rule and have
drifted; they are left as written. New references name module plus method.

## Addendum (2026-10-04, karr k59) — a broker may come with connect options beside it

The *Decision* below opens with "When the connect info is a single blessed
`DBIO::AccessBroker`". That is no longer the only broker form. Core ADR 0030,
addendum 2026-09-27 (II) (core k243), lets a connect call carry its options
beside the broker and hands a backend `[ $broker, \%options ]` when they hold
something a backend applies — `pool_size` or DBD attributes — but only to a
transport declaring `broker_connect_options`. This transport declares it, and
its `connect_info` override takes the two-element form.

What this driver decides, and nothing more:

- **The form is read through core's seams only.**
  `_strip_private_connect_attrs` and `_access_broker_call_options` split the
  options; `_access_broker_pool_size($answer, $beside)` sizes the pool from the
  answer and from beside the broker under core's one rule (the same value, or
  it throws naming `pool_size`, core k245). The override adds no reading of its
  own, which `t/06-thin-transport-structure.t` asserts by requiring those
  methods to be core's.
- **DBD attributes beside the broker are dropped**, as
  `DBIO::MySQL::EV::ConnectInfo::dbi_to_conninfo` drops them from DBI-form
  connect info — core's parity rule for a transport without a DBD. They are
  kept only where core's `_access_broker_call_attributes` answers for them.
  An EV::MariaDB parameter given there is an attribute like any other and is
  dropped too; it reaches a pooled connection through the broker's answer.
- **The rotation policy is untouched.** The options beside the broker never
  become conninfo: every connection still asks the broker, through the same
  provider, and nothing of its answer is stored.

`t/30-access-broker-connect-options-mock.t` holds the behaviour.

## Addendum (2026-10-06, karr k63, k78) — refused rather than connected without

Two maintainer decisions of 2026-10-06. Both follow one line: a broker
connection that cannot be opened as it was asked for is not opened.

- **A connection parameter beside the broker is refused (k78).** This replaces
  one sentence of the k59 addendum above: "An EV::MariaDB parameter given there
  is an attribute like any other and is dropped too". Dropped, it left every
  pooled connection opened without `ssl_verify_server_cert`, `charset` or the
  `host` that stood beside the broker, and nothing said so. A key beside the
  broker that is set to a value and is, by its name, no DBI attribute — core
  k298's measure, with both `mysql_` and `mariadb_` as DBD prefixes, since the
  transport is not told which DBD its owner uses — now makes `connect_info`
  croak, naming the keys and no value, and `_async_broker_conninfo` croak again
  for every connection. DBD attributes are still dropped, `pool_size` still
  sizes the pool.
- **A whole DSN as the database name of a hash answer is refused (k63).**
  `DBIO::AccessBroker::Static->new(dbname => 'dbi:mysql:…')` is a form core's
  sync storage takes as the DSN. On this transport the DSN became the database
  name and no host was given, so EV::MariaDB connected to the client library's
  default, the local server, with the broker's credentials. The alternative —
  reading the DSN out of the hash, as a DBI-form answer is read — was
  considered and not taken: the answer is refused, at attach and for every
  connection, under a HostBound view too, with a message that names the form
  and nothing of the DSN.

`t/39-access-broker-parameters-beside-mock.t` (and its live half) and section 10
of `t/29-access-broker-conninfo-mock.t` (live: `t/38-access-broker-dsn-dbname-live.t`)
hold the behaviour.

## Context

Core ADR 0013 establishes the AccessBroker / CredentialSource seam: a storage can
be handed a broker instead of raw connect info, and the broker yields credentials
on demand — the mechanism for rotating credentials (short-lived DB passwords from a
vault) without restarting the app. Core ADR 0014 notes that the *async* drivers
consume this seam at the driver level (`set_access_broker` /
`current_access_broker_connect_info`) even though it is not yet lifted into the
abstract `DBIO::Storage::Async`. The broker interface itself and the
lift-into-core question are core-owned and tracked there; this ADR does not restate
them.

The async-specific problem the seam does not solve by itself: a sync DBI storage
holds one `$dbh` and can simply re-fetch credentials the next time it
reconnects. This driver holds a **pool** of EV::MariaDB connections created lazily
and on demand by `DBIO::Storage::PoolBase`. For rotation to work, *each new pooled
connection* must be built from freshly-fetched, freshly-normalized broker
credentials — not from a single snapshot captured when the schema first connected,
which would pin the pool to a password that later expires.

## Decision

When the connect info is a single blessed `DBIO::AccessBroker`, wire the broker to
the storage and install a `_conninfo_provider` coderef that re-fetches and
re-normalizes credentials from the broker; hand that coderef to the pool so
`PoolBase` calls it to build *every* connection, instead of handing the pool a
static conninfo snapshot.

- **Detect and attach.** `connect_info` recognises the single-blessed-broker shape
  and calls `set_access_broker($broker, 'write')` (`Storage.pm:77-79`).
- **Install the provider.** `_conninfo_provider` is set to a closure that, on each
  call, runs `_current_async_connect_info($mode)` through
  `_normalize_async_connect_info` and returns fresh normalized conninfo
  (`Storage.pm:80-85`); the accessor exposes it (`Storage.pm:134`).
- **Pool consumes the provider, not a snapshot.** When building the pool, if a
  `_conninfo_provider` is present it is passed as the pool's `conninfo_provider`
  (`Storage.pm:152-153`); only in the non-broker case is a static `conninfo` passed
  (`Storage.pm:155-157`). `PoolBase` then invokes the provider for each
  `_create_connection`, so every new pooled connection uses freshly-fetched
  credentials.
- **Normalize once, at the seam.** Both the provider and the non-broker path route
  through `_normalize_async_connect_info` (`Storage.pm:115-132`), which maps
  `dbname`→`database` and extracts `pool_size`; `_conninfo_hash` then treats stored
  conninfo as already-normalized and returns it as-is (`Storage.pm:168-177`) — no
  re-normalization on the hot path.

## Rationale

Rotating credentials only help if the pool actually picks them up; a pool that
captured the broker's first answer and reused it forever would authenticate new
connections with a stale password and fail once the credential expired. Passing the
pool a *provider coderef* rather than a *value* is what makes the pool's own lazy,
on-demand connection creation (ADR 0003 / core ADR 0014's PoolBase) re-pull
credentials at exactly the right moment — connection-creation time — without the
pool needing any broker knowledge or a teardown/rebuild cycle. The provider closes
over `current_access_broker_connect_info` (the core ADR 0013 hook, available because
it lives on base `DBIO::Storage`), so the driver consumes the core seam without
re-implementing credential fetching. Centralising the `dbname`→`database` /
`pool_size` normalization in one method, called by both the provider and the static
path, keeps the broker and non-broker cases producing identically-shaped conninfo
and keeps `_conninfo_hash` off the hot path.

This is shipped and unit-tested (`t/02-access-broker.t` exercises the broker wiring
without a live DB; `t/11-access-broker-live.t` against a real server), hence
**accepted**, not proposed.

## Consequences

- Broker-backed pools rotate credentials transparently: each new pooled connection
  is built from freshly-fetched, freshly-normalized broker credentials, with no
  pool teardown. Existing live connections are unaffected until they are recycled.
- The pool is handed a *coderef* in the broker case and a *value* in the non-broker
  case (`Storage.pm:152-157`). The pool's connection creation must keep calling the
  provider per connection (PoolBase contract); a change there that cached the first
  result would silently defeat rotation.
- All conninfo normalization (`dbname`→`database`, `pool_size` extraction) happens
  once in `_normalize_async_connect_info`; `_conninfo_hash` assumes its input is
  already normalized. A new normalization rule must go in that one method or the
  broker and static paths will drift.
- The broker interface and the open question of lifting broker consumption into the
  core abstract `DBIO::Storage::Async` are owned by core (ADR 0013 seam, ADR 0014
  "Future architecture work"); this ADR records only how *this* driver wires the
  existing seam into its pool, and does not pre-empt that core decision.
