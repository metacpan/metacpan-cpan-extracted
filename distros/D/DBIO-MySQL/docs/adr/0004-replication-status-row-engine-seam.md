# ADR 0004 — `_replication_status_row` is the single replication-state seam

- Status: accepted; the placement of the verb amended 2026-08-05 (see below)
- Date: 2026-06-20
- Tags: storage, replication, mariadb, seam, backfill

## Amendment (2026-08-05, karr #30) — the verb is a server fact, and the row keys are not identical

The seam itself stands: `_replication_status_row` is still the single place a
`SHOW ... STATUS` is issued, and `is_replicating` / `lag_behind_master` still
contain no SQL. Two things below are wrong and are now fixed.

1. **The override was on the wrong class.** Putting the modern verb in
   `DBIO::MySQL::Storage::MariaDB` keyed it to the *DBD driver*, not to the
   server. `DBD::MariaDB` reaches MySQL servers (that is how this dist's live
   suite reaches MySQL) and `DBD::mysql` reaches MariaDB ones, and a MariaDB
   server under `load_components('MySQL')` never reaches the subclass at all —
   this storage has no `_rebless`. Both products renamed the statement, at
   different releases, so the verb now comes from
   `DBIO::MySQL::Storage::_replication_status_statement`, decided from
   `_is_mariadb` plus the server version: `SHOW REPLICA STATUS` from MySQL
   8.0.22 and from MariaDB 10.5.1, `SHOW SLAVE STATUS` below either boundary.
   MySQL 8.4 **removed** the legacy spelling, so the parent's unconditional
   `SHOW SLAVE STATUS` was a syntax error there.

2. **"The row keys are identical" is false on MySQL.** MySQL renamed the
   *output* with the statement — "only the terminology used for the statement
   and its output has changed" (Reference Manual 15.7.7.36) — so
   `SHOW REPLICA STATUS` there answers with `Replica_IO_Running`,
   `Replica_SQL_Running` and `Seconds_Behind_Source`. MariaDB's alias keeps the
   `Slave_` / `Seconds_Behind_Master` names. So the subclass's own override made
   `is_replicating` read a `Slave_IO_Running` that a MySQL 8.0.22+ replica no
   longer returns: the statement succeeded and the answer was silently wrong.
   `is_replicating` and `lag_behind_master` now read both spellings, and answer
   `undef` — core's "this driver cannot say" — for a row carrying neither.

The `// SHOW SLAVE STATUS` fallback is gone with the override. It was never the
protection it looked like: with `RaiseError` on, an unknown statement throws
rather than returning `undef`, so the second arm ran only for a server that
answered the *modern* statement with no row, i.e. one that is not a replica.
The version gate replaces it. Pinned offline by `t/30-server-dialect.t`.

## Context

`DBIO::Replicated::Storage` (core) asks a storage `is_replicating` and
`lag_behind_master`. On MySQL/MariaDB both answers come from one row of a
`SHOW ... STATUS` statement — `Slave_IO_Running`, `Slave_SQL_Running`,
`Seconds_Behind_Master`. But the statement name was renamed: MySQL and older
MariaDB use `SHOW SLAVE STATUS`; MariaDB 10.5+ renamed it to
`SHOW REPLICA STATUS` (the legacy form still works for a while, then is
removed).

Originally `is_replicating` and `lag_behind_master` each issued their own
`SHOW SLAVE STATUS` directly, in both the MySQL class and the MariaDB
subclass — four hard-coded statements, two of them in the subclass purely to
swap the verb (karr #5).

## Decision

Introduce one protected seam, `_replication_status_row`, that returns the
status row as a hashref (or `undef` when the server is not a replica).
Everything that needs replication state goes through it; nothing issues
`SHOW ... STATUS` directly.

- `DBIO::MySQL::Storage::_replication_status_row` runs the legacy
  `SHOW SLAVE STATUS` (the MySQL default).
- `DBIO::MySQL::Storage::MariaDB::_replication_status_row` tries the modern
  `SHOW REPLICA STATUS` first and falls back to `SHOW SLAVE STATUS`
  (`... // ...`), covering MariaDB across the rename boundary.
- `is_replicating` and `lag_behind_master` are written once against the row
  shape and read it via the seam; they contain no SQL.

## Rationale

The statement *verb* is the only thing that differs between MySQL and MariaDB
here — the row keys are identical. Putting the verb behind a one-method seam
means the two consumers (`is_replicating`, `lag_behind_master`) are written
once and the engine difference is a single override, matching the ADR 0001
rule that MariaDB carries only deltas. It also gives one obvious place to
adapt if MariaDB later drops the legacy statement, or if a deployment needs to
read status from a side channel (a monitoring view) rather than `SHOW`.

## Consequences

- New replication-aware behaviour (e.g. reading GTID position, channel-aware
  status) consumes `_replication_status_row`; it does not add another
  `SHOW ... STATUS`.
- The MariaDB fallback is intentional and load-bearing — removing the
  `// SHOW SLAVE STATUS` branch breaks pre-10.5 MariaDB. Keep both arms until
  the supported MariaDB floor is past the rename.
- This seam is driver-local; the `is_replicating` / `lag_behind_master`
  *contract* is owned by core's `DBIO::Replicated::Storage`. Changing those
  method names or return contracts is a core concern, not this ADR's.
