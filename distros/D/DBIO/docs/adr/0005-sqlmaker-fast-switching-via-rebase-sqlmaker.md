# ADR 0005 — SQLMaker fast-switching via rebase_sqlmaker

- Status: accepted
- Date: 2026-06-19
- Tags: sqlmaker, drivers, storage, backfill

## Context

The DBIO SQLMaker hierarchy (ADR 0002, ADR 0004) is built on canonical
`SQL::Abstract` with a fixed set of DBIO enhancements mixed in through
`DBIO::SQLMaker::ClassicExtensions`. A driver normally selects its SQL
generation class once, at storage construction. But a connection can need a
*different* SQLMaker than the one its storage class implies — most concretely
when one storage instance must speak a second engine's SQL after connect, or
when a test must swap the SQL core under a live `$schema` without rebuilding it.

DBIO keeps the SQLMaker deliberately thin for exactly this reason. The POD calls
it a "nexus class": indirection maintained *on purpose* so the SQL-generation
core can be swapped per-`$schema` without architectural change.

## Decision

Treat `DBIO::SQLMaker` as a swappable nexus, and provide
`connect_call_rebase_sqlmaker` as the storage-level connect hook that swaps the
SQL-generation core of a live `$schema`'s storage onto a requested SQLMaker base
class — guaranteed by design and by tests to keep working.

- The "nexus class" contract is stated in the SQLMaker POD DESCRIPTION
  (`lib/DBIO/SQLMaker.pm:43-51`): the indirection is "explicitly maintained in
  order to allow swapping out the core of SQL generation within DBIO on
  per-C<$schema> basis without major architectural changes … guaranteed by
  design and tests."
- `connect_call_rebase_sqlmaker($requested_base_class)`
  (`lib/DBIO/Storage/DBI.pm:1603-1648`) does the swap mechanically: it is a
  *rebase*, not a re-bless. It synthesises a new class
  `"${old}__REBASED_ON__${requested}"`, injects it with `@ISA = ($old,
  $requested)` via `inject_base`, reinitialises C3 MRO, points
  `sql_maker_class` at the synthetic class and clears the cached `_sql_maker`
  so the next access rebuilds through the combined hierarchy.
- The swap is gated for consistency: the target must descend from
  `DBIO::SQLMaker::ClassicExtensions` and from a `SQL::Abstract` engine
  (`DBI.pm:1629-1636`), so a rebase can only land on a SQLMaker that already
  honours ADR 0002/0004 — it cannot smuggle in an off-hierarchy SQL core.
- `ClassicExtensions` documents itself as the "quasi-role … mixed in via classic
  C<@ISA>" and points at this hook (`lib/DBIO/SQLMaker/ClassicExtensions.pm:7-12`).

## Rationale

The nexus indirection is cheap to keep and expensive to lose. By making the
SQLMaker a thin join point rather than a class that bakes engine choice in at
construction, DBIO can change the SQL core of an already-connected `$schema`
without tearing down storage or relationships. A *rebase* (synthetic
`__REBASED_ON__` class + C3 reinit) rather than a re-bless means both the old and
the requested base remain in the MRO: the original `DBIO::SQLMaker::new`
override (ADR 0004, the `select.where` paren-restore + `disable_old_special_ops`)
still runs, and the requested base's overrides layer on top — so fast-switching
never silently drops the DBIO rendering decisions it sits above.

This is a DBIO-original capability: neither Heritage.pod nor Migration.pod
describe a per-`$schema` SQLMaker swap, and there is no DBIx::Class equivalent.
The "guaranteed by design and tests" wording in the POD is backed in
`t/sqlmaker/rebase.t`, which asserts the exact post-rebase linear MRO
(`DBIO::SQLMaker__REBASED_ON__… → DBIO::SQLMaker → <requested> →
DBIO::SQLMaker::ClassicExtensions → …`) and then proves a rebased override
actually fires on a real `as_query`.

## Consequences

- The SQLMaker stays a deliberately thin nexus. New drivers benefit for free:
  any DBIO SQLMaker subclass is rebase-eligible as long as it keeps the
  `ClassicExtensions` + `SQL::Abstract` ancestry the gate (`DBI.pm:1629-1636`)
  requires.
- Rebasing is idempotent and ordered: `connect_call_rebase_sqlmaker` returns
  early if the current class already `isa` the requested base
  (`DBI.pm:1614-1617`), and the synthetic class places the *old* class before
  the requested one in `@ISA`, so the DBIO `new` override (ADR 0004) keeps
  precedence.
- The fast-switch contract is load-bearing and test-pinned. `t/sqlmaker/rebase.t`
  asserts the exact MRO; any change to the SQLMaker base layout (ADR 0002) or to
  C3 setup in `DBIO::Base` (ADR 0001) can shift that linearisation and must be
  re-checked against this test, not just compiled.
