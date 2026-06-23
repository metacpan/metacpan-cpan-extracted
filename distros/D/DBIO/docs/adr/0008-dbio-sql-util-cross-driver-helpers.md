# ADR 0008 — DBIO::SQL::Util cross-driver helpers

- Status: accepted
- Date: 2026-06-19
- Tags: sql, drivers, util, backfill

## Context

DBIO splits every database into its own distribution (ADR 0001), and each driver
ships its own DDL, Diff and Deploy modules (ADR 0006, ADR 0007). Several
low-level SQL string operations are needed identically across those drivers and
across the core deploy orchestrator: quoting an identifier with embedded-quote
escaping, and splitting a multi-statement SQL blob into individual statements
while respecting dialect quoting. In DBIx::Class such helpers were scattered
inside Storage::DBI and the SQLMaker; with drivers now in separate
distributions, duplicating them per driver would let them drift.

## Decision

Provide a single shared `DBIO::SQL::Util` (`lib/DBIO/SQL/Util.pm`) — an
Exporter-based module of cross-driver SQL string helpers that core and every
driver reuse rather than re-implement.

- `@EXPORT_OK = qw(_quote_ident _split_statements)` (`SQL/Util.pm:10`).
- `_quote_ident` (`SQL/Util.pm:16-26`) quotes a SQL identifier, escaping an
  embedded `"` as `""`.
- `_split_statements` (`SQL/Util.pm:30-84`) splits SQL on `;` while respecting
  dollar-quoting (`$$` and tagged `$tag$`) and returns trimmed, non-blank
  statements.

These are dialect-aware string utilities common to all engines, not
driver-specific SQL: identifier quoting and statement splitting are the same
problem everywhere, so they live once.

## Rationale

The driver-per-distribution split (ADR 0001) makes a shared helper layer the only
way to keep these primitives single-sourced; without it, every driver's DDL
class would carry its own copy and they would diverge silently. Locating them in
a tiny functional module — `use DBIO::SQL::Util qw(...)` — keeps them
dependency-light and importable by both core (the deploy orchestrator splits a
DDL blob into statements before executing them: `DBIO::Deploy::Base:146` calls
`_split_statements`) and the drivers (each `::DDL` class imports `_quote_ident`).

This is a new structure with no DBIx::Class equivalent: Heritage.pod's removed-
dependencies list notes `SQL::Abstract::Util` was *merged into SQL::Abstract*
(`lib/DBIO/Manual/Heritage.pod:530`) but says nothing about a DBIO-side SQL
helper module — `DBIO::SQL::Util` exists because the split-driver architecture
created the need, as the fork-birth commit's "per-database drivers extracted into
their own CPAN distributions" framing implies.

## Consequences

- Identifier quoting and statement splitting are single-sourced. Drivers import
  from `DBIO::SQL::Util` instead of carrying private copies; a fix to quoting or
  dollar-quote handling lands once and reaches every driver.
- The module is a genuinely shared layer: core's `DBIO::Deploy::Base` consumes
  `_split_statements`, and the per-driver `::DDL` classes consume `_quote_ident`.
  It is a cross-cutting utility, not owned by any single driver.
- It is deliberately minimal (two helpers). It is the home for *cross-driver* SQL
  string primitives only — engine-specific SQL stays in the driver. New shared
  string helpers (not full SQL generation, which is the SQLMaker's job, ADR 0002)
  belong here; resist growing it into a second SQL engine.
- Tested in `t/sql_util.t`.
