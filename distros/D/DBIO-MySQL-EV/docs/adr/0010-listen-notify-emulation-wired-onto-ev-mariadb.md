# ADR 0010 — LISTEN/NOTIFY emulation wired onto EV::MariaDB: own statement runner, socket probe, fork guard

- Status: accepted
- Date: 2026-09-26
- Tags: async, listen, notify, emulation, ev-mariadb, fork-safety, builds-on-core-0056, builds-on-dbio-mysql-0008

## Context

Core ADR 0056 (karr core k219, addenda k222 and k227) made LISTEN/NOTIFY a core
async contract: core `DBIO::Storage::Async` owns the public API, the channel
registry, one dedicated listen connection, reconnect with backoff,
re-subscribing and the fork guard; a transport fills the listen seams, and one
without server push may emulate them with a timer (§6). MySQL and MariaDB have
no LISTEN/NOTIFY. The maintainer decided on 2026-09-26 that both MySQL
transports emulate it over a notify table (karr k44 here, dbio-mysql k54).

**dbio-mysql ADR 0008** records the emulation itself and is not restated here:
the table, the per-channel mark / lookback window / dedup, delivery on commit,
no history, retention, explicit deployment, the defaults, and the rule that the
listen connection runs one statement at a time. It ships the sans-I/O class
`DBIO::MySQL::NotifyTable`, which this transport holds, one object per listen
connection. (This repo's own ADR 0008 is the rename; "dbio-mysql ADR 0008"
always means the other one.)

What dbio-mysql ADR 0008 decides for DBI (a DBD's async binding, `ping`,
`AutoInactiveDestroy`) does not carry over to EV::MariaDB. Four facts, each
measured against MariaDB 10.11.19 with EV::MariaDB 0.08 (scratch scripts and
the tests below), shape the EV side:

1. **Exclusive operations.** `prepare`, `execute`, `close_stmt` and `ping` die
   ("another operation is in progress") while any other operation is pending on
   the handle; `query` pipelines only behind other queries.
2. **Prepared statements are not freed with their Perl handle.** The statement
   id is an integer, not an object; without `close_stmt` the server keeps every
   statement until the connection closes (`Prepared_stmt_count` 0 → 30 after 30
   prepare+execute). A poll per second would leave 3600 an hour, against a
   server-wide `max_prepared_stmt_count` (default 16382).
3. **`is_connected` does not track death.** It stays true after the server
   KILLed the session, and even after an operation failed on it with "Server
   has gone away"; only `socket` drops to -1, and only after an operation
   failed. A killed idle connection's socket is readable (EOF) at once.
4. **Fork.** EV::MariaDB records the connecting pid and, in a forked child,
   closes nothing — no `COM_QUIT`, no `shutdown()` — when the child exits or
   drops its copy, even with a statement in flight: the parent's session
   survives. But EV re-arms the default loop in the child automatically, and
   EV::MariaDB's I/O callback does not check the pid. A child that **resumes the
   EV loop** while a statement was in flight at fork time reads the reply on the
   shared socket: the child ran the parent's callback with a garbage result, and
   the parent's next query hung (3 of 3 runs). `finish` in the child goes
   through the same fork-aware cleanup: watchers stopped, client state dropped,
   the parent's session untouched (20 of 20 queries fine afterwards).

## Decision

`DBIO::MySQL::EV::Storage` fills the core listen seams with
`DBIO::MySQL::NotifyTable`, declares `listen` and `notify`, and wires them onto
EV::MariaDB as follows. Nothing of core is overridden and no `@ISA` changes:
the transport holds a NotifyTable, it does not inherit from one. Private
helpers are `_mysql_*`, never `_listen_*` or `_watch_*`.

### 1. A dedicated handle, opened like a pool spawn

`_listen_open` builds a new `EV::MariaDB` handle outside the pool from the
connect info a pool spawn would get at that moment — `_conninfo_provider` when
an AccessBroker is attached, so credentials are fresh — and resolves when its
`on_connect` fires. An `on_error` before that fails the open; one after it goes
to core's `_listen_lost`. The handle carries a NotifyTable built from the
`notify_*` accessors (`inherited` class data seeded from
`DBIO::MySQL::NotifyTable->defaults`), so invalid settings throw before
anything connects. The pool's connect-action replay does not run on it.

### 2. One FIFO statement runner, with `close_stmt`

Every statement of the emulation — a mark, a poll, a cleanup — goes through one
queue per listen handle (`_mysql_listen_statement`). A statement with binds is
`prepare` → `execute` → `close_stmt`; the handle counts as idle only after the
close (it is exclusive too), and only then does the statement's Future settle
and the next one start. A statement without binds is a plain `query`. Nothing
else is ever sent on the handle, so fact 1 can never fire; the mock test's fake
client dies on any overlap and records it. The runner does not reuse
`DBIO::MySQL::EV::QueryExecutor`, which does not close its statements (see
Future architecture work).

### 3. A timer loop that never overlaps

`_listen_watch` arms a one-shot `EV::timer` for the connection's poll
interval. The tick runs one poll, hands what is new to `_listen_dispatch` in
order (checking before each one that the watch is still current, so nothing is
dispatched after an unwatch), runs the retention cleanup when due, and only then
arms the timer again. A tick that finds a statement running or queued — a
subscribe's mark — yields and re-arms. A failed poll, or anything a tick throws,
is `_listen_lost`. A failed cleanup is `_listen_lost` when the probe (§4) says
the connection is dead, and otherwise core's `_listen_error` (core k227): a
listener without `DELETE` must not reconnect in a loop, and a dead connection
must not be polled on as if a housekeeping step had failed. `_listen_unwatch`
drops the watch state and with it the timer; a statement in flight completes on
the handle and finds the watch gone. `_listen_close` is EV::MariaDB's
synchronous `finish`, which tolerates a dead handle and one with a statement in
flight.

### 4. The probe reads the socket, not the server

`_listen_probe` must be synchronous. EV::MariaDB's `ping` is asynchronous and
exclusive, so a synchronous ping would have to run the EV loop from inside
`listen_alive` — re-entering every other callback of the program — and would
die over a statement in flight; `is_connected` is useless (fact 3). The probe:

- a statement in flight: **alive**, without touching the handle — that
  statement reports a dead connection itself (dbio-mysql ADR 0008 §6);
- no socket (`socket` is -1 after a failed operation): **dead**;
- otherwise the idle socket must have **nothing to read**, checked with a
  zero-timeout `select`. A MySQL server never speaks unasked, so a readable idle
  socket is the server hanging up — KILL, restart, `wait_timeout` — and means
  dead.

Not caught: a peer that vanished without closing (a partition). The next poll
meets it, bounded by the TCP stack or a `read_timeout` in the connect info, as
the DBD ping of the `future_io` transport would be.

### 5. A fork guard for a child that resumes the loop

`_listen_open` keeps an `EV::fork` watcher with the connection. EV runs fork
watchers in a child before its loop does anything else; in any process other
than the opener this one drops the poll watch and `finish`es the child's copy
of the handle (fact 4). A child that never runs the loop never fires it and
needs nothing: its exit is already safe. Every callback of the runner and the
loop also returns at once outside the opener process, so the "connection
finished" cancellations `finish` raises in the child reach nothing.

## Consequences

- `transport_capabilities` is `on_connect_replay listen notify`.
  `t/06-thin-transport-structure.t` used to assert "no listen/notify/copy/
  pipeline". For listen/notify that was right about the engine, and is replaced
  because the maintainer decided on emulation; copy and pipeline stay undeclared
  and asserted (ADR 0009).
- The POD of `DBIO::MySQL::EV::Storage` (*LISTEN / NOTIFY (emulated)*) states
  latency, on-commit delivery, no history, the lookback limit, retention, the
  table and its deployment, privileges, knobs, the probe and the fork
  behaviour, and points to dbio-mysql ADR 0008 and the NotifyTable POD rather
  than repeating them.
- The Futures are plain `Future`s settled from EV::MariaDB callbacks, like every
  other Future of this transport: a caller runs the EV loop until they are ready
  (core ADR 0056 addendum k222: where the transport's Futures cannot await, the
  caller's cannot either).
- `EV::MariaDB` is required at 0.08: its fix for a use-after-free after
  `close_stmt` matters for a runner that closes a statement every poll.
- Pinned offline by `t/22-listen-notify-mock.t` (the real core machinery over a
  fake EV::MariaDB that enforces exclusivity and has a real socket; each of the
  decisions above was mutated out once and turned the matching assertions red)
  and live by `t/22-listen-notify-live.t`, including both fork cases. With the
  fork guard removed, the live child-resumes-the-loop case silenced the parent's
  listening in 2 of 2 runs: no delivery, no error, no rebuild.
- Verified live against MariaDB 10.11 only; MySQL 8.0 is still to be run.

## Future architecture work (tracked cross-repo, not here)

Findings on this repo's pool path, reported on karr k44 for their own cards:

- **Pool connections and a child that resumes the loop.** Fact 4 applies to
  every EV::MariaDB handle, the pool's included: a child that runs the EV loop
  while a pooled query was in flight at fork time can read its reply. The pool
  has no fork guard.
- **`DBIO::MySQL::EV::QueryExecutor` leaks prepared statements.** Every bound
  query on a pooled connection (every CRUD op with binds, and `notify`) leaves a
  server-side statement until the connection closes (fact 2).
- **EV::MariaDB upstream:** its I/O and timer callbacks could ignore a forked
  process as its operation entry points already do; that would make both
  guards unnecessary.

## Amendment (2026-09-26, karr k45) — the executor closes its statements too

The second bullet of *Future architecture work* is resolved, and with it the
reason §2 gives for the listen runner not reusing
`DBIO::MySQL::EV::QueryExecutor`. The executor now does for every bound query
what §2 decided for the listen runner: `prepare` → `execute` → `close_stmt`, the
close also after a failed `execute` and after one that croaked, and the Future
settles only once the close has completed. The pool releases a connection when
its query's Future is ready, so it gets the handle back idle (fact 1). The
Future carries the outcome of the `execute`, exactly once: a close that croaks
or reports an error settles it at once and changes nothing about it.
`_run_pool_connect_statement` carried its own copy of prepare + execute and
leaked the same way; it now runs through the executor.

Measured on MySQL 8.0.30 with one pooled session and 150 bound statements (50
pooled, 50 `insert_async`, 50 pinned): without the close, `Com_stmt_close` +0
and the global `Prepared_stmt_count` 0 → 150; with it, `Com_stmt_close` +150
and `Prepared_stmt_count` 0 → 0. Pinned by `t/23-close-stmt-mock.t` and
`t/23-close-stmt-live.t`. The same verification ran `t/22-listen-notify-live.t`
against MySQL 8.0.30 and it passed, which settles the last bullet of
*Consequences* for that file.

The listen runner still keeps its own statement path. §2's reason is gone, but
the runner's FIFO queue is what keeps statements on the listen handle from
overlapping, and the executor has no queue — the pool gives it that guarantee.

## Amendment (2026-09-26, karr k46) — the pool has a fork guard too

The first bullet of *Future architecture work* is resolved. Fact 4 holds for
pooled handles as for the listen handle, and three more facts decided the
shape of the fix (MySQL 8.0.30, EV::MariaDB 0.08, EV 4.37, scratch scripts):

- `finish` in a forked child calls every operation in flight back
  **synchronously** with `(undef, "connection finished")` — a `query` and a
  prepared `execute` alike.
- After `finish` an operation in the child croaks "not connected"; before it,
  EV::MariaDB's own entry-point check croaks "connection not valid after fork".
- `finish` during the connect handshake calls neither `on_connect` nor
  `on_error`.

Without a guard, the child's callback got the parent's rows, and the parent's
statement never completed, nor did the next one on that session.

**One `EV::fork` watcher per pool.** `DBIO::MySQL::EV::Pool::_create_connection`
arms it with the first connection, in the process that creates the
connections, and the watcher holds the pool weakly. In any other process it
`finish`es every handle in the pool's `_connections`. That list is complete
at any moment: core's `DBIO::Storage::PoolBase` keeps checked-out and pinned
connections in it, and a retired one has left it. Iterating it when the watcher
fires therefore covers idle, checked-out and `txn_do_async`-pinned
connections, with no bookkeeping per connection. A watcher per connection
would need a side table, because an `EV::MariaDB` handle is opaque and has
nowhere to keep one. That table would have to be cleaned on every way a
connection leaves the pool: retire, readiness failure, and shutdown in the
owner and in a non-owner. It would also mean N watchers instead of one. The
guard leaves the pool's own state alone, and the watcher goes when the pool
goes.

**The executor's callbacks return at once outside the process that called
`execute`**, as §5 decided for the listen runner. `finish` calls them back.
What they would do next belongs to the parent: `close_stmt`, settling the
Future, the storage's release into the pool (which can hand the connection to
a queued waiter and start its query), the caller's `->then` chain, and a
transaction's ROLLBACK. The Future stays pending in the child. In the owner,
k45's order (prepare, execute, `close_stmt`, then settle) is unchanged.
`on_connect` / `on_error` are not cleared before `finish`, because `finish`
does not call them.

**Neither fork watcher keeps the loop running.** An active `EV::fork`
watcher alone keeps `EV::run` from ever returning; `keepalive(0)` removes
that and it still fires after a fork (both measured). The pool's watcher lives
as long as the pool, so without it every program that runs the loop until its
queries are done would hang: a connected, idle EV::MariaDB handle does not
keep the loop alive, the watcher did (live, through the real pool). §5's listen
watcher gets the same: in the parent an open listen connection always has its
poll timer armed or a statement in flight, so there it never mattered, but in a
child that resumed the loop it outlived the handle it had disarmed and kept the
child's `EV::run` from returning.

A child that uses the inherited pool anyway gets a failed Future from any
`*_async`: "connection not valid after fork" before its loop has run, "not
connected" after. It should build its own storage; core's rule that a forked
child does not operate an inherited pool is unchanged.

Limits that remain:

- A fork made inside a callback returns into the same loop iteration. Another
  handle's I/O event already pending in that iteration then runs before the
  fork watchers, which libev runs at the start of the next one. Only the
  upstream change in the third bullet closes that.
- A child that resumes a synchronous wait of the parent's, such as the
  `until $f->is_ready` loop of `_run_pool_connect_statement`, waits forever:
  the Future it waits on stays pending there.

Nothing of this belongs in core. The guard hangs on the event loop's fork
hook, which core has no view of; `PoolBase`'s refusal to tear down from a
non-owner process is unchanged and still right.

Pinned by `t/24-pool-fork-guard-mock.t` and `t/24-pool-fork-live.t`. The mock
runs a real fork over a fake EV::MariaDB whose completions are EV timers, so
libev itself orders the fork watcher before them. The following mutations were
each made once and each turned the test red:

- the watcher not armed;
- no owner check;
- the pool held strongly;
- idle handles skipped;
- the executor unguarded;
- `keepalive(0)` removed, on either watcher; the loop claims in `t/24` and in
  §13 of `t/22-listen-notify-mock.t` then fail after their bound.

Live, each case holds a pooled statement with `LOCK TABLES` from a second
session, and the parent stays out of the loop while the lock is released.
Without the pool guard, the checked-out query and the pinned transaction both
never completed in the parent. With the pool guard but an unguarded executor,
the child settled both Futures and released the connections into its copy of
the pool.

## Amendment (2026-09-27, karr k54) — a child that takes the pool over

Core karr k233 changed what a forked child's pool is. Its first `acquire`,
`release`, retire or `shutdown` now runs `PoolBase::_verify_pid`, which drops the
parent's connections without closing them, makes the child the pool's owner
(`_owner_pid`), and lets the child spawn connections of its own. The k46
amendment's rule, "in any other process it `finish`es every handle in the
pool's `_connections`", then finished the child's own fresh connection
whenever the child acquired before its loop ran: the watcher fires at the
start of the next loop iteration, typically inside the `get` of that very
call. Finishing during the handshake calls neither `on_connect` nor
`on_error` (k46's third fact), so the child's acquire stayed pending for good.

**The watcher asks who owns the pool.** It finishes `_connections` only while
`_owner_pid` is defined and not `$$` -- the exact condition core's
`_verify_pid` acts on -- and, as before, only in a process other than the one
that armed it. Until the child takes the pool over, the pool's connections are
the parent's and are finished as before; afterwards they are the child's and
keep working. Not the negation of core's `_teardown_belongs_here`: that counts
a pool with no recorded owner as not ours, which is the safe side for closing
and the unsafe one for `finish`, a real close in the process that opened the
handle.

**The takeover leaves a gap, closed by a weak stash.** A handle that was in
flight or pinned at fork time is no longer in `_connections` after the
takeover, but stays alive: the statement's callbacks and the storage's
release closure hold it, and a transaction context holds a pinned one. Its
watchers are still armed on the socket the parent is reading, so with the
ownership check alone the child read the parent's replies again -- k46's bug,
back for the acquire-first order. The pool therefore overrides `_verify_pid`:
in a process that does not own the pool it keeps a weak reference to each
connection it holds, then delegates to core. The watcher finishes whichever
of those are still alive. Weak, because an idle handle nothing else holds
should be freed when core drops it, and EV::MariaDB's destructor is
fork-aware too (it stops the watchers and skips `mysql_close`). Nothing is
finished in `_verify_pid` itself: core also calls it from `shutdown`, and so
from the pool's `DESTROY` at a child's global destruction, where
EV::MariaDB's Perl callbacks must not run. This is a fourth `PoolBase`
override next to the three ADR 0003 names.

With k233 installed, a child that uses the inherited pool no longer gets a
failed Future ("connection not valid after fork" before its loop has run,
"not connected" after), as the k46 amendment said. Its `*_async` calls run on
connections of its own.

**k46's armed-pid check stays, as a second condition.** The watcher is armed
once, with the pool's first connection, so the process that armed it opened
that connection -- a parent that ever opened one armed it already -- and the
pool can hold nothing it inherited there. The watcher object exists only in
that process and the ones forked from it. With k233 the check never changes an
outcome: a process opens a connection only through `acquire`, whose
`_verify_pid` made it the owner. With a core before k233 `_owner_pid` never
changes and nobody calls `_verify_pid`, so the stash stays empty, and the two
checks together are exactly k46's. The ownership check alone would not be: a
child that opens the first connection of a pool its parent built but never
used arms the watcher itself, still is no owner, and would have its own
connection finished mid-connect, its acquire pending for good.

Pinned offline by claims 6-9 of `t/24-pool-fork-guard-mock.t`; 6-8 skip
with a core before k233, 9 runs with any core. Each of these mutations was
made once and turned it red: the ownership check replaced by k46's armed-pid
check alone (claims 6 and 8: the child's connection finished, its query never
completed); the stash disabled (claim 8: both inherited handles unfinished, the
child read the parent's two replies); the stash held strongly (claim 6); the
armed-pid check dropped (claim 9 under a core before k233: the child's own
connection finished, its query never completed -- with k233 the child owns
the pool and claim 9 stays green, as the check is redundant there). There is
no live counterpart yet; `t/24-pool-fork-live.t` covers a child that does not
use the pool.

## Amendment (2026-10-04, karr k55) — the pool retires a connection that is gone

Core's pool retires a connection reported to it through
`PoolBase::_mark_connection_dead` instead of handing it out again (core k230,
core ADR 0047 addendum 2026-09-27), and leaves it to the transport to say which
connection is dead: only the transport can tell a lost session from a statement
error the session survives. Fact 3 holds for pooled handles as for the listen
handle, so `is_connected` cannot be what says it. Three more facts, read from
EV::MariaDB 0.08's XS and not yet measured against a server:

- A connection lost by a statement is reported through **that statement's
  callback** and nowhere else. `on_error` is called for a failed connect, for
  an unusable socket right after connect, and for the error of a secondary
  result set of a multi-statement query -- which may be the connection lost
  while those were read, or a statement error on a session that is still
  there. Nothing watches an idle connection's socket.
- When sending a statement fails, EV::MariaDB drops its client state. From then
  on every operation croaks "not connected", `socket` is -1 and `error_number`
  is 0: no error number survives that case.
- `pending_count` is taken down before a statement's callback runs, so inside
  the callback of the last statement in flight the handle counts as idle.

**The handle decides, with §4's probe.** `DBIO::MySQL::EV::Pool::_mysql_connection_gone`
asks what `_listen_probe` asks: no socket is gone; an operation queued or in
flight (`pending_count`, where the listen runner has its `busy` flag) is not
gone, whatever the socket shows; otherwise a readable idle socket is gone. No
round trip, nothing read, never blocking. It is a method of the pool so that
the borrow-time check of core's `_idle_connection_alive` (karr k58) can be the
same question asked of an idle connection.

**Not the error text, and no list of error numbers.** dbio-mysql's `future_io`
adapter decides by the client library's number on the DBD handle (2006, 2013,
2055 -- its k65). That list is a private of `DBIO::MySQL::Storage::Async`,
which this transport does not inherit and must not (it would bring the
`future_io` base in); and a number is not enough here, since the send-failure
case leaves 0. The socket covers both cases the list names -- the client
library gives its socket up on each -- and the one it cannot.

**Every failed statement is asked about, before the release.**
`DBIO::MySQL::EV::Storage::_mysql_execute` is the one place both dispatches,
pooled and pinned, reach the executor through. It reports the connection when a
statement fails through its callback or EV::MariaDB refuses to dispatch it. The
report is the first callback of the failed Future, so it precedes the pooled
release of `_query_async` and `insert_async`; and it is the only place a
transaction's connection, or `deploy_async`'s, can be reported from, since core
releases those. A statement that succeeds is not asked about.

**`on_error` asks too, it does not assume.** `Pool::_new_connection` wraps the
`on_error` core's readiness wiring passes in: report the connection if it is
gone, then run core's. Unconditional, as dbio-postgresql-ev does for EV::Pg,
would retire a live session for a secondary statement's error (core ADR 0047
addendum k237). The handler holds the pool and the handle weakly.

What this leaves open:

- A session that ended while its connection sat idle is found by the first
  statement sent on it. That call fails; the one after it gets a new
  connection. Handing such a connection out at all is karr k58's to prevent.
- A `close_stmt` that loses the connection after its `execute` succeeded does
  not fail the statement (the k45 amendment), so nothing is asked; the next
  statement on that connection finds it gone.
- A peer that vanished without closing, as in §4.
- `_listen_probe` keeps its own copy of the probe. It differs in one respect:
  it does not ask `select` again after an `EINTR`.

Pinned offline by `t/32-pool-dead-connection-mock.t`: the real pool, storage,
executor and core transaction machinery over a fake EV::MariaDB whose socket is
one end of a real socketpair. Each of these mutations was made once and turned
it red: the report on a failed callback dropped; the report on a refused
dispatch dropped; the `on_error` report dropped; "no socket" answered as not
gone; the `pending_count` guard dropped; the readable check dropped; every
handle answered as gone (the statement-error cases); the report made from the
pooled release callback, after the release, instead of from the failed
statement (the queued caller was handed the dead handle, and a transaction's
connection was not reported at all). Run against a server on 2026-10-05, see the live check at the end of the k58
amendment.

## Amendment (2026-10-04, karr k58) — an idle connection is asked about before it is handed out

Core's pool asks `PoolBase::_idle_connection_alive` about every idle connection
`acquire` is about to hand out, and retires one the seam does not vouch for
(core k241, core ADR 0047 addendum 2026-09-27). The seam must answer without a
round trip. `DBIO::MySQL::EV::Pool` fills it with the question the k55
amendment already asks: an idle connection is vouched for unless
`_mysql_connection_gone`. This closes the first point the k55 amendment left
open: a session the server ended while its connection sat idle costs no caller
a failed call. What ends after the check, or without the server saying so, is
still found by a statement and reported as in the k55 amendment.

**The seam answers and does nothing else.** No report to the pool (core
retires the connection it asked about), no operation on the handle, nothing
sent, nothing read. EV::MariaDB's `ping` is asynchronous and exclusive (§4), so
there is no cheaper round trip to be tempted by.

**An idle connection with an operation in flight is vouched for.** Nothing of
the transport leaves one behind: a statement's Future settles after its last
operation was answered, `close_stmt` included (k45 amendment). A caller that
kept the handle can. Its reply is due on the socket, so the socket says
nothing, and retiring the connection would end that operation; handing it out
is what the pool did before the seam existed.

**The check now runs on every borrow, so a wrong "gone" costs a reconnect per
borrow, not one after a failure.** A session that is still there is taken for
gone exactly when its idle socket has something to read with `pending_count`
at 0. Two cases were read from the sources; the live check below measured
them:

- The further result sets of a statement that returned more than one (a
  `CALL`). EV::MariaDB 0.08 calls back with the first result, `pending_count`
  already taken down, and reads the others afterwards (`deliver_result`, then
  `drain_multi_result`); no accessor shows that state. A connection released
  in that callback and borrowed again before they were read is retired. No
  statement the transport builds returns more than one result set.
- A TLS record that carries no MySQL data (a TLS 1.3 session ticket or key
  update). A server's tickets follow the handshake and precede its answer to
  the authentication on the stream, so the client has read them before the
  connection is ever idle.

Either costs a reconnect, never an error, and loses no statement. A case that
made every idle socket readable would turn the pool into a connect per call
without any error to show for it; the live check below is what rules that
out.

Measured for §4's probe on the listen connection (MariaDB 10.11, no TLS): a
`KILL`ed idle connection's socket is readable at once (fact 3), and the probe
answers alive for a connection that is still there. The seam on pooled
connections is measured below.

**Fork.** Core asks only about connections of the process that owns the pool:
`acquire` runs `_verify_pid` first, which drops the connections a child
inherited (k54 amendment). The seam itself only looks at the socket, so it
could not take a reply from the parent either.

Pinned offline by section 9 of `t/32-pool-dead-connection-mock.t`, through
the pool's `acquire`. Sections 2 to 6 of that file had ended the session on
the idle connection before the call; they end it after the borrow now, which
is the death a statement still finds. Each of these mutations turned section 9
red: the seam answering not alive for everything; without the readable check;
an operation in flight counted as gone; the seam reading what is on the
socket; the seam writing to it.

### Live check (2026-10-05, karr k55 and k58)

`t/32-pool-dead-connection-live.t` ran against MySQL 8.0.30 and MariaDB 11.8.8,
over plain TCP and over TLS 1.3 (`TLS_AES_256_GCM_SHA384`, switched on with
`ssl_cipher=DEFAULT` in the DSN, which `ConnectInfo` passes on to EV::MariaDB;
the session proves it with `Ssl_version` and `Ssl_cipher`). Not reachable: TLS
1.2 (EV::MariaDB has no `tls_version` option; both servers negotiated 1.3) and a
Unix socket (remote servers).

- **k55.** A session `KILL`ed during a statement: exactly that call fails, the
  connection is reported dead and retired, the next call runs on a new
  `CONNECTION_ID`. Same for the prepare/execute path, a queued caller, an
  `insert_async` and a `KILL` in the middle of `txn_do_async` (nothing
  written). The handle after such a failure: `socket` -1, `is_connected` 1,
  `pending_count` 0, `error_number` 2013 (query path) or 2006 (prepare
  path) -- the same on both servers; `is_connected` is useless here, as
  recorded in fact 3. After a duplicate key (1062) or a syntax error (1064, and
  0 on the prepare path) the socket stays open and the session is the same
  afterwards: nothing is reported, nothing retired.
- **k58, session ended while idle.** A `KILL` and a `wait_timeout` of 1 s are
  found by the seam on both servers, both modes: the next call runs without an
  error on a new session, the pool keeps its size, no statement had to fail.
- **k58, healthy idle connection.** 12 calls separated by pauses plus 4 s idle,
  on both servers, plain and TLS: same `CONNECTION_ID`, the idle socket never
  readable, 0 connections opened or retired, the check never said "gone". The
  same for a call chained in the callback of the previous `SELECT`, `INSERT`,
  `insert_async` and of a `CALL` with bind values (20 chains each).
- **k58, the multi-result `CALL`: confirmed, with a narrow reach.** A `CALL`
  sent without bind values answers with its first result set and leaves its
  closing `OK` packet on the socket (`pending_count` 0, readable). MariaDB
  11.8.8, plain TCP: 1 of 20 chained calls took the healthy session for gone in
  some runs and none in others (a race with the packet's arrival); the socket
  held `07 00 00 .. 00 00 00 02 00 00 00`, an `OK` packet. A direct `query` on
  a handle showed it on MySQL 8.0.30 over TLS in the callback, gone one loop
  turn later. Cost: one reconnect, no error. Left open: telling that packet
  from a hang-up is a design question (executor or pool); the live test carries
  it as a TODO. A TLS 1.3 session ticket on an idle connection was not seen.

  *Superseded (2026-10-07, karr k83): the reach was not narrow, and the cost was
  not only a reconnect. See "Measured again" below. Since 2026-10-14 (karr k84,
  "Decided" below) a `CALL` without bind values is read to its end through
  prepare / execute, so it no longer leaves the rest unread on the connection;
  other multi-result statements without bind values still can (karr k75).*

Each live case was turned red once by a mutation: the seam answering "alive" for
everything (the idle `KILL` and `wait_timeout` cases); the report after a failed
statement dropped (the k55 cases); `_mysql_connection_gone` answering "gone" for
every handle (the k55 statement-error cases, the healthy-idle, `CALL` and chained
cases).

### Measured again (2026-10-07, karr k83) — the unread rest costs more than a reconnect

The 2026-10-05 check ran against servers in the same LAN. Against MySQL 8.0.30
and MariaDB 11.8.9 behind a load balancer, where the rest of a `CALL`'s answer
arrives later, two statements above no longer hold for a `CALL` sent without
bind values over plain TCP:

- **"A narrow reach" does not hold.** 11 to 19 of 20 chained calls took the
  healthy session for gone, and so did a call made right after the `CALL` had
  settled, not chained (0 to 13 of 30). With a procedure that sleeps after its
  result set it is every time: both servers send the result set at once and
  the rest when the procedure ends.
- **"Never an error" does not hold.** A statement with bind values that
  follows such a `CALL` on the same connection fails: EV::MariaDB refuses its
  `prepare` while it reads the rest ("another operation is in progress"), and
  the client library refuses it when it is chained in the `CALL`'s callback or
  runs on a transaction's connection ("Commands out of sync; you can't run
  this command now"). On a pooled connection the wrong "gone" hides part of
  that behind a reconnect. A statement without bind values is queued behind
  the rest and runs; a `CALL` with bind values is not affected.

The cause is the one this amendment read from the sources: the callback runs
before `drain_multi_result`, `pending_count` does not count the drain, and no
accessor shows it. EV::MariaDB 0.08 gives no sign that an answer was read to
its end, so neither the executor nor the pool can wait for it without reading
the SQL text, an EV::MariaDB croak text or the bytes on the socket, or sending
a statement of their own. Nothing is decided here: the state is held by
sections e) to g) of `t/32-pool-dead-connection-live.t` as TODO, and what to do
about it is open (karr k75 for the wrong "gone", k84 for the failing statement).

Over TLS 1.3 none of it was seen: the client library (libmariadb 3.4.9) had
read the whole answer before `query` returned, so nothing was left unread when
the Future settled.

### Decided (2026-10-14, karr k84) — a `CALL` without bind values is prepared and executed

The maintainer chose to have the executor read the whole answer of a `CALL`,
so that the statement that follows on the connection runs, pooled and pinned.
`DBIO::MySQL::EV::QueryExecutor` sends a statement without bind values that
begins with `CALL` (leading whitespace and comments allowed, any case) through
`prepare` / `execute` / `close_stmt`, as it does a statement with bind values.
There the client library reads the whole answer before the `execute` callback
runs, and the Future settles after the `close_stmt`: nothing is left unread when
the connection goes back to the pool, so the wrong "gone" of k75 does not
arise from a `CALL` either, and a statement with bind values that follows is not
refused. Rows, insert id and affected count reach the caller as before; the
statement is registered as held like any statement without bind values when it
is issued inside a callback (k48), so a blocking wait there still dies instead of
hanging.

What this does not cover, by design: it reads the SQL text. A multi-statement
text that does not begin with `CALL` (`SET @a = 1; CALL p()`) is still a plain
`query`, and so is any other statement that answers with several result sets.
Neither the upstream signal (EV::MariaDB counting the drain) nor a probe
through the croak text was built.

### Measured again (2026-10-22, karr k75) — the wrong "gone" of a `CALL` is gone

With karr k84 in (a `CALL` without bind values is prepared and executed),
`t/32-pool-dead-connection-live.t` was run against MySQL 8.0.30 and MariaDB
11.8.9 behind the cluster load balancer, plain TCP and TLS 1.3, EV::MariaDB
0.08: five runs per server of the file as k84 left it, one after the other (each runs plain TCP and TLS). In every
section, the borrow-time check answered "gone" for no healthy connection:
`alive_false=0` in all counts, `opened=0`. Section f): for each of the
eight kinds (`SELECT`, `SELECT ?`, `INSERT`, `insert_async`, `CALL` with one
and with two result sets, each without and with bind values) 20 chained calls,
with 40 borrow-time checks per kind, none answered
"gone", on both servers and in both modes; sections e) and g) (the procedure that sleeps 0.4 s after its result
set: the handle is not readable when the `CALL` settles, nor 1.0 s later
without a loop turn) the same. The TODO assertions of k58 had been made hard
by k84; nothing in the file is TODO now.

What was looked for and found: a multi-statement text sent as `query` does not
leave several result sets, because EV::MariaDB connects without
`CLIENT_MULTI_STATEMENTS` and both servers answer with a syntax error at the
second statement (`SELECT 1; SELECT 2`, `SET @a = 1; CALL p()`,
`SELECT 1; CALL p()`; 20 of 20 each; the session stays: section h). So the
sentence of the k84 decision "a multi-statement text that does not begin with
`CALL` is still a plain `query`" is true and harmless: it cannot succeed.

One remainder, measured with a throwaway section, not kept: a session that
`PREPARE`s a `CALL` itself (`PREPARE h FROM 'CALL p()'`) and runs `EXECUTE h` as
a `query` gets the several result sets of a `CALL` again. Over plain TCP, 20
chained calls on a pool of one: the first took the session for gone on both
servers (`alive_false=1`, one reconnect; the prepared statement lived in the
session that was retired, so the further calls had nothing to execute and the
numbers after it say nothing); over TLS none. This is SQL a caller writes
by hand; no statement the transport builds is of that kind. Not built. If it
matters, the executor would have to recognise `EXECUTE` too, which is the
same reading of the SQL text the k84 decision made for `CALL`, with the same
limits. A recommendation, not a decision.

