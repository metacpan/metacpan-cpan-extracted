# ADR 0002 — Retrieve DB2 identity via `SELECT IDENTITY_VAL_LOCAL() FROM sysibm.sysdummy1`

- Status: accepted
- Date: 2026-06-21
- Tags: storage, db2, identity, autoincrement, correctness

## Context

After an `INSERT` into a table with a `GENERATED ALWAYS AS IDENTITY` column,
DBIO must return the generated value (`last_insert_id`). Every engine exposes a
different primitive, and the family records each as its own decision: PostgreSQL
has `RETURNING`; MySQL/MariaDB has session-scoped `LAST_INSERT_ID()` (mysql-async
ADR 0004); MSSQL has `SCOPE_IDENTITY()` and routes GUID keys around the identity
machinery (mssql ADR 0001); Sybase ASE has no scope-safe single-statement form
and falls back to `SELECT MAX(col)` under a writer-storage transaction (sybase
ADR 0004); DuckDB has no identity column at all and uses real sequences (duckdb
ADR 0004).

DB2's scope-safe primitive is `IDENTITY_VAL_LOCAL()`: it returns the most
recently assigned identity value **for the current connection in the current
scope**, so a trigger that inserts into another identity table does not corrupt
it. The idiomatic modern spelling is `VALUES(IDENTITY_VAL_LOCAL())`. DB2 has no
bare `SELECT <expr>` without a table, so a scalar expression is selected against
the one-row catalog table `sysibm.sysdummy1`.

## Decision

`DBIO::DB2::Storage::_dbh_last_insert_id` (`Storage.pm:51-69`) retrieves the
generated identity with:

    SELECT IDENTITY_VAL_LOCAL() FROM sysibm<name_sep>sysdummy1

prepared via `prepare_cached`, executed, and the single column of the single row
returned (`undef` when no row comes back).

- **`SELECT ... FROM sysibm.sysdummy1`, not `VALUES(...)`.** The in-code comment
  (`Storage.pm:57-59`) states the choice: it is "An older equivalent of
  `VALUES(IDENTITY_VAL_LOCAL())`, for compat with ancient DB2 versions. Should
  work on modern DB2's as well." The `SELECT ... FROM sysibm.sysdummy1` spelling
  is the broadly-compatible form; `VALUES(...)` is the newer one DB2 also
  accepts. The driver deliberately emits the older form so it runs across the
  widest version range.
- **The qualifier is built from the server name separator.** `$name_sep` comes
  from `$self->sql_name_sep` (`Storage.pm:54`), which queries
  `SQL_QUALIFIER_NAME_SEPARATOR` from the server (default `.`). The catalog
  reference is therefore `sysibm<name_sep>sysdummy1`, not a hard-coded
  `sysibm.sysdummy1`, so it stays correct on a server that reports a
  non-`.` qualifier separator.

## Rationale

`IDENTITY_VAL_LOCAL()` is the only DB2 primitive that is both single-statement
and **scope-safe**: it is connection-and-scope local, so unlike a
connection-global counter it is not poisoned by a trigger inserting into another
identity table between the application's `INSERT` and its key read. That
scope-safety is the correctness stake — choosing a non-scope-safe form (or
reading `MAX(col)` as Sybase must, sybase ADR 0004) would reintroduce exactly the
trigger-and-interleaving races those siblings document. Selecting the expression
`FROM sysibm.sysdummy1` rather than via `VALUES(...)` is a pure
backward-compatibility choice — the comment pins it to "ancient DB2" support —
and costs nothing on modern servers. Deriving the catalog qualifier from the
server-reported separator rather than hard-coding `.` keeps the statement valid
under DB2 configurations that report a different `SQL_QUALIFIER_NAME_SEPARATOR`.

## Consequences

- Identity retrieval is one cheap statement on the same connection as the
  INSERT, and is scope-safe against triggers — no transaction bracketing is
  needed for the single-row case (contrast sybase ADR 0004, where the
  `SELECT MAX(col)` fallback *must* be wrapped in a writer-storage transaction
  to be correct).
- The statement is `prepare_cached`, so the prepared handle is reused across
  inserts on the connection.
- `IDENTITY_VAL_LOCAL()` returns `NULL` if no identity has been generated on the
  connection in scope; `_dbh_last_insert_id` maps an empty fetch to `undef`.
  Callers must not treat a non-identity insert's `last_insert_id` as meaningful.
- The `sysibm<name_sep>sysdummy1` reference depends on `sql_name_sep` being
  resolved (it lazy-queries the server on first access, `Storage.pm:30-40`); the
  hard-coded `.` fallback covers the common case if the server returns no value.
- Do not "modernise" this to `VALUES(IDENTITY_VAL_LOCAL())` for tidiness — the
  current spelling is a deliberate ancient-DB2 compatibility choice, not an
  accident.

## Related

- sybase ADR 0004 (identity via `SELECT MAX(col)` in a locked txn — the
  no-scope-safe-primitive sibling)
- mssql ADR 0001 (`SCOPE_IDENTITY()` + GUID identity suppression)
- mysql-async ADR 0004 (session-scoped `LAST_INSERT_ID()` on the pinned
  connection)
- duckdb ADR 0004 (no identity column; real sequences + GUID defaults)
