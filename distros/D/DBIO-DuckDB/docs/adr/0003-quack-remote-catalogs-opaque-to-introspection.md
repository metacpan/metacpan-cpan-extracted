# ADR 0003 — Quack remote catalogs are opaque to introspection; deploy on the server

- Status: accepted
- Date: 2026-06-20

## Context

Quack (a DuckDB extension, v1.5+) exposes an embedded DuckDB instance over
HTTP-based RPC. A DuckDB client can `ATTACH 'quack:host:port' AS remote` and
query the remote catalog as if it were local, while remaining an ordinary
in-process DuckDB via `DBD::DuckDB` (see ADR 0002).

DuckDB's catalog metadata surfaces — `information_schema.*`, `duckdb_tables()`,
`duckdb_columns()`, `duckdb_indexes()`, `duckdb_constraints()` — do **not**
enumerate the contents of a quack-attached remote catalog. They report only the
local catalog. `DBIO::DuckDB::Introspect` (and therefore `Deploy->diff`, which
introspects both the live source and an in-memory target) is built entirely on
those surfaces. Pointed at a quack-attached client, introspection sees an empty
remote catalog and the test-deploy-and-compare diff would compute a spurious
"create everything" delta.

The driver's `catalog` attribute (on `Introspect` and `Deploy`) exists for
**locally-attached file catalogs** (e.g. `ATTACH '/path/x.duckdb' AS mycat`,
DuckLake), where the system views *do* resolve the attached catalog — it is not
a quack mechanism.

## Decision

Treat quack remote catalogs as **opaque to the introspect/diff/deploy layer**,
and document the operational boundary rather than trying to make introspection
RPC-aware.

1. `DBIO::DuckDB::Introspect` and `DBIO::DuckDB::Deploy` make **no attempt** to
   enumerate or diff a quack-attached remote catalog. Schema management is a
   server-side operation: deploy the schema on the process that *owns* the
   DuckDB database (the one that runs `quack_serve`), not against a client that
   has merely `quack_attach`ed it.
2. The `catalog` attribute remains scoped to locally-attached file/DuckLake
   catalogs. It is explicitly **not** a way to point Deploy at a quack remote.
3. For client-side verification of remote columns, the documented tool is
   `PRAGMA table_info('remote.tablename')`, which *does* work over quack and
   returns `cid`/`name`/`type`/`notnull`/`dflt_value`/`pk` — used for spot
   checks, not as an introspection backend.

## Consequences

- The "deploy where the data lives" rule keeps the test-deploy-and-compare
  invariant intact: both sides of every diff are introspected from catalogs the
  system views can actually see.
- Running `Deploy`/`diff`/`upgrade` against a quack-attached client catalog is
  unsupported by design; it would silently produce a wrong diff, so it is
  called out in `Deploy`'s POD and here rather than guarded in code.
- If a future Quack/DuckDB release makes remote catalogs visible to
  `information_schema`/`duckdb_*`, this boundary can be relaxed and Introspect
  taught to resolve a remote catalog — revisit then.
