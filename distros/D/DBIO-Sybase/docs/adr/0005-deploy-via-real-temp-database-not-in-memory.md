# ADR 0005 — Deploy compares against a real temp database, not an in-memory one

- Status: accepted
- Date: 2026-06-20
- Tags: deploy, diff, ase, temp-database

## Context

DBIO's deploy/upgrade triad (`Deploy` → `DDL` + `Introspect` + `Diff`) uses a
**test-deploy-and-compare** strategy: render the desired schema, materialise it
somewhere disposable, introspect both the live DB and the disposable copy with
the *same* introspector, and diff the two normalised models. Drivers that have a
throwaway in-memory database (SQLite's `:memory:`) materialise the desired
schema there for free.

Sybase ASE has **no in-memory database**. The disposable copy has to be a real
database on the same server.

`DBIO::Sybase::Deploy` therefore subclasses the core
`DBIO::Deploy::Base::TempDatabase` and supplies the engine-specific glue:
`_create_temp_db` issues `CREATE DATABASE _dbio_tmp_<pid>_<time>`,
`_drop_temp_db` issues `DROP DATABASE`, and the core base re-points the
`database=`/`dbname=` portion of the DSN at the temp DB for the deploy +
introspect pass.

## Decision

Materialise the desired-state schema in a uniquely-named real temp database
(`CREATE DATABASE`/`DROP DATABASE`) rather than seeking an in-memory shortcut,
and express it by plugging into the core `Deploy::Base::TempDatabase` contract
rather than re-implementing the orchestration locally.

## Rationale

- An in-memory DB simply does not exist on ASE; a real temp database is the only
  way to introspect the *rendered* schema with the identical code path used on
  the live DB, which is the whole point of test-deploy-and-compare (both sides
  go through `DBIO::Sybase::Introspect`, so renderer/introspector skew cannot
  hide a diff).
- The orchestration (introspect-live, deploy-to-temp, introspect-temp, diff,
  drop) is engine-agnostic and now lives in core (adopted from dbio core
  #12–16). Keeping only the two T-SQL glue methods here avoids re-deriving
  ~160 lines of deploy/diff/apply/upgrade plumbing that core already owns.

## Consequences

- `CREATE DATABASE` cannot run inside a transaction on ASE, so `_create_temp_db`
  forces `AutoCommit` on (committing any open work first) for that one call.
  This is intrinsic to ASE and must not be "tidied" into the surrounding
  transaction.
- Deploy requires a connection with rights to `CREATE`/`DROP DATABASE` — a
  heavier privilege than ordinary DML. This is a real operational constraint of
  the Sybase deploy path, unlike the file-based drivers.
- The temp DB name is `<temp_db_prefix><pid>_<time>`; collisions are avoided by
  pid+timestamp. A crashed run can leak a `_dbio_tmp_*` database that must be
  dropped manually.
- `install` still falls back to the SQL::Translator path
  (`storage->deploy`) because the native `DDL` path is not yet the default for
  fresh installs; the temp-database machinery is exercised by `diff`/`upgrade`.
