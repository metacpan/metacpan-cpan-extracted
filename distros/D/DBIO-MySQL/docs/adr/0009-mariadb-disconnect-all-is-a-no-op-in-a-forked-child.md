# ADR 0009 — `DBD::MariaDB::dr::disconnect_all` is a no-op in a forked child

- Status: accepted
- Date: 2026-10-24
- Tags: mariadb, fork, dbd, storage, future_io, workaround

## Context

DBI's `END` block calls `DBI->disconnect_all` at every normal exit. DBD::MariaDB
(measured with 1.24, DBI 1.651) carries that out on every connection it lists
without looking at `InactiveDestroy`, `AutoInactiveDestroy` or the pid of the
handle. In a forked child that means every connection the child inherited: the
close sends `COM_QUIT` down the socket parent and child share, and the server
ends the parent's session. A handle destroyed under `AutoInactiveDestroy` stays
listed after it is freed, so the same call may instead die in a DBI
`active kids (-1) < 0` panic, which turns the child's exit status into 22.
DBD::mysql has no such `disconnect_all` and is not affected. The effect was
measured on MySQL 8.0.30 and MariaDB 11.8.8 (karr k56); the cause is read from
the DBD's sources in `docs/upstream/dbd-mariadb-disconnect-all-after-fork.md`,
a report that is drafted and **not sent**.

It hits every DBD::MariaDB connection of the process, not only this dist's. For
the emulated LISTEN of ADR 0008 it meant a rebuilt listen connection and
notifications lost in the gap (karr k54), and a pool connection that failed on
its next statement.

DBD::MariaDB has no per-handle lever: neither a flag nor the stored pid reaches
`disconnect_all`. What is left is not letting the call run in the child.

## Decision

`DBIO::MySQL::MariaDBForkGuard->install` wraps
`DBD::MariaDB::dr::disconnect_all` once. The wrapper compares `$$` with the pid
that installed the guard: in that process it hands over to the original,
unchanged; in any other it returns without doing anything.

- **Process-wide, foreign handles included.** Closing a connection inherited
  across a fork is never right, so there is nothing to distinguish (maintainer's
  decision 2026-10-24).
- **Installed by the connect paths, not by a class hierarchy.** After a connect
  whose handle reports driver `MariaDB`: `DBIO::MySQL::Storage`'s
  `_run_connection_actions` (the sync storage, which also serves
  `load_components('MySQL')` over a `dbi:MariaDB:` DSN) and
  `DBIO::MySQL::Storage::Async`'s `_mysql_connect` (the `future_io` pool and
  listen connections). `DBIO::MySQL::Storage::MariaDB` is not the common point:
  a `dbi:MariaDB:` DSN under `load_components('MySQL')` never reaches it. The
  guard is never installed for a DBD::mysql handle and DBD::MariaDB is not
  loaded for it. Idempotent; no `@ISA`, `use base` or `connection()` change,
  so the rule on composition seams is not touched.
- **The owner is the pid at installation.** The first DBIO connect over
  DBD::MariaDB must therefore happen before the fork for the child to carry the
  wrap, which is the order in every real use: the child inherits connections
  and so a connect came first.

## Consequences

- A forked child exits cleanly (status 0, no panic) and its parent's pool,
  listen and raw DBD::MariaDB connections live. `t/63-future-io-listen-live.t`
  g) lost its TODO and passes on MySQL 8.0.30 and MariaDB 11.8.8, through
  DBD::MariaDB and DBD::mysql.
- A connection a child opens **itself** is not closed by `disconnect_all` either
  (the child is not the owner). Its `DESTROY` and an explicit `disconnect` still
  close it; only the exit-time sweep is gone.
- An explicit `DBI->disconnect_all` in the child is a no-op too. DBI documents
  that `InactiveDestroy` does not disable an explicit `disconnect`; this is the
  deliberate difference, argued above.
- It replaces a sub in a package we do not own. If DBD::MariaDB ever fixes the
  defect upstream the wrap becomes redundant, not wrong; remove it then.
- Pinned offline, against a MySQL wire-protocol stub (`t/lib/MySQLProtocolStub.pm`:
  handshake, OK to everything, hang-up on `COM_QUIT`), by
  `t/149-mariadb-fork-disconnect-all.t` (the four variants of the report,
  the installing process still closing, idempotence),
  `t/150-mariadb-fork-guard-sync-connect.t` and
  `t/151-mariadb-fork-guard-async-connect.t` (installed by each connect path,
  and not before one). Each of the three connect-path facts needs a process of
  its own, hence two files.
