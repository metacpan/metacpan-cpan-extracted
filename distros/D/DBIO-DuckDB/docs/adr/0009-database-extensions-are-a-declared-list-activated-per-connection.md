# ADR 0009 — DuckDB extensions are a declared list; INSTALL once per host, LOAD per connection

- Status: accepted
- Date: 2026-10-22

## Context

Core ADR 0066 makes the database extensions of a schema a declared list the
driver runs: installed state read by the driver, rules of an extension in a
class, per-connection activation as data the driver turns into statements.
dbio-postgresql carries the first implementation (karr dbio-postgresql k136).
DuckDB has the same two steps under other names: `INSTALL name` fetches the
extension file into the host's extension directory (`~/.duckdb/extensions`),
`LOAD name` makes it part of one database instance. Its catalog is
`duckdb_extensions()` (`extension_name`, `installed`, `loaded`,
`extension_version`).

Measured against libduckdb 1.5.3: `json`, `parquet`, `icu` and `autocomplete`
are installed and loaded from the start; `httpfs` is installed (from `core`)
and not loaded; `spatial` and `tpch` are neither until `INSTALL` fetched them.
`INSTALL` of an installed extension is idempotent, `LOAD` of a loaded one too.

## Decision

1. The declaration is `duckdb_extensions(...)` on the `DBIO::DuckDB`
   component, in the spelling of `pg_extensions` minus the schema: a name,
   optionally followed by a hashref whose only option is `class`.
2. `DBIO::DuckDB::Extension` is the plain class. The driver's table of
   family classes is empty: no DuckDB extension distribution exists, so every
   name gets the plain class unless the declaration names one. The plain
   class has no rules and activates its own name (`load`).
3. The installed state is read from `duckdb_extensions()` (installed, loaded,
   version) by the deploy, over the live connection.
4. Activation: on every new connection the storage runs `INSTALL name` and
   `LOAD name` for each activated library. `INSTALL` is per host and
   idempotent, `LOAD` per database instance; an extension that cannot be
   installed or loaded fails the connect, loudly.
5. The in-memory database a diff builds its target model in gets the same
   activation, otherwise a type of an extension fails there.
6. The deploy never drops an extension. DuckDB has no `DROP EXTENSION` and a
   loaded extension stays loaded for the instance; leaving the declaration
   removes the `LOAD` of the next connection and nothing else.
7. No claims and no annotations: DuckDB has no extension-owned objects in
   the user's schemas that the model would need to hide, so the driver defines
   no addresses. A class that claims fails with core's "not implemented".
8. Scope is `connection`; a quack-attached remote is not asked, the remote
   has its own host and its own activation.

## Consequences

- An application states `spatial` once and every connection, pool or
  not, has it loaded.
- A machine without network and without the extension file cannot connect to
  a schema that declares it.
- A family class that needs claims has to bring the driver's address kinds
  with it (a later ADR).
