# ADR 0010 — Session reset of a pool connection: DISCARD ALL, then the connect actions from a timer

- Status: accepted
- Date: 2026-10-30
- Tags: async, pool, session, security, ev-pg
- Builds on: core ADR 0079 (the session of a pooled connection, core karr k398)

## Context

A pool connection is lent to one borrow at a time. Before this decision the
session state of a borrow -- `SET`, `SET ROLE`, `set_config(..., false)`, a
temporary table, a prepared statement, a session advisory lock, a `LISTEN` --
stayed on the connection and was there for the next borrower, which may be
another request of the application. Core now resets the session when a borrow
ends and asks the transport for the reset: `_reset_pool_connection($conn)`
answers a Future; done means the connection is as a fresh one, failed or
unanswered within `reset_timeout` means it is retired.

## Decision

`DBIO::PostgreSQL::EV::Storage::_reset_pool_connection` sends `DISCARD ALL` as a
bare statement (`$pg->query`, Simple Query protocol, no binds) on exactly the
connection the pool hands it, and runs the connect actions again
(`_setup_pool_connection`: `search_path`, extension `LOAD`, `on_connect_do`,
`on_connect_call`) once the server has answered. The Future is done after both.

- **One reset path.** A statement, a transaction (after its `COMMIT` or
  `ROLLBACK`, which `DISCARD ALL` needs: it refuses to run inside a transaction
  block), a pipeline and `copy_in` all end in `Pool::release`; the reset is the
  pool's, once per borrow. The transport has no reset of its own beside it and
  no switch to turn it off.
- **The connect actions run from an EV timer, not inside the callback of
  `DISCARD ALL`.** The actions drive the EV loop to the end of each statement
  (`_run_pool_connect_statement`). EV::Pg counts the callback it is delivering
  in `pending_count` and would hand the answer of the first replayed statement
  to that callback, still running; the transport already refuses the wait for
  that reason (`Blocking wait refused`). A zero-second timer lets the callback
  return first.
- **Failure text names the step, never a value.** A failed `DISCARD ALL` and a
  failed replay fail the Future with a message that names the reset and which
  step; the statement text, binds and connection parameters are not in it.
- **`_txn_inner_future` calls `next::method`.** The seam is core's, with a
  default (core k397); this transport adds its refusal for a pool whose every
  connection is held by a callback and keeps core's.

## Consequences

- Session state is the borrow's. State a program wants on every borrow is a
  connect action (`on_connect_do`), which the reset puts back.
- A connection is idle in the pool a few milliseconds after its borrow ended,
  not at that moment: a caller that is queued gets it when the reset is
  answered, and the pool opens another connection if it has room instead of
  waiting. Tests that count idle connections wait for the reset
  (`t/lib/PoolReset.pm`).
- A connection with a statement still in flight cannot be reset (EV::Pg refuses
  the dispatch): its reset fails and the pool retires it.
- The replay is synchronous like the replay at spawn. A borrow costs the
  `DISCARD ALL` round trip, one turn of the loop for the timer, and one round
  trip for each connect statement the program has.
