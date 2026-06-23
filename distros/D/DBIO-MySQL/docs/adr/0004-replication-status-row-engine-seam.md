# ADR 0004 — `_replication_status_row` is the single replication-state seam

- Status: accepted
- Date: 2026-06-20
- Tags: storage, replication, mariadb, seam, backfill

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
