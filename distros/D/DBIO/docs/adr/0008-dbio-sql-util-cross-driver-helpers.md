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

- `@EXPORT_OK = qw(_quote_ident _split_statements)`.
- `_quote_ident` quotes a SQL identifier, escaping an
  embedded `"` as `""`.
- `_split_statements` splits SQL on `;` while respecting
  dollar-quoting (`$$` and tagged `$tag$`) and returns trimmed, non-blank
  statements.

  **Amended 2026-10-08 (k326):** the splitter no longer cuts at every `;`
  outside a dollar quote. It reads the text as SQL and delivers no comment as
  a statement. See the addendum of that date.

These are dialect-aware string utilities common to all engines, not
driver-specific SQL: identifier quoting and statement splitting are the same
problem everywhere, so they live once.

## Rationale

The driver-per-distribution split (ADR 0001) makes a shared helper layer the only
way to keep these primitives single-sourced; without it, every driver's DDL
class would carry its own copy and they would diverge silently. Locating them in
a tiny functional module — `use DBIO::SQL::Util qw(...)` — keeps them
dependency-light and importable by both core (the deploy orchestrator splits a
DDL blob into statements before executing them: `DBIO::Deploy::Base`'s
`_execute_ddl` calls `_split_statements`) and the drivers (each `::DDL` class
imports `_quote_ident`).

This is a new structure with no DBIx::Class equivalent: Heritage.pod's removed-
dependencies list notes `SQL::Abstract::Util` was *merged into SQL::Abstract*
(`lib/DBIO/Manual/Heritage.pod`) but says nothing about a DBIO-side SQL
helper module — `DBIO::SQL::Util` exists because the split-driver architecture
created the need, as the fork-birth commit's "per-database drivers extracted into
their own CPAN distributions" framing implies.

## Consequences

- Identifier quoting and statement splitting are single-sourced. Drivers import
  from `DBIO::SQL::Util` instead of carrying private copies; a fix to quoting or
  dollar-quote handling lands once and reaches every driver.
  **Amended 2026-10-08 (k326):** what the splitter handles is more than dollar
  quotes now, and what it leaves to the caller is named; see the addendum.
- The module is a genuinely shared layer: core's `DBIO::Deploy::Base` consumes
  `_split_statements`, and the per-driver `::DDL` classes consume `_quote_ident`.
  It is a cross-cutting utility, not owned by any single driver.
- It is deliberately minimal (two helpers). It is the home for *cross-driver* SQL
  string primitives only — engine-specific SQL stays in the driver. New shared
  string helpers (not full SQL generation, which is the SQLMaker's job, ADR 0002)
  belong here; resist growing it into a second SQL engine.
- Tested in `t/sql_util.t`.

## Addendum 2026-10-08 — `_split_statements` reads the text as SQL (karr k326)

The Decision describes the splitter as it was: a cut at every `;` outside a
dollar-quoted string. That cut a statement in two wherever a semicolon stood
inside a string literal or a trigger body, and it delivered a comment as a
statement of its own, so each caller dropped what began with `--` -- and with
it the statement behind a comment line. Since karr k326 `_split_statements` in
`lib/DBIO/SQL/Util.pm` reads the text as SQL. The decision of this ADR -- one
shared helper module, the same two exports -- is unchanged; what changed is
what the one helper does.

A semicolon ends a statement only where it stands as one. It does not inside

- a string literal (`'...'`, PostgreSQL's `E'...'`, Oracle's `q'[...]'`);
- a quoted identifier (`"..."`, `` `...` ``, `[...]`);
- a comment (`--` to the end of the line, `/* ... */`);
- a dollar-quoted string (`$$...$$`, `$tag$...$tag$`);
- the body of a `CREATE TRIGGER`, from its `BEGIN` to the `END` that closes it.

Comments in front of a statement are taken off it, and a piece that holds
nothing but comments is no statement and is not delivered. A caller therefore
needs no comment filter of its own: `_execute_ddl` in `DBIO::Deploy::Base` and
`deploy_async` / `_execute_ddl_async` in `DBIO::Storage::Async` run what the
splitter delivers. `/*! ... */` and `/*+ ... */` are code and stay; comments
inside and behind a statement are left as they are.

The backslash is where the dialects part: standard SQL reads it as a
character, MySQL and ClickHouse as an escape inside a literal. Called without
an option, the splitter reads the text under both readings and ends a
statement where either does; `{ backslash_escapes => 0 | 1 }` as second
argument names one.

Not covered, and so still the caller's to hand over whole or dollar-quoted:

- the body of a function, a procedure or an event that is not dollar-quoted --
  its semicolons still end a statement;
- the `DECLARE` section a trigger carries before its `BEGIN` (Oracle,
  Firebird);
- Transact-SQL, where an `END` may be followed by a new `IF`.

The comment block above `_split_statements` is the full specification;
`t/sql_util.t` pins it, and `t/test/55_async_deploy_comment_parity.t` pins
that the async deploy path delivers what the sync one does.

## Addendum 2026-10-09 — the driver declares the dialect the splitter reads (karr k332)

The splitter reads the text under a dialect-neutral reading, and where the
dialects part -- the backslash in a literal -- it takes both readings and cuts
where either does. That keeps every statement boundary of a text that is right
under one reading, but a literal that ends in `\` in front of a later literal
with a semicolon is cut on PostgreSQL, where the text only has one reading. The
text does not say which dialect it is written in; the driver knows. Core had no
seam to ask it. `{ backslash_escapes => ... }` existed as an option and nobody
passed it.

**Decision.** The dialect is declared by the *storage*, as the method
`_ddl_sql_dialect` (`DBIO::Storage::DBI::Capabilities`): `undef` by default, or
`'postgresql'`, `'sqlite'`, `'mysql'` (MariaDB declares `'mysql'`).
`_split_statements($sql, { dialect => NAME })` takes the dialect; an unknown
name croaks. Undeclared behaves exactly as before. An explicit
`backslash_escapes` still wins over what the dialect implies.

**Why the storage, not a deploy class or a capability.** The driver already
reports its DDL facts to core on the storage: `_use_transactional_ddl` and
`_ddl_statement_is_transactional` (ADR 0026 addendum) are asked there, by the
sync deploy through `$self->schema->storage` and by the async deploy through
`_owner_storage`. A deploy class (`_ddl_class` and friends) is reachable from
the sync `Deploy::Base` only -- the async path has no such object -- and a
capability is a boolean per feature (`_supports_*`), which a dialect name is
not. The storage method is the one place both paths already ask. It is a
per-statement-style hook with a default, not a flag, so a driver that never
defines it sees no change.

`DBIO::Deploy::Base::_split_ddl($storage, $sql)` is the single place that asks
the storage and calls the splitter; `_execute_ddl` uses it.

**Consequence for the drivers.** A driver declares its dialect in its own
repo; until it does, the splitter reads as before and its suite stays green.

**What the declaration unlocks.** Two readings only one dialect knows are
switched on by the dialect name and nowhere else; undeclared, or declared as
another dialect, the text is read as before:

- `postgresql`: `CREATE [OR REPLACE] FUNCTION | PROCEDURE ... BEGIN ATOMIC ...
  END` (SQL-standard body, PostgreSQL 14+) -- the semicolons between `BEGIN
  ATOMIC` and its `END` end nothing; and block comments nest (`/* a /* b; */
  c; */`), which no other engine does.

A semicolon between parentheses ends nothing in any dialect (`CREATE RULE ... DO
ALSO (INSERT ...; INSERT ...)`), and a bare `end` / `begin` as a column name in a
trigger body is no block boundary; neither needs a dialect and both are read
unconditionally since the same ticket.

The async deploy (`deploy_async`, `_execute_ddl_async` in
`DBIO::Storage::Async`) still calls `_split_statements` without the dialect; it
moves onto `_split_ddl($self->_owner_storage, $ddl)` once the pool work that
owns that file has landed.
