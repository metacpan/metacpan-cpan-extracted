# DBIO Connection Credentialing & Replication

How DBIO obtains database credentials and how it routes work across a primary
and read replicas. Exists to keep two historically-independent strands —
credential provision and read/write routing — cleanly separated now that both
live in the same codebase.

## Language

### Credentials vs. topology

**AccessBroker**:
A source of database credentials for exactly one backend identity.
_Avoid_: connection manager, router, pool, DSN provider.

**CredentialSource**:
The contract a backend storage depends on to obtain (and refresh) its connect
info — satisfied by **AccessBroker** subclasses, owned by the consumer (Storage).
_Avoid_: provider, factory, credential service.

**Backend identity**:
One set of credentials (user / password / lease), independent of which host uses it.
_Avoid_: account, login, role.

**Host**:
The location of one database server (dsn / host / port) — topology, never identity.
_Avoid_: node, instance.

**HostBound view**:
An adapter that pairs one **CredentialSource** with one **Host** at connect time,
so a single credential can serve many servers without the broker knowing the host list.
_Avoid_: routing broker, multi-host broker.

### Replication

**Topology**:
The set of backends (one master + zero or more replicants) and which is which — owned by Replicated.
_Avoid_: cluster config, layout.

**Routing**:
Deciding which backend serves a given query (writes → master, reads → balancer) — owned by Replicated.
_Avoid_: load balancing (that is one routing strategy, not the concept).

**Master**:
The sole writer backend; the only backend whose **CredentialSource** gates transaction safety.
_Avoid_: primary-as-credential, leader.

**Replicant**:
A read-only backend in the pool; its **CredentialSource** never gates transactions.
_Avoid_: slave, secondary.

## Relationships

- An **AccessBroker** supplies exactly one **Backend identity**; it never holds a **Host** list.
- **Replicated** owns **Topology** and **Routing**; it assigns each **Host** to a **Backend**.
- A **HostBound view** pairs one **CredentialSource** with one **Host** — this is how one credential serves many servers.
- Only the **Master** backend's **CredentialSource** gates transaction safety; **Replicant** credentials never do.
- A **CredentialSource** seam is real on the source axis (two adapters: `Static`, `Vault`); on the consumer axis it has two real consumers in core — the synchronous `Storage::DBI` (connect/reconnect path) and the async, Future-returning `Storage::Async` (per-pool-spawn `conninfo_provider`). Each consumes the same inherited broker-management API (`set_access_broker` / `current_access_broker_connect_info`) and adds only its tier's wiring: `Storage::DBI` via the `Storage::DBI::AccessBroker` mixin, `Storage::Async` via its lifted async-broker seam that feeds fresh credentials to every new pool connection.

## Example dialogue

> **Dev:** "If one Vault role issues a user/password valid on the primary and all replicas, do I hand each replica its own broker?"
> **Owner:** "No — that is one **Backend identity**, so it is one **AccessBroker**. Replicated owns the **Host** list; a **HostBound view** pairs that one credential with each **Host** at connect time. The broker never sees the list."
> **Dev:** "So a broker can point at multiple servers?"
> **Owner:** "A broker never represents multiple **Hosts** — that would be **Topology** in the wrong layer. It represents one credential that Replicated spans across **Hosts**."

## Flagged ambiguities

- **ReadWrite broker** historically bundled a **Backend identity** + a **Host** list + **Routing** (read round-robin) into one object. Resolved: that conflation is the category error this context removes — identity → **AccessBroker**, hosts + **Routing** → **Replicated**. `DBIO::AccessBroker::ReadWrite` is to be deleted; its read round-robin was unreachable through the storage layer anyway.
- The `$mode` parameter (`'read'`/`'write'`) on the broker API. Resolved: vestigial under single-identity **CredentialSource**s — deprecated, not load-bearing. Routing decides read vs write, not the broker.
