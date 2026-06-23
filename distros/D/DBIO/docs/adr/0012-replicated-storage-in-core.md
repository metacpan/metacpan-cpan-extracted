# ADR 0012 — Replicated storage in core

- Status: accepted
- Date: 2026-06-19
- Tags: replicated, storage, topology, moose, backfill

## Context

DBIx::Class shipped read/write-splitting replicated storage as an external
distribution feature: `DBIx::Class::Storage::DBI::Replicated` was gated behind a
heavyweight optional dependency set (Moose, MooseX::Types,
MooseX::Types::LoadableClass and friends) — the `--with-replicated` optional
feature. Replication was therefore both *separate* and *Moose-coupled*. DBIO,
which roots its whole internal tree on a lightweight non-Moose base
(`DBIO::Base`, ADR 0001), needs replication to fit that base rather than drag a
Moose stack into core.

## Decision

Bring replicated storage into the core distribution as a first-class
`DBIO::Replicated::*` subsystem, re-implemented on `DBIO::Base` /
`Class::Accessor::Grouped` with no Moose dependency, available unconditionally.

- `DBIO::Replicated` (`lib/DBIO/Replicated.pm`) is the Schema component; loading
  it forces `+DBIO::Replicated::Storage` and coordinates one master backend plus
  optional replicants. Writes, transactions and deploy go to the master; reads
  go to the configured balancer.
- The subsystem is a *top-level* `DBIO::Replicated::*` tree, not nested under
  `DBIO::Storage::*`: `Replicated::Storage` (coordinator), `Replicated::Backend`
  (+ `Backend::Master`, `Backend::Replicant`), `Replicated::Pool` (replicant
  pool, validation/lag tracking), `Replicated::Balancer` (+ `Balancer::First`,
  `Balancer::Random`), and `Replicated::DebugProxy`.
- **No Moose.** Every module roots on the DBIO base classes —
  `Replicated::Storage` extends `DBIO::Storage::DBI`; `Backend`, `Balancer` and
  `Pool` use base `DBIO::Base`; accessors are `Class::Accessor::Grouped`
  `mk_group_accessors(simple => ...)`. There is no `use Moose`, no MooseX in the
  subsystem.
- **Unconditional in core.** The core `cpanfile` has no replication optional
  feature and no replication-gated Moose dependency. Moose/Moo appear only as
  `suggests` for the unrelated `DBIO::Moo`/`DBIO::Moose` user bridges.

## Rationale

Two things were wrong with the upstream arrangement for DBIO: replication was an
extra install, and it forced a Moose runtime that the rest of DBIO does not use.
Re-implementing the subsystem on `DBIO::Base` + `Class::Accessor::Grouped` makes
replicated storage a peer of every other core storage and component — same OOP
substrate, same MRO, no parallel object system — and removes the optional-feature
gate so any schema can `load_components('DBIO::Replicated')` without dependency
gymnastics. The de-Moosing is the architecturally significant half: "in core" is
the headline, but "in core *without* the Moose stack" is the decision that made
it fit.

Putting the subsystem at top-level `DBIO::Replicated::*` (not
`DBIO::Storage::Replicated::*`) signals it is a first-class feature coordinating
storage backends, not a Storage-layer plugin. The clean separation of
*identity/credentials* from *topology/routing* — Replicated owns Topology and
Routing; the credential side is the AccessBroker seam (ADR 0013) — is the domain
boundary documented in CONTEXT.md.

Heritage records it (`lib/DBIO/Manual/Heritage.pod:96-115`): "C<DBIx::Class::
Replicated> was an external distribution. L<DBIO::Replicated> ships in the core
distribution," loaded as a Schema component; and the migration table
(Migration.pod) maps `DBIx::Class::Replicated → DBIO::Replicated (in core)`.

## Consequences

- Replicated storage is always available in core, loaded as one Schema component,
  with no optional-feature install and no Moose runtime pulled in.
- Read/write routing is owned here (writes/txns/deploy → master, reads →
  balancer, default `Balancer::First`); credential provision is *not* — that is
  the AccessBroker seam (ADR 0013). A replicant's credential never gates
  transactions; only the master's does (CONTEXT.md). The two concerns meet at the
  `HostBound` view (ADR 0013), which lets one credential identity serve every
  host in the topology.
- **Layout flag:** the karr ticket says "lib/DBIO/Storage Replicated." The real
  shape is a top-level `DBIO::Replicated::*` subsystem (ten modules), not a single
  `Storage/Replicated.pm`. The relocation out of `Storage::` is itself part of the
  decision (first-class, not a Storage plugin).
- Tested in `t/test/08_replicated.t`, with broker interaction in
  `t/access_broker/06-replicated-passthrough.t` (the seam to ADR 0013).
