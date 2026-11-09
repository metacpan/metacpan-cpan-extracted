# ADR 0035 — MSSQL ODBC connections rebless to a dedicated pure-ODBC storage class, off DBD::Sybase

- Status: accepted
- Date: 2026-07-16 (generalised 2026-08-05 — k142)
- Tags: storage, rebless, connector, registry, mssql, odbc, sybase, firebird, supersedes-0016

## Context

[ADR 0016](0016-mssql-connector-registry-reblesses-to-sybase-storage.md) recorded
that the core connector registry reblesses a `Microsoft_SQL_Server` ODBC
connection to `DBIO::MSSQL::Storage::Sybase` — one Sybase-derived MSSQL storage
class serving *both* the `DBD::Sybase` and `DBD::ODBC` transports — and
deliberately did **not** create a pure-ODBC MSSQL storage class. The driver-side
companion (`dbio-mssql` ADR 0006) recorded the same decision, justifying it by
calling a near-empty ODBC storage class a duplicate and a "maintenance trap".

That single-class design carried a cost the decision under-weighed: reblessing an
ODBC connection into `DBIO::MSSQL::Storage::Sybase` forced `DBIO::Sybase` (a
separate distribution) and its whole Sybase/FreeTDS layer into the ISA of a
connection that never uses it. Every Sybase-inherited behaviour — FreeTDS
detection (`_using_freetds`, the `_init` statement-cache workaround), the
`NoBindVars` rebless, `syb_date_fmt` — is inert on the ODBC transport, yet an
ODBC-only MSSQL deployment still had to depend on `DBIO::Sybase`.

## Decision

**An ODBC-detected MSSQL connection reblesses to a dedicated pure-ODBC storage
class, `DBIO::MSSQL::Storage::ODBC`, which does not pull in `DBIO::Sybase`; the
`DBD::Sybase` path keeps `DBIO::MSSQL::Storage::Sybase`.** The shape is a
transport-neutral base with one thin transport class per DBD.

- **Shared MSSQL semantics live in a transport-neutral base.**
  `DBIO::MSSQL::Storage` (in `dbio-mssql`) owns the engine-level behaviour that is
  identical regardless of DBD — MSSQL dialect, IDENTITY / `IdentityInsert`,
  `UniqueIdentifier`, money/subselect/savepoint handling. It self-registers only
  the synthetic `MSSQL` DBD name via `register_driver` and is never itself a
  rebless target.
- **Each DBD gets a thin transport class over that base.**
  `DBIO::MSSQL::Storage::ODBC` inherits from `DBIO::Storage::DBI::ODBC` and
  `DBIO::MSSQL::Storage`, with `DBIO::Sybase` absent from its ISA; it overrides
  nothing (the base already holds the dialect), so it is inheritance-only.
  `DBIO::MSSQL::Storage::Sybase` inherits from `DBIO::Sybase::Storage` and
  `DBIO::MSSQL::Storage`, retaining the real Sybase/FreeTDS behaviour and its own
  `NoBindVars` `_rebless`.
- **The core connector registry repoints to ODBC.** The baked-in
  `%_connector_registry` in core `DBIO::Storage::DBI` — and its
  `register_connector_driver` POD example — map `Microsoft_SQL_Server` to
  `DBIO::MSSQL::Storage::ODBC`. The lookup/rebless machinery
  (`_determine_connector_driver`) is unchanged; only the target class changed. The
  `DBD::Sybase` path continues to converge on `DBIO::MSSQL::Storage::Sybase`.

### The rule is not MSSQL-specific: every connector-registry value is that engine's ODBC class

Added 2026-08-05, reported out of `dbio-firebird` k20. The registry entry
this ADR fixed for MSSQL was wrong for **Firebird** in the mirror-image way:
`Firebird => DBIO::Firebird::Storage` named the `DBD::Firebird` class, so a
`dbi:ODBC:Driver=Firebird` DSN — which reports `SQL_DBMS_NAME = Firebird` —
was reblessed into a storage that speaks the `ib_*` API of a DBD the handle is
not. What that inherits and cannot run: `_init`'s `_set_sql_dialect(3)`, which
appends `ib_dialect=3` to the connect string (a `DBD::InterBase` DSN parameter
landing in an ODBC one, with a disconnect/reconnect around it),
`connect_call_use_softcommit` (`ib_softcommit`), `connect_call_datetime_setup`
(`ib_time_all`), `_explain_query`'s `$sth->func('ib_plan')` (a private XSUB of
`DBD::Firebird`/`DBD::InterBase`), and an `_ping` that selects from
`RDB$DATABASE` where `DBD::ODBC` has a real ping. In the other direction it
drops `DBIO::Storage::DBI::ODBC` out of the ISA and with it `_using_freetds`
and `_disable_odbc_array_ops`. The entry now reads
`Firebird => DBIO::Firebird::Storage::ODBC`.

**The invariant is stated once so the next entry cannot get it wrong.** The
only path into `%_connector_registry` is
`DBIO::Storage::DBI::ODBC::_rebless`, so the connection is *already* an ODBC
one when the lookup runs. Every value must therefore be that engine's storage
class **for this transport**, never its native-DBD class. That is now written
at the table itself and in the `register_connector_driver` POD, which is where
the mistake was made twice.

**Checked for the same confusion elsewhere, and there is none.** The table has
two entries; `Microsoft_SQL_Server` has pointed at `DBIO::MSSQL::Storage::ODBC`
since this ADR. The multi-transport question the family actually has —
`dbio-mssql` serving `DBD::ODBC` and `DBD::Sybase`, `dbio-firebird` serving
`DBD::ODBC`, `DBD::Firebird` and `DBD::InterBase` — is resolved one layer up,
in `%_driver_registry` by DBD name, and never reaches this table. No
transport dimension is added to the key: `$conn` is `'ODBC'` at the single
call site, core ships no ADO connector, and a second key for one caller would
be an abstraction with no user (house rule 2). If an ADO connector is ever
added, *that* is when the key grows.

## Rationale

The "near-empty duplicate is a maintenance trap" objection that justified the
single-class design is void once the shared behaviour is hoisted into the
transport-neutral base: the ODBC class duplicates nothing — it is pure
inheritance (`DBIO::Storage::DBI::ODBC` + `DBIO::MSSQL::Storage`). In exchange, an
ODBC-only MSSQL deployment no longer depends on `DBIO::Sybase` or drags a dead
FreeTDS/`NoBindVars` layer through its ISA. Splitting by transport also makes each
path's `isa` honest — the ODBC tests assert `DBIO::MSSQL::Storage::ODBC`, the
Sybase tests assert `DBIO::MSSQL::Storage::Sybase` (or `::Sybase::NoBindVars`) —
where before both transports landed on the same class.

Shipped and live-verified against MSSQL 2022, and offline with the entire optional
Sybase stack absent, hence **accepted**, not proposed.

## Consequences

- **ODBC-only MSSQL deployments drop the `DBIO::Sybase` dependency.** The dead
  Sybase/FreeTDS layer is no longer in the ISA of an ODBC connection.
- **Two rebless targets instead of one.** `Microsoft_SQL_Server` (ODBC) →
  `DBIO::MSSQL::Storage::ODBC`; the `DBD::Sybase` driver-name path →
  `DBIO::MSSQL::Storage::Sybase`. The registry lookup and rebless mechanism are
  otherwise unchanged from ADR 0016.
- **Ownership split (unchanged from ADR 0016).** The registry *mapping* is
  core-owned — hard-wired in core's `%_connector_registry`; `dbio-mssql` never
  calls `register_connector_driver` — so this superseding record is core's. The
  two transport storage classes are driver-owned; their supersession is tracked in
  `dbio-mssql`'s own ADR (see below).
- **Firebird over ODBC has a rebless target** (k142): `Firebird` maps to
  `DBIO::Firebird::Storage::ODBC`, shipped by `dbio-firebird` (its ADR 0010,
  commit `70aefa4`) as the same thin transport class over an engine-neutral
  base — `DBIO::Storage::DBI::ODBC` + `DBIO::Firebird::Storage::Common`. The
  `DBD::Firebird` and `DBD::InterBase` paths keep their own classes through
  `%_driver_registry`. **Core has no observable for this**: neither transport
  class is installable from core, so the assertion that a
  `dbi:ODBC:Driver=Firebird` DSN determines to the right class lives where the
  class does — `dbio-firebird` `t/59-odbc-storage.t`, which drives the whole
  route offline with `SQL_DBMS_NAME` stubbed at the one getter core reads it
  through. Core's side is one line and this record.
- **Traceability gap, recorded to close it.** The registry flip
  (`Microsoft_SQL_Server` → ODBC) was folded into the squashed release commit
  `2e34555fa` without being called out in that commit's body or in any ADR — which
  is why ADR 0016 went stale unnoticed. The driver-side rationale is explicit in
  `dbio-mssql` commits `c73dcde` ("route ODBC off the Sybase class") and `2cc2df7`.

## Relationship to other ADRs

- **Supersedes [ADR 0016](0016-mssql-connector-registry-reblesses-to-sybase-storage.md).**
  0016's core decision — `Microsoft_SQL_Server` reblesses to
  `DBIO::MSSQL::Storage::Sybase`, with no pure-ODBC class — is reversed here.
  0016's Status is updated to "superseded by 0035"; its text is otherwise left
  intact as the historical record of the single-class design and why it was tried.
- **Driver companion to supersede.** `dbio-mssql` ADR 0006
  (single-Sybase-class-serves-both) records the same now-reversed decision on the
  driver side and must be superseded there against this ADR (its next number,
  0007). That is driver-owned work and is tracked as a karr ticket on the
  `dbio-mssql` board — this core ADR does not write in that repo.
