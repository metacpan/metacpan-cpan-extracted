# ADR 0078 — An async caller waits for a bounded time, and never for its own transaction

- Status: accepted (coordinator decision of 2026-10-30, karr k397, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-30
- Tags: async, pool, timeout, transaction, pipeline, connect-options, relates-0030, relates-0049

## Context

An async storage hands its work to a pool of connections
(`DBIO::Storage::PoolBase`). A caller that finds every connection busy is
queued and holds its SQL and binds until a connection is free. A transaction
(`txn_do_async`) and a pipeline hold one connection of the pool for as long as
they run, and their coderef may return a Future.

## Decision

1. **A wait for a pool connection is bounded in time.** `acquire_timeout`
   (seconds, default 30, `0` for no timeout) covers the caller's whole wait:
   the time in the queue and the time a new connection takes to come up. At
   expiry the caller's waiter is withdrawn from the queue and fails with
   `no pool connection within N seconds`; a connection that becomes free
   later goes to the next queued caller or to the idle list.
2. **The queue may be bounded in size.** `max_waiters` (a positive integer,
   default no limit): with that many callers queued, `acquire` fails at once
   with `pool exhausted: N callers waiting` and queues nothing.
3. **A transaction may be bounded in time.** `txn_timeout` (seconds, default
   none), counted from the call of `txn_do_async`. At expiry the transaction
   is cancelled through the cancel path (ROLLBACK best-effort, connection
   retired) and the returned Future fails with
   `transaction timed out after N seconds`.
4. **The timer is one seam of the async storage.** `_delay($seconds)`
   returns a Future that resolves from the event loop; its default is
   `_listen_delay`, which every transport implements.
5. **A transaction or pipeline never waits for a Future of its own pool's
   queue.** The pool records the Futures it queued the storage's calls for
   and the aggregates made of them. The default of `_txn_inner_future` and of
   `_pipeline_inner_future` asks the pool about the Future the coderef
   returned; a Future that waits in the queue of the same pool has its waiter
   withdrawn and failed, so its statement never runs, and the bracket fails
   at once with `the coderef returned a Future queued for this
   transaction's own pool; call it on the context` (pipeline:
   `pipeline's`). A transaction ends with ROLLBACK, a pipeline retires its
   connection.
6. **The async options are a declared list.** The core names `pool_size`,
   `acquire_timeout`, `max_waiters` and `txn_timeout`
   (`DBIO::Storage::_core_async_option_names`); a backend adds its own names
   with the class method `async_option_names`. With an `async` mode set, the
   sync storage keeps every declared name out of its own `DBI->connect` and
   hands it to the backend, which reads it with `async_option`; any other
   name is an unknown attribute. Without a mode the DBD decides.

## Rationale

A bound turns a stuck pool into a failure the caller can handle. A Future
queued behind its own transaction cannot settle before that transaction ends,
so refusing it names the mistake where it is made. One list of option names
lets a backend take options without core knowing them.

## Consequences

- Every transport gets the timeout through `_listen_delay`; a transport
  without it gives `acquire_timeout => 0`.
- Error messages name the option and the number, never SQL, binds or values.
- A Future the caller derives with `->then` from a storage Future is not
  known to the pool; the transaction's own context is the place for its
  statements.
