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

## Addendum 2026-10-07 — stage 1 has a second entry for a declared driver (karr k64, core ADR 0059)

The Context above describes the storage as it comes in from the DSN: the
generic class, sent through the registry and `_rebless`. A schema that
**declares** the driver — the `Sybase` component or `-syb` — pins
`DBIO::Sybase::Storage` and is never sent that way. Under core ADR 0059 such a
storage adapts itself through `_adapt_to_access_path`, and for this driver
that hook is the second entry to stage 1:

- on a `dbi:Sybase:` DSN the declared base becomes
  `DBIO::Sybase::Storage::ASE` **without `sp_server_info`** — the schema has
  said what the server is. "Server type is genuinely runtime data" holds for
  the DSN detection only;
- it never becomes `DBIO::MSSQL::Storage::Sybase`. A server DBD::Sybase found
  to be Microsoft SQL Server at login (`syb_server_version_string`) is reported
  through core's `_driver_mismatch`;
- the placeholder decision that followed the rebless
  (`auto_cast` / `::ASE::NoBindVars`) is one body,
  `ASE::_adapt_to_placeholder_support`, called from `ASE::_rebless` and from
  the hook. It no longer calls itself after moving to `NoBindVars`; as written
  before, that call never returned.

The dispatch by `sp_server_info`, the open seam for other server types and
stage 2 are unchanged. The one-time FreeTDS warning now comes from the shared
body, on both entries.

Open, and not decided here: stage 2 builds the trait class over whatever class
the storage has. For a storage with layers (`DBIO::Storage::Composed`) that is
the composed class, so `DBIO::Sybase::Storage::FreeTDS` is linearised **ahead**
of the layers and the composition registry no longer knows the instance's
class. *Decided by the addendum below.*

## Addendum 2026-10-25 — storage layers stay ahead of the FreeTDS trait class (karr k77)

Decision (maintainer, 2026-10-25): **layers first.** Storage layers
(`register_storage_layer`) stay ahead of the driver, and the driver includes
the FreeTDS trait class synthesised at runtime.

- When `ref $self` is a `DBIO::Storage::Composed` class (`composition_of`),
  stage 2 builds the trait over the composition's **base**:
  `<base>::FreeTDS` with `@ISA = (<base>, DBIO::Sybase::Storage::FreeTDS,
  <rest of base's linear ISA>)`, c3. The layers are then set over it again
  with `DBIO::Storage::Composed->recompose(ref $self, $trait_class)` and the
  instance is blessed into the class that returns. A storage without layers is
  handled as before.
- Consequences: `composition_of(ref $storage)` knows the class (base
  `<ASE class>::FreeTDS`, layers unchanged); a layer method that the FreeTDS
  class has too (e.g. `set_textsize`) is asked first.
- No second `_init` call (karr k68): the chain goes on with `next::method`.
- `DBIO::MSSQL::Storage::Sybase` (dbio-mssql) inherits this `_init`, so its
  layered storage behaves the same under FreeTDS; no change is needed there
  (`t/59-component-rebless.t`, section 7b).
- This changes a runtime `@ISA`; it is recorded here as the card and ADR the
  house rule on composition seams requires.
