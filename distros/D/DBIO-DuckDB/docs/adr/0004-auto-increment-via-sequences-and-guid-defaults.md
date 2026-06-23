# ADR 0004 — Auto-increment is implemented with real sequences; GUID keys default via uuid()

- Status: accepted
- Date: 2026-06-20

## Context

DBIO Result classes declare surrogate keys with `is_auto_increment => 1` and
expect the database to supply the value. The portable model behind this is
PostgreSQL/MySQL-style identity columns. DuckDB does not have an `AUTO_INCREMENT`
column attribute; it has **real `CREATE SEQUENCE` objects** plus
`DEFAULT nextval('seq')`, and it has a **native `UUID` type** with a `uuid()`
generator function.

Two engine facts forced concrete decisions in `DBIO::DuckDB::DDL`:

- A DuckDB sequence does **not** auto-advance when a row is inserted with an
  explicit value (unlike a PostgreSQL `IDENTITY`/`serial`). Test fixtures and
  manual inserts that supply small literal IDs would therefore collide with a
  sequence starting at 1.
- A GUID-family key (`uuid`/`guid`/`uniqueidentifier`) maps to DuckDB's native
  `UUID` type, which cannot take an **integer** `nextval()` default. Karr #6
  recorded a real deploy failure: the core test schema's `artist_guid` /
  `money_test` tables were rejected by DuckDB's strict type checking when an
  upper-cased fallthrough type or an integer sequence default was emitted for a
  UUID/MONEY/CHARACTER column.

## Decision

Implement `is_auto_increment` natively against DuckDB's type system rather than
emulating an identity column.

1. For an integer-keyed auto-increment column, `DBIO::DuckDB::DDL` emits a
   dedicated per-column sequence `"${table}_${col}_seq"` (created **before** the
   table) and a `DEFAULT nextval('...')` on the column.
2. Each such sequence is created with a high `START` value (`1_000_000`) so that
   fixtures and manual inserts using small explicit IDs do not collide with
   `nextval()`. This deliberately biases the auto-generated range upward to
   compensate for DuckDB sequences not advancing on manual inserts.
3. For a GUID-family auto-increment column (`uuid`/`guid`/`uniqueidentifier`),
   **no sequence** is emitted; the column is typed `UUID` and defaults via
   `uuid()`.
4. The type map normalises engine-foreign type names to DuckDB types so strict
   `CREATE TABLE` checking accepts them — notably
   `uniqueidentifier`/`guid` → `UUID`, `money` → `DECIMAL(19,4)` (DuckDB has no
   MONEY type), and `character` → `VARCHAR`. Unknown types fall through
   upper-cased.

## Consequences

- Auto-increment works on DuckDB without an identity column, and integer and
  GUID surrogate keys each get the correct generator.
- The `1_000_000` start bias means auto-assigned integer IDs begin at a large
  value; application code must not assume auto-increment IDs start at 1. This is
  a visible behavioural difference from the identity-column drivers and is the
  price of letting fixtures use small explicit IDs safely.
- The per-column-sequence naming convention (`"${table}_${col}_seq"`) is part of
  the round-trip contract: introspect detects auto-increment by recognising a
  `nextval(...)` default, so the DDL and introspect sides must keep using the
  same convention.
- New engine-foreign type names that DuckDB's strict checker would reject must
  be added to the type map; an unmapped type that DuckDB does not understand
  will fail at deploy, not silently.
