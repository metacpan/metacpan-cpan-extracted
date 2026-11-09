# ADR 0005 — The Future::IO listen seams live here once: one watch loop, one drain seam, one mode switch

- Status: accepted
- Date: 2026-09-26
- Tags: async, listen, notify, future-io, seams, watch-loop, builds-on-core-0056, extends-0004

## Context

Core ADR 0056 (karr core k219) made LISTEN/NOTIFY part of the core async
contract. Core `DBIO::Storage::Async` owns the public surface and the
transport-neutral machinery — the channel registry, one dedicated listen
connection, serialised channel operations, self-healing with backoff, the fork
guard — and a transport fills nine *listen seams* that croak until provided
(ADR 0056 §5). §6 leaves the shape of watching to the transport: socket-driven
or timer-driven, core ships no poll mode.

Two `future_io` drivers are queued against those seams: PostgreSQL
(dbio-postgresql k77) watches `pg_socket` and drains `pg_notifies`; MySQL
(dbio-mysql k54) has no server push and emulates with a notify table and timer
polling. Three of the nine seams do not depend on the database at all on this
transport:

- `_listen_delay` — the backoff timer. On `future_io` it is
  `Future::IO->sleep`, whatever the database.
- `_listen_watch` / `_listen_unwatch` — a loop of *wait, drain, dispatch, wait
  again*. Only the drain is DB-specific; the wait is `Future::IO` either way.
- `_notify_send` — one statement on a pooled connection with the payload as a
  bind value. Only the statement is DB-specific.

Written per driver, each would reimplement the same loop and meet the same
traps on its own: a callback that unlistens or reconnects in the middle of a
batch, a cancelled poll whose callback still runs, a derived Future nobody
holds, a connection kept alive by its own watcher. And each would call
`Future::IO` itself, which ADR 0004's isolation principle keeps in this dist.

## Decision

`DBIO::Async::Storage` implements `_listen_delay`, `_listen_watch`,
`_listen_unwatch` and `_notify_send` **once**, for every `future_io` driver. A
driver supplies two new seams, the five connection seams core already names,
and its capability declaration.

1. **`_listen_delay($seconds)`** returns `Future::IO->sleep($seconds)` as it
   is: pending on return, resolved by whichever loop drives `Future::IO`,
   cancellable. It is not re-wrapped into `future_class` — every `Future::IO`
   implementation returns a `Future` subclass, and a wrapper would only stand
   between core's `cancel` and the timer.

2. **One drain seam, `_listen_drain($conn)`**, croaking until provided. It
   returns the pending notifications as an arrayref of
   `[$channel, $payload, $sender_pid]` tuples in arrival order — empty when
   nothing is pending — **or a Future of such an arrayref**, because an
   emulating transport's drain is a query and a query on this transport is a
   Future (`_query_async_pinned($conn, ...)` on the listen connection). It dies,
   or its Future fails, when the connection is dead. In socket mode that
   includes end of file: a readable socket that yields nothing because the peer
   closed it must die, or the loop polls a socket that stays readable forever.

3. **One mode switch, `_listen_poll_interval`**, asked once per watch. The
   base answers `undef`: **socket-driven**. A positive number of seconds:
   **timer-driven** at that interval. Anything else fails the arm — core
   reports it on every attempt — rather than letting a zero interval spin.

   - *Socket-driven:* poll the connection's socket through `_await_readable`
     (on the dup `_conn_poll_fh` caches), drain, dispatch, poll again. The
     first drain runs **one loop tick after** the watch starts, before the
     first poll: libpq can hold notifications it read during the subscribe
     round trip, and they never make the socket readable again. It is
     deliberately not run inside `_listen_watch` — core's `_listen_op_arm` marks
     the connection watched only after `_listen_watch` returns, so a callback
     dispatched from inside it that unlistens the last channel or calls
     `listen_reconnect` would close the connection without unwatching it.
     After every poll the loop confirms readability with a zero-timeout
     `select` on the dup before draining. `Future::IO`'s built-in
     implementation does not select while it has only read pollers and no
     timer: it presumes every poll ready and clears `O_NONBLOCK` while the
     callbacks run. A drain on a quiet socket in that round would block in
     `recv` — and with it the query the program was really waiting for —
     until a notification arrived.
   - *Timer-driven:* `_listen_delay($interval)`, drain, dispatch, wait again.
     The loop never calls `_conn_fileno` or `_conn_poll_fh`. Latency is the
     poll interval and a notification becomes visible when its writer commits;
     a driver declaring `listen` in this mode states both in its POD (core ADR
     0056 §6).

4. **Errors end the loop and go to core.** A failed poll or timer, a drain that
   dies or fails, a malformed drain result, any throw in the iteration: the
   loop stops and calls `_listen_lost($conn, $error)`. Healing is core's.

5. **Unwatch really stops it.** The watch state lives on the connection
   hashref under the reserved key `_dbio_async_listen_watch`, next to
   `_dbio_async_poll_fh`, and is the watch's identity. `_listen_unwatch` takes
   it off the connection **first** and then cancels the Future it awaited
   (poll, timer or drain) — cancelling runs that Future's callback
   synchronously, and the callback must find the watch already gone. The loop
   checks the identity before every dispatch and before re-arming, so a
   channel callback that unlistens the last channel or calls
   `listen_reconnect` mid-batch — both unwatch synchronously — ends the loop
   right there: the rest of the batch is not dispatched, nothing is re-armed.
   The state records its pid; a poll a forked child inherits and fires does
   nothing, so the child never reads the parent's socket.

6. **Nothing the loop registers keeps anything alive.** Its callbacks hold the
   storage, the connection and the state weakly. The only strong path is
   connection → state → pending Future. The state must hold a driver's pending
   drain Future: a `Future` holds its derived Futures only weakly, so an
   unheld one is lost with its rows. A reconnect opens a new connection
   hashref (core `_listen_open`), so the old one and the dup cached on it are
   freed — a dup kept alive would keep the old socket open at the OS level.

7. **`_notify_send`** runs `_notify_sql($channel, $payload)` — a new seam,
   croaking until provided, answering `($sql, \@bind)` in the `?` dialect —
   through `_query_async`, which shapes the placeholders and releases the
   pooled connection. The payload travels only in the binds (ADR 0017 §3, as
   restated by core ADR 0056).

**Deliberately not here.** `transport_capabilities` stays
`('on_connect_replay')`: this base cannot drain anything, and ADR 0056 §2
gates by the declared name, so `listen` / `notify` are the concrete driver's
to declare. `_listen_open`, `_listen_close`, `_listen_subscribe`,
`_listen_unsubscribe` and `_listen_probe` stay core's croaking seams,
inherited unchanged — connecting, quoting a channel and probing are
DB-specific. The emulation itself — notify table, high-water mark, drain
query — is the driver's; the loop only paces it.

## Rationale

- **The traps are the transport's, not the database's.** Every item in points
  5 and 6, and both mode-specific details in point 3, come from `Future` and
  `Future::IO` semantics. Solving them once is the same argument core ADR 0056
  makes for the machinery above, one layer down.
- **One seam per concern.** The drain is the only thing the loop cannot know;
  making it the single driver hook for watching keeps the PostgreSQL and MySQL
  implementations to one method each. Allowing it to return a Future is what
  lets the emulation fit the same loop without a second one.
- **ADR 0004 isolation.** `Future::IO` is still touched only here — the new
  calls are `_listen_delay`'s `sleep` and the loop's use of `_await_readable`.
  A driver never names `Future::IO`.
- **Loud over silent.** A malformed drain result or an invalid interval is
  reported through core's `on_listen_error` rather than degraded around.

## Consequences

- A `future_io` driver offering LISTEN/NOTIFY supplies `_listen_drain`,
  `_notify_sql`, `_listen_open`, `_listen_close`, `_listen_subscribe`,
  `_listen_unsubscribe` and `_listen_probe`, optionally
  `_listen_poll_interval`, and declares `listen` / `notify` in its own
  `transport_capabilities`.
- The listen connection must be a hashref, as `_conn_poll_fh` already
  requires.
- The loop's private steps are named `_watch_*`, not `_listen_*`: they share an
  inheritance chain with core's private `_listen_*` helpers, and a same-named
  method appearing in core later would be silently shadowed. `t/13` lists them
  as introduced here and unknown to core, which is the tripwire.
- Each socket wake costs one zero-timeout `select`.
- **Not covered, surfaced for the drivers:** a subscribe or unsubscribe round
  trip on the watched connection can move pending notifications into the
  client library's buffer while leaving the socket quiet. The loop drains at
  watch start and on readability only, so those wait for the next
  notification. Whether the driver drains after its own `LISTEN` / `UNLISTEN`
  or this dist grows a re-drain entry point is for dbio-postgresql k77 to
  decide with a real libpq in hand.
- **Also surfaced:** with `future_class` `'Future'`, a Future core builds with
  `->new` and settles later cannot be `->get`-ed while it is pending — plain
  `Future` has no `await`, whichever `Future::IO` implementation is loaded.
  `listen(...)->get` works when `_listen_open` resolves synchronously, as a
  blocking DBI connect does; a driver whose open is truly asynchronous makes
  that call croak ("is not yet complete and does not provide ->await").
- Pinned by `t/19-listen-seams.t`, which drives these seams under core's real
  machinery through `listen` / `unlisten` / `notify` / `listen_reconnect`, with
  a fake driver over a real pipe and `Future::IO`'s built-in implementation.

## Future architecture work (tracked cross-repo, not here)

- **dbio-postgresql k77** — the socket-driven driver: `_listen_drain` over
  `pg_notifies` (dying on a closed connection), `_notify_sql` as
  `SELECT pg_notify(?, ?)`, the five connection seams, the capabilities; and
  the buffered-after-subscribe question above.
- **dbio-mysql k54** — the timer-driven emulation: `_listen_poll_interval`, a
  drain query on the listen connection, `_notify_sql` as an `INSERT` with
  bound values, and the POD statement of latency and on-commit delivery.

## Addendum 2026-09-26 — core k222 watches from the call; the first drain stays one tick later (karr k23)

Core k222 changed the step that calls `_listen_watch` (core ADR 0056 addendum
2026-09-26, decision 2). `_listen_op_arm` now sets `watching` **before** it
calls `_listen_watch`, not after it returns. Afterwards it checks whether its
attempt is still current: a callback or a death report during the watch that
ended or replaced the attempt owns the state, and the arm stops there. A
watch that threw on a still-current attempt resets `watching` and fails the
attempt as before.

That removes the reason §3 gives for running the socket-mode first drain one
loop tick after the watch starts. A callback dispatched from inside
`_listen_watch` that unlistens the last channel or calls `listen_reconnect`
now finds the connection marked watched, and core unwatches it before closing
it. Core's addendum says this dist may now drain inside `_listen_watch`;
nothing requires it to. The body of §3 stays as recorded; its last reason is
superseded by this addendum. Why the first drain exists at all — libpq can
hold notifications it read during the subscribe round trip, and they never
make the socket readable again — is unchanged.

### Decision

**The first socket-mode drain stays one loop tick after the watch starts.**
Two reasons hold independently of core's `watching` bookkeeping; both concern
what the consumer observes.

1. **No dispatch from inside the API call.** When `_listen_open` and
   `_listen_subscribe` resolve synchronously — a blocking DBI connect does,
   and so does t/19's fake — core runs `_listen_op_arm`, and with it
   `_listen_watch`, inside `listen()` and inside `listen_reconnect()`. A drain
   there would run a channel callback before the call returned, and so before
   the caller's own code after `listen(...)->get`: subscribe first, then read
   a snapshot. It would do so only when the client library happened to buffer
   a notification during the subscribe. The same callback would then run
   sometimes synchronously inside `listen()` and sometimes later from the
   loop, and it could re-enter the listen API while core is in the middle of
   `listen()`.
2. **Order relative to core's post-watch steps.** `_listen_op_arm` sets the
   phase `up`, fires `on_listen_reconnect` and settles the waiting `listen()`
   and `listen_reconnect()` Futures only **after** `_listen_watch` returns. A
   drain inside the watch would deliver the rebuilt connection's
   notifications before `on_listen_reconnect`, the hook where a consumer
   re-reads state after an outage (core ADR 0056): the consumer would see the
   new stream before learning the old one broke. It would also deliver them
   before the caller's Future resolves.

Timer mode is unaffected: its first drain waits one poll interval anyway.

### Consequences

- No code change. The POD of `THE LISTEN WATCH LOOP` in
  `DBIO::Async::Storage` states these two reasons in place of the old one.
- Pinned by `t/19-listen-seams.t`. Section 3 checks that nothing is drained
  inside `_listen_watch`; its test name now gives these reasons. Section 4
  checks, with a notification buffered at open and seams that resolve
  synchronously, that `listen()` returns a done Future without having run the
  callback, which runs once the loop is driven. It also checks, on a rebuilt
  connection with a notification buffered at its open, that
  `on_listen_reconnect` fires before that notification is dispatched, on both
  rebuild paths (`listen_reconnect`, and healing after end of file), and that
  nothing is dispatched inside `listen_reconnect()` itself. Run against a
  variant of `_listen_watch` that drains inline in socket mode, those
  assertions fail. They pass with the delay.
- The "Also surfaced" await point under Consequences is addressed on core's
  side by k222 (core ADR 0056 addendum, decision 1): a pending Future that
  `listen`, `unlisten` or `listen_reconnect` hands out is now derived from a
  pending Future of the transport's own seams, so its `get` awaits wherever
  the transport's Futures can.
