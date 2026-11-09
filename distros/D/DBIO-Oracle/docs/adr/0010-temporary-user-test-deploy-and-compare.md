# ADR 0010 — Test-deploy-and-compare in a temporary Oracle user, on connections of its own

- Status: accepted
- Date: 2026-10-25
- Tags: deploy, diff, upgrade, oracle, temp-user, drivers
- Supersedes: [ADR 0002](0002-savepoint-on-live-connection-test-deploy-and-compare.md)

## Context

Core's test-deploy-and-compare migration (core ADR 0007) builds the diff target
by deploying the desired schema into a throwaway location, introspecting it with
the same introspector as the live database, and diffing the two models. ADR 0002
chose, for Oracle, a `SAVEPOINT` on the live connection: deploy, introspect,
`ROLLBACK TO SAVEPOINT`. Its load-bearing invariant was "the rollback fully
restores the live session".

That invariant does not hold on Oracle. Oracle commits implicitly before and after
every DDL statement, and `COMMIT` "also erases all savepoints in the transaction".
Measured live (karr k36, `t/54-deploy-live.t`, section 4, Oracle 23ai Free):

- the first `CREATE TABLE` of the test deploy commits the transaction and erases
  the savepoint; `ROLLBACK TO SAVEPOINT` fails with `ORA-01086`, swallowed by the
  `eval` that guarded it;
- the test deploy stays in the live schema, all of it -- what was meant as a look
  at the desired state is an installation;
- an uncommitted row of the caller is committed, also when the DDL then fails
  (`ORA-00955`); with `AutoCommit` the savepoint is gone before any DDL;
- on a schema that is not empty the test deploy dies at the first existing table.

From 2026-10-06 `diff`, `upgrade` and `_build_target_model` refused with a DBIO
exception (commit 8849e0e), and the card stayed open for a new strategy.

An Oracle schema is a user account. The things ADR 0002 held against a throwaway
user -- it is privileged, it is more than a transaction -- are costs, not
impossibilities: the user that runs the deploy can be given `CREATE USER` and
`DROP USER`, and `DROP USER ... CASCADE` takes everything of the test deploy away
in one statement.

## Decision

`DBIO::Oracle::Deploy` derives from `DBIO::Deploy::Base::TempDatabase` (core ADR
0020) and builds the desired state in a **temporary user**, the counterpart of the
temporary database of PostgreSQL and MySQL:

1. **The right is checked first.** `session_privs` of the connected user must hold
   `CREATE USER` and `DROP USER`. If not, `diff` and `upgrade` throw a DBIO
   exception that names the missing privilege, before anything is created.
2. `CREATE USER DBIO_TMP_<pid>_<n>` -- prefix `DBIO_TMP_`, `n` a counter per
   process, a random password -- with `QUOTA UNLIMITED` on the default tablespace
   of the connected user (`user_users`), and only the grants the install DDL needs:
   `CREATE SESSION`, `TABLE`, `SEQUENCE`, `TRIGGER`, `VIEW`. Indexes and keys come
   with `CREATE TABLE`; nothing in `DBIO::Oracle::DDL` writes a procedure, type or
   synonym.
3. The install DDL runs on a connection **as the temp user**, same DSN as the
   storage's `_dbi_connect_info`; the introspection runs there too, and reads the
   user it is connected as (`SELECT USER FROM DUAL`).
4. `DROP USER ... CASCADE`, on every path -- the base class's `eval` around the
   deploy guarantees it. A drop that fails is not raised: it is warned about with
   the name of the user left on the server and the error, passwords masked
   (`DBIO::Util::mask_connect_secrets`), as in core.
5. **`CREATE USER`, `GRANT` and `DROP USER` never run on the live connection.**
   They commit implicitly. They run on a connection of their own, opened with the
   storage's credentials and `AutoCommit`, for the duration of the call. The
   caller's transaction is not touched: it stays open, and what it holds stays
   uncommitted. The live connection is only read from (the introspection of the
   live schema).

The seams of the base class that are overridden: `_create_temp_db` (privilege
check, user, grants), `_drop_temp_db`, `_temp_connect_info` (the user's login on the
storage's DSN), `_temp_dsn` (unchanged), `temp_db_prefix` (`DBIO_TMP_`).
`_build_target_model` and `_deploy_and_introspect_temp` are core's. `install` and
`apply` are unchanged.

## Consequences

- `diff` and `upgrade` need `CREATE USER` and `DROP USER`. This is the cost ADR 0002
  avoided and now accepts; the refusal names the missing right so it is cheap to
  fix. The standing test database grants them to its user (`maint/k8s/oracle.yaml`).
- The live connection and the caller's transaction are untouched by the test
  deploy -- the property ADR 0002 wanted and could not have.
- A process killed between `CREATE USER` and `DROP USER` leaves a `DBIO_TMP_*`
  user. The prefix is what finds it:
  `SELECT username FROM all_users WHERE username LIKE 'DBIO\_TMP\_%' ESCAPE '\'`;
  `DROP USER <name> CASCADE` removes it.
- The temp user's password exists for the length of the call and is not logged;
  the base class's connection errors and the drop warning go through
  `mask_connect_secrets`.
- Three connections are open during a call: the caller's, the admin connection and
  the temp user's.
- The diff over this path is as good as `DBIO::Oracle::Diff`. Its ALTERs of
  columns write names bare while install quotes them; that is the diff's, not
  this strategy's. (Addendum, karr k37: the diff now creates a table only the
  desired schema has, whole -- columns, keys, sequence and trigger, then its
  indexes, then its foreign keys after every `CREATE TABLE`, quoted as install
  writes them. An upgrade over an empty schema therefore equals `install`
  (`t/55-diff-index-live.t`). The model carries the sequence of a column but
  not its trigger; the diff writes the install's trigger.)
- (Addendum, karr k58, [ADR 0011](0011-schema-qualified-table-names-and-a-temp-user-per-foreign-schema.md):
  a table in another schema, `schema.table`, gets a temporary user of its own,
  `DBIO_TMP_<pid>_<n>_<k>`, per foreign schema; the diff of such a schema is no
  longer refused.)
- The savepoint name `_dbio_deploy` and its collision remark are gone with the
  strategy. Two deploys in one process get two names; two processes differ in the
  pid.

## Related

- [ADR 0002](0002-savepoint-on-live-connection-test-deploy-and-compare.md) --
  superseded
- core ADR 0007 (test-and-compare migration), core ADR 0020 (`TempDatabase`)
- `t/58-deploy-temp-user.t` (offline, handle doubles), `t/54-deploy-live.t` (live,
  including the replay of the old strategy in section 4)
- karr k36 (this), k37 (the diff of a new table, done)
