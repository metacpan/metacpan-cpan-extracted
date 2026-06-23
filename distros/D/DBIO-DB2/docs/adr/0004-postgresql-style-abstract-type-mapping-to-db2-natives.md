# ADR 0004 — PostgreSQL-style abstract types are mapped to DB2 natives in `DBIO::DB2::Type`

- Status: accepted
- Date: 2026-06-21
- Tags: types, ddl, introspect, diff, db2, family-axis

## Context

Core ADR 0006 demotes `SQL::Translator` to optional and makes each driver own
its DDL; core ADR 0007 makes the diff compare *introspected* models. Both remove
the central database-agnostic type layer DBIx::Class inherited from SQLT, and
they leave each driver to decide **how much type translation it does** — a
contested axis across the family:

- **Against abstract mapping** (pg ADR 0004): PostgreSQL stores, emits,
  introspects and compares **exact PostgreSQL type strings**; only a tiny
  canonical base set is routed through an adapter, everything else passes
  verbatim. PostgreSQL's enums/arrays/extension types make an abstract
  round-trip lossy, so PostgreSQL refuses to do one.
- **For a centralized mapper** (firebird ADR 0006): Firebird funnels all three
  layers (introspect, DDL, diff) through one `DBIO::Firebird::Type` module that
  *is* a translation table, with a single "bare type, size rendered once"
  invariant — because three divergent copies of the mapping had produced a real
  bug.

DBIO Result classes commonly declare columns with **PostgreSQL-flavoured
abstract types** — `serial`, `bigserial`, `timestamptz`, `boolean`, `uuid` —
because PostgreSQL is the family's reference dialect. DB2 has none of those
spellings: no `serial`, no `boolean`, no `uuid` type, and its timestamp has no
`tz` variant. So DB2 columns written in the portable PostgreSQL vocabulary have
to be turned into DB2 natives somewhere.

## Decision

DB2 chooses the **mapping** side of the axis. `DBIO::DB2::Type::_db2_column_type`
(`Type.pm:11-61`) is the single home for DB2 type translation, with a
`%type_map` (`Type.pm:24-56`) from abstract/PostgreSQL-flavoured names to DB2
natives, consumed by both DDL emit and the Diff/introspect comparison side
(the function accepts both the hashref column-info shape from `DDL.pm` and the
`($type, $size)` shape from the Diff modules, `Type.pm:14-19`).

The PostgreSQL-flavoured mappings that define the choice:

- `serial    → INTEGER`  and  `bigserial → BIGINT` — DB2 has no `serial`; the
  identity behaviour is supplied separately by `GENERATED ALWAYS AS IDENTITY`
  in `DBIO::DB2::DDL` (the type just becomes the underlying integer).
- `timestamptz → TIMESTAMP`  (and `timestamp with time zone → TIMESTAMP`) — DB2
  `TIMESTAMP` carries no timezone, so the `tz` distinction is dropped.
- `boolean / bool → SMALLINT` — DB2 (LUW, the targeted versions) has no native
  boolean column; it is stored as a small integer.
- `uuid → CHAR(16)` — DB2 has no UUID type; a UUID is stored as a fixed 16-byte
  character column.

A type that already carries a parameter suffix (`/\(.+\)$/`) passes through
untouched (`Type.pm:22`); an unmapped name falls through upper-cased
(`uc $type`, `Type.pm:58`); a `$size` is appended when present (`Type.pm:59-60`).

## Rationale

Unlike PostgreSQL, DB2 has **no lossless verbatim path** for the vocabulary
Result classes are actually written in: `serial`, `boolean`, `uuid` and
`timestamptz` are not DB2 type names, so passing them through verbatim (pg ADR
0004's strategy) would simply hand DB2 a type it rejects. The portable
PostgreSQL-flavoured spellings therefore *must* be translated to DB2 natives for
a `CREATE TABLE` to succeed at all — so DB2 lands on the mapping side of the axis
by engine necessity, not preference. Given that mapping is required, it is
centralized in one module for the same reason firebird ADR 0006 centralizes
its: introspect, DDL and diff must agree on the mapping or test-deploy-and-compare
produces phantom ALTERs on every upgrade, and a single shared function makes the
three layers agree by construction (`_db2_column_type` is already shaped to serve
both the DDL hashref form and the Diff `($type,$size)` form).

This is the lowest-priority of the four DB2 decisions because the mapping table
is small and uncontroversial *for DB2*; it is recorded because it places DB2 on
the contested family axis explicitly — DB2 maps where PostgreSQL refuses to,
and the reason is that DB2's type system, not a stylistic preference, leaves no
verbatim option for the abstract vocabulary in play.

## Consequences

- DB2 deliberately loses information PostgreSQL preserves: `timestamptz`'s
  timezone, `boolean`'s distinctness from a small integer, and `uuid`'s
  type identity (it becomes `CHAR(16)`). This is the accepted cost of having no
  native equivalent; round-tripping a `timestamptz` column through DB2 and back
  will read as `TIMESTAMP`, and a diff comparing the two must account for that
  on both sides via this same map.
- Because introspect, DDL and diff all funnel through `_db2_column_type`, a new
  abstract→DB2 mapping is added in exactly one place; any consumer that
  re-derives type names elsewhere risks the introspect/DDL disagreement that
  firebird ADR 0006 documents as a bug class.
- An unmapped type degrades to its upper-cased self rather than throwing
  (`Type.pm:58`); a name DB2 does not understand fails at deploy, not silently.
- A type written with an explicit parameter suffix bypasses the map entirely
  (`Type.pm:22`), so a caller can always reach a DB2 type the abstract table
  does not cover by spelling it natively.

## Related

- pg ADR 0004 (exact PostgreSQL type strings, **no** abstract mapping — the
  opposite end of this axis)
- firebird ADR 0006 (centralized type system — the same centralize-the-mapping
  rationale DB2 follows)
- core ADR 0006 (native deploy owns SQL generation)
- core ADR 0007 (diff compares introspected models)
