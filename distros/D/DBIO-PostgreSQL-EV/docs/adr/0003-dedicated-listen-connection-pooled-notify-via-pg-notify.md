# ADR 0003 — Dedicated buffered connection for LISTEN, pooled NOTIFY via pg_notify

- Status: accepted
- Date: 2026-06-21
- Tags: async, listen-notify, pool, ev-pg, drivers
- Superseded in part: the driver-owned `listen` / `unlisten` / `notify` and the
  buffering and serialising *machinery* described below are superseded by core
  ADR 0056 (see the Amendment); the split itself -- a dedicated connection for
  LISTEN, a pooled `pg_notify` for NOTIFY -- stands

## Amendment (2026-09-27, karr k43) — the API and the machinery are core's, this dist fills the seams

The decision this ADR records is in force and unchanged: LISTEN runs on one
dedicated connection outside the pool, NOTIFY on a pooled connection as
`SELECT pg_notify($1, $2)` with channel and payload bound. What is superseded
is *who implements the rest*.

Core ADR 0056 made LISTEN/NOTIFY a core async contract. `listen`, `unlisten`,
`notify`, `listen_alive`, `listen_reconnect`, the hooks `on_listen_error` /
`on_listen_reconnect` and the backoff settings are defined once in
`DBIO::Storage::Async`, and so are the channel registry, the queue that runs one
channel operation at a time on the listen connection, reconnect with backoff,
re-subscribing every channel and the fork guard. `DBIO::PostgreSQL::EV::Storage`
no longer overrides `listen` / `unlisten` / `notify` (or `disconnect`, which it
overrode only to finish its LISTEN connection); it fills the listen seams with
EV::Pg: `_listen_open` / `_listen_close`, `_listen_subscribe` /
`_listen_unsubscribe`, `_listen_watch` / `_listen_unwatch`, `_listen_probe`,
`_listen_delay` and `_notify_send`.

Read as superseded, therefore:

- **Buffering until connected is the open's Future, not a pending list.**
  `_listen_open` resolves on EV::Pg's `on_connect` and core subscribes only
  after that, so nothing is still sent on a handle that is not connected -- the
  guarantee this ADR's *Rationale* asks for -- but `_listen_pending` is gone.
- **The k15 serialiser is core's queue.** `_dispatch_listen_queue` and its
  `_listen_dispatching` flag are gone. That also ends the defect k46 found in
  them: a synchronous croak from EV::Pg's `query` (*"not connected"*, *"another
  command is already in progress"*) left the flag set, and every later
  LISTEN / UNLISTEN waited in the queue forever. The seam turns such a croak
  into a failed Future, and core probes the connection and heals or reports.
- **The connection heals.** EV::Pg's `on_error` used to `warn` and nothing
  more; a dead LISTEN connection stayed dead. It now goes to core's
  `_listen_lost`: close, report, wait the backoff (an EV timer), reconnect,
  LISTEN every channel again, fire `on_listen_reconnect`.
- **The connection is fork-safe and rotates credentials.** It is built by
  `DBIO::PostgreSQL::EV::Pool::_new_connection`, like a pooled one, so it closes
  fork-safe (karr k45), and from the same per-spawn conninfo path (ADR 0009), so
  every reconnect uses the broker's current credentials.
- **The channel is quoted as one identifier.** It went through the SQLMaker's
  `_quote`, which splits on the name separator, so a channel with a `.` was sent
  as a qualified name the server rejects. `_pg_quote_channel` quotes it whole
  and refuses a name over 63 bytes rather than letting PostgreSQL truncate it --
  the rules of the `future_io` transport (dbio-postgresql k77).

The *Consequences* change accordingly: `disconnect` still ends the LISTEN
connection, but it is core's `disconnect` that does; and a subscription is
still not active the instant `listen` returns, but `listen` now returns a
Future that resolves once the LISTEN is in effect, so a caller can wait for it
instead of guessing. The `Storage.pm:NNN` references below point at the file as
it was on 2026-06-21.

## Context

PostgreSQL LISTEN/NOTIFY is asymmetric in a way a connection pool exposes
sharply. A `LISTEN` subscription is *stateful and long-lived*: notifications
arrive asynchronously on the exact backend connection that issued the `LISTEN`,
for as long as that connection lives. A `NOTIFY` is *stateless and
instantaneous*: it is a fire-and-forget statement that returns immediately and
needs no follow-up. A pool that hands connections out and takes them back cannot
host a `LISTEN` — the subscription would vanish the moment the connection was
released and reused — but it is the natural home for a one-shot `NOTIFY`.

Two further EV::Pg realities shape the LISTEN side. `EV::Pg->new` returns *before*
the socket is actually connected, and a `query()` dispatched on a not-yet-connected
handle throws "not connected" (`Storage.pm:498-500`). And on the NOTIFY side, the
SQL `NOTIFY` statement takes no bind placeholders, so inlining a payload as a
string literal invites quoting bugs (`Storage.pm:576-577`).

## Decision

Split the two directions across two different connection strategies.

- **LISTEN on a dedicated, buffered, out-of-pool connection.** `listen` does not
  touch the pool. It lazily builds a single dedicated `EV::Pg` handle
  (`Storage.pm:501-523`) with `keep_alive => 1` and an `on_notify` callback that
  dispatches to the registered per-channel handler (`Storage.pm:515-520`).
  Because the socket is not connected yet, `LISTEN`/`UNLISTEN` statements are
  *buffered*: an `on_connect` callback flushes a pending queue once the socket is
  up (`Storage.pm:508-513`); until then statements are pushed onto
  `_listen_pending` (`Storage.pm:527-531`), and `unlisten` mirrors the same
  buffer-or-send logic (`Storage.pm:542-554`). The dedicated handle is torn down
  in `disconnect` (`Storage.pm:692-695`).
- **NOTIFY on a pooled connection via `pg_notify()`.** `notify` acquires a normal
  pooled connection (`Storage.pm:573`), runs
  `SELECT pg_notify($1, $2)` with the channel and payload as bind params, and
  releases the connection in the callback (`Storage.pm:578-586`). The method's POD
  states the contrast explicitly: "Unlike listen, this does not require a
  dedicated connection — it uses a pooled connection from the normal pool"
  (`Storage.pm:563-564`). Using the `pg_notify()` *function* rather than the bare
  `NOTIFY` statement is what makes binding the channel and payload possible.

## Rationale

The asymmetry of the feature dictates the asymmetry of the implementation. A
`LISTEN` must outlive any single checkout, so it cannot share the pool's
release-and-reuse lifecycle; a dedicated keep-alive connection with its own
`on_notify` pump is the only correct host. The connect-race buffering is not
optional polish — without it the first `LISTEN` issued right after
`EV::Pg->new` would reliably throw "not connected"; queuing until `on_connect`
and flushing is the documented fix (`Storage.pm:498-500`). On the NOTIFY side,
the statement is stateless, so paying for a dedicated connection would be waste —
the pool is correct — and routing through `pg_notify($1, $2)` instead of literal
`NOTIFY channel, 'payload'` lets libpq bind the values, sidestepping the
payload-quoting bugs that string interpolation into a `NOTIFY` statement invites
(`Storage.pm:576-577`).

This is shipped and covered by the live listen/notify tests, hence **accepted**,
not proposed.

## Consequences

- A storage that uses LISTEN holds one extra connection outside the pool for as
  long as any subscription is active; `disconnect` must (and does) finish it
  (`Storage.pm:692-695`) or it leaks.
- LISTEN/UNLISTEN issued before the dedicated socket finishes connecting are
  silently buffered and flushed on `on_connect`; a subscription is therefore not
  guaranteed active the instant `listen` returns, only once the socket is up.
  Callers must not assume synchronous subscription.
- NOTIFY shares the normal pool and its capacity limits; a flood of NOTIFYs
  competes with query traffic for pooled connections. This is the intended
  trade for not paying a dedicated connection per NOTIFY.
- The payload always travels as a bind parameter through `pg_notify()`, never as
  inlined SQL; any future change to `notify` must keep it that way to preserve
  quoting safety.
