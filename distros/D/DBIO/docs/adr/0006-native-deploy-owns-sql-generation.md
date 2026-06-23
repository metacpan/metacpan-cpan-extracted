# ADR 0006 — Native Deploy owns SQL generation (deployment_statements contract, SQLT optional)

- Status: accepted
- Date: 2026-06-19
- Tags: deploy, ddl, sql-translator, drivers, backfill

## Context

DBIx::Class generated DDL through `SQL::Translator`: `deployment_statements()`
handed the schema to SQLT, which translated the in-memory model into
engine-specific `CREATE TABLE` SQL on the fly. SQLT was therefore a hard runtime
dependency of any DBIx::Class app that deployed a schema, and the quality of the
DDL was bounded by SQLT's producer for each engine.

The DBIO fork split every database into its own driver distribution (ADR 0001 /
Heritage). That split makes a per-engine DDL producer owned by the driver the
natural home for deployment, and removes the reason to route DDL through a
central translator that no driver controls.

## Decision

Each DBIO driver owns native DDL generation; `SQL::Translator` is demoted to an
optional dependency; and `deployment_statements()` changes contract — it no
longer generates SQL on the fly.

- The native deploy layer is rooted at `DBIO::Deploy::Base`
  (`lib/DBIO/Deploy/Base.pm`), the shared base for per-driver `Deploy`
  orchestrators (`DBIO::PostgreSQL::Deploy`, `DBIO::MySQL::Deploy`,
  `DBIO::SQLite::Deploy`, `DBIO::DuckDB::Deploy`). Its `install`/`apply`/`upgrade`
  methods are shared; only how the target model is obtained is engine-specific.
- `DBIO::DeploymentHandler::DeployMethod::Native`
  (`lib/DBIO/DeploymentHandler/DeployMethod/Native.pm`) routes `deploy`/`upgrade`/
  `diff` to the storage's native Deploy class — resolved via
  `$storage->dbio_deploy_class` or the `::Storage` → `::Deploy` naming
  convention (`Native.pm:57-81`) — and stubs out the old DBIx::Class
  prepare/initialise contract (`Native.pm:34-40`), which has nothing to prepare
  under a test-and-compare deploy.
- `deployment_statements()` no longer translates. On `DBIO::Storage::DBI`
  (`lib/DBIO/Storage/DBI.pm:3124-3163`) it reads a pre-existing DDL file from the
  deploy directory and returns its contents, and **throws** if none exists,
  directing callers to `DBIO::Schema->deploy` (which routes to the native Deploy
  class). `DBIO::Schema::deployment_statements` (`lib/DBIO/Schema.pm:1258-1265`)
  delegates to storage. There is no on-the-fly SQL generation without a Deploy
  class.
- `SQL::Translator` is not a `requires` in the core `cpanfile`; the only SQL
  dependency is `SQL::Abstract` (for query building, ADR 0002), not DDL.

## Rationale

Routing DDL through a central translator no driver controls is the wrong layer
once databases are separate distributions: the engine that knows its own DDL
best is the driver, not a shared producer. Native per-driver deploy lets each
engine emit exactly the DDL it wants (and is the substrate the introspect+diff
migration of ADR 0007 needs — the diff layer compares *introspected* models, so
the deployer that fills a scratch database must be native too). Demoting SQLT to
optional drops a hard dependency from every deploying app and stops bounding DDL
quality by SQLT's producers.

Heritage.pod records the intent (`lib/DBIO/Manual/Heritage.pod:117-126`): "Every
driver ships its own native Deploy, Introspect, and Diff modules … so
SQL::Translator is an optional dependency rather than a required one."

**Flag — code is stricter than the prose.** Heritage says `deploy()` "falls back
to the L<SQL::Translator> path transparently." Core ships no such fallback: the
`deployment_statements` path on `Storage::DBI` *throws* when no DDL file and no
native Deploy class is present (`Storage/DBI.pm:3160-3162`), and
`DeployMethod::Native` *throws* when it cannot resolve a native Deploy class
(`Native.pm:73-78`). The "transparent SQLT fallback" is a property a driver may
choose to provide, not something core implements. The ADR records what the code
does: native-or-throw, SQLT optional and unused by core's own deploy path.

## Consequences

- DDL generation is a driver concern. Each driver ships `Deploy`, `Introspect`
  and `Diff` modules; core ships only the shared bases
  (`DBIO::Deploy::Base`, `DBIO::Deploy::Base::TempDatabase`) and the routing
  `DeployMethod::Native`.
- `deployment_statements()` is no longer a SQL generator — it is a DDL-file
  reader that throws on a miss. Code or tests that called the DBIx::Class
  `deployment_statements` expecting freshly translated SQL must move to
  `DBIO::Schema->deploy` / the native Deploy class. This is a real contract
  change, not a rename.
- `SQL::Translator` is optional: absent from the core `cpanfile` requires, and
  core's own deploy path never calls it. Apps that still want a SQLT-based
  workflow must supply it themselves.
- **Naming flag (ticket vs code):** there is no `lib/DBIO/Deploy.pm`. The native
  deploy layer is `DBIO::Deploy::Base` (+ `::TempDatabase`) plus
  `DBIO::DeploymentHandler::DeployMethod::Native` and per-driver `::Deploy`
  subclasses. The karr ticket's "DBIO::Deploy" is shorthand for that cluster.
- This decision pairs with ADR 0007 (native Introspect + Diff): native Deploy
  fills the scratch database that the diff layer introspects to compute a
  migration. Cake's DDL DSL (ADR 0010) feeds the schema definition this layer
  deploys.
