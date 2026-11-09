# ADR 0072 — Class names are class names

- Status: accepted (coordinator decision of 2026-10-29, karr k380, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-29
- Tags: security, componentised, class-loading, storage, replicated, relates-0066

## Context

DBIO loads classes by name in many places: components, result classes,
resultset classes, the cursor class, storage layers, the types of a replicated
pool, deploy and introspection classes. The loader is
`ensure_class_loaded` / `load_optional_class` of `Class::C3::Componentised`,
reached through `DBIO::Componentised`, and some modules require a class they
name themselves.

## Decision

### 1. A class name is a Perl package name

A string that DBIO loads as a class matches
`\A[A-Za-z_]\w*(?:::\w+)*\z`. Anything else is not a class name and is
refused with `'...' is not a class name` before any file is looked for.

`DBIO::Componentised` overrides `ensure_class_loaded` and
`load_optional_class` with this check and continues with `next::method`.
Schema, ResultSet, ResultSource, Storage, Replicated and every component
loaded through `load_components` pass through it. A component written
`+Foo::Bar` is resolved to `Foo::Bar` before the load and loads as before.

### 2. One helper for modules that require a class themselves

`DBIO::Util::assert_class_name($name)` is the same check as a function. A
module that requires a class by name without `ensure_class_loaded` calls it
first. The call sites: the extension list, `DBIO::Candy`, `DBIO::Cake`,
`DBIO::UUIDColumns`, `DBIO::Schema` (deploy class), the native deploy method of
the deployment handler, `DBIO::Storage::PoolBase`,
`DBIO::InflateColumn::Serializer`, `DBIO::Generate` and `dbiogen`.

### 3. Replicated types are checked by their base class

`pool_type`, `balancer_type`, `backend_storage_class`, `replicant_type` and
`storage_class` name a class that is a `DBIO::Replicated::Pool`, a
`DBIO::Replicated::Balancer`, a driver storage (`DBIO::Storage::DBI`) or a
`DBIO::Replicated::Backend::Replicant` respectively. The check
(`DBIO::Util::assert_class_isa`) runs after the load and before `->new`.

### 4. What the check covers

The check decides that a name is a class name, so loading resolves to a
module in `@INC` and nowhere else. It does not decide which installed module
may be loaded. Result classes, cursor classes, storage types and connect
options are code written by the application's developer; they are never
taken from a request.

## Rationale

- **One rule, one place.** The loader of the component system is the single
  point every class name passes, so the rule holds for all of them at once.
- **A name stays a name.** A path, a relative segment, a space or a leading
  digit is not a package; refusing it keeps class loading to what it is
  named for.
- **Types are checked by what they are.** A replicated type that is not of
  the base class it is used as fails at the line that names it.

## Consequences

- `DBIO::Componentised` gains the two overrides; code that called
  `Class::C3::Componentised->ensure_class_loaded` directly calls it on
  `DBIO::Componentised` or uses `assert_class_name`.
- `DBIO::Util` exports `assert_class_name` and `assert_class_isa`.
- The replicated types fail with a message naming the expected base class.
