# ADR 0003 — apply_limit replaces limit_dialect / emulate_limit

- Status: accepted
- Date: 2026-06-19
- Tags: sqlmaker, limit, drivers, backfill

## Context

DBIx::Class drove LIMIT/OFFSET generation from the *storage* layer through two
coupled mechanisms: a `sql_limit_dialect` string naming the dialect (e.g.
`LimitOffset`, `RowNumberOver`, `GenericSubQ`), and an `emulate_limit()`
dispatch that selected one implementation out of a fixed per-dialect matrix
(the `LimitDialects` set). Adding or altering a database's limit behaviour
meant teaching that central matrix about it.

DBIO removes both. The limit decision moved out of storage and onto the
SQLMaker, where the rest of SQL generation already lives.

## Decision

Replace the `sql_limit_dialect` string and the `emulate_limit()` /
`LimitDialects` matrix with a single overridable hook, **`apply_limit`**, on
the SQLMaker subclass.

- The default implementation lives in `DBIO::SQLMaker::ClassicExtensions`
  (`apply_limit`, `lib/DBIO/SQLMaker/ClassicExtensions.pm:617`) and emits the
  SQL-standard `LIMIT ? OFFSET ?` supported by PostgreSQL, SQLite and most
  modern databases.
- A driver that needs different syntax (MySQL `LIMIT ?, ?` offset-first,
  Oracle `ROWNUM`, SQL Server `ROW_NUMBER() OVER()`) overrides `apply_limit`
  on its own SQLMaker subclass — it does not register a dialect string.
- No `sql_limit_dialect`, `emulate_limit` or `LimitDialects` remains in the
  storage layer.

## Rationale

The dialect-string + central-matrix design put the limit decision in the wrong
place (storage, away from SQL generation) and made it closed: every driver's
limit behaviour had to be a value the core matrix already knew. A single
`apply_limit` method inverts that — the behaviour *is* the override, owned by
the driver's SQLMaker, open to any syntax without a central registration. This
also fits the post-fork architecture where database-specific code was split
out into per-driver distributions (ADR 0001 / Heritage): a driver carries its
own limit syntax in its own SQLMaker, with no string round-trip through core.

`DBIO::Manual::Heritage` records the change: "DBIx::Class used a
`sql_limit_dialect` string and an `emulate_limit()` dispatch table inside the
storage layer. DBIO removes both. Each driver's SQLMaker subclass provides an
`apply_limit` method instead." The default `apply_limit` returning
`LIMIT ? OFFSET ?` was confirmed directly in the code.

## Consequences

- LIMIT/OFFSET is a SQLMaker concern, overridable per driver with no central
  dialect table. Custom `emulate_limit` overrides port to `apply_limit`
  overrides.
- The in-code signature is `apply_limit($sql, $rs_attrs, $rows, $offset)`
  (it consumes the resultset attrs to parse order/grouping for windowed
  variants). The Heritage/Migration prose abbreviates this to
  `apply_limit($sql, $rows, $offset)`; drivers overriding it must match the
  4-argument form in the code.
- Cross-repo fallout, **not owned here**: driver dists may still carry stale
  `limit_dialect`-era tests that assert the old matrix (e.g. dbio-informix
  karr #12). Each driver retires its own; this ADR records only the core
  decision.
