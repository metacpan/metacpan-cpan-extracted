# ADR 0003 — Definition-string index comparison instead of field-by-field

- Status: accepted
- Date: 2026-06-20
- Tags: diff, index, introspect, drivers

## Context

Core's diff layer (core ADR 0007) supplies `DBIO::Diff::Compare`, the
engine-agnostic comparison kernel, including `changed_index_fields` — the
generic way to detect an index change by comparing structured fields (columns,
uniqueness, access method). The expectation is that each driver's `Diff::Index`
reuses that field comparator.

That contract is too coarse for PostgreSQL. A PostgreSQL index can differ along
axes the generic field set does not model: a partial-index `WHERE` predicate, an
expression index (`lower(name)`), storage parameters (`WITH (lists = 100)` for
ivfflat), the access method, `INCLUDE` columns, opclasses, collations. Two
indexes can compare "equal" on the generic fields while being materially
different in PostgreSQL. PostgreSQL already hands us a canonical, fully-rendered
form of every index — `pg_get_indexdef` — that captures all of these exactly.

## Decision

`DBIO::PostgreSQL::Diff::Index` overrides core's field-by-field contract and
compares indexes by **full definition-string equality**, deliberately *not*
using `DBIO::Diff::Compare`'s `changed_index_fields`.

- Index identity is by name. When an index exists on both sides, the comparison
  is a plain string compare of the `pg_get_indexdef` definition:
  `$src_def ne $tgt_def` (`Diff/Index.pm:85-87`).
- Any difference emits a **drop-then-create pair** rather than an in-place ALTER
  (`Diff/Index.pm:88-100`) — PostgreSQL has no general `ALTER INDEX` that can
  change predicate / expression / method, so recreate is the only correct path.
- `as_sql` for a create reuses the introspected `pg_get_indexdef` string
  verbatim when present (`Diff/Index.pm:128-131`), so the emitted DDL is exactly
  what PostgreSQL itself would report.

This builds on core ADR 0007 (the introspect+diff layer and the `Diff::Compare`
contract it defines); see that ADR for the contract this one overrides. It does
not restate the test-and-compare strategy.

## Rationale

Under test-and-compare both `definition` strings come from the same
`pg_get_indexdef` on two PostgreSQL servers, so string equality is reliable, not
brittle: identical indexes serialise identically, and any real difference —
partial predicate, expression, storage param, access method — changes the string.
A field-by-field comparator would need to grow a PostgreSQL-specific field for
every one of those axes and still risk drift from what the database actually
stores; comparing the database's own rendered form sidesteps the whole problem
and is a genuine PostgreSQL strength.

karr #4 marks this as STAYS-divergent. SEAM A: "Diff/Index.pm definition-string
comparison STAYS (compares `pg_get_indexdef`, a pg strength)." SEAM B: "Index
compare stays definition-string (NOT a Compare candidate)." So while sibling
diff classes adopt core's `mk_diff_accessors` / `changed_fields`, the index
differ is explicitly exempt.

## Consequences

- Any index change is a drop+create, never an in-place alter. For large indexes
  this is more expensive than a targeted ALTER would be — but PostgreSQL offers
  no ALTER for the dimensions that actually change, so recreate is correct, and
  `CREATE INDEX CONCURRENTLY` (when used) keeps it online.
- The comparison is only as stable as `pg_get_indexdef`'s rendering. Because both
  sides come from the same PostgreSQL version under test-and-compare, formatting
  differences cannot produce false positives within a run; comparing across
  major-version servers could, and is out of scope for the in-run diff.
- `DBIO::PostgreSQL::Diff::Index` intentionally does not gain a
  `changed_index_fields` path. Future reviews proposing to "align it with the
  other diff classes" should be pointed here.
