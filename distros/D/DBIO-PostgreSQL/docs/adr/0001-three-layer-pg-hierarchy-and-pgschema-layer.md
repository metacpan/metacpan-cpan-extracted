# ADR 0001 — Three-layer PostgreSQL hierarchy and the PgSchema namespace layer

- Status: accepted
- Date: 2026-06-20
- Tags: architecture, pgschema, namespaces, introspect, ddl, keystone

## Context

Every other DBIO driver (SQLite, DuckDB, MySQL, Sybase) models a two-tier
world: a Schema component (the connection/database) and Result classes (the
tables). Enums, types and functions either do not exist or are folded into a
column's type string. PostgreSQL does not fit that shape. Its real object tree
is three deep —

    Cluster → Database → Schema (namespace) → { Table, Type, Function, ... }

— and the middle tier, the PostgreSQL *schema* (namespace: `public`, `auth`,
`api`), owns objects that are not tables: enum types, composite types, and
functions all belong to a namespace, not to any one table. A two-tier model has
nowhere to put them, so it flattens everything into `public` and loses the
structure multi-tenant and API-separation patterns depend on.

## Decision

Introduce a third component layer, `DBIO::PostgreSQL::PgSchema`, with no analog
in any other DBIO driver, and split PostgreSQL metadata across three layers by
the object that actually owns it.

1. **Database layer** — `DBIO::PostgreSQL` (the Schema component). Tracks the
   namespace-level and database-level state as class data:
   `_pg_schema_classes`, `_pg_extensions`, `_pg_search_path`, `_pg_settings`
   (`PostgreSQL.pm:10-13`), exposed through `pg_schemas` / `pg_extensions` /
   `pg_search_path` / `pg_settings` (`PostgreSQL.pm:126-193`).
2. **PgSchema layer** — `DBIO::PostgreSQL::PgSchema`. A namespace is a
   first-class subclassable object that holds the schema-scoped types. Enum,
   composite-type and function *definitions* are class data accumulated in
   package-level hashes (`PgSchema.pm:7`) and read back via `_pg_enum_defs` /
   `_pg_type_defs` / `_pg_function_defs` (`PgSchema.pm:52-54`); the declarative
   `pg_enum` / `pg_type` / `pg_function` class methods push into them. These
   live on the namespace, deliberately **not** on any Result.
3. **Result layer** — `DBIO::PostgreSQL::Result`. A table carries only the
   namespace it belongs to, via `pg_schema` (`Result.pm:9,48-54`), which flows
   into `pg_qualified_table` to produce the `schema.table` form
   (`Result.pm:65-70`).

## Rationale

The three layers are not gratuitous structure — they mirror PostgreSQL's own
ownership rules. An enum belongs to a namespace and can be shared by many
tables in it; modelling it as class data on `PgSchema` (rather than re-declaring
it per Result) is the only placement that matches the database. Making the
namespace a real subclassable layer is what lets multi-tenant setups treat
`auth` / `api` / per-tenant schemas as objects rather than bare strings, and
gives `DDL` and `Introspect` a single place to read schema-scoped types from.

The CLAUDE.md design note "Why a separate PgSchema layer?" records the same
intent: PostgreSQL schemas are fundamental, types/functions belong to a schema
not a table, and without the layer everything collapses into `public`.

## Consequences

- **`schema.name` is the universal model key.** Because objects live in
  namespaces, every introspected artifact is keyed by its qualified name.
  `DBIO::PostgreSQL::Introspect->qualified_key` builds the canonical
  `"schema.name"` string (`Introspect.pm:140-170`) that indexes tables,
  columns, indexes and the rest. This is the single biggest structural
  divergence from the other drivers, whose keys are bare table names — recorded
  as karr #4 SEAM C ("KEEP ALL 7"): the whole introspection contract diverges
  because of qualified keys.
- **Cross-schema is a first-class case, not an edge case.** A foreign key may
  point into another namespace, so the FK introspection query selects a
  `remote_schema` alongside `remote_table` (`Introspect/ForeignKeys.pm:46`) and
  keys the target by its qualified name. A flat-namespace driver never needs
  this column.
- **DDL emits schema-qualified objects and dedupes physical tables.** View DDL
  is emitted with its qualified name (`DDL.pm:166`), skipping virtual views and
  de-duplicating by qualified key (`DDL.pm:162-166`); the same qualified key
  guards the table walk so that multiple result sources mapping to one physical
  table emit it only once (`DDL.pm:182-183`).
- New PostgreSQL object kinds (types, functions, policies) have an obvious home:
  schema-scoped ones go on `PgSchema`, table-scoped ones (indexes, triggers,
  RLS, CHECK constraints) go on `Result`. Driver authors copying the two-tier
  pattern from another DBIO driver will not find this layer and must read this
  ADR first.

This is the keystone PostgreSQL ADR; the remaining driver ADRs (0002–0005)
specialise core strategies *within* this three-layer hierarchy.
