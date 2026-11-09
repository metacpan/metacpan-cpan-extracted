# ADR 0008 — The connect key `schema` on PostgreSQL: one schema class in several namespaces

- Status: accepted
- Date: 2026-10-13
- Tags: tenant, connect-info, search-path, deploy, extensions, namespace

## Context

Core ADR 0065 defines one generic connect key, `schema`: the namespace a
connection works in and into which a deploy over it installs. Core owns the
word and the contract; a driver gives it meaning by overriding the storage seam
`_set_connection_schema`, which runs on every new connection, sync and async
pool, ahead of the application's connect actions.

A multi-tenant application keeps the same tables once per tenant, each set in
a PostgreSQL schema of its own, and wants one DBIO schema class for all of
them.

Three facts of the server shape the decision:

- an unqualified name is resolved, and an unqualified object created, along
  the session's `search_path`;
- `SET search_path` accepts a schema that does not exist and passes over it:
  an unqualified `CREATE TABLE` then lands in the first schema of the path
  that does exist, without an error or a notice;
- an extension belongs to the database, and `CREATE EXTENSION` without
  `WITH SCHEMA` puts its objects into the first schema of the `search_path`.

Maintainer decision 2026-10-12 (karr k128, from the discussion of k103).

## Decision

1. **The namespace comes from the connection; the class names none.** A
   schema class that is to serve several namespaces declares its tables
   without a schema and writes its SQL (view definitions, defaults,
   `pg_extra_ddl`) without one. `connect(..., { schema => 'tenant_a' })` makes
   `tenant_a` the namespace of that schema object. Nothing is written into
   class data: the same class is connected for `tenant_a` and `tenant_b` at
   once.

2. **The search path** of every connection of such a schema is the namespace,
   then the schemas of the extensions `pg_extensions` declares, each once, in
   the order of the extensions — `public` for an extension that names no
   schema, and `public` when no extension is declared. It is one rule,
   `connection_search_path` in `lib/DBIO/PostgreSQL/Util.pm`.
   `_set_connection_schema` in `lib/DBIO/PostgreSQL/Storage.pm` writes it as
   one `SET search_path TO ...` through `_do_query`, so the sync connection and
   each pool connection get it. `pg_search_path` is not read on such a
   connection.

3. **Extensions are never installed into the namespace.** On a connection
   with a namespace, `install_ddl` in `lib/DBIO/PostgreSQL/DDL.pm` writes
   every `CREATE EXTENSION` with `WITH SCHEMA` — the declared schema, `public`
   otherwise — and refuses an extension whose schema is the namespace. A
   `CREATE EXTENSION` written by a diff of such a connection names its schema
   too (`install_schema` on the target model's extension entry, set by
   `_mark_extension_schemas` in `lib/DBIO/PostgreSQL/Deploy.pm`, read by
   `as_sql` in `lib/DBIO/PostgreSQL/Diff/Extension.pm`).

4. **The install script carries itself.** Behind the extensions it creates
   the namespace (`CREATE SCHEMA IF NOT EXISTS`), sets the search path, writes
   the objects, and closes with the same path. It therefore installs into the
   namespace whichever connection runs it: the one it was written for, the
   connection to the temporary database of a diff — which no connect action
   runs on — or `psql -f`. A namespace that is not there is created; nothing
   is left to land in `public`.

5. **The deploy of the instance is restricted to the namespace.**
   `_schema_filter` in `lib/DBIO/PostgreSQL/Deploy.pm` answers the namespace
   of the schema object's connection, ahead of the class's `pg_schemas`. The
   diff compares that namespace alone and, being restricted, drops no
   extension.

6. **Schema classes that manage several namespaces stay with `pg_schemas` and
   `pg_schema_class`** and are connected without the key. On a connection
   with a namespace the install refuses what names a namespace of its own: a
   `pg_schema_class` binding, a result class with a `pg_schema`, a table name
   that carries its schema. The entries of `pg_schemas` refuse nothing; a
   schema an extension names still has to be declared there.

## Consequences

- One schema class is installed into and queried in any number of
  namespaces, sync and over `future_io`, with no per-tenant class and no
  `on_connect_do` of the application's own.
- A function body or a view definition that names a schema is the same text
  in every namespace; the class writes them without one.
- The schema an extension is installed in is on the search path of every
  tenant connection. Objects somebody else puts into that schema are visible
  to unqualified names behind the namespace.
- An `on_connect_do` that sets `search_path` runs after the seam and
  replaces the path.
- The install role needs the right to create a schema in the database unless
  the namespace is `public`.
- Enums, composite types and functions are declared through a PgSchema class
  bound by name (`pg_schema_class`), which a connection with a namespace
  refuses; an enum column declared with `extra => { list => [...] }` gets its
  type in the namespace.

## Future architecture work (tracked cross-repo, not here)

- The native `ev` backend (`dbio-postgresql-ev`) and the extension layers
  (`dbio-postgresql-age`, `dbio-postgresql-postgis`) take the key through
  core's seam on their own boards.

## Addendum 2026-10-25 (karr k131)

Maintainer decision on the follow-up of k128:

- **The refusals stay.** The install of a connection with the key still
  refuses a `pg_schema_class` binding, a result class with a `pg_schema`, a
  table name that carries its schema, and an extension whose schema is the
  namespace. Decision 6 is confirmed as written.
- **The diff creates the schema of an extension.** The deploy of such a
  connection sees the namespace alone (decision 5), so a diff before the first
  install cannot know whether the schema an extension is declared in exists.
  A `CREATE EXTENSION ... WITH SCHEMA` of a schema other than `public` is
  therefore written behind `CREATE SCHEMA IF NOT EXISTS` of the same schema
  (`create_schema` on the extension entry, set by `_mark_extension_schemas`,
  read by `as_sql` in `Diff/Extension.pm`). An extension whose control file
  fixes its schema is written without the clause as before: the server
  creates that schema itself.
- **`CREATE EXTENSION` carries a schema** with or without the key (karr k141);
  the one exception is the fixed control-file schema just named.

## Addendum 2026-10-25, (d) (karr k131)

- **A schema is looked up before it is created.** `CREATE SCHEMA` checks
  `CREATE` on the database before it reads `IF NOT EXISTS`, so a role that may
  use a namespace an administrator made for it could not install. On a
  connection with the key the install script and the diff create the
  namespace, the schema of a declared extension and the other `pg_schemas`
  entries only where `pg_catalog.pg_namespace` lacks them: a `DO` block
  (`Util::create_schema_if_missing`) with the lookup and a plain `CREATE
  SCHEMA`. A DO block because the script is written without a server and runs
  in the temporary database of a diff as well; one piece for the deploy
  splitter, as the `pg_settings` blocks are. In the diff the namespace is
  marked `create_if_missing` in the target model (`Deploy::_mark_namespace`,
  read by `Diff/Schema.pm`) and the extension entry keeps `create_schema`.
  A connection without the key writes `CREATE SCHEMA IF NOT EXISTS` as before.
  Not measured: the missing privilege itself; the test database has a
  superuser only (`t/189` offline, `t/190` live show the form and that it
  runs).

## Addendum 2026-10-25, (a) (karr k131)

- **Types and functions of a tenant, as they are.** No new interface
  (no `pg_namespace_class`). Decision 6 stands: a `pg_schema_class` binding is
  refused on a connection with the key. Found, not built: the declarations
  that need no binding are the enum column with `extra => { list => [...] }`
  and raw SQL in `pg_extra_ddl`; both are written without a schema, so the
  `search_path` of the script puts them into the namespace, one set per
  tenant (`t/191` offline, `t/192` live; they were green before this change).
  `pg_enum`, `pg_type` and `pg_function` exist on `PgSchema` only, which is
  reached through the binding, so there is no schema-level declaration of
  enums, composite types or functions for such a connection. A refusal of a
  `pg_function` that names a schema therefore has no path to guard and is not
  built; the SQL of a function, header and body, is written as given and not
  read.
