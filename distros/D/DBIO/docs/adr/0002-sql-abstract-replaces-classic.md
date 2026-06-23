# ADR 0002 — SQL::Abstract replaces SQL::Abstract::Classic

- Status: accepted
- Date: 2026-06-19
- Tags: sqlmaker, sql-abstract, backfill

## Context

DBIx::Class generated SQL through `SQL::Abstract::Classic` — an older fork of
SQL::Abstract that DBIx::Class pinned specifically because the canonical
`SQL::Abstract` had moved on to a new internal engine (the *expand / render*
pipeline) that the DBIx::Class SQLMaker layer was not written against.

DBIO inherited that SQLMaker layer at the fork (ADR 0001) but did **not**
inherit the `::Classic` pin. The SQLMaker hierarchy here is built directly on
modern `SQL::Abstract`.

## Decision

Build the DBIO SQLMaker hierarchy on canonical **`SQL::Abstract`**, not
`SQL::Abstract::Classic`.

- `DBIO::SQLMaker` (`lib/DBIO/SQLMaker.pm`) does
  `use base qw( DBIO::SQLMaker::ClassicExtensions SQL::Abstract )` — the engine
  base class is `SQL::Abstract` itself.
- `DBIO::SQLMaker::ClassicExtensions` is a quasi-role mixed in by `@ISA` that
  carries DBIO's enhancements *over* `SQL::Abstract` (JOIN support, functions
  in SELECT lists, GROUP BY / HAVING, multicolumn IN, `...FOR UPDATE`).
- `cpanfile` requires `SQL::Abstract` `2.000001` (the expand/render engine);
  `SQL::Abstract::Classic` is not a dependency.

## Rationale

Pinning `::Classic` is a maintenance dead end: it ties the ORM to a frozen fork
of its SQL engine and locks out the expand/render pipeline that modern
`SQL::Abstract` uses to represent and rewrite query trees. Since the DBIO fork
was already a clean break with no compatibility shim (ADR 0001), there was no
reason to carry DBIx::Class's `::Classic` pin forward — the constraint that
forced it (a SQLMaker not written for the new engine) was something DBIO could
simply fix in its own SQLMaker layer instead of working around.

The query API stays compatible; the cost was confined to small adjustments in
the SQLMaker layer, because the new engine's behaviour differs from `::Classic`
in spots the SQLMaker depends on. `DBIO::Manual::Heritage` records this:
"DBIx::Class depended on `SQL::Abstract::Classic` … DBIO uses the canonical
`SQL::Abstract` instead. The query API is compatible; the internal extensions
required small adjustments in the SQLMaker layer."

## Consequences

- DBIO drivers express SQL through the modern expand/render pipeline. This is
  the substrate that ADR 0003 (`apply_limit`) and ADR 0004 (paren-restore +
  `expand_op`) build on — neither is expressible against `::Classic`.
- The "small adjustments in the SQLMaker layer" are not free: behaviours that
  `::Classic` provided implicitly must be reproduced explicitly on the
  `SQL::Abstract` base. The canonical case is the `select.where`
  paren-restore, which is its own decision (ADR 0004) and exposed a defect
  (karr #26).
- DBIO must track `SQL::Abstract` `>= 2.000001`; engine-internal changes in
  future `SQL::Abstract` releases land directly on DBIO's SQL generation and
  must be regression-tested against the SQLMaker layer.
