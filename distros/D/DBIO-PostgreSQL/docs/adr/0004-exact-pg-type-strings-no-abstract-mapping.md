# ADR 0004 — Exact PostgreSQL type strings, no abstract type mapping

- Status: accepted
- Date: 2026-06-20
- Tags: types, ddl, introspect, sql-translator, drivers

## Context

Core ADR 0006 demotes `SQL::Translator` to optional and makes each driver own
its DDL; core ADR 0007 makes the diff compare *introspected* models. Both
decisions remove the central, database-agnostic type layer that DBIx::Class
inherited from SQLT — a layer that mapped every column to an abstract type and
back to an engine type.

PostgreSQL's type system is the worst possible fit for an abstract round-trip.
It has enums, composite types, arrays (`text[]`), parameterised types
(`numeric(p,s)`, `vector(1536)`), and extension-supplied types whose names this
driver cannot enumerate ahead of time. Mapping `jsonb` → some abstract "JSON" →
back risks losing `jsonb` vs `json`; mapping `vector(1536)` through an abstract
layer that has never heard of pgvector simply cannot work.

## Decision

Store, emit, introspect and compare PostgreSQL types as **exact PostgreSQL type
strings**. Only a small set of canonical *base* types is routed through an
adapter; everything else passes through verbatim.

- **Base types via the adapter (single source of truth).** Only types that
  `DBIO::Schema::Type::is_base_type` recognises are canonicalised and resolved
  through `DBIO::PostgreSQL::Adapter->to_native` (`DDL.pm:383-387`). The adapter
  maps the portable base set to PostgreSQL natives — e.g. `integer → bigint`,
  `timestamp → timestamptz`, `blob → bytea`, and builds `numeric(p,s)` /
  `character(n)` from precision/scale/size (`Adapter.pm:9-27`).
- **Everything else passes verbatim in DDL emit.** `_pg_column_type` returns the
  declared string untouched for enums (`pg_enum_type`), composites
  (`pg_type_name`), arrays (anything ending `[]`), and any parameterised /
  extension type (anything ending `(...)` — `numeric(p,s)`, `vector(1536)`)
  (`DDL.pm:368-381`); a legacy-alias map only normalises PG-dialect spellings to
  their canonical PG names, never to an abstract type (`DDL.pm:389-422`).
- **Introspect reads the exact PostgreSQL type.** Column, type, function and
  sequence introspection take the type straight from
  `pg_catalog.format_type(...)` (`Introspect/Columns.pm:38`, and the same call
  in `Introspect/Types.pm`, `Introspect/Functions.pm`, `Introspect/Sequences.pm`).
- **Comparison is PG-string to PG-string.** Diff compares the introspected
  PostgreSQL type strings directly; there is no lossy translation step on either
  side.

## Rationale

This is the concrete reason the CLAUDE.md design notes give for **not** using
`SQL::Translator` anywhere in this driver: SQLT is database-agnostic and would
lose PostgreSQL-specific types, treat JSONB as text, and mangle enums and
parameterised/extension types. Under test-and-compare both type strings come
from `format_type` on real PostgreSQL servers, so comparing them as strings is
not just lossless — it is comparing what the database actually stores. The base
adapter exists only so the *portable* subset (the types a user might write
generically, like `integer`) has one canonical native spelling; it is a
convenience over the verbatim path, not a translation layer the rest of the
system depends on.

The `cpanfile` and `dist.ini` carry no `SQL::Translator` dependency, consistent
with this decision and with core ADR 0006.

## Consequences

- New PostgreSQL or extension types need **no** code change to be deployable and
  diffable: `vector(1536)`, `geometry(Point,4326)`, a custom composite — all
  flow through verbatim. This is what makes the extension-heavy stacks in the
  CLAUDE.md use cases work without per-type support.
- The driver does not protect the user from a misspelled type: a bogus type
  string passes through to PostgreSQL, which raises the real error. That is the
  intended trade — PostgreSQL is the validator, not an abstract type table.
- Because comparison is string-based, type equivalences PostgreSQL treats as
  equal but spells differently (e.g. `int4` vs `integer`) rely on `format_type`
  normalising both sides; both sides coming from `format_type` under
  test-and-compare guarantees that within a run.
- `SQL::Translator` stays absent from this driver's dependencies. Any future
  proposal to reintroduce an abstract type layer should be weighed against this
  ADR and the loss-of-fidelity cases it lists.
