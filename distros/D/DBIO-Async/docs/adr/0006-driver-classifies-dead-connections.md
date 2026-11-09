# ADR 0006 — The driver says when a connection is dead: one seam after a failed query, one before an idle borrow

- Status: accepted
- Date: 2026-09-27
- Tags: async, pool, connection-health, seams, future-io, builds-on-core-0047, backfill
- Origin: backfilled 2026-10-04 (karr k31). Records what karr k26 and k28 put
  in place on 2026-09-27, as the code stands; it decides nothing new.

## Context

The pool cannot see a connection die. Its only per-connection health signal is
the readiness Future, which resolves once when the connection comes up. After
the server drops a session, `release` put the dead connection back on the idle
list and the next `acquire` handed it to a caller whose query failed the same
way; in a pool of one, every later caller's did.

Core ADR 0047 answered this in two addenda of 2026-09-27, both on
`DBIO::Storage::PoolBase`:

- **`_mark_connection_dead($conn)`** (karr core k230): whoever sees a death
  reports it. A checked-out connection is then retired by its one hand-back
  (`release` goes through `_retire_in_use_connection`, so a caller queued for
  the slot gets a fresh connection); an idle one is retired at once. "Report,
  not probe": core does not infer a death, the transport calls the method.
- **`_idle_connection_alive($conn)`** (karr core k241): an optional seam
  `acquire` asks about each idle connection before handing it out. The default
  answers true without looking; false or a throw retires the connection and
  `acquire` goes on to the next one.

Both addenda name dbio-async as a follow-up, and both leave the same question
open on this transport: `future_io` is poll-shaped, it has no connection error
callback, and which errors end a session is knowledge the DBDs disagree on. A
`future_io` driver also writes a storage adapter and never a pool, while core
asks the **pool** the borrow-time question.

## Decision

`DBIO::Async::Storage` carries two optional driver seams. Each has a default
that leaves the behaviour from before it, and neither may block or send
anything to the server: they are answered from the handle's local state, the
error itself, or a non-blocking read of what the server already sent.

### `_conn_error_is_fatal($conn, $error, ...)` — after a failed query (karr k26)

1. **The driver classifies.** The seam answers whether the query that just
   failed on `$conn` left the connection dead. It is handed the connection the
   query ran on and the Future's failure: the message, then any category and
   details. The default answers false, so a driver that does not fill it keeps
   every connection in the pool, as before.

2. **Asked for every failed query, and only for those.** `_query_async` and
   `_query_async_pinned` (through `_dispatch_pinned`) register the callback
   `_mark_dead_on_fail` builds with `on_fail` on the query Future. The dispatch
   goes through core's `_seam_future`, so a driver's `_await_query_result` that
   dies or returns no Future is a failed Future and is asked about like any
   other failure. A query that succeeds is never asked about. Neither is a
   cancelled one: a cancel is no failure and says nothing about the session
   (a statement cancelled in flight has its connection retired on a path of
   its own, without the seam).

3. **Reported before the release.** In `_query_async` the callback from
   `_mark_dead_on_fail` is registered ahead of the one from `_release_on_ready`,
   and a `Future` runs its callbacks in registration order. On a true answer
   the pool is told (`_mark_connection_dead`) while the connection is still
   checked out, so the release that follows retires it instead of idling it or
   handing it to a queued caller.

4. **A throw of the seam counts as dead, and is reported.** `_mark_if_fatal`,
   the body of the callback, calls the seam inside an `eval`. A throw marks the
   connection dead and goes to the pool's `on_error` (a `warn` should that die
   too); a failing report to the pool is warned about as well. Nothing leaves
   the callback: the query Future keeps its own error, and the connection is
   still handed back exactly once.

5. **A transaction's connection goes back through core's finalizer.**
   `_query_async_pinned` registers the report and no release: the pinned
   connection's one hand-back belongs to its holder. For a transaction that is
   core's `_finalize_txn_async` in `DBIO::Storage::Async`, whose release comes
   after the `ROLLBACK`; that release retires a connection reported dead.

6. **Nothing is retried.** The failed query's caller sees that query's error.

### `_idle_connection_alive($conn)` — before an idle borrow (karr k28)

7. **The pool delegates core's seam to the adapter.**
   `DBIO::Async::Pool` overrides `_idle_connection_alive` and passes the
   question to the owning storage's method of the same name, the way it already
   delegates `_create_connection`, `_shutdown_connection` and readiness. The
   storage's default answers true without looking. Same name, same contract as
   core's: a driver following core's instruction to override
   `_idle_connection_alive` does so on the class it writes.

8. **The pool catches nothing.** A throw from the storage reaches core's
   `acquire`, which counts it as not vouching, passes it to the pool's
   `on_error` and retires the connection — the rule core applies to every pool.
   With the storage reference lost (the DESTROY path) the pool answers true
   without asking, as `_await_conn_ready` short-circuits there.

9. **No helper for the check.** The base makes a zero-timeout readability
   check of its own in the listen watch loop (ADR 0005) and does not offer it
   for this seam: what a readable idle socket means differs by engine and is
   the driver's to decide.

## Rationale

- **The knowledge is the driver's.** Only the driver can tell a
  connection-level error from a statement error the session survives — for
  DBD::Pg, libpq has given up the socket; for DBD::mysql and DBD::MariaDB, the
  error code on the handle is a lost connection. This base ships no DB-specific
  code (ADR 0004), so it asks instead of guessing.
- **One hand-back stays one.** The report does not add a second release; it
  changes what the existing one does (core ADR 0047, "retire on release, not on
  report"). That is why the pinned path reports and leaves the hand-back to the
  transaction finalizer.
- **The order is what makes the report count.** A connection marked after its
  release would already be idle — or already with a queued caller, whose query
  then fails too.
- **A callback that dies would skip the release.** The classification runs
  inside the completion of the query Future, where a die escapes into whatever
  completed it and skips every callback registered after it. So the seam's
  throw is contained, and read as "dead" because nothing vouches for the
  connection — the rule core applies to a throwing `_idle_connection_alive`.
- **Named subs, not closures.** `_mark_dead_on_fail` builds its callback the
  way `_release_on_ready` does, closing over the connection alone and not over
  the SQL and the caller's bind arrayref (core ADR 0044).
- **The two seams are siblings.** One reports a death after a query failed on
  the connection; the other narrows the window before a query is sent on a
  connection that died while idle. Neither closes it alone: a connection can
  die between the check and its first statement, and that statement's failure
  is then reported through `_conn_error_is_fatal`.

## Consequences

- A driver that fills neither seam behaves as before both: nothing is reported,
  and idle connections are handed out unchecked.
- The pinned statement queue reads the report: when a statement fails and the
  pool has been told its connection is dead, the statements already waiting
  behind it are failed without being sent. A statement issued once the failure
  is known is refused too (addendum 2026-10-09, karr k47; first decided the
  other way, to be dispatched and meet the dead handle); core's `ROLLBACK` is
  one.
- The listen connection is asked about too, when a drain query on it fails
  through `_query_async_pinned`. The pool does not hold that connection, so the
  report changes nothing there; healing a dead listen connection is core's.
- `_shutdown_pool_connection` is called for every connection retired this way,
  once, and may be handed one that is already dead.
- Both names are listed in `t/13-seam-ownership.t` and `t/01-storage-api.t`.
  `t/22-dead-connection-retire.t` pins the report-and-release path — the order
  with a queued caller, the default, the arguments, the transaction, the
  throwing seam, the paths that never ask, the connection the pool does not
  hold — and `t/23-idle-connection-alive.t` the delegation, the default, the
  throw and when the seam is asked, both against the real `DBIO::Async::Pool`
  over core's own pool code.

## Addendum 2026-10-09 -- nothing more is sent on a connection reported dead (karr k47)

The decision stands; one consequence is reversed. Karr k26 let a statement
issued once the failure was known -- from the failed statement's callbacks, or
core's `ROLLBACK` -- be dispatched and left the dead handle to refuse it. The
maintainer decided (2026-10-09) to refuse it in the queue instead.

- `_queue_start`, the one place the pinned queue dispatches, asks the pool
  (`_connection_is_dead`) before it does. A connection reported dead gets
  nothing: the statement's Future fails `not sent: this connection was reported
  dead ...`, and the seam is not reached. This is the rule the queue already
  followed after a cancel in flight (`abandoned`), now for a reported death too.
- A refused statement is no query for `_conn_error_is_fatal`: the seam is asked
  once for the failure that killed the connection, not again for a statement
  issued after it. Core no longer issues a `ROLLBACK` there (core k274, see
  below), so the transaction fails with the error that killed the connection.
- Why: a connection reported dead is retired at its hand-back, so any further
  statement is futile, and on a protocol out of step it may hang instead of
  failing.
- Not done here, and since done in core (dbio 70362dee3, core k274): a
  connection reported dead gets no `ROLLBACK` from `_txn_rollback_and_fail`;
  the caller gets the original error. A cancel of the Future of `txn_do_async`
  retires the connection the same way.
- Pinned by `t/24` section 3 and `t/22` section 4.
