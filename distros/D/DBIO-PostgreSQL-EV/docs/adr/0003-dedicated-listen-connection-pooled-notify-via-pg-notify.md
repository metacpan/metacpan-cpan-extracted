# ADR 0003 — Dedicated buffered connection for LISTEN, pooled NOTIFY via pg_notify

- Status: accepted
- Date: 2026-06-21
- Tags: async, listen-notify, pool, ev-pg, drivers

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
