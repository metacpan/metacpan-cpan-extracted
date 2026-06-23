# ADR 0013 — AccessBroker / CredentialSource seam

- Status: accepted
- Date: 2026-06-19
- Tags: accessbroker, credentialsource, storage, vault, replicated, backfill

## Context

DBIx::Class carried database credentials as raw `connect_info` — a DSN plus
user/password, or a single DSN string. There was no abstraction for *where*
credentials come from, no lifecycle (fetch / rotate / refresh), and no way to
plug in a secrets backend. With replicated storage now in core (ADR 0012) and
credential rotation (e.g. Vault-issued leases) a real operational need, DBIO
separates two historically-independent strands that now share a codebase:
credential provision and read/write routing. The domain language for this seam is
defined in `CONTEXT.md`; this ADR records the architectural decision, not the
vocabulary.

## Decision

Introduce a credential seam with two axes — a *source* axis (where credentials
come from) and a *consumer* axis (who needs them) — mediated by
`DBIO::AccessBroker`.

- **AccessBroker is the CredentialSource.** `DBIO::AccessBroker`
  (`lib/DBIO/AccessBroker.pm`) supplies the connect info for exactly *one backend
  identity*, and is storage-agnostic — it returns connection *parameters*, not
  handles. The abstract `connect_info_for` croaks until a subclass implements it
  (`AccessBroker.pm:54-55`); `needs_refresh`/`refresh` provide the rotation
  lifecycle. A broker does **not** route and does **not** own a host list
  (CONTEXT.md:12-19, 54).
- **Source axis: Static + Vault.** Two adapters subclass AccessBroker:
  `DBIO::AccessBroker::Static` (single fixed credential set, transaction-safe, no
  rotation) and `DBIO::AccessBroker::Vault` (TTL'd rotating credentials,
  not transaction-safe by default). `DBIO::AccessBroker::HostBound` is *not* a
  third source — it is a view that pairs one CredentialSource with one Host at
  connect time (CONTEXT.md:29-32), holding no credentials of its own and
  delegating every credential operation to the wrapped broker, so one credential
  can serve many servers in a Replicated topology (ADR 0012) without the broker
  learning the host list.
- **Consumer axis: Storage::DBI (today).** The broker-consumption machinery —
  the `access_broker` accessor, `set_access_broker`,
  `current_access_broker_connect_info` — lives on the *base* `DBIO::Storage`
  (`lib/DBIO/Storage.pm:25, 98, 134`), so any storage subclass *can* be a
  consumer; in core the one real consumer is `DBIO::Storage::DBI`, via the
  `DBIO::Storage::DBI::AccessBroker` mixin (detects a broker as connect_info,
  routes to it for current credentials at connect/reconnect).

## Rationale

Raw `connect_info` is fine when credentials are static and known at boot, and
nothing else when they rotate or come from a secrets manager. Modelling the
*source* as a pluggable CredentialSource (Static today, Vault for rotation,
anything tomorrow) lets credential lifecycle be a first-class concern without
touching the storage that consumes it. Keeping the broker to a single backend
identity — never a host list — is the deliberate boundary that keeps it from
re-becoming a router: topology and routing belong to Replicated (ADR 0012), and
the `HostBound` view is the explicit, minimal join between one credential and one
host. CONTEXT.md flags the historical `ReadWrite` broker (which bundled identity
+ hosts + routing) as exactly the category error this seam removes.

This is a DBIO-original abstraction with no DBIx::Class precedent; Heritage.pod
places it under "NEW CONCEPTS" (`lib/DBIO/Manual/Heritage.pod:357-391`,
"DBIO::AccessBroker — credential source interface"), listing the Static, Vault and
HostBound built-ins. CONTEXT.md states the seam shape precisely
(`CONTEXT.md:58`): "real on the source axis (two adapters: `Static`, `Vault`); on
the consumer axis it currently has one real consumer (`Storage::DBI`), with
`Storage::Async` a planned-but-unwired second."

## Consequences

- Credentials are sourced through a pluggable lifecycle, not hard-wired. Adding a
  new source is a new `DBIO::AccessBroker` subclass implementing
  `connect_info_for` (+ rotation hooks); the consuming storage is unchanged.
- The seam keeps credentials and topology cleanly apart: a broker is one
  identity, Replicated owns the host list (ADR 0012), and `HostBound` is the only
  thing that pairs them — so one Vault lease can serve a master and every
  replicant without the broker knowing they exist.
- The consumer machinery sitting on base `Storage` (not `Storage::DBI`) is the
  load-bearing design choice for the open seam: it means async storage can become
  a consumer without moving the seam. See ADR 0014 — and the flag below.
- **Seam-status flag (code vs CONTEXT.md).** CONTEXT.md:58 calls async a
  "planned-but-unwired second" consumer. That is true of the **core abstract**
  `DBIO::Storage::Async`, which references no broker. It is **stale** for the
  concrete async *driver* dists: `dbio-postgresql-async` and `dbio-mysql-async`
  already call `set_access_broker` / `current_access_broker_connect_info` in their
  `Async/Storage.pm` (PostgreSQL `:82-112`, MySQL `:78-108`). So the second
  consumer exists in the driver distributions but has not been promoted into the
  core abstract interface, and CONTEXT.md has not been updated. Recorded as the
  shared seam with ADR 0014; closing it (lift the consumption into
  `Storage::Async`, refresh CONTEXT.md) is cross-repo work, tracked there, not in
  this ADR.
- Tested in `t/access_broker/` (Static source, HostBound view lifecycle,
  Storage::DBI reconnect, Replicated passthrough). No dedicated core Vault test was
  found; the Vault adapter's behaviour is exercised through driver dists.
