# Callbacks handed to EV::Pg, the pool, idle connections — DBIO::PostgreSQL::EV

## The house pattern

Every callback this class gives EV::Pg to settle one of its Futures:

1. returns at once when `$$` is not the pid that issued the statement
   (forked child, `Pool` "Fork safety");
2. marks the connection first: `my $delivering = DBIO::PostgreSQL::EV::Future->_delivering($pg);`
   — `Future::await` and the pool's connect-action replay
   (`_run_pool_connect_statement`) die with *"Blocking wait refused"* inside
   such a callback while the connection has more results due, because EV::Pg
   would hand the next result to the running callback and spin. The same mark
   is how the pool knows a connection is held by a running callback
   (`Pool::_pg_held_by_callbacks`): a callback without it is one a blocking
   call queued for the pool hangs in;
3. on the pooled path, settles the Future **before** releasing the connection,
   through `_pg_settle_and_release` (the release happens even when settling
   dies; the die is rethrown after);
4. reports a dead connection before the release (`_pg_report_if_dead`), so the
   pool retires it. A connection the pool cannot use again is retired, never
   idled — also one that is open: a COPY whose stream could not be ended
   leaves libpq in the COPY, and `copy_in` reports it itself
   (`_mark_connection_dead`);
5. talks to the pool the connection was **acquired from**, never to
   `$self->pool` (core's rule for every async transport). `pool` builds
   lazily in the slot `disconnect` empties, so it is asked once, where work
   begins (`my $pool = $self->pool; $pool->acquire->then(...)`), and `$pool`
   is handed on: `_dispatch_query($pg, $sql, $bind, $pool)`,
   `_dispatch_notify(..., $pool)`, `_pg_settle_and_release($pool, $pg, ...)`,
   `_pg_report_if_dead($pool, $pg)`. Settling runs the caller's callbacks,
   and one that disconnects the storage leaves the release with an empty
   slot — EV::Pg does not call the callback it is delivering to again from
   `finish`. A disconnect from outside does not show it: there `finish`
   calls the callbacks while the old pool is still in the slot. `t/75`
   (mock) and `t/76` (live) hold it.

EV::Pg can call a callback **again** after its operation has ended: the
pipeline sync after an error result, a COPY whose `put_copy_end` returned -1 —
EV::Pg hands the -1 on and keeps the callback queued. A late call returns
without touching the Future or the pool. Where the callback releases the
connection, "ended" is a flag of its own (`copy_in`'s `$phase`), never
`$f->is_ready`: a cancelled Future is ready, and its connection still has to go
back.

EV::Pg can also **drop** a callback without calling it: the one it is
delivering to, when a call made inside it loses the connection in its flush
(`put_copy_data`, `put_copy_end`) or finishes it. That call still returns its
value — `put_copy_end` answers 1 on a connection libpq had already dropped. A
callback that would wait for another firing after such a call asks
`is_connected` first.

EV::Pg croaks at dispatch *before* queueing the callback (*"not connected"*,
*"another command is already in progress"*): fail and release right there,
once. Create the callback in a named dispatch sub, not in the `->then`
closure, so it does not pin `$bind` for the query's flight.

## Blocking inside a callback

A blocking call on the **storage** inside such a callback needs another
connection. Queued while callbacks on the call stack hold every connection of
the pool (`then` on a pooled statement or a `txn_do` coderef with
`pool_size => 1`; N nested ones with N), it is refused: `Future::await` takes
the caller out of the pool's queue (`_withdraw_waiter`) and **fails** it, so
the refused call never runs. `Pool::_new_waiter` marks the queued caller's
Future, `Future::new` carries the mark down every `then`. A refusal that leaves
its caller queued and pending wedges the pool — the next release hands the
connection to a chain nobody holds. That holds for **every** way `await` gives
up while the Future hangs off a queued caller — the callback-held refusal, the
"more result(s) due" refusal, the loop running dry — through the one
`_withdraw_queued`; only a statement already on the wire completes after a
refusal. Not covered: a `txn_do` coderef that *returns* the Future of a queued
storage call (needs a core seam). A connection that can still come back (idle,
connecting, statement in flight, held with no callback of its own running) must
not be refused: `t/56-blocking-on-empty-pool-mock.t`.

**A spawn that is running holds its slot like a callback does.** A caller is
queued when the pool has no *room*, which is not "at its size": core opens a
connection synchronously inside `acquire` and the spawn keeps its slot from
before the conninfo provider is asked (`PoolBase`'s `_spawning`), so a call
made from inside it — the AccessBroker's answer, or a callback the loop runs
while the broker's client fetches — is queued behind it, in a pool of one with
no connection open. The connection is handed out only after the spawn has
returned, and the spawn is below that call on the stack: a blocking wait there
hangs (any watcher keeping the loop alive, the LISTEN connection for one) or
dies of a dry loop. `Pool::_pg_opening` counts those slots, and with them the
connection a connect statement is being replayed on — counted by then, held by
no callback, marked by `Future->_replaying($conn)` in
`_run_pool_connect_statement`. `_pg_held_by_callbacks` takes both for held, and
the refusal names how many the pool is opening. A spawn alone is no reason to
refuse: with another connection busy with a statement in flight the call waits
for that one. Not seen: whatever else runs the loop inside a spawn, not through
the connect statement seam. `t/77` (mock) and `t/78` (live) hold it.

## Idle connections — the look before a borrow

EV::Pg's `on_error` tells the pool a connection died — from its read watcher,
so only while the EV loop runs. A program that only blocks runs it for its own
calls and no longer. `Pool::_idle_connection_alive` (core's borrow-time seam)
covers the idle connection nobody read of; core retires what it does not vouch
for, quietly, and takes the next or spawns.

**Dead only where that is certain**, in this order:

1. `is_connected` false → dead (a caller's `finish`, `on_error` replaced);
2. `pending_count` → vouched for, no look: retiring would run that
   statement's callback inside `acquire`;
3. the server's end of the socket is closed → dead: `_pg_peer_closed`, one
   `poll` with a zero timeout for `POLLRDHUP` (plus `POLLHUP`/`POLLERR`/
   `POLLNVAL`), which the kernel reports with the backend's last words still
   unread in front of the close.

**Readable is never dead** — a live idle session is sent notifications,
notices, parameter changes, TLS tickets; `POLLIN` is not asked for. The seam
sends nothing, reads nothing, runs no callback and never the loop (no
`EV::run`, not even `NOWAIT`: no foreign watcher may run inside `acquire`).
EV::Pg has no method that makes libpq read outside the loop — `PQconsumeInput`
is called from `io_read_cb` alone (Pg.xs) — so there is no "let libpq read,
then ask libpq" as on `future_io`.

`POLLRDHUP` has no name in Perl and its value is the platform's: `_pg_rdhup`
measures the bit once per process on a socket pair, and answers 0 where `poll`
does not behave so — the pool then vouches as before. Not seen: a session
ending after the look, or in the milliseconds between a backend's last message
and its exit; a peer gone without closing. TLS is not measured (the look is at
the TCP connection underneath).

A handle handed **straight from a release to a queued caller** is never asked
about; there the dispatch's croak and `_pg_report_if_dead` are still the only
report (`t/41` d, `t/32`). A fake `EV::Pg` answers `is_connected`,
`pending_count` and `socket` (`-1`: nothing to look at, vouched for). `t/57`
holds every branch on real sockets, `t/63` against a server.
