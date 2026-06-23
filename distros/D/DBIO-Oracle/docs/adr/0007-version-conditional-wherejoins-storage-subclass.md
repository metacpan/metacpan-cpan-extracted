# ADR 0007 — Pre-9i `(+)` joins via a version-conditional storage subclass

- Status: accepted
- Date: 2026-06-22
- Tags: storage, sqlmaker, joins, legacy, oracle, drivers

## Context

Oracle did not support ANSI `JOIN ... ON` syntax until version 9.0. Servers older
than that express outer joins with the proprietary WHERE-clause `(+)` operator:
`SELECT x FROM y, z WHERE y.id = z.id(+)`. DBIO generates ANSI join SQL by
default. To support a pre-9i server, the *entire join rendering* changes — not a
single method but the whole `select` / `_recurse_from` path — yet everything else
about Oracle storage (LOB handling, sequences, savepoints, quoting, the SQL
maker base) is identical regardless of server version.

The version is not known until connect time, so the choice of join dialect has to
be made dynamically per connection, not statically per distribution.

## Decision

Ship the legacy behaviour as a thin storage *subclass* selected by version, with
its own SQLMaker subclass:

- `DBIO::Oracle::Storage::WhereJoins` extends `DBIO::Oracle::Storage` and
  overrides exactly one thing — the SQL maker class
  (`__PACKAGE__->sql_maker_class('DBIO::Oracle::SQLMaker::Joins')`,
  `Storage/WhereJoins.pm:1-10`). It inherits all other Oracle storage behaviour
  unchanged and uses `mro 'c3'`.
- `DBIO::Oracle::SQLMaker::Joins` extends `DBIO::Oracle::SQLMaker` and overrides
  the join-rendering path only: `select` rewrites the join list into WHERE
  conditions (`SQLMaker/Joins.pm:21-29`), `_recurse_from` flattens the FROM into
  a comma list (`Joins.pm:31-48`), and `_recurse_oracle_joins` builds the `(+)`
  predicates from `-join_type` (`Joins.pm:50-119`). Full outer joins
  **throw** — Oracle 8 would require a `UNION` of left and right joins, which
  cannot be constructed at the WHERE-clause stage (`Joins.pm:81-83`,
  `Storage/WhereJoins.pm:24-27`).
- DBIO autodetects the Oracle version and reblesses to this storage automatically
  for pre-9.0 servers; the modern `DBIO::Oracle::Storage` path is the default.

## Rationale

Subclassing is the honest factoring because the legacy join dialect is a *total
replacement of one concern* layered on top of an otherwise-identical storage —
not a flag, not a branch sprinkled through the modern code path. A runtime flag
would litter the common `select`/FROM rendering with `if pre-9i` branches; a
separate subclass keeps the modern path branch-free and confines all the legacy
WHERE-join logic to two files that a maintainer can ignore entirely when working
on current Oracle. Because the choice depends on the connected server version, it
must be a runtime rebless, which the driver registry already supports.

Oracle is the only DBIO driver that ships a version-conditional storage subclass,
because it is the only one whose join *syntax* changed incompatibly across
supported server versions. Throwing on full outer joins rather than silently
emitting wrong SQL is the same fail-loud discipline applied elsewhere in the
driver: the `(+)` syntax genuinely cannot express a full outer join, so the only
honest answer is an exception.

## Consequences

- Pre-9i Oracle gets working left/right outer joins through the normal DBIO API
  with no caller awareness; full outer joins are unsupported and throw.
- The legacy path is isolated: changes to modern Oracle join handling live in
  `DBIO::Oracle::SQLMaker`, legacy `(+)` handling lives in
  `DBIO::Oracle::SQLMaker::Joins`, and the only storage difference is the one
  `sql_maker_class` line. Do not merge the two SQLMakers or add version branches
  to the modern one — point such proposals here.
- `WhereJoins` sits on top of the ISA-composed `DBIO::Oracle::Storage` (ADR 0001)
  and re-declares `mro 'c3'`, so it inherits the full mixin stack (LOB,
  sequences, savepoints, FK deferral, NLS setup) correctly.

## Related

- ADR 0001 (storage mixin composition — the base this subclass extends)
- ADR 0005 (Oracle SQLMaker — the base SQL maker `SQLMaker::Joins` extends)
- core ADR 0016 (MSSQL connector registry reblesses to a derived storage — the
  same runtime-rebless-to-a-subclass mechanism, here keyed on server version
  rather than connector)
