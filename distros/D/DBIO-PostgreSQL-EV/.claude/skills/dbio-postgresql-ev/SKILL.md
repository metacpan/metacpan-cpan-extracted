---
name: dbio-postgresql-ev
description: Load when working on the DBIO::PostgreSQL::EV driver — EV::Pg async storage, the Future API, Pool, LISTEN/NOTIFY, Pipeline, COPY.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::PostgreSQL::EV

The native `ev` async transport for PostgreSQL (core ADR 0030 / 0031). Speaks
libpq's async wire protocol through EV::Pg — no DBI, no DBD::Pg.

## Namespace

| Class | Purpose |
|---|---|
| `DBIO::PostgreSQL::EV` | The distribution's overview: POD only, no methods, no `connection()` hook |
| `DBIO::PostgreSQL::EV::Storage` | The transport — a `DBIO::Storage::Async` subclass |
| `DBIO::PostgreSQL::EV::Future` | `future_class`: a `Future` whose `get` runs the EV loop |
| `DBIO::PostgreSQL::EV::Pool` | Fork-safe EV::Pg pool on core's `DBIO::Storage::PoolBase` |
| `DBIO::PostgreSQL::EV::TransactionContext` | Core's context plus the `txn_pg` alias |
| `DBIO::PostgreSQL::EV::ConnectInfo` | `dbi_to_conninfo` / `dbi_dsn_parts` / `conninfo_string` |
| `DBIO::PostgreSQL::EV::TestHarness` | Installable live harness; ships under `lib/`, not `t/` |

## Reaching the transport

A schema that declares the PostgreSQL driver (core ADR 0067: `use DBIO
'Schema', -pg` or `load_components('PostgreSQL')`; a schema without a driver
is refused at connect), a `dbi:Pg:` DSN plus `{ async => 'ev' }` at connect.
The declared sync `DBIO::PostgreSQL::Storage` registers
`register_async_mode( ev => 'DBIO::PostgreSQL::EV::Storage' )`, and core
resolves the mode over the *storage* MRO. The schema loads no component of
this distribution.

```perl
package MyApp::Schema;
use DBIO 'Schema', -pg;

my $schema  = MyApp::Schema->connect(
    'dbi:Pg:dbname=myapp;host=localhost', $user, $pass,
    { async => 'ev' },
);
my $storage = $schema->storage;   # the sync DBIO::PostgreSQL::Storage
my $async   = $storage->async;    # the embedded EV transport
```

The CRUD `*_async` methods of storage, ResultSets and rows dispatch into the
transport; `listen`, `notify`, `copy_in`, `pipeline`, `deploy_async` are called
on `$storage->async`. `*_async` without the mode croaks, as does a mode whose
backend is missing (ADR 0030 §3).

`DBIO::PostgreSQL::EV` stays a POD page: loaded as a component it changes
nothing, and it keeps defining no methods and no `connection()` hook (ADR 0032
§7, guarded by `t/00-load.t` and `t/27`).

## Connection info and AccessBroker

Users connect with a `dbi:Pg:` DSN; libpq conninfo is the transport-internal
shape, rendered by `conninfo_string` for `EV::Pg->new`.

**One reader, measured on the owner** (karr k58, k61, k64): the dbh and the
pool are opened from the same connect info and must end up in the same place
as the same user. `Storage::_pg_read_connect_info` reads connect info wherever
it comes from — what `connect_info` is given, what a broker answers at attach
and for every connection (`broker => 1`) — into the `[ \%conninfo, \%opts ]`
pair. A form the sync storage reads as a connection
(`DBIO::Storage::DBI::_normalize_connect_info`) is read as that connection:

| Form | Read as |
|---|---|
| `[ 'dbi:Pg:...', $user, $pass, \%attrs, \%extra ]` | `dbi_to_conninfo` |
| `{ dsn => 'dbi:Pg:...', user, password, %attrs }`; a `dbname` that is a whole DSN | that DBI form — every other key an attribute, `host`/`sslmode` beside the `dsn` too |
| `{ dbname, host, user, password, sslmode, ... }` | libpq parameters, minus `pool_size` and the owner's keys: its options (core's `_strip_private_connect_attrs`) and DBI attributes by name (`_pg_is_dbi_attribute`) |
| `'host=... dbname=...'`, a `postgresql://` URI | libpq conninfo string |

A hash or string may be followed by an options hash. Everything else is refused
in `connect_info` (a refusal, see *Refusals* below) — through a schema at the first `->async` — naming the form,
never a value: a coderef or `dbh_maker` (the owner's way to a dbh), a conninfo
string with user and password beside it, another driver's DSN. Put a rule
about connect info in the reader, never as a guard at a caller. Two rules
depend on the origin: an answer that renders to an **empty conninfo**
(`[ {}, {} ]`, `{ pool_size => 3 }`, `{ dbname => undef }`, a blank string,
`dbi:Pg:;`) is refused — libpq would fill it from `PGHOST`/`PGUSER` — while
static connect info that does is taken (open on k66); a hash outside an array
is a broker's answer only.

`dbi_to_conninfo` reads the DBI form **as DBI and DBD::Pg read it**, each a
port of the source, step by step — change it only against the source, never
to what looks more sensible; `t/53-dbi-to-conninfo.t` holds each case against
DBI's `connect` and libpq's parser:

- DBI (`dbi_dsn_parts`, DBI's own pattern): attributes in front of the DSN,
  `dbi:Pg(RaiseError=>1):...`, count over `\%extra` over `\%attrs`; `Username`
  and `Password`, when defined, replace `$user`/`$pass`. Of the attributes
  only those two and `pool_size` are read; the rest is dropped — there is no
  DBD here.
- DBD::Pg and libpq (`_dbd_pg_params`): `db=`/`database=` → `dbname=`, `;`
  outside single quotes → blank, a non-empty user/password appended behind
  the DSN's parameters, so they win over a `user=` in it; quotes, `\`
  escapes, blanks as separators, the later value of a keyword.

It dies, quoting nothing of the DSN, for what libpq cannot read, and leaves
the array it is given alone.

No message quotes a password (karr k78): the reader names forms, keys and the
DBI driver; every text that names connect info or passes on libpq's goes
through core's `DBIO::Util::mask_connect_secrets` — the DSN `dbi_to_conninfo`
does not read, the croak of `EV::Pg->new` and every `on_error` text (both in
`Pool::_pg_new`, where every handle is made). `t/65` holds every message.

With a broker attached, `_async_broker_conninfo` asks it anew for every pool
spawn and every open of the listen connection, through core's
`_current_async_connect_info`, and refuses without a broker attached — what
core's seam answers then is no broker's answer. A broker selects `ev` in its
own attrs (`dbi_attrs => { async => 'ev' }` on Vault) or as
`connect($broker, { async => 'ev' })`.

`connect_info` keeps no conninfo from a broker's answer (karr k63, as core
k252): `$self->{_conninfo}` holds only static connect info. Whatever the
`connect_info` before stored — conninfo, pool size, options — is dropped
before anything is read (karr k67, k66), so a call that throws leaves nothing
of it: refused static connect info leaves nothing to connect from, a failed
attach its broker with what stood beside it. A storage whose broker is detached has
nothing to connect from — never the answer of the attach.

The transport declares `broker_connect_options` (karr k60), so core hands it
the options beside a broker as `[ $broker, \%options ]`. The `connect_info`
override takes that form only through core's seams — never a reading of its
own: `_strip_private_connect_attrs` + `_access_broker_call_options` split the
options, `_access_broker_pool_size($read, $beside)` sizes the pool from the
answer as the reader read it (its hash, any attribute of a DBI-form answer,
beside the broker; answer and beside must agree or it throws naming
`pool_size`). DBD attributes beside the broker are dropped
like the same keys in DBI-form connect info. The declaration is a promise:
`t/51-access-broker-connect-options-mock.t` holds the behaviour behind it.

A connection parameter beside the broker (`sslmode`, `connect_timeout`, any
lowercase key that is no DBI attribute by core k298's measure: uppercase first
letter, `private_`, `dbi_`, `dbd_`, `pg_`) is refused, never dropped (karr
k76): `_pg_refuse_parameters_beside_broker` refuses naming the keys, no value,
from `connect_info` and again from `_async_broker_conninfo` for every
connection, so a refused storage opens nothing. Through a schema that is the
first `->async`, not `connect`; the sync owner refuses it as well, where it
opens its own dbh (core k307). Such a parameter belongs in the broker's
answer. A hash to every storage connects the schema and reaches every pooled
and the listen connection; only the owner's dbh is not opened from it — the
sync owner refuses a hash answer with more than `dbname`/`host`/`port` where
it connects (first dbh use, every reconnect), not at `Schema->connect` (core
k298, karr k78, k81). The DBI form with the parameter in the DSN reaches both
halves; `connect_info_for_storage` answers each its own.

## Async API — signatures and resolution shapes

Inherited from `DBIO::Storage::Async`; source/SQLMaker arguments, **never raw
SQL**:

```perl
$storage->select_async($source, $select, $where, $attrs);   # → raw row arrayrefs
$storage->select_single_async($source, $select, $where);    # → one row arrayref
$storage->insert_async($source, \%vals);                    # → returned-columns hashref
$storage->update_async($source, \%vals, \%where);           # → affected-row count
$storage->delete_async($source, \%where);                   # → affected-row count
```

The shapes are binding (ADR 0031 §3); `_post_insert_sql` is ` RETURNING *`.

The maker quotes as the connection says (karr k88, from dbio-postgresql k121):
`_sql_maker_args` takes `quote_char` (when defined) and `name_sep` from the
owning sync storage's `sql_maker` — through `_owner_storage`, never
`_effective_owner_storage`, whose private sibling shares this very maker. A
backend without an owner keeps `"` and `.`; `limit_dialect` stays
`LimitOffset`. `t/102` holds it.

## Refusals

What the transport refuses to do with what it was given is a `DBIO::Exception`
at the caller's place (karr k88, maintainer's decision 2026-10-16; as
dbio-postgresql k120 for `future_io`): `_pg_refuse($message, $connect_info)`, a
function, never `croak`. It throws through package `…::Storage::_Refusal`,
which `%Carp::Internal` hides and whose `_skip_namespace_frames` adds
`^Future\b|^EV\b` to core's `^DBIO`, so the place is the caller's also through
the pool or in a loop callback. A rule of `DBIO::PostgreSQL::Util`
(`quote_channel`, `number_placeholders`) croaks; `_Refusal::of_util` raises it
again as a refusal. Core's `DBIO::Carp` never stops at a frame whose callee is
anonymous: a closure that refuses needs a name (`copy_in`'s writer is
`Sub::Util::set_subname`d `copy_in_writer`). Hand refused connect info to
`_pg_refuse` so the verbose trace masks its password.

Not refusals, and strings as they were: the server's error
(`DBIO::Exception::Server`), libpq's text, EV::Pg's croak (`_pg_dispatch_error`
— dispatch, COPY, pipeline enter and exit), a refused blocking wait
(`Future::await`, `_pg_refuse_connect_wait`), a statement after its
transaction's `COMMIT`. `t/103` holds the refusals.

## The `?` seam

`DBIO::PostgreSQL::SQLMaker` is shared with the sync driver and keeps emitting
`?`. `_transform_sql` rewrites `?` → `$N` **once, inside the transport**
(`_query_async` / `_query_async_pinned`). Never shape SQL in a caller, a layer
or a test — test the seam directly. The rule itself is kept once, in
`DBIO::PostgreSQL::Util::number_placeholders` (dbio-postgresql); `_transform_sql`
only delegates to it, as the `future_io` transport does (karr k88; `t/85`).

A `?` is a placeholder where PostgreSQL reads SQL (karr k84). What its scanner
(`scan.l`) reads as something else is passed over as a whole: `'...'` and
`"..."`, `E'...'` with its backslashes, a dollar-quoted body (`$$`, `$tag$`),
a `--` comment, a `/* */` comment (nests); a run never closed goes to the end.
The measure is the server, not DBD::Pg, which reads less (no nesting, no
lowercase `e`). So a layer may send a `$$` body through `_query_async`
(dbio-postgresql-age does), and literal SQL that runs over the dbh runs here
with the same binds — except what is not read: `:name` (DBD::Pg's own) and
`standard_conforming_strings = off`.

Outside such text every `?` is a placeholder, behind an operator character
too — no operator is known (dbio-postgresql k120): `col <@?` → `col <@$1`,
`@? ?` → `@$1 $2`, as DBD::Pg reads it at the dbh. `\?` is a literal question
mark and loses its backslash: the way to write the operators `?`, `?|`, `?&`
and `@?`, over the dbh and here alike. The maker writes the jsonpath operator
so: `@\? ?::jsonpath` goes out as `@? $1::jsonpath`, and `as_query` shows
`@\?`. `$N` already there passes through; `$N` beside a `?` placeholder is
refused, and `SELECT a @? $1::jsonpath` is such a mix. A statement is shaped
once: the `?` a `\?` left is a placeholder to a second pass. `t/03` and `t/85`
hold it, `t/24` against the dbh of a server.

## Callbacks handed to EV::Pg — the house pattern

Every callback this class gives EV::Pg to settle one of its Futures:

1. returns at once when `$$` is not the pid that issued the statement
   (forked child, `Pool` "Fork safety");
2. marks the connection first: `my $delivering = DBIO::PostgreSQL::EV::Future->_delivering($pg);`
   — `Future::await` and the pool's connect-action replay
   (`_run_pool_connect_statement`) die with *"Blocking wait refused"* inside
   such a callback while the connection has more results due, because EV::Pg
   would hand the next result to the running callback and spin. The same mark
   is how the pool knows a connection is held by a running callback
   (`Pool::_pg_held_by_callbacks`, karr k71): a callback without it is one a
   blocking call queued for the pool hangs in;
3. on the pooled path, settles the Future **before** releasing the connection,
   through `_pg_settle_and_release` (the release happens even when settling
   dies; the die is rethrown after);
4. reports a dead connection before the release (`_pg_report_if_dead`), so the
   pool retires it. A connection the pool cannot use again is retired, never
   idled — also one that is open: a COPY whose stream could not be ended
   leaves libpq in the COPY, and `copy_in` reports it itself
   (`_mark_connection_dead`, karr k65);
5. talks to the pool the connection was **acquired from**, never to
   `$self->pool` (karr k88; core's rule, dbio-async k46). `pool` builds
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
pipeline sync after an error result (karr k47), a COPY whose `put_copy_end`
returned -1 — EV::Pg hands the -1 on and keeps the callback queued (karr k57).
A late call returns without touching the Future or the pool. Where the
callback releases the connection, "ended" is a flag of its own (`copy_in`'s
`$phase`), never `$f->is_ready`: a cancelled Future is ready, and its
connection still has to go back.

EV::Pg can also **drop** a callback without calling it: the one it is
delivering to, when a call made inside it loses the connection in its flush
(`put_copy_data`, `put_copy_end`) or finishes it. That call still returns its
value — `put_copy_end` answers 1 on a connection libpq had already dropped.
A callback that would wait for another firing after such a call asks
`is_connected` first (karr k65).

EV::Pg croaks at dispatch *before* queueing the callback (*"not connected"*,
*"another command is already in progress"*): fail and release right there,
once. Create the callback in a named dispatch sub, not in the `->then`
closure, so it does not pin `$bind` for the query's flight.

A blocking call on the **storage** inside such a callback needs another
connection. Queued while callbacks on the call stack hold every connection of
the pool (`then` on a pooled statement or a `txn_do` coderef with
`pool_size => 1`; N nested ones with N), it is refused: `Future::await` takes
the caller out of the pool's queue (`_withdraw_waiter`) and **fails** it, so
the refused call never runs (karr k71). `Pool::_new_waiter` marks the queued
caller's Future, `Future::new` carries the mark down every `then`. A refusal
that leaves its caller queued and pending wedges the pool — the next release
hands the connection to a chain nobody holds. That holds for **every** way
`await` gives up while the Future hangs off a queued caller — the k71 refusal,
the k44 "more result(s) due" refusal, the loop running dry — through the one
`_withdraw_queued` (karr k85, k86); only a statement already on the wire
completes after a refusal. Not covered: a `txn_do` coderef that *returns* the
Future of a queued storage call (karr k87; needs a core seam). A connection that can still come
back (idle, connecting, statement in flight, held with no callback of its own
running) must not be refused: `t/56-blocking-on-empty-pool-mock.t`.

**A spawn that is running holds its slot like a callback does** (karr k88). A
caller is queued when the pool has no *room*, which is not "at its size": core
opens a connection synchronously inside `acquire` and the spawn keeps its slot
from before the conninfo provider is asked (`PoolBase`'s `_spawning`, core
k277), so a call made from inside it — the AccessBroker's answer, or a
callback the loop runs while the broker's client fetches — is queued behind
it, in a pool of one with no connection open. The connection is handed out
only after the spawn has returned, and the spawn is below that call on the
stack: a blocking wait there hung (any watcher keeping the loop alive, the
LISTEN connection for one) or died of a dry loop. `Pool::_pg_opening` counts
those slots, and with them the connection a connect statement is being
replayed on — counted by then, held by no callback, marked by
`Future->_replaying($conn)` in `_run_pool_connect_statement`.
`_pg_held_by_callbacks` takes both for held, and the refusal names how many
the pool is opening. A spawn alone is no reason to refuse: with another
connection busy with a statement in flight the call waits for that one. Not
seen: whatever else runs the loop inside a spawn, not through the connect
statement seam. `t/77` (mock) and `t/78` (live) hold it.

## Idle connections — the look before a borrow

EV::Pg's `on_error` tells the pool a connection died (karr k49) — from its read
watcher, so only while the EV loop runs. A program that only blocks runs it
for its own calls and no longer. `Pool::_idle_connection_alive` (core's
borrow-time seam, karr k72) covers the idle connection nobody read of; core
retires what it does not vouch for, quietly, and takes the next or spawns.

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
is called from `io_read_cb` alone (Pg.xs, 0.02 and 0.07) — so there is no
"let libpq read, then ask libpq" as on `future_io`.

`POLLRDHUP` has no name in Perl and its value is the platform's: `_pg_rdhup`
measures the bit once per process on a socket pair, and answers 0 where `poll`
does not behave so — the pool then vouches as before. Not seen: a session
ending after the look, or in the milliseconds between a backend's last message
and its exit (5–7 ms on PostgreSQL 18.6); a peer gone without closing. TLS is
not measured (the look is at the TCP connection underneath).

A handle handed **straight from a release to a queued caller** is never asked
about; there the dispatch's croak and `_pg_report_if_dead` are still the only
report (`t/41` d, `t/32`). A fake `EV::Pg` answers `is_connected`,
`pending_count` and `socket` (`-1`: nothing to look at, vouched for). `t/57`
holds every branch on real sockets, `t/63` against a server.

## Transactions

Core's `txn_do_async` pins one pooled connection, runs the coderef inside the
`BEGIN`'s callback, and sends `COMMIT` only once every statement the context
handed out has settled without failure, else `ROLLBACK` (core k236); it ends
the context as it sends either (core k237). In the coderef use `$ctx->*_async`
and chain with `then` — blocking `$ctx` methods are refused. This transport
adds:

- `_query_async_pinned` sends the pinned connection's statements one at a time
  in issue order (the next goes out before the previous one's Future settles),
  so a coderef that dies mid-flight still gets a clean `ROLLBACK`; a statement
  issued on the connection after `COMMIT`/`ROLLBACK` fails at once. Pipeline
  mode bypasses the queue.
- `_txn_commit_rolled_back` reads `$pg->result_meta->{cmd_status}`: a `COMMIT`
  PostgreSQL answers with `ROLLBACK` fails the transaction.

## Pipeline

`pipeline(\&batch)` brackets ONE pooled connection with libpq pipeline mode
and hands the block a `DBIO::Storage::Async::PipelineContext`; only calls on
that context are batched.

```perl
my @rows = $async->pipeline(sub {
  my ($batch) = @_;
  $batch->future_class->needs_all(
    map { $batch->insert_async($source, { msg => $_ }) } @msgs
  );
})->get;
```

## LISTEN/NOTIFY

`listen`, `unlisten`, `notify`, `listen_alive`, `listen_reconnect`, the hooks
and the backoff are core's (core ADR 0056): registry, one dedicated
connection, one channel operation at a time, self-healing, fork guard. The
seam obligations are in skill `dbio-driver-development`, "LISTEN / NOTIFY —
core contract, transport seams". Never override the public methods here.

This class fills the seams with EV::Pg, socket-driven:

| Seam | Here |
|---|---|
| `_listen_open` | a new fork-safe handle from `Pool->_new_connection`, `keep_alive`, current conninfo (broker asked anew); no connect-action replay |
| `_listen_close` | quiet the handlers, `finish` |
| `_listen_subscribe` / `_listen_unsubscribe` | `LISTEN` / `UNLISTEN` with `_pg_quote_channel` → `DBIO::PostgreSQL::Util::quote_channel` (one identifier, over 63 bytes refused) |
| `_listen_watch` / `_listen_unwatch` | switch what `on_notify` / `on_error` do; notifications before watching are held, then delivered |
| `_listen_probe` | `is_connected`, no round trip |
| `_listen_delay` | an `EV::timer` |
| `_notify_send` | pooled `SELECT pg_notify($1, $2)`, binds only |

Private helpers are `_pg_*`, never `_listen_*`: they share an inheritance chain
with core's `_listen_*` privates. A listen callback gets `($channel, $payload,
$sender_pid)`.

## COPY

`$async->copy_in($table, \@columns, sub { my ($put) = @_; $put->(\@row) })` —
COPY FROM STDIN, PostgreSQL text format. The coderef runs to its end inside
EV::Pg's callback: what the server has not read by then waits in libpq's
output buffer, in client memory.

A COPY ends in one place, `$end`, and how it ends decides (karr k65):

- the Future fails with the coderef's error before any other;
- a COPY the server answered leaves its connection in the pool; one that ends
  with its stream open — `put_copy_end` answered -1, croaked, or answered 1
  on a connection that is gone — is retired;
- the writer dies for a row `put_copy_data` did not take (0: libpq could not
  grow its buffer; -1) and for every row after it, and the COPY fails with
  that even when the coderef catches the die; called outside its COPY it dies
  too.

What `put_copy_data` / `put_copy_end` answer, and when, is read at Pg.xs and
libpq's `fe-exec.c` (`PQputCopyData`, `PQputCopyEnd`), never from memory.
`t/73` holds every end against a fake that keeps libpq's state, `t/74`
against a server.

## Transport capabilities and the thin transport

`transport_capabilities` is exactly `on_connect_replay listen notify copy
pipeline broker_connect_options`. The orchestration — CRUD runner, `txn_do_async`, `deploy_async`,
`sql_maker`, the sync `->get` fallbacks, the LISTEN/NOTIFY API, `disconnect` —
is core's; `t/06-thin-transport-structure.t` fails if it is redefined here.
This class fills seams only (the ones above, plus `connect_info`,
`_txn_context_class`, `_txn_conn_accessor` = `'txn_conn'`, `_ddl_class` =
`DBIO::PostgreSQL::DDL`) and adds `copy_in`.

## Never write

- `$storage->async_backend(...)` — no such method in core; the opt-in is `{ async => 'ev' }`.
- `load_components('PostgreSQL::EV')` as the activation — it activates nothing.

## Dependencies and testing

`cpanfile` holds the pins. `EV::Pg` is `>= 0.02, < 0.08`: 0.02.x runs on
libpq 15, 0.07.x needs libpq 16+ (`maint/docker/README.md`).

Offline mocks replace `EV::Pg` in a `BEGIN` block (`$INC{'EV/Pg.pm'}`) and
drive the real storage and pool on EV timers. Call `EV::now_update()` before
arming a watchdog or timed wait: a timer counts from the loop's cached "now".

```bash
env -u DBIO_TEST_PG_DSN ../dbio/maint/capped-test prove -lr t/    # offline
```

Live files need `DBIO_TEST_PG_DSN` / `_USER` / `_PASS` and self-skip without
them; same wrapper, one at a time, never `prove -j` (how to run: `CLAUDE.md`).

A live file reads the test login and opens connections of its own through
`t/lib/LiveServer.pm` (`use lib "$FindBin::Bin/lib"`, karr k77), never by hand:
`conninfo` is the login as the transport reads static connect info
(`dbi_to_conninfo` with `env => 1` — no split at `;` and `=`; `DBI_USER` /
`DBI_PASS` for a user or password the login leaves undefined, as DBI reads
them for `control_dbh`), `control_dbh` the observer / sender / locking session,
`require_server` the gate for a file without one. With `DBIO_TEST_PG_DSN` set
and no server behind it the file **fails** — one failed test, the reason
masked, a plan — it does not skip and does not die before its plan.

A process has one alarm (karr k88, core k300). A test file sets it once, at
file level and without a handler — `alarm 120;` — as its backstop, and never
clears it. A wait that wants a timeout and a message of its own goes through
`t/lib/GuardedWait.pm`: `until_ready($f, $seconds, $message)` runs the loop
and returns the Future, done or failed; `run($code, $seconds, $message)` is
the same guard around a blocking call. Both borrow the alarm through core's
`DBIO::Test::AsyncHarness::await` and give it back, due when it was due. No
`alarm 0`, no `$SIG{ALRM}`, no second `alarm` in a test file: `t/80` fails on
each, `t/79` holds the helper.
