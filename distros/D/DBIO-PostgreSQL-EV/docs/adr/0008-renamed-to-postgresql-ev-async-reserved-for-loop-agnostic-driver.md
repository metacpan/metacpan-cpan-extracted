# ADR 0008 — Renamed to DBIO::PostgreSQL::EV; ::Async reserved for the loop-agnostic driver

- Status: accepted
- Date: 2026-06-30
- Tags: packaging, naming, ev-pg, async, drivers
- Superseded in part: the `async_backend` opt-in named below is superseded by
  core ADR 0030 (see the Amendment); the rename itself stands

## Amendment (2026-09-05, karr k31) — the `async_backend` opt-in is superseded by core ADR 0030

The rename this ADR decides is in force and unchanged. Its *Demo / opt-in*
decision bullet and the matching *Consequences* entry are not: both describe the
mechanics of core ADR 0029 — a pluggable `async_backend` on the sync storage,
defaulting to a forked fallback — which core has since **withdrawn**. No
`async_backend` method exists any more, and there is no default async backend.

What holds instead, per core ADR 0030: async is an explicit **per-connection**
mode, chosen at `connect` with `{ async => 'ev' }` and fixed for the life of that
storage instance. The `ev` mode is registered by the sync driver —
`DBIO::PostgreSQL::Storage` calls
`register_async_mode( ev => 'DBIO::PostgreSQL::EV::Storage' )` — and core
resolves it by walking the *storage* MRO, so this distribution's schema
component takes no part in it. Nothing degrades: without the opt-in a `*_async`
call croaks, and so does a requested mode whose backend is not installed
(ADR 0030 §3). `demo/dbio-demo-async` accordingly opts in **at** `connect`, not
after it.

Read the `async_backend` sentences below for the record; do not implement from
them.

## Context

This distribution is the EV::Pg / libpq-async PostgreSQL driver: it bypasses DBI
and speaks libpq's async protocol directly, and it is hard-wired to the EV event
loop (`EV::Pg` drives all IO through `EV`). It was originally named
`DBIO::PostgreSQL::Async` / `DBIO-PostgreSQL-Async` and first shipped to CPAN as
`GETTY/DBIO-PostgreSQL-Async-0.900000`.

Since that release the DBIO family grew a generic, loop-agnostic async layer —
`DBIO::Async::Storage` (the `dbio-async` dist), built on `Future` / `Future::IO`,
where the user picks the event loop and no loop is a hard requirement. A *second*
PostgreSQL async driver, built on that shared layer rather than on EV::Pg, is
planned. That loop-agnostic driver is the one that should legitimately own the
`DBIO::PostgreSQL::Async` name: "Async" describes the loop-agnostic Future-bearing
posture, not a driver welded to one specific loop. Two drivers cannot share the
namespace, and calling the EV-only driver "Async" overpromises — it can never be
loop-agnostic.

## Decision

Rename this distribution and its namespace to `DBIO::PostgreSQL::EV` /
`DBIO-PostgreSQL-EV`, naming the driver for the event loop it is actually bound
to, and reserve the `DBIO::PostgreSQL::Async` namespace for the future
loop-agnostic driver.

- **Namespace.** `DBIO::PostgreSQL::Async::*` → `DBIO::PostgreSQL::EV::*`
  (`DBIO::PostgreSQL::EV`, `::EV::Storage`, `::EV::Pool`, `::EV::ConnectInfo`,
  `::EV::TransactionContext`). Module files move under `lib/DBIO/PostgreSQL/EV/`.
- **Dist + tooling.** `dist.ini` `name` → `DBIO-PostgreSQL-EV`; the shipped skill
  and worker agent slugs become `dbio-postgresql-ev` /
  `dbio-worker-postgresql-ev`.
- **CPAN.** This is a namespace migration, not a deletion:
  `DBIO-PostgreSQL-Async-0.900000` stays published on CPAN, and the historical
  `Changes` entries keep the old name (they correctly record what was released).
- **Demo / opt-in.** The async demo previously relied on the sync PostgreSQL
  driver defaulting its `async_backend` to this dist (install the dist, get async
  for free). That default is being withdrawn: the sync driver defaults to the
  forked fallback and EV becomes opt-in. The demo now sets
  `async_backend('DBIO::PostgreSQL::EV::Storage')` explicitly before its first
  `*_async` call.

## Rationale

Naming the driver `EV` is honest about its single hard constraint: it runs on
EV::Pg and the EV loop, full stop. Reserving `::Async` for the loop-agnostic
driver keeps the family namespace meaningful — `::Async` = generic /
`Future::IO` / loop-agnostic, `::EV` = this EV-specific driver — instead of
burning the more general name on the more specific thing. Doing the rename now,
before the loop-agnostic driver exists, avoids a later collision on
`DBIO::PostgreSQL::Async` and spares users of the new driver a confusing
after-the-fact migration. The migration is mechanical: no runtime behaviour
changes here, the only behavioural consequence (EV opt-in) lives in the sync
driver's default and is reflected in this dist only by the demo.

This rename is shipped in this commit, hence **accepted**, not proposed.

## Consequences

- `DBIO-PostgreSQL-Async-0.900000` remains the last release under the old name on
  CPAN; new releases ship as `DBIO-PostgreSQL-EV`. Users pin/move accordingly.
- The `DBIO::PostgreSQL::Async` namespace and the `dbio-postgresql-async` slug are
  now free and reserved for the future loop-agnostic, `DBIO::Async::Storage`-based
  PostgreSQL driver.
- Async is opt-in. Enabling async on a PostgreSQL schema now requires pointing
  `async_backend` at `DBIO::PostgreSQL::EV::Storage` explicitly; code that relied
  on the sync driver auto-routing to this backend must add that opt-in (as the
  demo now does).
- The Codeberg repository (`codeberg.org/dbio/dbio-postgresql-async`) and the
  on-disk repo directory keep the old slug for now; renaming them, and updating
  the sync driver's default `async_backend`, are separate follow-ups outside this
  commit.
