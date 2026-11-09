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
(`lib/DBIO/DB2/Deploy.pm`) that splices the desired schema into a throwaway
`CREATE SCHEMA` block. `install` / `diff` / `apply` / `upgrade` and the
dbh/schema accessors are inherited unchanged from `DBIO::Deploy::Base`.

- **Throwaway is a SCHEMA in the live database.** `_build_target_model`
  (`lib/DBIO/DB2/Deploy.pm`) issues `CREATE SCHEMA DBIO_TEST_<pid>` in the same
  database, points `CURRENT SCHEMA` at it for the duration of the compare deploy
  (ADR 0006), re-emits the install DDL with every object position
  schema-qualified to that test schema, introspects the test schema, and tears
  the schema down through `_drop_test_schema` on the way out — **even on
  failure**. The teardown empties the schema before it drops it: FK constraints,
  then tables, then views, then `DROP SCHEMA ... RESTRICT`, each statement in
  its own `eval`, best-effort. The build error is saved right after the build
  `eval`, and `die $err if $err and not $model` re-raises only when the build
  itself failed.
- **DDL is schema-qualified by a regex pass, not by the DDL renderer.**
  `DBIO::DB2::DDL` does **not** auto-qualify table/index names — `install_ddl`
  (`lib/DBIO/DB2/DDL.pm`) emits unqualified `CREATE TABLE "<name>"` /
  `CREATE INDEX "<name>" ON "<name>"`, every identifier double-quoted through
  `_db2_quote_ident`. So `_split_qualify_ddl` (`lib/DBIO/DB2/Deploy.pm`) splits
  the install DDL into statements and rewrites `CREATE/DROP TABLE`,
  `CREATE [UNIQUE] INDEX`, `DROP INDEX`, `CREATE VIEW` (the name position only)
  and the target of an inline `REFERENCES` to `$test_schema."<name>"` before
  executing each. A view's body is not rewritten; it is what `CURRENT SCHEMA`
  is moved for (ADR 0006).

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
an oversight. The in-code comment above `_split_qualify_ddl` states it: "The regex
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
  `DBIO_TEST_<pid>` schema. `_build_target_model` clears a leftover of the same
  name — left by an earlier run under the same pid — before `CREATE SCHEMA`, so
  only a leak under another pid has to be dropped manually. The normal-path
  teardown always runs (even when the build `eval` failed), but it is
  best-effort: a statement that fails in it is skipped, not raised.
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

## Addendum 2026-10-05 — the text brought in line with the code (karr k38)

The text above was corrected in place on this date wherever the code had moved
on since it was written, and the line references were replaced by module path
and sub name. The decision — a temp schema, not a temp database — is unchanged.
What changed, and why:

- **The schema is `DBIO_TEST_<pid>`, not `_dbio_test_<pid>`.** The text named
  the lowercase, underscore-led spelling. `_build_target_model` creates
  `DBIO_TEST_<pid>`, and the comment there says why the other spelling cannot
  work: Db2 rejects an unquoted identifier that starts with an underscore
  (SQL20521N), and `SYSCAT` stores schema names uppercased, so a lowercase name
  would never match the introspector's `tabschema` filter. Neither `Changes` nor
  the commit history names a card for the change; every commit this repository
  still holds already creates the uppercase name.
- **`install_ddl` no longer emits bare names.** When this ADR was written the
  DDL left a simple name bare (`CREATE TABLE artist`). Since karr k28 every
  identifier goes through `_db2_quote_ident` and is always double-quoted: Db2
  folds an unquoted name to uppercase while the SQLMaker quotes what it emits,
  so the bare form installed `ARTIST` and the queries for `"artist"` missed it
  (SQL0204N).
- **The teardown is `_drop_test_schema`, not one `DROP SCHEMA ... RESTRICT`.**
  `RESTRICT` succeeds only on an empty schema, and by then the schema holds the
  deployed tables. `SYSPROC.ADMIN_DROP_SCHEMA` drops a populated schema but
  needs the `SYSTOOLSPACE` tablespace, which a stock instance does not have
  (SQL0443N). So the schema is emptied with plain DDL and catalog lookups — FK
  constraints first, so the tables can go in any order, then tables (their
  indexes go with them), then views — and dropped last. Each statement is an
  `eval` of its own, so one failure does not abort the rest. The comment above
  `_drop_test_schema` has the full account.
- **The re-raise reads a saved error.** The text quoted
  `die $@ if $@ and not $model`. The teardown runs in `eval`s, and each one
  blanks `$@`, so that line read the last teardown `eval`'s `$@`: a build
  failure came back as a silent `undef` model, or was masked by a teardown
  error. Since karr k35 the error is captured right after the build `eval` and
  the line is `die $err if $err and not $model`; the intent — re-raise only when
  the build itself failed — is the one this ADR stated (ADR 0006).
- **`_split_qualify_ddl` covers more shapes.** `CREATE UNIQUE INDEX`, which the
  `CREATE INDEX` substitution never matched (karr k29); `CREATE VIEW` in its
  name position, with `_build_target_model` moving `CURRENT SCHEMA` to the test
  schema and back so the unrewritten body resolves there (karr k35, ADR 0006);
  and the target of an inline `REFERENCES`, without which a child table in the
  test schema would reference the **live** parent.
- **A leak under the same pid is cleared at the start.** `_build_target_model`
  looks the name up in `SYSCAT.SCHEMATA` and runs `_drop_test_schema` on a
  leftover before `CREATE SCHEMA`, which would otherwise collide (SQL0601N).
  A leak under another pid is still manual.

The quoting change is also the first time the lock-step obligation under
*Consequences* came due, and it was missed. `_split_qualify_ddl` still matched a
bare `\w+`, which cannot match a leading double-quote, so none of its
substitutions fired and the whole compare DDL ran unqualified — into the live
schema. karr k29 made the pass match the quoted form; ADR 0006 records the same
fault class for `CREATE VIEW`, which the pass had never covered.
