# ADR 0002 — Temp-DATABASE deploy (not temp-schema): separate database + AutoCommit dance + schema filter

- Status: accepted
- Date: 2026-06-20
- Tags: deploy, temp-database, autocommit, multi-tenant, drivers

## Context

Core's test-and-compare migration (core ADR 0007) needs to deploy the desired
schema into a throwaway location, introspect it, and diff it against the live
database. Core ADR 0006 makes deploy a native, per-driver concern, and core
ships `DBIO::Deploy::Base::TempDatabase` as the shared orchestration for engines
that need a real scratch database: create temp db → deploy + introspect →
always drop. PostgreSQL is exactly such an engine — but two PostgreSQL realities
do not fit the generic temp-database flow:

1. `CREATE DATABASE` / `DROP DATABASE` **cannot run inside a transaction
   block**, and DBD::Pg connections default to a transaction being open.
2. This driver manages a *subset* of namespaces (`pg_schemas`), so
   introspection of the scratch database must be scoped to those namespaces or
   it would diff against `public` and the catalog noise.

A temp-*schema* approach (create a scratch namespace in the live database
instead of a whole database) was rejected: it cannot reproduce database-level
objects (extensions, settings) and risks colliding with or mutating live state.

## Decision

`DBIO::PostgreSQL::Deploy` extends core's `DBIO::Deploy::Base::TempDatabase`
(`use base` in `Deploy.pm`) — inheriting `install` / `diff` / `apply` /
`upgrade` unchanged — and overrides only the genuinely PostgreSQL-specific
seams. This is the PostgreSQL specialisation of the strategy owned by core ADR
0006 (native deploy) and core ADR 0007 (test-and-compare); see those for the
strategy itself.

- **Real separate database, with the AutoCommit dance.** `_create_temp_db`
  commits any open transaction and locally forces `AutoCommit => 1` around
  `CREATE DATABASE`, because it cannot run in a txn; `_drop_temp_db` is
  symmetric around `DROP DATABASE IF EXISTS` (both in `Deploy.pm`). The temp
  database name is `temp_db_prefix . $$ . '_' . time()`.
- **Schema filter from `pg_schemas` into introspection.** The introspector
  factory `_new_introspect` reads the connected schema's `pg_schemas` and
  passes them as `schema_filter` so introspection of both live and temp
  databases stays scoped to the managed namespaces (`Deploy.pm`,
  `_new_introspect`). The core base only passes `dbh`.
- **`install_schema` is kept, PostgreSQL-only.** `CREATE SCHEMA IF NOT EXISTS`
  for one namespace (`Deploy.pm`, `install_schema`) — the per-schema install
  primitive that multi-tenant setups loop over to give each tenant its own
  namespace. It has no counterpart in the flat-namespace drivers.

## Rationale

PostgreSQL comparing with itself is always correct (core ADR 0007's premise), so
the scratch target must be a faithful PostgreSQL database, not a same-database
namespace that cannot hold extensions or settings. The AutoCommit dance is not
optional polish: without committing and dropping into autocommit, `CREATE
DATABASE` raises *"CREATE DATABASE cannot run inside a transaction block"* under
DBD::Pg's default open transaction. The `schema_filter` exists because this
driver is namespace-scoped by design (ADR 0001) — introspecting unmanaged
namespaces would produce spurious diffs.

karr k4 SEAM D records exactly this split: adopt `TempDatabase`, delete the
inherited `install`/`apply`/`upgrade`/`diff`/`_dbh`/`temp_db_prefix`, but
**keep** `_create_temp_db`/`_drop_temp_db` (the AutoCommit dance), `install_schema`
(pg-only), and the `_new_introspect` override that forwards `schema_filter`.

## Consequences

- A migration needs CREATEDB privilege and a server that allows `CREATE
  DATABASE` (no open txn at that moment). On a connection pool that keeps a txn
  open, the forced `COMMIT` in `_create_temp_db`/`_drop_temp_db` is load-bearing.
- The temp database is always dropped (core `TempDatabase` guarantees the drop
  and re-raises on failure), so a failed diff never leaks a scratch database.
- Multi-tenant install is a supported first-class path via `install_schema`,
  distinct from full `install`. This stays in the driver, not core, because no
  flat-namespace engine has the concept.
- If core ever moves the AutoCommit-around-DDL handling into `TempDatabase`
  itself, these two overrides become candidates for removal — until then they
  must stay even though the rest of the orchestration is inherited.

## Addendum 2026-09-28 (karr k89)

The schema filter above scopes every section of the introspected model except
one: extensions are database-level, so `Introspect` fetches them unfiltered and
a deploy restricted by `pg_schemas` still diffed the extensions of the whole
database. Every extension it did not declare itself — including ones another
application in the same database depends on — became a `DROP EXTENSION`
(found in karr k82).

Maintainer decision (option a of k89): **a deploy restricted by `pg_schemas`
creates declared extensions that are missing — and updates their versions —
but drops none.** An unrestricted deploy (no `pg_schemas` declared) owns the
whole database and behaves exactly as before: extensions not declared via
`pg_extensions` are dropped. The alternatives — drop only extensions whose
objects live in the managed schemas (b), or keep the behaviour and document it
(c) — were not taken.

The rule lives in the one place that knows whether a deploy is restricted:
`DBIO::PostgreSQL::Deploy`. `_schema_filter` answers the restriction (the same
answer `_new_introspect` hands the introspector), and the `diff` override
withholds the `DBIO::PostgreSQL::Diff::Extension` drop operations of a
restricted deploy; `upgrade` goes through `diff` and inherits the rule. The
diff engine itself is unchanged — a `DBIO::PostgreSQL::Diff` built by hand is
unrestricted — and the diff's `source`/`target` models stay as introspected.
Pinned offline by `t/78-deploy-restricted-keeps-extensions.t`, live by
`t/79-deploy-restricted-keeps-extensions-live.t`.

## Addendum 2026-10-09 (karr k89)

The rule of the 2026-09-28 addendum stays the default. A deploy that does own
its extensions although it declares `pg_schemas` can say so with an explicit
parameter: `DBIO::PostgreSQL::Deploy->new(schema => $s,
manage_extensions_when_restricted => 1)`. Set, `diff` leaves the
`DROP EXTENSION` operations in, so extensions the schema does not declare are
dropped (declared ones are created and updated either way). Only `diff` reads
it; the introspector stays restricted to `pg_schemas`, and an unrestricted
deploy is unaffected. Pinned by the same two tests.

## Addendum 2026-10-05 (karr k98)

The Decision and the karr k4 SEAM D paragraph record the state at the time of
the decision: `install` / `diff` / `apply` / `upgrade` all inherited unchanged.
Two of the four have since become thin overrides in `DBIO::PostgreSQL::Deploy`,
each wrapping the inherited method rather than replacing it:

- `install` checks the declared extensions against the server first
  (`_check_extensions_available`, karr k41) and then runs the inherited
  install. The same check runs ahead of the temp deploy, through an override of
  `_deploy_and_introspect_temp`.
- `diff` withholds the `DROP EXTENSION` operations of a restricted deploy
  (addendum 2026-09-28 above, karr k89).

Only `apply` and `upgrade` are still inherited unchanged; `upgrade` goes
through `diff` and so picks up its override. The orchestration stays core's,
so the decision stands — what no longer holds is the word "unchanged" for
`install` and `diff`.

## Addendum 2026-10-29 (karr k151)

The temporary database is an empty database made from `template0`:
`CREATE DATABASE <temp> TEMPLATE template0`, with the encoding and collation
of the live database taken from its `pg_database` row. `template0` is
immutable and not connectable; `template1`, which a plain `CREATE DATABASE`
copies, is server-wide and may hold objects that belong to nobody's schema,
and it is never touched, by the deploy or by a test. The locale clauses depend
on the server and the provider of the live database: `ENCODING`, `LC_COLLATE`
and `LC_CTYPE` always; from PostgreSQL 15 `LOCALE_PROVIDER` and `ICU_LOCALE`;
from 16 `ICU_RULES` where set; from 17 `LOCALE` or `BUILTIN_LOCALE` for the
builtin provider. Each value read from the catalog is written as a quoted
literal.

Directly after the database is created, ahead of the install DDL, the deploy
introspects it without the `pg_schemas` filter and requires it to hold only
the base: the schema `public`, empty, and the extension `plpgsql`. Anything
else stops the deploy; the message names the objects, and the temporary
database is dropped like after any other failure of the temp deploy. The check
runs inside the phase that the clean-up protects (`_deploy_and_introspect_temp`),
not in `_create_temp_db`, so the name of the database is never lost.

The target model is therefore exactly what the schema declares. An extension
the live database holds and the schema does not declare appears in the diff
as not declared, by the existing rule of the 2026-09-28 addendum.
