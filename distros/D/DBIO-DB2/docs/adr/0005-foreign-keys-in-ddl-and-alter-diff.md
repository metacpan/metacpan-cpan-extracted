# ADR 0005 — Foreign keys are emitted in install DDL and diffed via ALTER

- Status: accepted
- Date: 2026-06-22
- Tags: ddl, diff, deploy, foreign-keys, db2, family-axis

## Context

DB2 (LUW) **enforces** referential integrity: a declared `FOREIGN KEY`
constraint is checked at write time, unlike DuckDB, which accepts the syntax
but does not enforce it. DuckDB ADR 0001 therefore omits FKs from its install
DDL and ships no FK differ, and it explicitly predicts the counterpoint: *"the
feature is only meaningful once the engine enforces FKs and the DDL can emit
them."* DB2 is exactly that case.

DB2 uses the test-deploy-and-compare strategy (ADR 0001): both the `source`
and the `target` model handed to `DBIO::DB2::Diff` come from
`DBIO::DB2::Introspect` — `target` is introspected from a throwaway schema
that was just built from the install DDL. Until now `DBIO::DB2::DDL` did **not**
emit `FOREIGN KEY` clauses; the relationship data was consumed only to
topologically order table creation. That left a trap: had a standalone FK
differ been added while the DDL stayed FK-free, the introspected `target` would
carry zero foreign keys, the differ would see FKs on the live `source` but none
on the `target`, and every `upgrade` would emit a phantom `DROP` of every FK —
the exact idempotency break DuckDB ADR 0001 describes. So the FK differ cannot
be added in isolation; the DDL must emit FKs first.

A second, smaller gap: `DBIO::DB2::Introspect::ForeignKeys` keyed the FK name
in the model as `fk_id`, an underscore-free local spelling that did not match
the `constraint_name` key that core ADR 0021 blessed as the canonical
foreign-key name. DB2 was named in ADR 0021 as a per-driver realignment
follow-up (karr #12).

## Decision

1. **`DBIO::DB2::DDL->install_ddl` emits foreign keys as named inline
   constraints.** Each `belongs_to` relationship marked
   `is_foreign_key_constraint` becomes
   `CONSTRAINT <name> FOREIGN KEY (<cols>) REFERENCES <reftable>(<refcols>)`
   inside `CREATE TABLE`, with `ON DELETE`/`ON UPDATE` appended only when the
   relationship sets a rule that is not `NO ACTION`. FK columns are extracted
   from the relationship `cond` (`{ "foreign.<refcol>" => "self.<localcol>" }`),
   the same way `DBIO::MySQL::DDL` does. PK/column/index emission is unchanged.

2. **Name-based FK identity via a deterministic name (Option 1).** The
   constraint name is `fk_<table>_<from_cols>`, derived from the relationship,
   not server-assigned. Because the live database and the throwaway compare
   schema are both built from this same DDL, both carry the *same* stable name,
   so the name-based match in the differ does not phantom-diff. This mirrors
   MSSQL, whose `DBIO::MSSQL::Diff::ForeignKey` keys FK identity by
   `constraint_name` and falls back to a deterministic name when no server name
   is present.

3. **New `DBIO::DB2::Diff::ForeignKey` + a fourth diff pass.** Built on
   `DBIO::Diff::Op` like its siblings, it keys FKs by `constraint_name` via
   `diff_nested(... scope => 'both' ...)` with `changed_fk_fields` (core
   `DBIO::Diff::Compare`, ADR 0019) as the change predicate. It emits:
   - **ADD**: `ALTER TABLE <t> ADD CONSTRAINT <name> FOREIGN KEY (...) REFERENCES ...`,
     with `ON DELETE`/`ON UPDATE` suppressed for `NO ACTION`.
   - **DROP**: `ALTER TABLE <t> DROP FOREIGN KEY <name>` (DB2 syntax), using the
     **real server name carried in the model**, not a regenerated one.
   - **modify**: DB2 has no in-place FK alter, so a changed FK is a
     drop-then-add pair, drop first.
   `DBIO::DB2::Diff` runs this pass **last**, after tables/columns/indexes, so
   any referenced table or column already exists. `scope => 'both'` skips FKs on
   brand-new tables (created inline by `DBIO::DB2::Diff::Table`) and on dropped
   tables (they vanish with the table).

4. **`fk_id` → `constraint_name` model-key realignment (completes karr #12).**
   `DBIO::DB2::Introspect::ForeignKeys` now keys the FK name as
   `constraint_name`, conforming to the core ADR 0021 canonical key, and
   `table_fk_info` reads it from there.

## Rationale

DB2 enforces RI, so a deployed schema *has* FKs and a deploy that did not carry
them would silently drop referential integrity. Emitting FKs in the DDL is
therefore required for correctness, not a nicety — which is precisely the
condition under which DuckDB ADR 0001 said FK emission becomes safe and a FK
differ becomes meaningful. The two changes are inseparable: under
test-deploy-and-compare the differ's `target` is only as complete as the DDL
that built it, so the DDL must emit FKs for the differ to be idempotent. The
idempotency test (`t/30-diff.t`, identical source/target → zero FK ops) encodes
exactly this: it fails the moment the DDL stops round-tripping FKs.

Name-based identity is sound here *only because* the name is deterministic and
DDL-derived: a server-assigned name would differ between the live database and
the compare schema and break the match. Per core ADR 0021, the constraint name
is read for DROP targeting and is **not** added to the compared field set —
`changed_fk_fields` compares FK *attributes* (`to_table`, `on_delete`,
`on_update`, the column lists), never the name, so two otherwise-identical FKs
with different names do not phantom-diff. Aligning the model key to
`constraint_name` is what lets the differ read the field uniformly with its
cross-driver siblings.

## Consequences

- DB2 install DDL now carries enforced foreign keys; a schema deploys with full
  referential integrity, and FK drift on existing tables is now visible to
  `diff`/`upgrade` (it was invisible before, as it still is on DuckDB).
- DB2 lands on the **emit-FKs** side of the family axis, opposite DuckDB, for
  the engine-enforcement reason DuckDB ADR 0001 anticipated.
- The deterministic name binds the DDL and the differ: changing the naming
  scheme in `DBIO::DB2::DDL` without re-deploying would make the differ see a
  renamed FK as drop+add. The name generator is the single source
  (`_fk_constraint_name`).
- karr #12 is complete: the model now uses the canonical `constraint_name` key;
  no `fk_id` consumer remains.

## Related

- core ADR 0021 (`constraint_name` optional canonical FK key; name read for
  DROP, never compared) — this ADR does not duplicate that cross-driver rule
- core ADR 0019 (FK comparator `changed_fk_fields` and desired-state skip)
- DuckDB ADR 0001 (FKs omitted from install DDL — the opposite end of the axis,
  whose "revisit when the engine enforces FKs" prediction this ADR realizes)
- MSSQL `DBIO::MSSQL::Diff::ForeignKey` (the mirrored FK diff op shape)
- ADR 0001 (test-deploy-and-compare against a temp schema)
- ADR 0004 (type mapping, the other half of DDL/diff agreement)
