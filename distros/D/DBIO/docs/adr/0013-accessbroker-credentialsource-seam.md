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
  handles. The abstract `connect_info_for` croaks until a subclass implements it;
  `needs_refresh`/`refresh` provide the rotation
  lifecycle. A broker does **not** route and does **not** own a host list
  (CONTEXT.md).
- **Source axis: Static + Vault.** Two adapters subclass AccessBroker:
  `DBIO::AccessBroker::Static` (single fixed credential set, transaction-safe, no
  rotation) and `DBIO::AccessBroker::Vault` (TTL'd rotating credentials,
  not transaction-safe by default). `DBIO::AccessBroker::HostBound` is *not* a
  third source — it is a view that pairs one CredentialSource with one Host at
  connect time (CONTEXT.md), holding no credentials of its own and
  delegating every credential operation to the wrapped broker, so one credential
  can serve many servers in a Replicated topology (ADR 0012) without the broker
  learning the host list.
- **Consumer axis: Storage::DBI (today).** The broker-consumption machinery —
  the `access_broker` accessor, `set_access_broker`,
  `current_access_broker_connect_info` — lives on the *base* `DBIO::Storage`
  (`lib/DBIO/Storage.pm`), so any storage subclass *can* be a
  consumer; in core the one real consumer is `DBIO::Storage::DBI`, via the
  `DBIO::Storage::DBI::AccessBroker` mixin (detects a broker as connect_info,
  routes to it for current credentials at connect/reconnect). (`Storage::Async`
  has since become the second — see the addendum of 2026-10-04.)

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
places it under "NEW CONCEPTS" (`lib/DBIO/Manual/Heritage.pod`,
"DBIO::AccessBroker — credential source interface"), listing the Static, Vault and
HostBound built-ins. CONTEXT.md states the seam shape precisely
(`CONTEXT.md`): "real on the source axis (two adapters: `Static`, `Vault`); on
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
- **Seam-status flag (code vs CONTEXT.md).** CONTEXT.md calls async a
  "planned-but-unwired second" consumer. That is true of the **core abstract**
  `DBIO::Storage::Async`, which references no broker. It is **stale** for the
  concrete async *driver* dists: `dbio-postgresql-async` and `dbio-mysql-async`
  already call `set_access_broker` / `current_access_broker_connect_info` in their
  `Async/Storage.pm`. So the second
  consumer exists in the driver distributions but has not been promoted into the
  core abstract interface, and CONTEXT.md has not been updated. Recorded as the
  shared seam with ADR 0014; closing it (lift the consumption into
  `Storage::Async`, refresh CONTEXT.md) is cross-repo work, tracked there, not in
  this ADR. (Closed since — see the addendum of 2026-10-04.)
- Tested in `t/access_broker/` (Static source, HostBound view lifecycle,
  Storage::DBI reconnect, Replicated passthrough). No dedicated core Vault test was
  found; the Vault adapter's behaviour is exercised through driver dists. (Core
  has one — see the addendum of 2026-10-04.)

## Addendum 2026-10-04 — the seam-status flag is closed: `Storage::Async` is the second consumer (karr k280)

What the flag above called open has landed, and three statements of this ADR
no longer describe the code:

- **The consumer axis has two consumers in core.** `DBIO::Storage::Async`
  consumes the broker itself: `_is_access_broker_connect_info`,
  `_setup_access_broker` / `_clear_access_broker`, the per-spawn
  `_conninfo_provider`, and the transport seam `_async_broker_conninfo`, on the
  `set_access_broker` / `current_access_broker_connect_info` it inherits from
  `DBIO::Storage` (ADR 0014 records the lift). `CONTEXT.md` states two real
  consumers; the sentence quoted in the Rationale is its earlier wording.
- **The async adapters live elsewhere than the flag says.** The `future_io`
  adapters are `DBIO::<Driver>::Storage::Async` in dbio-postgresql and
  dbio-mysql, on the shared base in dbio-async; the family holds no
  `dbio-postgresql-async` or `dbio-mysql-async` dist.
- **The Vault adapter is tested in core:** `t/access_broker/02-vault.t`, with
  its rotation and its failed refresh in `18-dbi-vault-rotation.t` and
  `23-vault-refresh-failure.t`.

And one thing this ADR leaves unsaid: **who builds a `HostBound` view.** The
application does — one `$broker->for_host($host)` per host, each handed to its
backend's connection (the master's `connect`, a replicant's `connect_replicants`
entry). Nothing in core calls `for_host`; Replicated passes a view through like
any broker (`t/access_broker/25-replicated-shared-rotating-broker.t`).

## Addendum 2026-10-09 — a HostBound view binds its host through a driver seam, and refuses what it cannot bind (karr k276)

Maintainer decision of 2026-10-09. The view's one way of naming a server was a
`host=`/`port=` token after `dbi:Driver:`. For every DSN that names its server
another way it put a `host=` token in front that the DBD does not read, so a
replicant given the view connected to the master of the answer, silently.

**Decision.**

- **A seam, `DBIO::Storage::DBI::_bind_host_into_dsn($driver, $dsn, $host,
  $port)`**, next to `_connect_params_dsn` (ADR 0057). Class or instance
  method, no instance data. It returns the DSN with the host (and the port,
  when defined) bound, or declines with the list `(undef, $form)`, `$form`
  being a key name or a dialect and never a value of the DSN.
- **The core default** is the old behaviour: the `dbi:Driver:` form whose parts
  are all `key=value` gets `host=`/`port=` replaced in place or put in front.
  It declines a DSN without the prefix, a part without `key=value` form (Easy
  Connect, TNS, data source name, mysql positional), a part whose key names a
  server another way (`hostaddr`, `hostname`, `server`, `servername`,
  `address`, `addr`, `dsn`; case-insensitively), and a `db`/`dbname`/
  `database` whose value begins `host:` or `host/port:` (Firebird). A local
  path or a Windows drive stays translatable.
- **Asked of whom.** The class of the storage the view was asked through, then
  the storage class registered for the DSN's DBD -- driver resolution is lazy,
  so before the first connection the storage is legitimately the generic class.
  The first whose seam is not core's default answers; else the default.
- **Refusal instead of silence.** What the seam declines, a code reference in
  slot 0, a `dbh_maker` and a host or port containing `;` make the view throw,
  naming the form, quoting neither the DSN nor a credential. The `;` check
  runs in the view before any seam is asked, so a driver never sees one. An
  undef slot 0 (`DBI_DSN`) and an empty hash (karr k253) are handed on as
  before; a hash answer with a `dsn` has the host bound into that DSN and no
  `host`/`port` attribute; a hash without one is unchanged (connection
  parameters, ADR 0057).

**Consequences.**

- A view over an answer the default cannot translate now throws where it used
  to connect to the wrong host. A driver whose DSN is such a form must override
  the seam to keep its views working. Open on the driver boards, nothing
  changed there by this decision: dbio-postgresql (`hostaddr=`), dbio-oracle
  (Easy Connect, TNS), dbio-db2 (`HOSTNAME=`), dbio-sybase (`server=`), ODBC
  and MSSQL (`Server=`, `DSN=`), dbio-mysql (positional), dbio-firebird
  (`db=host:path`).
- Until a driver does, giving the answer as connection parameters (ADR 0057)
  or as a DSN with `host=`/`port=` is the way.
- Tests: `t/access_broker/28-hostbound-dsn-dialects.t`. No ADR 0024 contract
  version moves: the seam has a default and no driver is required to override
  it.

## Addendum 2026-10-09 — a broker keeps account of every storage it is attached to (karr k278)

Maintainer decision of 2026-10-09: define the behaviour with several storages,
do not turn the back-reference into a stub. The broker held one weak reference,
to the storage attached last. One broker is attached to several storages as a
matter of course -- a sync owner and its embedded async backend, the master and
the replicants of a Replicated storage -- so the legacy
`current_connect_info_for` answered for whichever was attached last, and for a
storage that had detached the broker as well.

**Decision.**

- **The broker keeps all of them.** `set_storage` adds the storage; it replaces
  nothing. The references stay weak (karr k270, no cycle), and a storage that
  is freed drops out on its own.
- **A storage that detaches is taken out.** `DBIO::AccessBroker::unset_storage`
  removes that storage and no other. `DBIO::Storage::clear_access_broker` calls
  it on the broker it holds, and so does `set_access_broker` for the broker it
  replaces. `HostBound::unset_storage` hands it on to the wrapped broker as
  `set_storage` does; the references of storages that other views attached
  stay.
- **`current_connect_info_for($mode, $storage)`** takes the storage as an
  optional second argument and answers for it. Without one: no storage attached
  -- `connect_info_for`, as before; exactly one -- that one, as before; more
  than one -- it throws, naming the broker class and the count and pointing at
  the storage argument and `current_connect_info_for_storage`. It never picks
  one of several, and it refreshes nothing before it throws.

**Consequences.**

- A caller that asked a shared broker without a storage and got the answer of
  the last attached now gets an exception. Nothing in core or in the sibling
  repos called `current_connect_info_for` (grep, 2026-10-04); the storages
  themselves ask `current_connect_info_for_storage` with themselves.
- A subclass that overrides `current_connect_info_for` is not forced to take
  the second argument; it keeps answering as it did.
- Tests: `t/access_broker/27-broker-storage-backref.t`.
