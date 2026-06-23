# ADR 0002 — Test-deploy-and-compare via SAVEPOINT on the live connection, not a throwaway database

- Status: accepted
- Date: 2026-06-22
- Tags: deploy, diff, oracle, savepoint, drivers

## Context

Core's test-deploy-and-compare migration (core ADR 0007) builds the diff target
by deploying the desired schema into a throwaway location, introspecting it with
the *same* introspector used on the live database, and diffing the two
normalised models. Core ADR 0006 makes deploy a native per-driver concern, and
core ships `DBIO::Deploy::Base::TempDatabase` as the shared orchestration for
engines whose disposable copy is a **real, separate database**: create temp db →
deploy + introspect → always drop. The family splits along what each engine can
cheaply throw away — PostgreSQL (pg ADR 0002) and Sybase ASE (sybase ADR 0005)
materialise a whole scratch *database*; SQLite (sqlite ADR 0002) uses an
in-memory `:memory:` one; Firebird (firebird ADR 0007) creates and safely drops
a temp database via a throw-away handle; DB2 (db2 ADR 0001) uses a temp
*schema*.

Oracle fits none of those. Oracle has no in-memory database, `CREATE DATABASE`
is a heavyweight DBA operation (not something an application connection issues to
build a scratch copy), and an Oracle "schema" is a user account — creating and
dropping users per deploy is both privileged and expensive. What Oracle *does*
have, cheaply and inside the existing session, is the transaction: a `SAVEPOINT`
can mark a point, arbitrary DDL/DML can run, and `ROLLBACK TO SAVEPOINT` undoes
it. (Note Oracle DDL normally auto-commits — see Consequences.)

## Decision

`DBIO::Oracle::Deploy` extends `DBIO::Deploy::Base` (**not** `TempDatabase`) and
supplies the three class-name hooks (`_ddl_class`, `_introspect_class`,
`_diff_class`, `Deploy.pm:55-57`) plus an Oracle-specific `_build_target_model`
that runs the test deploy **inside a SAVEPOINT on the live connection**
(`Deploy.pm:70-89`):

1. `SAVEPOINT _dbio_deploy` on the live `$dbh`.
2. Inside an `eval`: execute the install DDL, then introspect the result via
   `_new_introspect($dbh)->model` — the same `DBIO::Oracle::Introspect` used on
   the live database, so both sides of the diff are normalised identically.
3. `ROLLBACK TO SAVEPOINT _dbio_deploy` **unconditionally** (in its own `eval`),
   even when the deploy or introspect step threw — the live connection state
   must be restored either way.
4. Re-raise the captured error if the build itself failed.

`install` / `diff` / `apply` / `upgrade` and the dbh/schema accessors are
inherited unchanged from `DBIO::Deploy::Base`. `_build_target_model` is the only
Oracle-specific piece of the orchestration.

## Rationale

Oracle comparing with itself is always correct (core ADR 0007's premise), and a
SAVEPOINT is the only disposable scratch that an ordinary connected handle can
create and discard against Oracle without DBA privilege or a second database.
The temp-*database* path (`TempDatabase`, core ADR 0020) is impractical here for
the same reasons PostgreSQL's path is *unavailable*: no `CREATE DATABASE` from an
app session, no `:memory:`. DB2 reached for a temp schema because DB2 schemas are
cheap namespaces; Oracle schemas are user accounts, so that path is closed too —
leaving the transaction-scoped savepoint as the honest minimum.

The unconditional rollback-in-`eval` (`Deploy.pm:84-85`) is deliberate: the test
deploy mutates the *live* connection, so a half-applied deploy must never persist
or leak into the user's session, and the restore must run even on the failure
path before the original error is re-raised.

## Consequences

- A migration needs only ordinary transactional rights on the live connection —
  no `CREATE DATABASE`, no per-deploy user/schema creation, unlike the
  PostgreSQL/Sybase/Firebird temp-*database* drivers and DB2's temp-*schema*
  driver. This is the lightest operational footprint of the server engines.
- Oracle does **not** sit under `DBIO::Deploy::Base::TempDatabase`, so the
  temp-database DSN-shape seam of core ADR 0020 (`_temp_dsn`) does not apply —
  there is no scratch DSN to derive.
- **The strategy assumes the test-deploy DDL is transactional/rollback-able
  within the savepoint.** Oracle DDL ordinarily issues an implicit commit, which
  would defeat the savepoint; this path is correct only where the deploy runs in
  a context that keeps the DDL inside the transaction (or the caller accepts the
  introspect-then-restore contract). Any change to how the install DDL is
  executed must preserve the "rollback fully restores the live session"
  guarantee — that is the load-bearing invariant of this ADR.
- The savepoint name `_dbio_deploy` is fixed; a nested DBIO deploy on the same
  connection would collide. Not a supported scenario today.

## Related

- core ADR 0006 (native deploy owns SQL generation)
- core ADR 0007 (native introspect + diff test-and-compare — the migration this
  implements)
- core ADR 0020 (temp-database DSN-shape seam — the `TempDatabase` hook Oracle
  does **not** use)
- db2 ADR 0001 (temp-SCHEMA throwaway — sibling that also extends
  `Deploy::Base` directly rather than `TempDatabase`)
- pg ADR 0002 (temp-DATABASE), sqlite ADR 0002 (`:memory:`), sybase ADR 0005
  (real temp database), firebird ADR 0007 (temp-DB drop safety) — the throwaway
  variants Oracle cannot use
