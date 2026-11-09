# ADR 0008 — LISTEN/NOTIFY is emulated over a notify table, with a per-channel lookback window

- Status: accepted; the reporting of a failed cleanup amended 2026-09-26 (see below)
- Date: 2026-09-26
- Tags: async, listen, notify, emulation, future_io, ev, notify-table, builds-on-core-0056, builds-on-dbio-async-0005

## Amendment (2026-09-26, karr k58) — a failed cleanup goes to core's `_listen_error`

The Consequences below put the report of a failed cleanup in a private
`_mysql_listen_report`, because core documented no transport-facing entry point
for an error that leaves the listen connection up. Core now does:
`DBIO::Storage::Async::_listen_error` (core ADR 0056 addendum, karr core k227),
the third transport-to-core method beside `_listen_dispatch` and `_listen_lost`.
`_mysql_listen_report` is gone, and the failed cleanup goes to `_listen_error`.

It is reported as before — to `on_listen_error`, warned without a hook, warned
again if the hook dies — with one rule the copy lacked: an error arriving in a
process that is not listening is ignored. That is core's fork guard. A forked
child whose own loop fires the poll it inherited for the parent's in-flight
cleanup runs that callback, and the copy would have reported the parent's
failure in the child.
After listening ends nothing changes in practice: ending it stops the watch,
which cancels the drain and with it the cleanup Future, so the callback never
runs. Section 7 stands: the failure is reported, the cleanup is retried a
period later, and the drain does not fail. Pinned offline by
`t/62-future-io-listen.t`, which checks that the error reaches
`_listen_error` and that the listen connection stays the same live handle.

## Context

Core ADR 0056 (karr core k219, addendum k222) made LISTEN/NOTIFY a core async
contract: core `DBIO::Storage::Async` owns the public API (`listen`,
`unlisten`, `notify`, `listen_alive`, `listen_reconnect`), the channel registry,
one dedicated listen connection, reconnect with backoff, re-subscribing every
channel and the fork guard; a transport fills the listen seams. §6 allows a
transport with no server push to **emulate** — wait, query rows newer than a
mark, deliver, wait again — and to declare `listen` / `notify` if its POD states
that latency is the poll interval and that delivery happens on commit.

dbio-async ADR 0005 (karr dbio-async k22) supplies the Future::IO half once for
every `future_io` driver: the watch loop with a **timer mode** selected by
`_listen_poll_interval` returning positive seconds, `_listen_delay`, and
`_notify_send` over a driver's `_notify_sql`. The driver supplies
`_listen_drain` (an arrayref of `[$channel, $payload, $sender_pid]`, or a Future
of one), `_notify_sql` and the five connection seams.

MySQL and MariaDB have no LISTEN/NOTIFY: no server push, and neither DBD::mysql,
DBD::MariaDB nor EV::MariaDB offers a notification API. The maintainer decided
on 2026-09-26 (karr k54) that both MySQL transports get the contract emulated —
`future_io` in this dist, `ev` in dbio-mysql-ev (its karr k44), which requires
DBIO::MySQL and so can reuse a part shipped here.

Three facts shape the design, each measured against MySQL 8.0.30 with
DBD::mysql 4.055 and DBD::MariaDB 1.24:

1. **AUTO_INCREMENT ids are handed out at INSERT, rows become visible at
   COMMIT.** Transaction A takes id 10, B takes 11 and commits first; a poll
   sees 11; a poller that asks only for `id > mark` never sees 10.
2. **One asynchronous statement per connection.** A `ping`, or a second
   `prepare`, while an asynchronous statement is in flight dies in both DBDs
   ("Calling a synchronous function on an asynchronous handle"). Releasing an
   in-flight statement handle on a live connection waits for its result;
   disconnecting first does not.
3. **`utf8mb4_bin` is a PAD SPACE collation** in MySQL 8.0 and MariaDB: in SQL,
   `'jobs' = 'jobs '`. And under a non-strict `sql_mode` an over-long value is
   silently truncated into a `VARCHAR`, where strict mode refuses it.

## Decision

### 1. One shared, sans-I/O class: `DBIO::MySQL::NotifyTable`

The emulation lives in `lib/DBIO/MySQL/NotifyTable.pm`, a plain class that does
**no I/O**: it builds SQL with its bind values, and it folds the rows a
statement returned into its state. No DBI, no Future, no event loop. The
`future_io` transport runs its statements through the DBD's async binding; the
`ev` transport can run the same statements through EV::MariaDB callbacks. One
object belongs to one listen connection. Its API, which dbio-mysql-ev reuses:

| Method | Returns / does |
|---|---|
| `new(%cfg)` | validates `table`, `poll_interval`, `lookback`, `retention`, `cleanup_limit`; croaks on anything invalid or unknown |
| `defaults` (class) | `(table => 'dbio_notify', poll_interval => 1, lookback => 60, retention => 3600, cleanup_limit => 1000)` |
| `table`, `poll_interval`, `lookback`, `retention`, `cleanup_limit` | read-only accessors |
| `quoted_table` | `` `dbio_notify` `` |
| `check_channel($ch)` | `$ch`, or croaks |
| `create_table_sql` / `drop_table_sql` | DDL strings |
| `notify_sql($ch, $payload)` | `($sql, \@bind)` |
| `subscribe_sql($ch)` | `($sql, \@bind)` — the mark statement |
| `subscribed($ch, \@rows)` | folds it; from now on the channel is polled |
| `unsubscribe($ch)` | local; no statement |
| `channels` | sorted list |
| `poll_sql` | `($sql, \@bind, $token)`, or `()` with nothing subscribed |
| `polled($token, \@rows)` | arrayref of `[$channel, $payload, $sender_pid]`, id order |
| `cleanup_sql` | `($sql, \@bind)` when a cleanup is due, else `()` |
| `cleaned($affected_or_undef)` | records the outcome |

A transport keeps the object on its listen connection, runs `subscribe_sql` and
hands the rows to `subscribed` before it reports the subscription in effect,
runs `poll_sql` on each tick and delivers what `polled` returns, runs
`cleanup_sql` when it returns a statement, and uses `notify_sql` for `notify`.
Its configuration accessors are `notify_table`, `notify_poll_interval`,
`notify_lookback` and `notify_retention`, `inherited` class data seeded from
`defaults`, so the defaults live in one place.

### 2. The table

```sql
CREATE TABLE IF NOT EXISTS `dbio_notify` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `channel`    VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `payload`    TEXT CHARACTER SET utf8mb4 NOT NULL,
  `pid`        BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `channel_id` (`channel`, `id`),
  KEY `channel_created_at` (`channel`, `created_at`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
```

- `created_at` is `DATETIME(6)` written as `UTC_TIMESTAMP(6)` and compared
  against `UTC_TIMESTAMP(6)` arithmetic: one clock (the server's), no session
  `time_zone` conversion, which a `TIMESTAMP` would apply per session.
- `channel` is `utf8mb4_bin` — case-sensitive like core's registry and
  PostgreSQL's quoted channel names. Its PAD SPACE comparison makes SQL return
  a superset; `polled` matches the rows to channel names **exactly, in Perl**.
- `payload` is `TEXT NOT NULL`: a string in is a string out under a
  Unicode-aware connection. An `undef` payload is sent and delivered as `''`,
  which is what PostgreSQL does.
- `pid` is the notifier's `CONNECTION_ID()` — the contract's `$sender_pid`.
- The indexes serve the two poll ranges and the cleanup. Index names are
  per-table in MySQL, so they carry no table prefix and a long table name
  cannot push them over 64 characters.
- The name defaults to `dbio_notify`, is configurable, and is validated as a
  plain identifier (`[A-Za-z_][A-Za-z0-9_]*`, at most 64 characters — core ADR
  0017 §3's validate-or-escape at the boundary) and backtick-quoted. A
  schema-qualified name is not supported.
- A channel over 255 characters and a payload over 65535 UTF-8 bytes are
  **refused** before any statement exists, so that `sql_mode` cannot change the
  outcome: a truncated channel would never match the name it was sent under.

### 3. Notify

`INSERT INTO t (channel, payload, pid, created_at) VALUES (?, ?,
CONNECTION_ID(), UTC_TIMESTAMP(6))` — channel and payload only as binds (core
ADR 0017 §3). The row is visible when the inserting transaction commits:
delivery on commit, PostgreSQL's moment. The transport's `notify` runs it on a
pooled connection in autocommit; to notify transactionally, a caller runs
`notify_sql` inside its own transaction.

### 4. The mark, the lookback window and the dedup — per channel

Each subscribed channel keeps three things: a **mark** (the highest id
delivered or known), a **cutoff** (a server time) and the set of ids it
**saw** in its last result.

- **Subscribe** takes, in one statement, the channel's `MAX(id)` as the mark,
  `UTC_TIMESTAMP(6) - lookback` as the cutoff, and the ids of the channel's rows
  created since that cutoff as the seen set. Nothing visible at that moment is
  delivered — no history. A row INSERTed before the subscribe and committed
  after it is not in that result, so it is delivered when it commits, as
  PostgreSQL delivers a NOTIFY to whoever listens at commit.
- **A poll** asks, per channel, for rows with `id > mark` **or**
  `created_at >= cutoff` — two `UNION ALL` branches, each an index range — plus
  one row carrying the next cutoff, formatted by the server with
  `DATE_FORMAT(..., '%Y-%m-%d %H:%i:%s.%f')` so string order is time order. New
  = returned minus seen; seen becomes the returned set; the mark and the cutoff
  only ever rise (the cutoff takes the maximum, so a server clock stepping back
  cannot reopen the window).

Because the window only moves forward, a row that has left it never returns, so
the seen set is exact and never larger than the window: **a notification is
never delivered twice**. Because a poll binds the cutoff its channel's
*previous* poll brought back, a row whose transaction committed within
`lookback` of its INSERT is always inside the window of the first poll that can
see it — independent of the poll interval and of a stalled loop.

**The limit, stated in the POD:** a notification is lost when its transaction
commits more than `lookback` seconds after its INSERT *and* a later
notification on the same channel was delivered in the meantime. Without a later
delivered notification on its channel it is delivered however long it took (its
id is above the mark), as long as the retention keeps the row.

Per channel, not global, because a global cutoff would let the subscribe of a
new channel — whose cutoff is "now minus lookback" — move an existing channel's
window past a notification about to commit (the offline unit test pins this
with a stalled channel).

Alternatives not taken:

- **Gap tracking** (remember missing ids below the mark, wait for them): ids are
  missing for good after a rollback, under `auto_increment_increment > 1`
  (Galera, multi-primary) and for every other channel's rows, so gaps need a
  time-based expiry anyway — the lookback, with more state.
- **A commit-ordered sequence stamped by the listener** (`UPDATE ... SET seq`):
  every listener would need write access, and the stamping `UPDATE` waits on
  row locks of uncommitted notifications, blocking polling behind the longest
  transaction.
- **A plain `id > mark`**: loses the out-of-order commit, the pitfall this
  design exists for.

The cost: each poll re-reads the subscribed channels' rows of the last
`lookback` seconds. At typical signalling rates that is a handful of rows; a
high-rate channel sizes `notify_lookback` down or uses a real queue.

### 5. Where the mark lives

In the `DBIO::MySQL::NotifyTable` object on the listen connection. Core opens a
new connection on every rebuild and re-subscribes every channel, so a rebuild
takes new marks: what was committed while no connection listened is not
delivered — PostgreSQL's semantics, and the reason core ADR 0056 leaves replay
out and has `on_listen_reconnect`. Carrying marks across reconnects was not
taken: an unlisten + listen, a `disconnect`, or a forked child's fresh `listen`
would then inherit a stale mark and replay history.

### 6. The listen connection runs one statement at a time

All statements of the emulation — the mark, the polls, the cleanup — run on the
dedicated listen connection, and the transport serialises them there:

- a drain whose tick finds a statement in flight returns `[]` without a
  statement (the next tick polls);
- a subscribe waits for the statement in flight, then runs its mark statement;
- the probe answers "alive" while a statement is in flight **without pinging**
  (the ping would die in the DBD, and core would take that for a death and
  reconnect), because that statement reports a dead connection itself;
- a statement cancelled by an unwatch marks the connection abandoned, and
  `_listen_close` disconnects before it releases the statement handle.

The mark is taken on the listen connection, not on a pooled one, although any
connection sees the committed rows. Core decides what a failed subscribe means
by probing the *listen* connection: alive means "the statement was refused",
and the channel is dropped for good. A pooled connection that died — every one
does across a server restart — would then make core drop a channel for a
failure that was not the channel's.

### 7. Retention

Every listener deletes rows older than `retention` seconds on its listen
connection, right after a poll: `DELETE ... WHERE created_at < UTC_TIMESTAMP(6)
- retention LIMIT cleanup_limit`, due on the first poll, then once a minute of
polling, and on the very next poll again while a run deletes a whole batch, so
a backlog is worked off in bounded steps. The `DELETE` walks the `created_at`
index; its next-key locks block a concurrent notify `INSERT` only when it
reaches the end of that index, and then for one bounded, autocommitted
statement. A failed cleanup — typically a listener account without `DELETE` —
is reported through `on_listen_error` (or warned) and retried a period later;
it does not fail the drain, since dropping a healthy connection over it would
reconnect in a loop. `retention => 0` turns the cleanup off for a deployment
that prunes the table itself. `retention` must exceed `lookback +
poll_interval`, so a late-committing notification is still there for the poll
that catches it. Default 3600 seconds.

### 8. The table is deployed explicitly, never created implicitly

Nothing creates the table as a side effect. `create_table_sql` gives the DDL for
a migration; the transport's `deploy_notify_table` runs it on a pooled
connection. A `listen` against a missing table fails its Future with a message
naming the table and `deploy_notify_table` — a refusal on a live connection, so
core drops the channel instead of reconnecting in a loop.

Auto-create was not taken because it is a schema change the deployer did not
ask for, run by an application account that should not need `CREATE`; because
DDL commits implicitly in MySQL, so a `CREATE TABLE` issued from the wrong
connection at the wrong moment ends a transaction; and because a table that
appears on first use escapes the schema tooling that owns every other table.

### 9. Defaults

`poll_interval` 1 second (the latency; one indexed query per second per
listening process), `lookback` 60 seconds, `retention` 3600 seconds,
`cleanup_limit` 1000 rows, table `dbio_notify`.

### 10. The listen connection's attributes

It is opened from the connect info a pool spawn would get — through
`_conninfo_provider`, so AccessBroker credentials are fresh — with
`AutoInactiveDestroy => 1` and the DBD's auto-reconnect forced off: DBD::mysql
switches `mysql_auto_reconnect` on by itself under `GATEWAY_INTERFACE` /
`MOD_PERL`, and a silently rebuilt session would hide the death core must see
(this dist's ADR 0005 gives the transactional reason for the same default). The
attribute's name is a sixth DBD-specific primitive,
`_mysql_auto_reconnect_attr`, overridden in
`DBIO::MySQL::Storage::MariaDB::Async` like the five of ADR 0007.
**Update (2026-10-04, karr k60):** no longer overridden per class; it is named
for the DBD of the DSN the connection is opened with (ADR 0007 addendum).

## Consequences

- `DBIO::MySQL::Storage::Async` and `DBIO::MySQL::Storage::MariaDB::Async`
  declare `listen` and `notify`; the listen seams live in the former and are
  inherited by the latter. Nothing of core or dbio-async is overridden, and no
  class changed its `@ISA`: the transport **holds** a `DBIO::MySQL::NotifyTable`,
  it does not inherit from one. Its private helpers are named `_mysql_*`, never
  `_listen_*` or `_watch_*`.
- The POD of both classes says the feature is emulated and states latency,
  on-commit delivery, the lookback limit, retention, the table and its
  deployment, the privileges (`SELECT` + `DELETE` to listen, `INSERT` to
  notify) and the knobs.
- A cleanup failure is reported the way core reports (`on_listen_error`, or a
  warning without a hook) through the public hook accessor, in
  `_mysql_listen_report`: core documents no transport-facing report entry point,
  and calling its private `_listen_report` would couple to a private.
- **DBD::MariaDB and fork.** With DBD::MariaDB 1.24, a forked child's normal
  exit ended every connection the parent holds, listen connection included:
  DBI's `END` runs `disconnect_all`, and DBD::MariaDB carries it out on every
  inherited connection, `AutoInactiveDestroy` notwithstanding (DBD::mysql does
  not), or dies in a DBI `active kids` panic with exit status 22. That is the
  DBD's defect (`docs/upstream/dbd-mariadb-disconnect-all-after-fork.md`, not
  sent) and is worked around since 2026-10-24: `_mysql_connect` installs
  `DBIO::MySQL::MariaDBForkGuard`, which makes `disconnect_all` a no-op in any
  process but the installing one (ADR 0009, karr k56). Listening survives the
  child's exit without a rebuild, and `t/63-future-io-listen-live.t` g) holds
  no TODO.
- Pinned offline by `t/61-notify-table.t` (the shared class against an
  in-memory model of the table: no history, the out-of-order commit, the
  in-flight-at-listen case, the limit, per-channel windows, PAD SPACE,
  subscriptions changing under a poll, the monotonic cutoff, cleanup pacing,
  validation) and `t/62-future-io-listen.t` (the real core and dbio-async
  machinery over a fake DBD that enforces fact 2), and live, on both DBDs, by
  `t/63-future-io-listen-live.t`.
- Verified live against a MySQL 8.0.30 server only. The statements avoid
  anything MariaDB 10.6 lacks (`DATETIME(6)`, `UTC_TIMESTAMP(6)`,
  `INTERVAL n MICROSECOND`, `DATE_FORMAT` `%f`, `DELETE ... LIMIT`, `UNION ALL`,
  `CAST(? AS UNSIGNED)` / `CAST(? AS DATETIME(6))`, `utf8mb4_bin`); a run
  against a MariaDB server is still to be made.

## Future architecture work (tracked cross-repo, not here)

- **dbio-mysql-ev k44** — the `ev` transport's listen seams over the same
  `DBIO::MySQL::NotifyTable` (section 1), with the same configuration accessors
  and the same one-statement-at-a-time rule on its listen connection.
- **Pool connections and fork** — done on this side since 2026-09-26 (karr
  k55): `_mysql_connect` in `DBIO::MySQL::Storage::Async` opens every
  connection, pooled or listening, with `AutoInactiveDestroy => 1` and the
  DBD's auto-reconnect off. The DBD::MariaDB `disconnect_all` behaviour above
  is worked around in the driver: ADR 0009, karr k56; the unsent report is in
  `docs/upstream/dbd-mariadb-disconnect-all-after-fork.md`.
