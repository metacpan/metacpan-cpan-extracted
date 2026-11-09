# ADR 0002 — ClickHouse is a standalone distribution, not a MySQL storage subclass

- Status: accepted
- Date: 2026-07-20

## Context

ClickHouse is reached over the MySQL wire protocol (ADR 0001), and `dbio-mysql`
already models a MySQL-family variant as a *storage subclass*:
`DBIO::MySQL::Storage::MariaDB` extends `DBIO::MySQL::Storage`. That precedent
invites the question: should ClickHouse likewise be
`DBIO::MySQL::Storage::ClickHouse` inside `dbio-mysql`, reusing the MySQL
storage and SQLMaker?

The MariaDB subclass is appropriate because MariaDB **is** MySQL for ORM
purposes: same transactional semantics, same `information_schema`, same
auto-increment, same foreign keys, same locking, same DDL shape. The subclass
adjusts a handful of dialect details on top of a fundamentally shared model.

ClickHouse shares the **wire protocol** with MySQL and essentially **nothing
else** at the semantic level:

- **No transactions, no savepoints** — MySQL storage assumes both.
- **No `SELECT ... FOR UPDATE`** — no row locking model at all.
- **No `INSERT ... RETURNING`.**
- **No auto-increment / `last_insert_id`** — identity is the MergeTree
  `ORDER BY` key; surrogate keys use `generateUUIDv4()`.
- **No foreign keys.**
- **`UPDATE` / `DELETE` are asynchronous mutations** (`ALTER TABLE ... UPDATE` /
  `... DELETE`), non-transactional and eventually applied — not row-level DML.
- **Mandatory table engines** (`ENGINE = MergeTree`, `ORDER BY ...`) with no
  MySQL analogue.
- **A different type system** (`Int8..64`, `UInt*`, `String`, `FixedString`,
  `LowCardinality`, `Array`/`Tuple`/`Map`, `Nullable(T)`, `DateTime64`, ...).
- **A different catalog** (`system.tables` / `system.columns`,
  `SHOW CREATE TABLE`) — not MySQL's `information_schema` shape.

## Decision

`DBIO::ClickHouse` is a **standalone distribution** (`DBIO-ClickHouse`,
namespace `DBIO::ClickHouse::*`), a direct subclass of `DBIO::Storage::DBI` —
**not** a storage subclass of `DBIO::MySQL::Storage` and **not** shipped inside
`dbio-mysql`.

It reuses the MySQL *transport* (a MySQL-wire DBD, ADR 0001) and MySQL-wire
*identifier quoting* (backticks), and nothing else. Every MySQL semantic that
ClickHouse does not implement is neutralised at this driver's own storage /
SQLMaker boundary (savepoints throw, `RETURNING` off, `FOR UPDATE` disabled),
rather than inherited from a MySQL storage class.

## Consequences

- ClickHouse-specific behavior evolves independently, without risking the
  stability of the widely-used `dbio-mysql` driver or contorting its class
  hierarchy.
- A ClickHouse-as-MySQL-subclass would inherit a **lying API**: methods and SQL
  generation that silently assume transactions, locking, `RETURNING` and
  auto-increment, which ClickHouse cannot honour. Keeping ClickHouse standalone
  makes the unsupported surface explicit and local.
- The cost is some duplication of the thin DBD/quoting choices already present
  in `dbio-mysql`. That is accepted: the shared surface is small and the
  semantic divergence is total, so the duplication does not create a meaningful
  maintenance coupling.
- The MergeTree DDL, ClickHouse type mapping, native introspection
  (`system.*` / `SHOW CREATE TABLE`), diff and deploy, and the async-mutation
  `UPDATE`/`DELETE` path are all owned by this distribution and tracked as its
  own follow-up work.
