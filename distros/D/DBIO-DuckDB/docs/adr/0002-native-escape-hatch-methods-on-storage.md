# ADR 0002 — DuckDB-native features are exposed as escape-hatch methods on Storage

- Status: accepted
- Date: 2026-06-20

## Context

DBIO inherits a row-oriented, DBI-shaped storage interface from
`DBIO::Storage::DBI`: prepare/execute, a row cursor, scalar bind. DuckDB is a
columnar, embedded analytical engine whose most valuable features do not fit
that shape:

- bulk loading via the native **Appender** API (orders of magnitude faster than
  row-by-row `INSERT`),
- columnar result transport (**Arrow** IPC buffers, bypassing the DBI row
  iterator and per-scalar coercion),
- file/table functions (`read_csv`, `read_parquet`, `read_json`),
- extension management (`INSTALL`/`LOAD`), `CHECKPOINT`,
- the **Quack** client-server RPC extension (`quack_serve`, `quack_attach`,
  `quack_detach`).

None of these are reachable through the portable ORM contract, and forcing them
through it would either be impossible (Appender, Arrow) or would mean smuggling
engine-specific SQL through `$rs->search`. Unlike `dbio-postgresql-async`, there
is no async-protocol reason to abandon DBI wholesale — DuckDB is embedded and
synchronous, so the DBI plumbing is kept for all ordinary ORM work
(transactions, bind, cursor, ResultSet) and only the columnar/server features
need an exit.

The async PostgreSQL driver set the family precedent of putting native-protocol
operations (`listen`/`notify`/`copy_in`) directly on its Storage object. This is
the first *blocking, DBI-based* DBIO driver to do the same, and it does so at a
larger surface.

## Decision

DuckDB-native features that do not fit the DBI/ORM model are exposed as
**direct methods on `DBIO::DuckDB::Storage`**, namespaced by feature family, and
documented as escape hatches — not routed through the portable ORM API.

1. The `duckdb_*` family wraps `DBD::DuckDB`'s `x_duckdb_*` entry points and
   raw DuckDB SQL: `duckdb_appender`, `duckdb_arrow_fetch`, `duckdb_read_csv`,
   `duckdb_read_parquet`, `duckdb_read_json`, `duckdb_version`,
   `duckdb_install_extension`, `duckdb_checkpoint`.
2. The `quack_*` family wraps the Quack RPC extension: `quack_serve`,
   `quack_attach`, `quack_detach`, plus the `connect_call_quack_attach`
   on-connect hook for `on_connect_call`.
3. Methods that interpolate caller-supplied values into SQL (extension names,
   quack addresses/tokens/aliases) **validate or escape every interpolated
   value** at the method boundary: identifier-shaped arguments are matched
   against `^[A-Za-z_][A-Za-z0-9_]*$`, string literals have `'` doubled, and
   addresses/tokens reject embedded quotes/newlines.
4. `duckdb_arrow_fetch` is explicitly marked **experimental**: it currently
   falls back to DBI row iteration and its return shape will change when the
   real libduckdb Arrow path lands. Callers are warned not to depend on the
   fallback shape in long-lived code.

## Consequences

- DuckDB power features are available without leaving the DBIO schema/Storage
  object — no second connection, no separate transport layer.
- The escape-hatch surface is engine-specific by construction. Code that calls
  `duckdb_*`/`quack_*` is not portable to another driver; that is the intended
  trade and is the reason these live as named methods rather than ORM sugar.
- Methods that bypass DBI also bypass DBI's placeholder binding, so input
  validation/escaping is a load-bearing security boundary in this driver, not a
  nicety. New escape hatches that build SQL strings must follow the same
  validate-or-escape discipline.
- `duckdb_arrow_fetch`'s contract is unstable until the Arrow path is
  implemented; that instability is documented at the method and acknowledged
  here so a future return-type change is not a surprise regression.
