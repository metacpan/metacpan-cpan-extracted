# ADR 0008 — Offline loadability: DBD::Oracle loaded lazily, type logic kept pure

- Status: accepted
- Date: 2026-06-22
- Tags: storage, type, dbd, testing, offline, oracle

## Context

DBD::Oracle is a heavyweight XS dependency that requires an Oracle client
library to even install — it cannot be assumed present on a developer or CI box
that only runs the offline SQL-generation and diff tests. Yet those offline tests
need to *load* `DBIO::Oracle::Storage`, `DBIO::Oracle::SQLMaker`, and the type
machinery to exercise SQL generation and model diffing. SQL generation, identifier
shortening, type-string mapping, and diff comparison need **no live database** and
therefore no DBD::Oracle; only actually binding a LOB against a real handle does.

A naive `use DBD::Oracle;` at the top of any Oracle module would make the whole
driver unloadable offline, breaking the family's offline-test convention (core
tests and driver SQL-gen tests must run without a live DB).

## Decision

Keep every module loadable without DBD::Oracle and load it lazily only at the
exact point a live LOB bind happens:

- **Pure type functions in `DBIO::Oracle::Type`** — `normalize_type`,
  `map_dbio_type_to_oracle`, `map_dbd_type_to_dbio`, `is_lob_type`,
  `is_text_lob_type` have no DBD::Oracle dependency and are usable offline (by
  `DBIO::Oracle::Diff`, `Introspect::Columns`, the DDL). Only
  `oracle_lob_bind_attrs` touches DBD::Oracle, and it `require`s it lazily at call
  time (`Type.pm:59-65`; module POD states the split, `Type.pm:7-18`).
- **Lazy load at the LOB-bind seam** —
  `DBIO::Oracle::Storage::LOBSupport::bind_attribute_by_data_type` does
  `require DBD::Oracle` only inside the `is_lob_type` branch, i.e. only when
  actually binding a LOB against a real handle (`LOBSupport.pm:31-53`,
  comment at `38-41`). It also performs a one-time version guard there, rejecting
  the known-broken DBD::Oracle 1.23 (`LOBSupport.pm:40-48`).
- **Single source for the predicates** — `DBIO::Oracle::Storage` exposes thin
  `_is_lob_type` / `_is_text_lob_type` wrappers that delegate to
  `DBIO::Oracle::Type` (`Storage.pm:282-286`), so the LOB-type checks used all
  over `LOBSupport` resolve through the pure module and stay offline-safe.

## Rationale

Splitting the type module into pure functions plus one lazily-DBD-backed function
is what lets the diff/SQL-gen stack run with zero Oracle client present, which is
the whole point of the family's offline-test rule — and it keeps the predicates
(`is_lob_type`) usable by both the offline diff path and the live bind path
without forking the logic. Pushing the `require DBD::Oracle` down to the actual
bind call (rather than module load) means the only code that ever needs the XS
driver is the code that genuinely talks to Oracle.

This is also entangled with the MRO/offline failure history (ADR 0001): the
`_prep_for_execute` LOB-rewrite path is reached under the offline
`DBIO::Test::Storage` hybrid, so it had to be both correctly composed *and*
loadable without DBD::Oracle. The version guard for the broken 1.23 release lives
at the bind seam rather than at load time precisely so that loading the module
offline never trips it.

## Consequences

- Offline SQL-generation, identifier-shortening, and diff tests run with no
  Oracle client and no DBD::Oracle installed; only integration tests
  (`DBIO_TEST_ORA_DSN`) and live LOB binds pull DBD::Oracle in.
- DBD::Oracle is a runtime dependency for live use but must **not** become a
  load-time `use` anywhere in the tree. New code that touches DBD::Oracle must
  `require` it lazily at the call that needs it, mirroring `LOBSupport` and
  `Type::oracle_lob_bind_attrs`.
- Type logic that is pure stays in `DBIO::Oracle::Type`; do not add a load-time
  DBD::Oracle dependency to that module or to anything on the SQL-generation /
  diff path.
- The DBD::Oracle 1.23 BLOB/CLOB breakage is guarded once per process at the bind
  seam, not at load (`LOBSupport.pm:40-48`).

## Related

- ADR 0001 (storage mixin composition + the offline `DBIO::Test::Storage` hybrid
  that made the `_prep_for_execute` path's offline-loadability a hard
  requirement)
- ADR 0006 (LOB chunked comparison — the live bind path that is the sole legitimate
  consumer of DBD::Oracle)
- ADR 0009 (Oracle diff/introspect fidelity — a downstream consumer of the pure
  `DBIO::Oracle::Type` functions on the offline diff path)
