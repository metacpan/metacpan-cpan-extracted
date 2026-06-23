# ADR 0001 — Three-layer storage inheritance: Common → InterBase → Storage

- Status: accepted
- Date: 2026-06-20
- Tags: storage, inheritance, drivers, dbd, architecture

## Context

Every other DBIO driver has a single `::Storage` class subclassing
`DBIO::Storage::DBI`. This distribution is the only one with a three-layer
storage chain:

    DBIO::Storage::DBI
      └─ DBIO::Firebird::Storage::Common      (shared logic)
           └─ DBIO::Firebird::Storage::InterBase   (DBD::InterBase backend)
                └─ DBIO::Firebird::Storage         (DBD::Firebird backend)

The driver name registration confirms two distinct backends:
`Storage::InterBase` does `register_driver('InterBase' => __PACKAGE__)`
(`lib/DBIO/Firebird/Storage/InterBase.pm:9`) and `Storage` does
`register_driver('Firebird' => __PACKAGE__)`
(`lib/DBIO/Firebird/Storage.pm:9`). DBD::Firebird is closely modelled on
DBD::InterBase, so the two DBD backends share one logic base but reach the
server through different driver names.

This mirrors the upstream DBIx::Class lineage, where the InterBase storage
class was the original and the Firebird storage class was layered onto it.

## Decision

Split Firebird/InterBase storage into three classes:

- `DBIO::Firebird::Storage::Common` carries all backend-agnostic logic and
  extends `DBIO::Storage::DBI` **directly** — the in-code comment makes the
  intent explicit: "It extends L<DBIO::Storage::DBI> directly to avoid
  unnecessary inheritance depth" (`Storage/Common.pm:9-13`). It owns the
  quote char, `sql_maker_class`, `_use_insert_returning`, `sqlt_type`,
  generator/sequence handling, savepoints and the server-version query.
- `DBIO::Firebird::Storage::InterBase` adds the DBD::InterBase specifics:
  SQL dialect 3 forcing (ADR 0002), the `_ping` workaround, and the
  `connect_call_use_softcommit` / `connect_call_datetime_setup` connect-calls.
- `DBIO::Firebird::Storage` adds only the DBD::Firebird driver registration
  and the deploy-class hook; everything else is inherited.

## Rationale

The two DBD backends genuinely differ (different driver names, different
runtime quirks) yet share the overwhelming majority of behaviour, so a shared
base is the honest factoring rather than copy-paste between two leaf classes.
Putting `Common` directly under `DBIO::Storage::DBI` (rather than nesting it
under InterBase) keeps the depth at the minimum the two-backend reality
requires — the comment in `Common.pm` is a deliberate guard against someone
"tidying" the chain into a deeper or shallower shape that no longer reflects
which backend owns which quirk.

The layout also tracks upstream DBIx::Class, where Firebird storage was a
subclass of InterBase storage. Preserving that lineage means a maintainer who
knows the upstream module map finds the same seam here, and the InterBase
backend remains usable on its own (it registers its own driver name).

## Consequences

- Backend-agnostic Firebird logic (sequences, savepoints, quoting, the SQL
  maker class, insert-returning) goes in `Storage::Common`. DBD::InterBase
  quirks go in `Storage::InterBase`. DBD::Firebird-only concerns go in
  `Storage`. Putting a change at the wrong layer either leaks an InterBase
  quirk into the Firebird path or duplicates shared logic.
- The chain depth is intentional and minimal; do not collapse `Common` into
  `InterBase` (it would couple shared logic to one backend) and do not insert
  further layers — point such proposals here.
- `DBIO::Firebird::Storage::InterBase` is a usable driver in its own right
  (registered as `InterBase`), not merely an abstract midpoint.
