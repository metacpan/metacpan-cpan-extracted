# ADR 0003 — Server-type reblessing and runtime FreeTDS trait synthesis

- Status: accepted
- Date: 2026-06-20
- Tags: storage, rebless, freetds, dispatch

## Context

`DBD::Sybase` is a single DBD that talks to *several* distinct servers
(Sybase ASE and Microsoft SQL Server) and can be compiled against *two*
different client libraries (the native Sybase OpenClient, or FreeTDS) whose
behaviour differs sharply — most visibly, TEXT/IMAGE and `LongReadLen` do not
work under FreeTDS, and transaction control statements differ.

The DSN alone (`dbi:Sybase:...`) cannot tell these apart. The driver registry
only routes on the DBD name (`Sybase`), so a second dispatch step is needed
*after* a handle exists, and a third axis (client library) is orthogonal to the
server type.

`DBIO::Sybase::Storage` resolves this in two stages:

1. **`_rebless`** runs `sp_server_info @attribute_id=1`, normalises the result
   (`SQL_Server` → `ASE`), and reblesses into
   `DBIO::Sybase::Storage::<servertype>` — `DBIO::Sybase::Storage::ASE`, or a
   class another dist registers (e.g. `DBIO::MSSQL::Storage::Sybase`).
2. **`_init`** detects FreeTDS via `syb_oc_version` and, if present,
   **synthesises a new class at runtime** — `<current>::FreeTDS` — whose `@ISA`
   is `(<current>, DBIO::Sybase::Storage::FreeTDS, <rest of the linear ISA>)`,
   sets its mro to c3, and reblesses the instance into it. The code comment
   calls this a "dirty version of instance role application."

## Decision

Keep both stages: data-driven reblessing on server type, and the dynamic
`::FreeTDS` ISA-synthesis for the client-library axis. Do not replace the
synthetic-class trick with a static `::FreeTDS` subclass per server type, and do
not move the FreeTDS fixups into `Storage::ASE` directly.

## Rationale

- **Server type is genuinely runtime data.** It is only knowable after a handle
  is open, and a third party (MSSQL) registers into the same dispatch — so the
  seam must stay open and live in the shared `Storage` base, not be hard-wired.
- **The two axes are independent.** Server type (ASE vs MSSQL) and client
  library (OpenClient vs FreeTDS) multiply. A static class matrix would need
  `ASE`, `ASE::FreeTDS`, `MSSQL::Sybase`, `MSSQL::Sybase::FreeTDS`, ... and each
  new server registrant would owe two classes instead of one. Synthesising
  `<whatever-we-rebless-to>::FreeTDS` at runtime mixes the FreeTDS concern onto
  *any* current class — including third-party ones — for free, while keeping the
  FreeTDS fixups (`SET TEXTSIZE`, explicit `BEGIN TRAN`/`COMMIT`/`ROLLBACK`,
  `SET CHAINED`) in one place (`Storage::FreeTDS`).
- The FreeTDS class must sit **after** the current class in the ISA so the
  current class's methods win and `next::method` chains forward — the ordering
  is deliberate, mirroring the ISA-ordering rule for ASE's own Storage mixins.

## Consequences

- The synthetic class is created with `no strict 'refs'` ISA assignment plus a
  `Class::C3->reinitialize` under an old mro; this is fragile by nature and must
  stay confined to `_init`. Do not expand the runtime-ISA trick to other
  concerns — new cross-cutting Storage behaviour goes in a normal mixin composed
  via `use base` (see the ASE storage and the driver-development skill).
- Adding support for another `DBD::Sybase`-served server type is done purely by
  *registering* a `DBIO::Sybase::Storage::<Type>` class; no change to the
  dispatcher is required, and FreeTDS support comes along automatically.
- FreeTDS is explicitly **experimental** (TEXT/IMAGE will not work); the
  `_rebless` path emits a one-time warning unless `DBIO_SYBASE_FREETDS_NOWARN`
  is set. That warning is part of the contract, not noise.
