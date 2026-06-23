# ADR 0003 — SQLMaker rewrites self-referencing UPDATE/DELETE and owns a lock-clause DSL

- Status: accepted
- Date: 2026-06-20
- Tags: sqlmaker, dml, locking, mariadb, backfill

## Context

MySQL has two SQL-dialect quirks that the query layer must paper over, both
inherited as a problem from the DBIx::Class MySQL storage:

1. **Self-referencing DML.** MySQL rejects an `UPDATE`/`DELETE` whose `WHERE`
   subquery selects from the same table being modified
   (`ERROR 1093: You can't specify target table 'x' for update in FROM
   clause`). DBIx::Class worked around this; DBIO must too, or any
   `delete`/`update` driven by a resultset that references its own table
   breaks.
2. **Locking syntax.** `SELECT ... FOR UPDATE` / `FOR SHARE` gained
   `OF tbl_name`, `NOWAIT` and `SKIP LOCKED` in MySQL 8.0.1, and MariaDB never
   adopted `FOR SHARE` (it spells it `LOCK IN SHARE MODE`).

The base `DBIO::SQLMaker` (core ADR 0002–0005) emits standard SQL; these are
MySQL-specific rewrites that belong in the driver's SQLMaker.

## Decision

`DBIO::MySQL::SQLMaker` overrides `update` and `delete` to detect a
self-referencing target and wrap the offending subquery, and owns a
hash-based lock-clause DSL via `_lock_select`. `DBIO::MySQL::SQLMaker::MariaDB`
overrides only the lock-type mapping.

- `update`/`delete` call `next::method`, extract the target table name
  (`_extract_target_name`), and pass the generated SQL through
  `_wrap_self_referencing_subquery`. When the target table appears in a
  `FROM`/`JOIN` inside the statement, the matching `SELECT` subquery is
  re-wrapped as `( SELECT * FROM (...) `_forced_double_subquery` )` — the
  classic MySQL double-subquery trick that breaks the self-reference. The walk
  uses `Text::Balanced::extract_bracketed` and recurses into nested
  parentheses.
- `_lock_select` accepts either a legacy string (`'update'` / `'share'`) or a
  hashref `{ type => ..., of => [...], modifier => ... }`, emitting
  `FOR UPDATE` / `FOR SHARE` plus the optional `OF <tables>` and
  `NOWAIT` / `SKIP LOCKED` clauses.
- `DBIO::MySQL::SQLMaker::MariaDB` reuses the modifiers but overrides the
  lock-type table so `share` → `LOCK IN SHARE MODE` instead of `FOR SHARE`,
  while accepting the identical DSL.
- `Text::Balanced` is loaded at compile time (`use Text::Balanced ()`), not
  lazily inside the method (karr #10 — lazy `require` was a forbidden
  optimisation under the house syntax rules).

Two smaller MySQL-isms ride in the same class: `insert` emits
`INSERT INTO t () VALUES ()` instead of the standard `DEFAULT VALUES` (which
MySQL does not support), and `STRAIGHT_JOIN` is accepted as a `join_type`.

## Rationale

Self-referencing DML is a correctness requirement, not an optimisation: without
the rewrite, ordinary resultset-driven `update`/`delete` calls throw on MySQL.
Doing it in SQLMaker (post-generation, on the final SQL string) keeps the rest
of the query pipeline engine-agnostic — the base maker builds standard SQL and
the driver patches only MySQL's parser limitation. The lock DSL lives here for
the same reason the base maker can't own it: the surface (`OF`, `NOWAIT`,
`SKIP LOCKED`) and the `FOR SHARE` vs `LOCK IN SHARE MODE` split are
engine-specific, and modelling the MariaDB difference as a one-table override
keeps that divergence to a single named subclass (consistent with ADR 0001).

## Consequences

- The double-subquery rewrite is a string-level transform over generated SQL;
  it is regex- and `Text::Balanced`-driven and inherently fragile against
  unusual SQL shapes. Changes to `_wrap_self_referencing_subquery` or
  `_extract_target_name` must keep the offline SQLMaker tests
  (`is_same_sql_bind`) green — they are the contract that this rewrite stays
  correct.
- Any new locking syntax (a future MySQL/MariaDB lock clause) extends the
  `$lock_types` / `$lock_modifiers` tables; the MariaDB subclass overrides only
  what genuinely differs.
- `Text::Balanced` is a real runtime dependency of this driver and must stay in
  the cpanfile `requires`.
