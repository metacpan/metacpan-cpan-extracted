# ADR 0010 — The ODBC transport branches off Storage::Common, not off the InterBase driver

- Status: accepted
- Date: 2026-08-05
- Tags: storage, inheritance, odbc, rebless, connector, registry, extends-0001

## Context

[ADR 0001](0001-three-layer-storage-inheritance.md) records a three-layer chain
— `Storage::Common` → `Storage::InterBase` → `Storage` — for the two native
DBDs. Firebird has a **third** transport, `DBD::ODBC`, and this distribution had
no class for it: `dbi:ODBC:Driver=Firebird` determined to core's generic
`DBIO::Storage::DBI::ODBC` and inherited nothing of this engine — core's
`LIMIT`/`OFFSET` instead of `FIRST`/`SKIP`, a `FROM`-less `EXISTS` statement,
`EXCEPT`/`INTERSECT` keywords the engine has no token for, core quoting,
`sqlt_type`, sequences and savepoints. The POD of `Storage::InterBase` had
pointed at `DBIO::Storage::DBI::ODBC::Firebird` in three places since the fork —
an upstream class name that never existed in this namespace — and the ODBC leg
of `t/10-firebird.t`, `t/20-firebird-core.t` and `t/30-datetime-firebird.t`
(`DBIO_TEST_FIREBIRD_ODBC_DSN`) advertised a transport the code did not
implement (karr k20).

The tempting shape is a subclass of `Storage::InterBase`, which is where the
Firebird-facing connect-calls already live. It is the wrong one: that class
speaks the `ib_*` API of `DBD::InterBase` — `ib_dialect` in the DSN,
`ib_softcommit`, `ib_time_all`, and `$sth->func('ib_plan')` for a query plan —
and none of it exists on a `DBD::ODBC` handle.

## Decision

**`DBIO::Firebird::Storage::ODBC` is a transport class over
`Storage::Common`, a sibling of the InterBase branch rather than a descendant
of it**: `use base qw/DBIO::Storage::DBI::ODBC DBIO::Firebird::Storage::Common/`
under `mro 'c3'`, the same shape `DBIO::MSSQL::Storage::ODBC` has (dbio-mssql
ADR 0007). The transport base comes first so `_rebless` — connector
determination — resolves there.

The cut between the classes is: **what is a fact about the SQL both engines
speak lives on `Storage::Common`; what hangs off a DBD's own API stays with that
DBD.** So this class inherits the `FIRST`/`SKIP` dialect, `RAND()`,
`GEN_ID` sequences, `RDB$DATABASE` in the `EXISTS` rendering with its
`supports_exists_query` declaration, the refusal of the four set operations
Firebird has no operator for, `INSERT ... RETURNING`, the `"` quote char and
`sqlt_type`; and it inherits none of the `ib_*` connect-calls, the dialect-3 DSN
rewrite, the InterBase `_ping`, or the `func('ib_plan')` plan read.

It carries five things of its own, all transport facts:

- `datetime_parser_type` — `Storage::Common` declares none (each transport
  does), and core's default is the historic `DateTime::Format::MySQL`.
- `connect_call_datetime_setup` as a **noop**, so `on_connect_call =>
  'datetime_setup'` works unchanged on all three transports. Connect-calls are
  resolved by method name, so the absence of the method is a die, not a skip.
- `_run_connection_actions` → `_disable_odbc_array_ops` when the driver
  identifies as `OdbcFb`, and the two savepoint workarounds
  (`_exec_svp_release` as a noop, `_exec_svp_rollback` swallowing the driver's
  undescribable error) — all three carried over from upstream `DBIx::Class`
  with their reasons.
- `_explain_query` **throws**. Firebird has no `EXPLAIN` statement and its plan
  is an attribute of the prepared statement (`isc_info_sql_get_plan`), which
  `DBD::ODBC` exposes in no form; inheriting core's prefix would be a parse
  error from the server and inheriting the InterBase override would be a call
  into a function the handle does not have.

**The registry mapping that routes an ODBC DSN here is core's, not this
repo's.** Core determines `dbi:ODBC:` to `DBIO::Storage::DBI::ODBC`, whose
`_rebless` reads `SQL_DBMS_NAME` and looks it up in core's
`%_connector_registry`. That table mapped `Firebird` to
`DBIO::Firebird::Storage` — the `DBD::Firebird` class — and was flipped to this
class by **core karr k142** (core commit `9676d53ad`). This distribution does not call
`register_connector_driver`: the ownership split is the one core ADR 0035 and
dbio-mssql ADR 0007 already record, and a driver-side registration would not
work anyway, since nothing loads the class before the lookup needs it.

## Rationale

The alternative shapes were: subclass `Storage::InterBase` (rejected — it drags
four `ib_*` writes and a private XSUB into a handle that has none of them);
teach `Storage::Common` the ODBC quirks with a transport check (rejected — a
driver-name match inside shared code, which is the ADR 0021 anti-pattern);
delete the ODBC references from POD and tests instead (rejected — the transport
works, is the better fit for long-running processes precisely because it has no
nested-statement-handle problem, and three test files already drive it).

Everything above is pinned offline in `t/59-odbc-storage.t`: the route from DSN
to class with only `SQL_DBMS_NAME` stubbed, the ISA order, the seams asked of
the storage rather than of `isa`, and the explain refusal. The registry half
was a `TODO` block naming core karr k142 while that flip was pending; with the
entry flipped it is a plain assertion, and the file registers nothing itself —
what it drives is the table an installed core ships.

## Consequences

- **A fourth place to put a change, and the cut decides which.** Engine SQL →
  `Storage::Common` (all three transports). `DBD::InterBase`/`DBD::Firebird`
  API → `Storage::InterBase`. `DBD::ODBC` → this class. A transport fact put on
  `Common` breaks the other two.
- **Query plans are unavailable over ODBC**, by refusal rather than by error.
- **Not verified against a server.** No Firebird was reached over ODBC for any
  of this: the savepoint and array-ops workarounds are upstream findings and the
  datetime claim is the ODBC canonical format. The `DBIO_TEST_FIREBIRD_ODBC_DSN`
  leg of the three live test files is where that gets checked.
- **A minimum core version.** Against a core older than karr k142 an ODBC DSN
  reblesses into the `DBD::Firebird` class unless the caller registers the
  mapping itself; the POD of this class says so and shows the one-liner.

## Relationship to other ADRs

- **Extends [ADR 0001](0001-three-layer-storage-inheritance.md).** 0001's chain
  is unchanged and its "do not insert further layers" guard still holds — this
  is a branch beside `Storage::InterBase`, not a layer between existing ones.
  0001's three-bucket rule for where a change goes gains a fourth bucket.
- **Same shape as dbio-mssql ADR 0007** (a dedicated pure-ODBC storage class
  over a transport-neutral base) and its core companion **ADR 0035**, which owns
  the connector-registry half for both drivers.
- **ADR 0011 (core)**, **ADR 0037**, **ADR 0039** and **ADR 0040** are the seams
  inherited here; ADR 0040 is the one this class overrides with a refusal.

## Addendum 2026-10-16 — the route is retired by core ADR 0067 (karr k53)

Core ADR 0067 makes every schema declare its driver and retires the generic
detection from the DSN, the connector registry with it: `_rebless` on
`DBIO::Storage::DBI::ODBC` and `register_connector_driver` are gone. The
paragraph above on the registry mapping, the `_rebless` reason for the ISA
order and the "minimum core version" consequence describe a core before that
ADR. On a core with it, this class is reached by declaring it —
`storage_type('+DBIO::Firebird::Storage::ODBC')`, on the schema class or a
clone — and a schema declaring nothing is refused at `connection`. The ISA
order is unchanged; it still carries the cut of this ADR (where transport and
engine both answer, the transport's answer wins). The component and `-fb`
declare `DBIO::Firebird::Storage`; a declared Firebird schema over an ODBC
DSN reaching this class through `_adapt_to_access_path` (core ADR 0059) is
open on karr k40. `t/59-odbc-storage.t` pins the declared route.
