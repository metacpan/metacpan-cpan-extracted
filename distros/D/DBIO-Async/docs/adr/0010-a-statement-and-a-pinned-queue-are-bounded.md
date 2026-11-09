# ADR 0010 — A statement on the wire and a pinned queue are bounded

- Status: accepted
- Date: 2026-10-30
- Tags: async, timeout, limits, builds-on-core-0078
- Origin: karr k54. Maintainer decision 2026-10-30.

## Context

Core bounds what a caller waits for at the pool (`acquire_timeout`,
`max_waiters`, `txn_timeout`, `reset_timeout`; core ADR 0078). Two places of the
transport were left without a bound: a statement on the wire, whose poll waits
for the connection until it answers, and the statements waiting behind it on a
pinned connection (ADR 0003, karr k33).

## Decision

1. **`statement_timeout`** (seconds; absent, `undef` or `0` is off). The clock
   starts when the statement goes on the wire -- `_flight_register`, pooled and
   pinned alike -- not while it waits in a pinned queue, and stops when it
   settles, is cancelled or its connection is closed. The timer is the
   storage's `_delay` (default `_listen_delay`, `Future::IO->sleep`).
2. **At expiry** the statement takes the cancel path of karr k29 / k33: its poll
   is let go of, its connection is reported dead to the pool and retired, what
   waits behind it on a pinned connection fails unsent. The caller's Future
   fails with `statement timed out after N seconds (statement_timeout)`.
   Whether the statement took effect is unknown.
3. **`max_pending_pinned`** (positive integer; default no limit) bounds the
   statements waiting behind the one in flight on one pinned connection. With
   that many waiting, the next statement fails at once with
   `not sent: N statements already wait on this connection (max_pending_pinned)`;
   the queue is unchanged. Cancelled entries do not count.
4. **Declared options.** Both are named by `async_option_names` of
   `DBIO::Async::Storage`, read with `async_option`, checked on connect by
   `_assert_async_option`. A driver adapter extends the list with `SUPER::`.
5. **Core options pass through.** `DBIO::Async::Pool` hands its storage on to
   core's pool, which reads `acquire_timeout`, `max_waiters` and
   `reset_timeout` from it; `txn_timeout` is core's. They are documented in
   `TIMEOUTS AND LIMITS`.
6. **Messages** name the option and the number, never SQL, binds or a value.

## Alternatives

- **`wait_any` left to the caller.** A caller can still do it; the dist gives a
  default.
- **Drain the connection instead of retiring it.** Rejected as in karr k29: the
  pool slot would stay held for the whole hang.
- **A pool-wide pending cap.** `max_waiters` and `acquire_timeout` of core
  bound the pool; `max_pending_pinned` bounds one connection.

## Consequences

- A hung server costs a bounded time per statement and one retired connection.
- A driver that overrides `_delay` returns a Future that can `cancel`.
