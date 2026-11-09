# ADR 0007 — Replication status for the Replicated pool: what `is_replicating` and `lag_behind_master` mean on PostgreSQL

- Status: accepted
- Date: 2026-10-10
- Tags: storage, replication, replicated, standby, lag, mysql-divergence

## Context

`DBIO::Replicated::Pool::validate_replicants` (core ADR 0012) decides for every
replicant whether it stays in the read pool, by asking its storage two
questions and nothing else:

1. `is_replicating` — a true value goes on to question 2, a defined false value
   deactivates the replicant, `undef` means "this driver cannot answer" and
   leaves the replicant as it is (manual management).
2. `lag_behind_master` — the replicant is active if the number is at most the
   pool's `maximum_lag` (default 0); `undef` again leaves it as it is.

The core base class answers neither. A PostgreSQL replicant therefore was never
taken out of the pool: not when its primary was gone, not when it had been
promoted to a primary of its own, not when it was minutes behind. Reads kept
going to it.

`dbio-mysql` had answered both for a MySQL/MariaDB replica, from
`SHOW REPLICA STATUS`. PostgreSQL has no such statement. The facts are spread
over `pg_is_in_recovery()`, `pg_stat_wal_receiver`, the WAL position functions
and `pg_last_xact_replay_timestamp()`, and a number of states have no MySQL
counterpart at all. "Do what MySQL does" is not a sufficient specification.

## Decision

`DBIO::PostgreSQL::Storage` answers both methods. One private seam,
`_replication_status_row`, reads the raw facts with a single statement (so the
two methods describe the same moment); the decision is made in Perl. Both
methods are defined for PostgreSQL 10 and later and use no setting of the
server.

### `is_replicating`

| The server is ...                                                    | Answer      |
|----------------------------------------------------------------------|-------------|
| older than PostgreSQL 10                                             | `undef`     |
| not in recovery: a primary, or a standby that has been promoted      | `0`         |
| in recovery, `pg_stat_wal_receiver` has no row (receiver gone, never connected, or none exists) | `0` |
| in recovery, WAL receiver state is not `streaming` (`waiting`, `restarting`, `stopping`) | `0` |
| in recovery, WAL receiver row present, state `streaming`             | `1`         |
| in recovery, WAL receiver row present, state unreadable              | `1`         |

The last row is a role that is not a member of `pg_read_all_stats`: it sees the
row with only `pid` set. The row exists only while the receiver process is
alive *and* has connected to its upstream, so its existence is the statement
"streaming" — reading the missing state as "not streaming" would take every
replicant out of the pool for an ordinary application role.

### `lag_behind_master`

Defined only where `is_replicating` is true; otherwise `undef`. A server that
follows no stream has no lag that means anything, even one that has replayed
everything it ever received.

- **0** when everything the standby has received is replayed
  (`pg_last_wal_replay_lsn() >= pg_last_wal_receive_lsn()`). This is what keeps
  an idle primary from looking like lag: the age of the last replayed
  transaction grows for as long as nothing is written.
- **Otherwise the age of the last replayed transaction**,
  `clock_timestamp() - pg_last_xact_replay_timestamp()`, in **whole seconds**,
  never negative.
- **`undef`** when WAL is outstanding and no transaction has been replayed yet
  (a standby that has just started): there is no timestamp, and no number is
  invented.

## Where PostgreSQL differs from MySQL, and why

| | `dbio-mysql` | `dbio-postgresql` |
|---|---|---|
| Server is not a replica (primary, promoted) | `undef` — left as it is | `0` — taken out |
| Replica whose upstream is gone | threads stopped → `0` | no receiver row → `0` |
| Replication by shipped files only (`restore_command`) | n/a | `0` (no WAL receiver exists) |
| Unit of lag | seconds, `Seconds_Behind_Source` | whole seconds |
| Caught up and the source idle | `0` | `0`, by position comparison |
| Lag not computable | `undef` (NULL column) | `undef` |

- **A server that is not in recovery answers 0, not nothing.** PostgreSQL can
  tell a primary from a standby exactly (`pg_is_in_recovery()`), and "not a
  standby" is a definite fact. Answering `undef` would keep a promoted standby
  in the read pool indefinitely — the very case the pool exists to catch,
  because after a failover the old standby *is* the new primary and is no
  longer a replica. Taking a primary out of the read pool loses nothing: with no
  replicant active the balancer reads from the master. MySQL's `undef` is a
  property of `SHOW REPLICA STATUS` returning no row, not a decision, and is
  not carried over.
- **Whole seconds, with a position comparison for zero.** MySQL's
  `Seconds_Behind_Source` is already integral and is `0` while the SQL thread
  has nothing to apply. PostgreSQL has only the age of the last replayed commit,
  which on an idle primary grows without bound although nothing is missing, so
  the position test must come first. Fractions are cut because a standby under
  steady load is always some milliseconds behind; a fractional answer would
  deactivate every standby under load at the default `maximum_lag` of 0.
- **Measured against what has arrived.** WAL the primary has written but not yet
  sent is not in the number. A silent link shows as lag only once
  `wal_receiver_timeout` ends the receiver and `is_replicating` turns false.
  Measuring at the primary would need a connection to the primary and a
  replication slot or `pg_stat_replication` privileges; the pool holds
  connections to replicants only.
- **A standby fed by `restore_command` alone is reported as not replicating.**
  It runs no WAL receiver, so nothing marks it as connected to a primary. This
  deactivates such a replica rather than leaving it to manual management. It is
  a consequence of the rule that "streaming" is the only replication this
  method can see; there is no switch against it.

## What DBIO::Replicated makes of it

- A replicant that is a promoted or mistakenly listed primary is deactivated;
  reads go to the other replicants and, with none left, to the master.
- A standby that lost its primary, or whose receiver is not in `streaming`, is
  deactivated and reactivated by the next `validate_replicants` after the
  receiver has reconnected.
- A standby further behind than `maximum_lag` whole seconds leaves the pool and
  comes back when it has caught up. With the default `maximum_lag` of 0 any
  standby with an unreplayed backlog is out until it has replayed it.
- A fresh standby with WAL outstanding and nothing replayed yet is left as it
  was until its first commit record is replayed.
- `DBIO::Replicated::Storage::is_replicating` and `lag_behind_master`
  aggregate over the replicants (`max` of the lags) and need no change.

The methods live on `DBIO::PostgreSQL::Storage` only. In a replicated schema
the master and every replicant are that class; the async backend
(`DBIO::PostgreSQL::EV::Storage`, `DBIO::PostgreSQL::Storage::Async`) is
embedded in it and the pool asks the owner synchronously, so neither backend
needs them.

## Consequences

- PostgreSQL replicants are validated like MySQL ones; a replica stays in the
  pool only while it is demonstrably streaming and within `maximum_lag`.
- The two drivers now answer differently for a server that is not a replica.
  Aligning `dbio-mysql` to `0` would change behaviour for existing users and is
  not decided here.
- The diagnosis rests on `pg_stat_wal_receiver`, which is read from a stock
  view and function set readable by PUBLIC; no extra privileges are needed.
  Without `pg_read_all_stats` the receiver state is invisible, so a receiver
  that is connected but momentarily `waiting`, `restarting` or `stopping` still
  counts as streaming.
- After a long quiet period the first new WAL arrives while the last replayed
  transaction is still the old one, so the age reads as the whole quiet period
  until that WAL is applied: a one-off overstatement, not a drift.

## References

- Implementation: `lib/DBIO/PostgreSQL/Storage.pm` (`is_replicating`,
  `lag_behind_master`, `_replication_status_row`)
- Tests: `t/88-replication-status.t` (offline, the decision table),
  `t/89-replication-status-live.t` (a server; with
  `DBIO_TEST_PG_STANDBY_DSN` a primary/standby pair)
- Core: `../dbio/docs/adr/0012-replicated-storage-in-core.md`,
  `DBIO::Replicated::Pool::validate_replicants`
- MySQL counterpart: `../dbio-mysql/lib/DBIO/MySQL/Storage.pm`
  (`is_replicating`, `lag_behind_master`)
- karr k118
