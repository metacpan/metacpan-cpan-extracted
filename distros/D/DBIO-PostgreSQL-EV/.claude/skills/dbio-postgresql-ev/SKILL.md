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

## Connect info and AccessBroker

Users connect with a `dbi:Pg:` DSN; libpq conninfo is the transport-internal
shape, rendered by `conninfo_string` for `EV::Pg->new`. One reader,
`Storage::_pg_read_connect_info`, reads connect info wherever it comes from —
what `connect_info` is given, what a broker answers at attach and for every
connection — into the `[ \%conninfo, \%opts ]` pair, so the dbh and the pool
end up in the same place as the same user. A rule about connect info lives in
the reader, never as a guard at a caller. `dbi_to_conninfo` is a step-by-step
port of DBI and DBD::Pg and changes only against their source
(`t/53-dbi-to-conninfo.t`). No message quotes a password: connect-info texts
go through core's `DBIO::Util::mask_connect_secrets` (`t/65`). A broker is
asked anew for every pool spawn and listen open (`_async_broker_conninfo`);
a connection parameter beside a broker is refused, never dropped.

The accepted forms, `dbi_to_conninfo` semantics, the broker rules and
`broker_connect_options`: `references/connect-info.md`.

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

The maker quotes as the connection says:
`_sql_maker_args` takes `quote_char` (when defined) and `name_sep` from the
owning sync storage's `sql_maker` — through `_owner_storage`, never
`_effective_owner_storage`, whose private sibling shares this very maker. A
backend without an owner keeps `"` and `.`; `limit_dialect` stays
`LimitOffset`. `t/102` holds it.


## Refusals

What the transport refuses is a `DBIO::Exception` at the caller's place:
`_pg_refuse($message, $connect_info)`, a function, never `croak` (the
`future_io` transport does the same). It throws through package `…::Storage::_Refusal`,
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
only delegates to it, as the `future_io` transport does (`t/85`).

A `?` is a placeholder where PostgreSQL reads SQL. What its scanner
(`scan.l`) reads as something else is passed over as a whole: `'...'` and
`"..."`, `E'...'` with its backslashes, a dollar-quoted body (`$$`, `$tag$`),
a `--` comment, a `/* */` comment (nests); a run never closed goes to the end.
The measure is the server, not DBD::Pg, which reads less (no nesting, no
lowercase `e`). So a layer may send a `$$` body through `_query_async`
(dbio-postgresql-age does), and literal SQL that runs over the dbh runs here
with the same binds — except what is not read: `:name` (DBD::Pg's own) and
`standard_conforming_strings = off`.

Outside such text every `?` is a placeholder, behind an operator character
too — no operator is known: `col <@?` → `col <@$1`,
`@? ?` → `@$1 $2`, as DBD::Pg reads it at the dbh. `\?` is a literal question
mark and loses its backslash: the way to write the operators `?`, `?|`, `?&`
and `@?`, over the dbh and here alike. The maker writes the jsonpath operator
so: `@\? ?::jsonpath` goes out as `@? $1::jsonpath`, and `as_query` shows
`@\?`. `$N` already there passes through; `$N` beside a `?` placeholder is
refused, and `SELECT a @? $1::jsonpath` is such a mix. A statement is shaped
once: the `?` a `\?` left is a placeholder to a second pass. `t/03` and `t/85`
hold it, `t/24` against the dbh of a server.

## Callbacks handed to EV::Pg and the pool

Every callback this class gives EV::Pg to settle a Future returns at once in a
forked child, marks its connection (`Future->_delivering($pg)`), settles the
Future before the release (`_pg_settle_and_release`), reports a dead
connection (`_pg_report_if_dead`) and talks to the pool the connection was
acquired from, never to `$self->pool`. Callbacks are created in a named
dispatch sub. A blocking call on the storage inside a callback needs another
connection and is refused when the pool has none to give. Idle connections get
a look before a borrow (`Pool::_idle_connection_alive`): dead only where
certain, readable never dead.

The pattern in full, the late/dropped callback cases, blocking behind a
running spawn and the idle look: `references/callbacks-and-pool.md`.

## Transactions

Core's `txn_do_async` pins one pooled connection, runs the coderef inside the
`BEGIN`'s callback, and sends `COMMIT` only once every statement the context
handed out has settled without failure, else `ROLLBACK`; it ends
the context as it sends either. In the coderef use `$ctx->*_async`
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
seam obligations are in skill `dbio-driver-development`, `references/async-transport.md`,
section "LISTEN / NOTIFY — core contract, transport seams". Never override the public methods here.

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

A COPY ends in one place, `$end`, and how it ends decides:

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

## Dependencies and testing

`cpanfile` holds the pins. `EV::Pg` is `>= 0.09`, no upper bound: it guards
fork itself and clears `error_fields` on a lost connection; it still
references libpq 16 symbols, so libpq 15 needs `maint/docker/README.md`.

Offline mocks replace `EV::Pg` in a `BEGIN` block (`$INC{'EV/Pg.pm'}`) and
drive the real storage and pool on EV timers. Call `EV::now_update()` before
arming a watchdog or timed wait: a timer counts from the loop's cached "now".

```bash
env -u DBIO_TEST_PG_DSN ../dbio/maint/capped-test prove -lr t/    # offline
```

Live files need `DBIO_TEST_PG_DSN` / `_USER` / `_PASS` and self-skip without
them; same wrapper, one at a time, never `prove -j` (how to run: `CLAUDE.md`).
The maintainer's own database for live runs is `dbio_pgev`; its login comes
from `dbio-db env postgresql`.

A live file reads the test login and opens connections of its own through
`t/lib/LiveServer.pm` (`use lib "$FindBin::Bin/lib"`), never by hand:
`conninfo` is the login as the transport reads static connect info
(`dbi_to_conninfo` with `env => 1` — no split at `;` and `=`; `DBI_USER` /
`DBI_PASS` for a user or password the login leaves undefined, as DBI reads
them for `control_dbh`), `control_dbh` the observer / sender / locking session,
`require_server` the gate for a file without one. With `DBIO_TEST_PG_DSN` set
and no server behind it the file **fails** — one failed test, the reason
masked, a plan — it does not skip and does not die before its plan.

A process has one alarm. A test file sets it once, at
file level and without a handler — `alarm 120;` — as its backstop, and never
clears it. A wait that wants a timeout and a message of its own goes through
`t/lib/GuardedWait.pm`: `until_ready($f, $seconds, $message)` runs the loop
and returns the Future, done or failed; `run($code, $seconds, $message)` is
the same guard around a blocking call. Both borrow the alarm through core's
`DBIO::Test::AsyncHarness::await` and give it back, due when it was due. No
`alarm 0`, no `$SIG{ALRM}`, no second `alarm` in a test file: `t/80` fails on
each, `t/79` holds the helper; it skips where `Time::HiRes::alarm` is not
implemented or the perl has no `fork`, and `t/121` runs it against a
`Time::HiRes::alarm` that dies, so the skip holds on every host.
