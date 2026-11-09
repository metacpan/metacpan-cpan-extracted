# ADR 0043 — Missing `is_nullable` means NOT NULL

- Status: accepted
- Date: 2026-08-16
- Tags: model, ddl, diff, breaking, cross-repo

> Accepted by maintainer decision in k147 (2026-08-16, option A).

## Context

`DBIO::Schema::Type::canonical_column` (core, `Type.pm`) canonicalises a missing
`is_nullable` key to `not_null => 1`:

    not_null => ($info->{is_nullable} ? 0 : 1),

So a compiled model without an explicit `is_nullable` says NOT NULL. But every
driver DDL in the family emitted the opposite: the nullability clause was gated
on the key being *present*:

    $def .= ' NOT NULL' if defined $info->{is_nullable} && !$info->{is_nullable};

A missing key therefore emitted nothing — the deployed column was nullable in the
database while the compiled model carried `not_null => 1`. Anyone who then
introspected and diffed against `target_from_compiled` got a difference on a
table that was deployed from exactly that schema. The compiled target and the
deployed table could not agree.

This affected every driver with `target_from_compiled`: PostgreSQL, MySQL, MSSQL,
Oracle, SQLite, DuckDB and Sybase (seven DDL sites; the extension drivers
inherit their DDL from these bases).

## Decision

Option A: a missing `is_nullable` means NOT NULL, matching what
`canonical_column` already claims and what ClickHouse does. The driver DDLs
change their gate from "present and false" to "not true":

    $def .= ' NOT NULL' if !$info->{is_nullable};

`is_nullable => 1` still renders nullable; `is_nullable => 0` and a missing key
both render NOT NULL. The model statement and the emitted DDL now agree.

## Consequences

- **Breaking change at the deploy result**: the emitted DDL changes for every
  column without an `is_nullable` key. Existing schemas that relied on the
  implicit-nullable behaviour must add `is_nullable => 1` explicitly.
- The compiled target and the deployed table can no longer diverge on this
  axis; `target_from_compiled` diffs stay clean.
- The invariant is worth a regression test per driver: a column without
  `is_nullable` must deploy as NOT NULL.
- The alternative (option B: missing means nullable, adjust the model) was
  rejected: it would have changed the model statement instead of the DDL and
  contradicted `canonical_column`'s long-standing claim.
