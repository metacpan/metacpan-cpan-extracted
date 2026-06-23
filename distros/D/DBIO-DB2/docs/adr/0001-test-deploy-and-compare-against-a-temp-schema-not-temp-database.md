# ADR 0001 — Test-deploy-and-compare against a temp SCHEMA, not a temp DATABASE

- Status: accepted
- Date: 2026-06-21
- Tags: deploy, diff, db2, temp-schema, drivers

## Context

Core's test-deploy-and-compare migration (core ADR 0007) builds the diff target
by deploying the desired schema into a throwaway location, introspecting it with
the *same* introspector used on the live database, and diffing the two
normalised models. Core ADR 0006 makes deploy a native per-driver concern, and
core ships `DBIO::Deploy::Base::TempDatabase` as the shared orchestration for
engines whose disposable copy must be a **real, separate database**: create temp
db → deploy + introspect → always drop. Most server engines plug into that base
— Sybase ASE (sybase ADR 0005) and PostgreSQL (pg ADR 0002) materialise a whole
scratch *database*; SQLite (sqlite ADR 0002) uses an in-memory `:memory:` one;
Firebird (firebird ADR 0007) creates and safely drops a whole temp database via
a throw-away handle.

DB2 does not fit any of those. DB2 has **no in-memory database** (so SQLite's
shortcut is unavailable) and, more decisively, `CREATE DATABASE` is not an
ordinary in-session SQL statement an application connection can issue against the
server it is already connected to — DB2 **requires an existing database to
connect to at all**, and the throwaway target therefore cannot itself be a fresh
database created on the fly through the live `$dbh`. The only object DB2 lets a
connected handle create and drop freely *inside* the existing database is a
**SCHEMA** (a namespace). So the disposable copy here is a temp *schema*, not a
temp database.

This is a deliberate divergence from the family's `TempDatabase` pattern. pg ADR
0002 **explicitly rejected** the temp-schema path for PostgreSQL: a same-database
namespace there "cannot reproduce database-level objects (extensions, settings)
and risks colliding with or mutating live state." DB2 takes the rejected path
anyway, because for DB2 the trade is reversed: a temp database is not creatable
from a connected handle, and DB2's relevant schema-level objects (tables,
indexes, constraints) *are* fully reproducible inside a throwaway schema, so the
fidelity concern that ruled it out for PostgreSQL does not bite here.

## Decision

`DBIO::DB2::Deploy` extends `DBIO::Deploy::Base` (not `TempDatabase`) and
supplies the three class-name hooks (`_ddl_class`, `_introspect_class`,
`_diff_class`), a `_new_introspect` factory that threads a target schema into the
introspector, and the DB2-specific `_build_target_model`
(`Deploy.pm:101-137`) that splices the desired schema into a throwaway
`CREATE SCHEMA` block. `install` / `diff` / `apply` / `upgrade` and the
dbh/schema accessors are inherited unchanged from `DBIO::Deploy::Base`.

- **Throwaway is a SCHEMA in the live database.** `_build_target_model`
  (`Deploy.pm:101-120`) issues `CREATE SCHEMA _dbio_test_<pid>` in the same
  database, re-emits the install DDL with every `CREATE/DROP TABLE/INDEX`
  statement schema-qualified to that test schema, introspects the test schema,
  and `DROP SCHEMA ... RESTRICT` on the way out — **even on failure** (the drop
  runs in its own `eval`, and `die $@ if $@ and not $model` re-raises only when
  the build itself failed).
- **DDL is schema-qualified by a regex pass, not by the DDL renderer.**
  `DBIO::DB2::DDL` does **not** auto-qualify table/index names — `install_ddl`
  emits bare `CREATE TABLE <name>` / `CREATE INDEX <name> ON <name>`
  (`DDL.pm:93-107`). So `_split_qualify_ddl` (`Deploy.pm:126-137`) splits the
  install DDL into statements and rewrites `CREATE/DROP TABLE` and
  `CREATE/DROP INDEX` to target `$test_schema.<name>` before executing each.

## Rationale

DB2 comparing with itself is always correct (core ADR 0007's premise), and the
faithful disposable copy DB2 actually permits a connected handle to build is a
schema, not a database — so the temp-*schema* path is the only one that lets
both sides of the diff run through the identical `DBIO::DB2::Introspect` code
path without standing up a second real database the connection cannot create.
pg ADR 0002 rejected this same path because PostgreSQL *can* make a real temp
database and a namespace there loses database-level fidelity; for DB2 neither
half of that holds, which is exactly why DB2 takes the path PostgreSQL would not.

The `_split_qualify_ddl` regex is a **self-flagged, deliberate fragility**, not
an oversight. The in-code comment (`Deploy.pm:122-125`) states it: "The regex
pass is conservative — `DBIO::DB2::DDL` emits a known shape — so we trade a small
fragility for not duplicating DDL rendering." The alternative was to teach
`DBIO::DB2::DDL` a schema-qualification mode and thread it through every emit
site, duplicating the rendering logic for the sole benefit of the deploy path.
The regex couples to the exact shape `DBIO::DB2::DDL` emits today; that coupling
is the accepted cost of keeping DDL rendering in one place.

## Consequences

- A migration needs only ordinary `CREATE SCHEMA` / `DROP SCHEMA` rights inside
  the existing database — **not** `CREATE DATABASE` privilege, unlike the
  Sybase, PostgreSQL and Firebird temp-*database* drivers. This is a lighter
  operational footprint than its server-engine siblings.
- The test schema lives in the **live database**, so a crashed run can leak a
  `_dbio_test_<pid>` schema that must be dropped manually. The normal-path drop
  is guaranteed (it runs even when the build `eval` failed).
- `_split_qualify_ddl` is load-bearing and tightly coupled to
  `DBIO::DB2::DDL`'s emitted shape. **Any change to how `DBIO::DB2::DDL`
  spells `CREATE TABLE` / `CREATE INDEX` / `DROP` (e.g. pre-qualifying names,
  bracketing, multi-line keywords) can silently break the qualification rewrite
  and must be made in lock-step with this regex.** If the DDL ever grows a
  native schema-qualification mode, this method becomes a candidate for removal.
- `_build_target_model` is the only DB2-specific piece of the deploy
  orchestration; the rest is inherited from `DBIO::Deploy::Base`. DB2
  deliberately does **not** sit under `DBIO::Deploy::Base::TempDatabase`, so the
  temp-database DSN-shape seam of core ADR 0020 (`_temp_dsn`) does not apply to
  this driver — there is no temp-database DSN to derive.

## Related

- core ADR 0020 (temp-database DSN-shape hook — the `TempDatabase` seam this
  driver does **not** use)
- pg ADR 0002 (temp-DATABASE deploy; **explicitly rejected** the temp-schema
  path DB2 takes)
- sqlite ADR 0002 (in-memory `:memory:` throwaway — the cheap variant DB2 cannot
  use)
- sybase ADR 0005 (real temp database, no in-memory — the server-engine sibling)
- firebird ADR 0007 (temp-DB drop safety on a throw-away handle)
