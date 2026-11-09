# ADR 0011 — `schema.table` is a schema qualifier; the diff builds a temporary user per foreign schema

- Status: accepted
- Date: 2026-10-25
- Tags: ddl, deploy, diff, introspect, oracle, schema, temp-user
- Extends: [ADR 0010](0010-temporary-user-test-deploy-and-compare.md)

## Context

Until k58 the driver refused a table name with a dot (a source `table('other.t')`),
because the server would have been handed a table nobody can reach. On Oracle a
schema is a user, and `CREATE TABLE "other"."t"` is ordinary SQL for a user with
the `ANY` privileges, so the dot has a meaning the driver can honour (maintainer
decision 2026-10-25, karr k58). ADR 0010 builds the desired state of a diff in
one temporary user, which cannot hold a table that belongs to another user.

## Decision

1. **A dot in a table name is a schema qualifier.** `schema.table` is the table
   `table` in the schema `schema`: the text before the first dot is the schema, the
   rest the table, each quoted exactly as spelled (`"OWNX"."item"`; a user made
   unquoted is upper case). Sequence, trigger, index and foreign keys of the table
   are qualified with the same schema. This holds for DDL, Introspect (the
   `schemas` attribute names the tables `schema.table`) and Diff. A name with an
   empty half (`.t`, `x.`) is still refused. Literal SQL (`\'name'`) is the user's
   own and is not read as a qualifier. A table of the connected user's own schema
   whose name holds a dot (made by literal SQL) therefore reads as a qualified one.
2. **The user must exist; the driver creates none.** `install` looks every schema
   up in `all_users` (by the exact name) before the first statement and refuses a
   missing one, naming the user, the table and, where the upper-case spelling
   exists, that hint. Writing into another user's schema takes the `ANY`
   privileges of the connected user; the driver grants none.
3. **`diff` and `upgrade` get a temporary user for each foreign schema.** The main
   temporary user of ADR 0010 is `DBIO_TMP_<pid>_<n>`; each foreign schema (in the
   order of the names) gets `DBIO_TMP_<pid>_<n>_<k>`. The install DDL is written
   with the temporary users as qualifiers (`DBIO::Oracle::Identifier::%SCHEMA_MAP`)
   and every statement runs on the connection of the user whose schema it writes
   to, so the temporary users need none of the `ANY` privileges. A temporary user
   sees only its own tables, so each is introspected on its own connection and the
   models are merged under the live keys, the temporary names written back as the
   real schemas (table keys, `schema`, foreign keys, sequences). A schema named like
   the connected user is its own schema: the main temporary user stands for it and
   its tables are bare in the model, as the live introspection reads them. The live
   schema is introspected with the declared foreign schemas. Every temporary user is
   dropped on every path; a drop that fails is warned about with that user's name and
   does not stop the others.
4. **Foreign keys across schemas write no `GRANT`.** A key from a table of one user
   to a table of another needs `REFERENCES` on the parent for the owner of the
   child. The install DDL and `apply` leave that to the owner of the parent; when
   it is missing, the server's error reaches the caller. Only among its own
   temporary users the deploy issues `GRANT REFERENCES ON parent TO child_user` (by
   the owner of the parent, before the key), because the desired state could not
   be built otherwise.

## Consequences

- A schema with `schema.table` sources can be diffed and upgraded; the second diff
  is empty (`t/84-ddl-cross-schema-live.t`, `t/58-deploy-temp-user.t` section 8).
- The diff of such a schema needs the same `CREATE USER`/`DROP USER` as before,
  and reads the foreign schemas through `all_*` as far as the connected user may
  see them.
- The temporary `REFERENCES` grant means the diff does not tell whether the live
  owner has granted the right; `apply` of a foreign key the live owner has not
  allowed fails at the server.
- A `DBIO_TMP_*` user left by a killed process is found by the prefix, as in ADR 0010;
  there can now be several per run.

## Related

- [ADR 0010](0010-temporary-user-test-deploy-and-compare.md)
- `t/85-ddl-cross-schema.t` (offline), `t/84-ddl-cross-schema-live.t` (live, a second
  user via `DBIO_TEST_ORA_EXTRAUSER_*`), conformance case `ddl-qualified-source-name`
- karr k58
