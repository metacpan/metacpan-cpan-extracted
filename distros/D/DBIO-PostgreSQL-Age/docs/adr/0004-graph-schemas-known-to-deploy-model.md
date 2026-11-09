# ADR 0004 — Graph schemas are known to the deploy model and never dropped

- Status: superseded by core ADR 0066 (karr k20): the mechanism is the extension list and `DBIO::PostgreSQL::Age::Extension`; the decision that graph schemas are never dropped stands
- Date: 2026-10-09
- Tags: deploy, introspection, model, age, graph, postgresql

## Context

`DBIO::PostgreSQL::Deploy` builds the schema the application declares in a
temporary database, introspects it, introspects the live database and diffs the
two. What the live database holds and the declaration does not is dropped. Two
filters keep the diff from dropping what is not the schema's: `pg_schemas`
restricts the deploy to named namespaces, and the extension-member filter of
the introspector hides what an installed extension owns, found through
`pg_depend`.

`create_graph` of Apache AGE makes a PostgreSQL schema named like the graph, a
table per label (`_ag_label_vertex`, `_ag_label_edge`, one per user label) with
indexes and sequences, and an `_age_cache_invalidate` trigger on each. None of
these objects has a `pg_depend` row to the `age` extension, so the second filter
does not see them. A deploy without `pg_schemas` therefore diffs a graph into
`DROP SCHEMA <graph> CASCADE`, `DROP TABLE` per label and `DROP TRIGGER`
(karr k12, point 3, measured 2026-10-05 on PG 18.6 / age 1.8.0). `apply` dies
and rolls back, or, depending on whether `age` is loaded in the session, drops
the graph and leaves `ag_graph` / `ag_label` rows behind (the latter is the
business of dbio-postgresql karr k109 / k110).

The question was whether the graph schemas belong out of the model, since AGE
knows them (`ag_catalog.ag_graph.namespace`), or whether `pg_schemas` is the
only supported way for AGE users.

## Decision

Maintainer decision of 2026-10-09, option (a): **graph schemas are known to the
deploy model, and AGE becomes a citizen of the model.**

- `DBIO::PostgreSQL::Age::Introspect` extends `DBIO::PostgreSQL::Introspect`
  and overrides `_build_model`. If `ag_catalog.ag_graph` exists
  (`to_regclass`), it reads `name` and `namespace` of every graph, adds a
  `graphs` section (`name => { name, schema }`) and removes from all other
  sections what lives in a graph schema: the schema; the tables, and with them
  the entries keyed by table (columns, indexes, triggers, foreign keys, check
  constraints, policies); sequences, functions and types. Without the catalog
  table the model is the base model.
- `DBIO::PostgreSQL::Age::Deploy` extends `DBIO::PostgreSQL::Deploy` and names
  that introspector in `_introspect_class`, the way
  `DBIO::PostgreSQL::PostGIS::Deploy` does.
- There is no diff class for `graphs`. A deploy does not create graphs from the
  model (they come from `create_graph`) and the target model is introspected
  from a temporary database that holds none, so a drop operation for a graph
  cannot arise.
- `pg_schemas` remains possible on top and means what it means for
  `DBIO::PostgreSQL::Deploy`.
- The class is **not** wired through `dbio_deploy_class` of the AGE storage
  layer. That hook is a single-owner override among storage layers (core
  composition collision rule) and `DBIO::PostgreSQL::PostGIS::Storage` already
  owns it; a second owner makes composition of AGE + PostGIS croak (measured),
  which `t/40-stacking.t` pins as a property of this driver. The class is
  instantiated directly. This is an open question for the maintainer, not a
  decision of this ADR (it needs deploy-hook chaining in core or a choice
  between the two). No `@ISA` of a component or storage class changes, and the
  connect path is untouched (ADR 0003, core ADR 0032 section 7).

## Consequences

- An unrestricted deploy beside AGE keeps the graph, its label tables, its
  data and its `ag_graph` registration: `t/13-age-model-live.t` pins diff and
  apply against a real graph, `t/12-age-model.t` the model rewrite and the diff
  on a fixture.
- Everything in a graph schema is invisible to the deploy, also an ordinary
  table a user put there by hand. A graph schema belongs to AGE.
- A foreign key from an application table to a label table keeps its reference
  to a table the model no longer has. That is not a supported shape of AGE
  data.
- `graphs` is read, never written: the deploy cannot create, rename or drop a
  graph. Graph lifecycle stays with `create_graph` / `drop_graph`.
- Selecting the class automatically from `$schema->deploy` / the storage is not
  done; see above.

## Rejected alternatives

- **`pg_schemas` as the only supported way.** Restricting the deploy to the
  application's own schemas works (karr k12, point 1) and stays available, but
  it puts the burden on every AGE user and fails silently the day somebody
  forgets the declaration: the consequence is a `DROP SCHEMA ... CASCADE` of a
  graph. A model that knows the graphs does not depend on the declaration being
  remembered.
- **Teaching the base introspector about AGE.** `DBIO::PostgreSQL` would then
  carry knowledge of one extension. The PostGIS driver set the pattern: the
  extension distribution ships its own introspector and deploy subclass.
