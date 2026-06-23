# ADR 0007 — Native Introspect + Diff layer (test-and-compare migration)

- Status: accepted
- Date: 2026-06-19
- Tags: introspect, diff, migration, deploy, drivers, backfill

## Context

DBIx::Class computed schema migrations with `SQL::Translator::Diff`: it parsed
two DDL representations through SQLT and diffed the parsed models to produce ALTER
statements. That inherits all of SQLT's coupling — the diff is only as good as
SQLT's per-engine parsers and producers, and (like deployment, ADR 0006) it runs
through a central translator no driver controls.

DBIO replaces this with a native introspect + diff layer, paired with native
deploy (ADR 0006), under the same per-driver-distribution architecture as the
rest of the fork (ADR 0001).

## Decision

Compute migrations by introspecting real schemas into a normalised model and
diffing the models natively — the "test-and-compare" strategy — replacing
`SQL::Translator::Diff`.

- **Introspect** turns a live schema into a normalised in-memory model.
  `DBIO::Introspect::Base` (`lib/DBIO/Introspect/Base.pm`) is the abstract base
  (lazy `model`, the normalised contract: `table_keys`, `table_columns`,
  `table_columns_info`, `table_pk_info`, `table_uniq_info`, `table_fk_info`,
  `table_is_view`, `view_definition`, comments). `DBIO::Introspect::DBI`
  (`lib/DBIO/Introspect/DBI.pm`) is the concrete generic implementation over DBI
  metadata APIs (`column_info`, `primary_key`, `foreign_key_info`, `table_info`);
  per-driver introspectors override it where native catalog queries are more
  accurate.
- **Diff** compares two introspected models into a list of operation objects.
  `DBIO::Diff::Base` (`lib/DBIO/Diff/Base.pm`) is the abstract orchestrator
  (`source` = live model, `target` = desired model, lazy `operations`,
  `has_changes`, `as_sql`, `summary`); subclasses implement only
  `_build_operations`. `DBIO::Diff::Compare` (`lib/DBIO/Diff/Compare.pm`) is the
  engine-agnostic comparison kernel (`norm`, `norm_type`, `arr_differ`,
  `changed_column_fields`, `changed_index_fields`, `changed_fk_fields`).
  `DBIO::Diff::Op` (`lib/DBIO/Diff/Op.pm`) is the base for one schema-change
  operation, each answering `as_sql` (engine DDL) and `summary` (human text),
  with the create/drop and create/change/drop walks (`diff_toplevel`,
  `diff_nested`).
- **Test-and-compare** is the workflow that ties them together. The desired
  schema is *deployed into a throwaway database and introspected* to obtain the
  target model, the live database is introspected for the source model, and the
  two are diffed. `DBIO::Deploy::Base::TempDatabase`
  (`lib/DBIO/Deploy/Base/TempDatabase.pm`) provides the shared temp-database
  orchestration for engines that need a real scratch DB (PostgreSQL, MySQL):
  create temp db → deploy + introspect → **always** drop, re-raising any error.
  In-memory engines (SQLite, DuckDB) override `_build_target_model` with a
  `:memory:` connection instead.

## Rationale

Diffing two *introspected* models is more honest than diffing two *parsed DDL
strings*: it compares what the database would actually contain, not what a parser
believes the DDL means. Deploying the desired schema to a scratch database and
introspecting it ("test-and-compare") removes the dependency on a per-engine DDL
producer being faithful — the database itself is the source of truth for the
target model. This only works because deploy is native (ADR 0006); the two
decisions are one architecture split across two ADRs.

Heritage.pod states it directly (`lib/DBIO/Manual/Heritage.pod:86-87`): "Every
driver ships its own native introspection, diff, and deploy modules (the
test-and-compare strategy) and does not require L<SQL::Translator>"; and
(`Heritage.pod:117-126`) the native class "deploys by introspecting both the live
database and the desired schema and diffing the two models (test-and-compare)."

## Consequences

- Migration no longer depends on `SQL::Translator::Diff`. The diff is driven by a
  normalised introspection contract (`Introspect::Base`) shared by all drivers,
  with per-driver overrides only where native catalog access beats generic DBI
  metadata.
- A migration requires a usable scratch database (or `:memory:`). `TempDatabase`
  guarantees the temp database is dropped even on deploy/introspect failure
  (`Deploy/Base/TempDatabase.pm`) and re-raises — so a failed diff never leaks a
  scratch DB but does surface its error.
- Diff output is a structured list of `DBIO::Diff::Op` objects, each with both
  `as_sql` and `summary`. Tooling can inspect or summarise a migration before
  applying it; this is richer than an opaque ALTER blob.
- **Naming flag (ticket vs code):** there is no `lib/DBIO/Introspect.pm` or
  `lib/DBIO/Diff.pm`. The layer is `DBIO::Introspect::{Base,DBI}` and
  `DBIO::Diff::{Base,Compare,Op}`. The karr ticket's "DBIO::Introspect /
  DBIO::Diff" is shorthand for those clusters.
- Pairs with ADR 0006 (native Deploy provides the deployer that fills the scratch
  database) and feeds ADR 0009 (`DBIO::Generate` reuses this same Introspect
  contract to emit Result classes — see that ADR).
