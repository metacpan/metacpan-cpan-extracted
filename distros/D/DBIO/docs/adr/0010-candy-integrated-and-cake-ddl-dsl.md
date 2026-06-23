# ADR 0010 — Candy integrated + Cake DDL DSL (DBIO original)

- Status: accepted
- Date: 2026-06-19
- Tags: candy, cake, dsl, type-registry, drivers, backfill

## Context

DBIx::Class offered exactly one way to write a Result class — the verbose
`__PACKAGE__->method(...)` style — with `DBIx::Class::Candy` available as a
*separate* CPAN distribution that imported short keyword sugar. DBIO keeps the
vanilla style but treats Result-class authoring as a place to do better: fold
Candy into core, and add a new DBIO-original DDL-flavoured DSL, Cake, that can
draw on the per-driver type registry so a column's declared type can pull in the
right component automatically.

## Decision

Integrate Candy into core and add Cake as a new DBIO-original DDL DSL that reads
the active storage class's type registry to auto-activate components and column
attributes.

- **Candy in core.** `DBIO::Candy` (`lib/DBIO/Candy.pm`, ABSTRACT at `:2`) ships
  in this distribution and exports the short keyword sugar (`column`,
  `primary_key`, `unique_constraint`, `relationship`, `has_many`, `has_one`,
  `belongs_to`, `might_have`, `many_to_many`, `inflate_column`, `table`, …). It
  sits between vanilla `DBIO::Core` and Cake: same method-based metadata, shorter
  names.
- **Cake is DBIO-original.** `DBIO::Cake` (`lib/DBIO/Cake.pm`, ABSTRACT at `:2`,
  DESCRIPTION at `:678-699`) is a DDL-like DSL with no DBIx::Class precedent. Type
  functions (`integer`, `varchar`, `text`, `boolean`, `timestamp`, `uuid`,
  `json`, `jsonb`, `array`, `vector`, …) and modifiers (`null`, `auto_inc`, `fk`,
  `default`, `on_create`, `on_update`) replace the hashref-heavy column-info form.
- **Type registry drives auto-activation.** The registry lives on the storage
  class: `register_type` / `type_info` / `all_type_names`
  (`lib/DBIO/Storage.pm:890-951`), and is *driver-contributed* — e.g. PostgreSQL
  registers `jsonb` in its own `Storage` class. Each entry carries
  `cake_options`, `components`, and `col_attrs`. Cake reads it twice: at import,
  it collects and `load_components` the registry's `components` for the active
  options (`Cake.pm:128-142`); at column definition, it merges the registry's
  `col_attrs` into the column for the active option (`Cake.pm:244-257`). So
  declaring a column of a registered type auto-activates the inflation component
  and attributes that type implies.

## Rationale

Authoring is where an ORM's ergonomics are most visible, and DBIO has three
distinct audiences: people who want the classic explicit style (Vanilla), people
who want the same model with less noise (Candy), and people who want a schema to
read like DDL (Cake). Folding Candy into core removes a separate install for the
middle case. Cake exists because the DDL-shaped style additionally lets the
column's *type* be the trigger: because drivers register their types, a `jsonb`
column can pull in JSON inflation without the author wiring a component by hand —
the type registry is the seam that makes type-driven behaviour driver-extensible
instead of hard-coded in core.

Heritage.pod records both (`lib/DBIO/Manual/Heritage.pod:149-207`): Candy "is
derived from C<DBIx::Class::Candy>, which has been integrated into the core
distribution," and Cake "reads like schema DDL … The type registry on the active
Storage class (C<cake_defaults()>, C<type_info($name)>) drives driver-aware
column type resolution."

**Flag — the auto-activation example differs from the ticket.** The karr ticket
says `jsonb` "auto-activates InflateColumn::JSONB." There is **no**
`InflateColumn::JSONB` component. The registered `json`/`jsonb` types load
`InflateColumn::Serializer` with `col_attrs => { serializer_class => 'JSON' }`
(core `json`: `lib/DBIO/Storage.pm:890-901`; PostgreSQL `jsonb`:
`dbio-postgresql/lib/DBIO/PostgreSQL/Storage.pm:13-17`). The *mechanism* the
ticket describes — declaring a registered type auto-activates an inflation
component — is exactly right; the *component name* in the ticket is wrong. This
ADR records the real binding: registered type → `cake_options` → `components` +
`col_attrs` from the registry.

## Consequences

- Three Result-class styles coexist (Vanilla, Candy, Cake) over the same
  underlying metadata. Candy needs no separate install; Cake is the concise
  DDL-shaped option.
- Type-driven behaviour is driver-extensible, not core-hard-coded: a driver adds
  a `register_type` entry and any Cake column of that type auto-loads the declared
  components and attributes. The registry (`Storage.pm:890-951`) is the contract.
- This ADR pairs with ADR 0009: Candy and Cake are also *output* styles of
  `DBIO::Generate` (`DBIO::Generate::Style::{Candy,Cake}`). Here they are the
  *runtime* DSLs; there they are code emitters that produce this syntax.
- Cake always loads `DBIO::Timestamp` so `on_create`/`on_update` and the
  `col_created`/`col_updated` helpers work (ADR 0011) — the Cake DSL is the most
  visible consumer of the integrated Timestamp component.
