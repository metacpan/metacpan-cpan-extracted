# ADR 0006 — AccessBroker credential rotation via a `_conninfo_provider` coderef

- Status: accepted
- Date: 2026-06-21
- Tags: async, accessbroker, credentials, rotation, pool, drivers

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
