# ADR 0011 — The session of a pooled connection is reset when its borrow ends: COM_RESET_CONNECTION, SET NAMES, then the connect actions

- Status: accepted
- Date: 2026-10-30
- Tags: async, pool, session, reset, ev-mariadb, builds-on-core-0079
- Karr: k100

## Context

Session state belongs to the borrower that made it. Core ADR 0079 makes the
pool the keeper of that rule: when a borrow, a transaction or a pipeline ends,
the pool asks the owning storage's `_reset_pool_connection($conn)` and hands the
connection on only after the Future it returned is done. The core default fails,
so a transport without a reset of its own gets a new connection for every
borrow.

A MySQL or MariaDB session holds user variables, session variables, temporary
tables, prepared statements, locks taken with `GET_LOCK` and, possibly, an open
transaction. The server can drop all of it on the same connection:
`COM_RESET_CONNECTION`, which EV::MariaDB 0.08 offers as `reset_connection`. A
new connection per borrow would cost a TCP and authentication round trip each
time and give up the pool.

## Decision

`DBIO::MySQL::EV::Storage::_reset_pool_connection` is the transport's answer to
the seam. It runs three steps, one after the other, and resolves after all three:

1. `COM_RESET_CONNECTION` through
   `DBIO::MySQL::EV::QueryExecutor::reset_connection`. The operation is
   exclusive in EV::MariaDB, so the executor counts it like a statement with
   bind values and settles its Future from the idle watcher like every other
   (ADR 0001, karr k51).
2. `SET NAMES <character set> COLLATE <collation>` with the two names the
   connection had when it was new. After the connect actions of its spawn
   (`_setup_pool_connection`) the transport reads `character_set_client` and
   `collation_connection` once per connection, in one statement, and keeps
   them. A name that is not made of letters, digits and underscores is
   refused before it reaches a statement: the spawn fails, the error quotes no
   value. The statement is a query on the pooled handle, so a refusal by the
   server fails the reset like any other step.
3. The connect actions again -- the connection's schema, `on_connect_call`,
   `on_connect_do` -- through core's `_setup_pool_connection`, with the runner
   a new connection uses (`_run_pool_connect_statement`). A reset drops the
   session settings those actions made, so a reset connection is what a new one
   is.

A reset the server refuses, one EV::MariaDB refuses to send, a connect action
that fails and a reset that does not answer within the pool's `reset_timeout`
all fail the Future; the pool retires the connection and the next borrower gets
a newly opened one. A connection that is gone is reported to the pool as a
failed statement reports it (ADR 0010, amendment k55). There is no option to
turn the reset off: a connection handed on unreset would carry the previous
borrower's session.

## Consequences

- The reset costs one round trip per borrow, plus the connect actions of the
  storage. A storage without connect actions sends only the reset.
- The connect actions run as they do on a new connection: one statement after
  the other, blocking the event loop while they run. They are the one part of
  the reset that does.
- Every borrow has the session of the new connection, character set and
  collation included: the second borrow of a connection sees the collation of
  the first, on MySQL and on MariaDB.
- A statement or `LAST_INSERT_ID()` that is wanted after a borrow has to be read
  inside that borrow; `insert_async` reads it on the pinned connection before
  the borrow ends, as before (ADR 0004).
- Prepared statements are dropped by the reset. The executor closes each
  statement it prepares before its Future settles (ADR 0010, amendment k45), so
  none is outstanding when a borrow ends.

## Pinned by

`t/59-session-reset-mock.t` (order, retirement on each failure, the timeout, the
name check) and
`t/58-session-reset-live.t` (character set and collation over two borrows of the
same connection, a user variable, a session variable, a temporary
table, a prepared statement, a `GET_LOCK` lock and an open transaction are gone
at the next borrow of the same connection, on MySQL and on MariaDB).
