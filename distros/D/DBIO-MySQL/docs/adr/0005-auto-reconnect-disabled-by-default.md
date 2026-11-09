# ADR 0005 — `auto_reconnect` is forced off by default

- Status: accepted; the MySQL hook point amended 2026-09-26 (karr k57), the
  attribute name keyed on the handle's DBD 2026-09-26 (karr k59); see below
- Date: 2026-06-20
- Tags: storage, transactions, safety, mariadb, backfill

## Amendment (2026-09-26, karr k57) — the MySQL arm runs on connect, not after the first insert

The policy stands unchanged: auto-reconnect off by default, an explicit value
in `connect_info` honoured, and the `exists` check stays. What changed is where
the MySQL arm runs.

`_dbh_last_insert_id` is called only when an INSERT fetches a generated key, so
piggybacking there applied the default only after the first such insert on each
handle. A fresh handle, and every reconnect, kept whatever DBD::mysql chose at
connect. DBD::mysql switches `mysql_auto_reconnect` on by itself when `MOD_PERL`
or `GATEWAY_INTERFACE` is set. So a transaction opened before the first insert
ran with auto-reconnect on, which is exactly the silent transaction loss this
ADR exists to prevent. Measured 2026-09-26 with DBD::mysql 4.055 against MySQL
8.0.30 under `MOD_PERL`: the fresh handle was on, it went off only after the
first insert, and it was on again after a reconnect. Test 54 of `t/10-mysql.t`,
"auto_reconnect unset regardless of ENV", asserted the documented default on a
fresh handle and failed.

The MySQL arm now lives in `DBIO::MySQL::Storage::_run_connection_actions`, the
same hook as the MariaDB arm and as upstream DBIx::Class. It runs on every new
handle before the storage hands it out, then calls `next::method`.
`_dbh_last_insert_id` only returns `mysql_insertid`. The Consequences below
should now read: both engines use `_run_connection_actions`, and a refactor
must still not drop either arm.

The MariaDB override still calls `DBIO::Storage::DBI::_run_connection_actions`
directly instead of `next::method`. That bypass now matters: it skips the
parent's arm, and that arm must not run on a DBD::MariaDB handle. DBD::MariaDB
refuses to FETCH `mysql_auto_reconnect` ("Unknown attribute"), and with
`RaiseError` on that fails the connect. Anything added to the parent's
`_run_connection_actions` later is skipped for DBD::MariaDB in the same way.
The same error now shows up earlier when a configuration pins
`DBIO::MySQL::Storage` over a `dbi:MariaDB:` DSN (`load_components('MySQL')`
with DBD::MariaDB). `t/05-use-dbio-schema.t` already treats that mismatch as
unsupported. It used to fail at the first auto-increment insert and now fails
at connect.

`t/10-mysql.t` pins both halves live under DBD::mysql. Test 54 checks that a
fresh handle is off under `MOD_PERL`. Test 56 checks that an explicit
`mysql_auto_reconnect => 1` survives the reset. Test 56 could not catch a
dropped `exists` check before, because no insert came first. Each was
confirmed by a mutation run: without the reset, 54 fails, and without the
`exists` check, 56 fails.

## Addendum (2026-09-26, karr k59) — the attribute name comes from the DBD on the handle

This addendum supersedes the k57 amendment wherever the two disagree. The
policy is unchanged. What changed is how the storage finds the attribute's
name.

k57 spelled `mysql_auto_reconnect` in `DBIO::MySQL::Storage`. The storage
class does not tell you the DBD. `DBIO::MySQL::connection` pins
`+DBIO::MySQL::Storage` for every DSN, so `load_components('MySQL')` over a
`dbi:MariaDB:` DSN runs the parent class on a DBD::MariaDB handle. DBD::MariaDB
dies on a FETCH of any `mysql_*` attribute ("Unknown attribute"), and with
`RaiseError` on every such connect died. The insertid read had the same flaw:
`mysql_insertid` dies there too. Before k57 that combination died at the first
auto-increment INSERT, for both reasons at once.

The k57 amendment called this combination "unsupported" and cited
`t/05-use-dbio-schema.t`, which treated it as a mismatch. That was wrong.
`DBIO::MySQL` picks a storage class and the DSN picks the DBD, and nothing in
the component's contract ties the two together. DBD::MariaDB is this dist's
recommended DBD and reaches MySQL servers. dbio-mysql-ev connects with exactly
`load_components('MySQL', 'MySQL::EV')` over `dbi:MariaDB:` (its test harness,
`t/17-upsert-live.t`, `t/25-sync-fallback-live.t`). After k57 every sync connect
there died. `t/05` was steering around a bug, not documenting a limit.

**Decision.** Each DBD's attribute names live in one table in
`DBIO::MySQL::Storage`. `_dbd_attribute($dbd, $what)` answers
`mysql_auto_reconnect` / `mysql_insertid` for `mysql`, and
`mariadb_auto_reconnect` / `mariadb_insertid` for `MariaDB`. For any other DBD
it throws rather than guess. Two kinds of caller use it:

- The sync storage asks with the DBD on the handle, `$dbh->{Driver}{Name}`.
  `_run_connection_actions` resets that DBD's auto-reconnect.
  `_dbh_last_insert_id` reads that DBD's insertid. The `exists` check looks
  only at that DBD's name. The other DBD's name in the connect attributes does
  not configure this handle, so it does not stop the reset.
- The future_io transports ask with the DBD their binding drives
  (`DBIO::MySQL::Storage::Async` for `mysql`,
  `DBIO::MySQL::Storage::MariaDB::Async` for `MariaDB`), through
  `_mysql_auto_reconnect_attr`. They need the name for the pool and listen
  connect attributes, before any handle exists. Their per-statement insertid
  stays one of their binding primitives (ADR 0007) and is not in the table.

`DBIO::MySQL::Storage::MariaDB` no longer overrides `_run_connection_actions`
or `_dbh_last_insert_id`. The parent serves both DBDs, so the call on a
DBD::MariaDB handle runs through `next::method` again, like on DBD::mysql. The
k57 amendment's warning no longer applies: the bypass of
`DBIO::Storage::DBI::_run_connection_actions` is gone, and with it the rule that
anything added to the parent was skipped for DBD::MariaDB. No `@ISA` changed.

**Consequences, replacing the k57 wording.** One hook serves both DBDs:
`DBIO::MySQL::Storage::_run_connection_actions`. A refactor must not key the
attribute on the storage class again. The Decision section's two bullets below
(the MySQL arm in `_dbh_last_insert_id`, the MariaDB arm in the subclass) are
history.

Measured 2026-09-26 against MySQL 8.0.30. DBD::mysql 4.055 turns auto-reconnect
on by itself under `MOD_PERL` or `GATEWAY_INTERFACE`, and DBD::MariaDB 1.24
does not. On DBD::MariaDB the reset is therefore defensive. It must hold there
anyway, and the connect must not die.

**Tests.** `t/64-dbd-attributes.t` covers both DBDs offline, with a fake handle
that behaves like each real DBD. It checks the fresh handle and a reconnect, an
explicit value, the other DBD's name, the insertid, and the refusal of an
unknown DBD. `t/05-use-dbio-schema.t` now runs `load_components('MySQL')` live
against whichever DSN it is given. It checks auto-reconnect off under
`GATEWAY_INTERFACE` and `MOD_PERL`, an auto-increment id that matches the row
written, and an explicit value that survives. Mutation runs: with k57's storage
restored, `t/05` dies at connect over `dbi:MariaDB:` ("Unknown attribute
mysql_auto_reconnect", exit 11). Without the reset, `t/05` fails over
`dbi:mysql:`. With `mysql_insertid` hard-coded, `t/05` dies at the insert over
`dbi:MariaDB:`. Without the `exists` check, the explicit-value test fails.

**Still open.** `{ async => 'future_io' }` under the same pinned combination
resolves `DBIO::MySQL::Storage::Async`, the DBD::mysql binding. It picks the
transport by the storage class (ADR 0007), so it still fails against a
DBD::MariaDB DSN. Changing that is beyond this addendum and is recorded on
karr k60.

**Update (2026-10-04, karr k60).** Closed offline: the future_io transport asks
`_dbd_attribute` with the DBD of the DSN being connected, not with a DBD fixed
per transport class, and its async binding is in the same table (ADR 0007
addendum). The second bullet of the Decision above is history.

## Context

`DBD::mysql` and `DBD::MariaDB` can transparently reconnect a dropped
connection mid-session (`mysql_auto_reconnect` / `mariadb_auto_reconnect`).
That is convenient for fire-and-forget scripts but catastrophic for a
transactional ORM: a silent reconnect inside an open transaction restarts the
session on a *fresh* connection, so the in-flight transaction is gone, locks
are released, and `SET`-based session state (strict mode, `FOREIGN_KEY_CHECKS`,
savepoints) evaporates — with no error surfaced to the application. The work
appears to continue and quietly commits outside the intended transaction
boundary.

DBIx::Class disabled this for the same reason. DBIO must preserve that safety
default across both DBD drivers.

## Decision

Force the DBD auto-reconnect attribute **off** by default, in both storage
classes, unless the user explicitly set it in `connect_info`.

- `DBIO::MySQL::Storage::_dbh_last_insert_id` clears
  `mysql_auto_reconnect` on the live handle when it is on and the user did not
  set it explicitly (`! exists $self->_dbio_connect_attributes
  ->{mysql_auto_reconnect}`).
- `DBIO::MySQL::Storage::MariaDB::_run_connection_actions` does the same for
  `mariadb_auto_reconnect` before delegating to the base connection actions.
- The guard is conditional on the user *not* having set the attribute: an
  explicit `{ mysql_auto_reconnect => 1 }` in `connect_info` is honoured. The
  default is safe; the override is the user's informed choice.

## Rationale

Silent transaction loss is the worst failure mode an ORM storage layer can
have — it corrupts data with no error. A safe-by-default that the user can
explicitly opt out of is the correct trade: the common case (transactional
work) is protected, and the rare legitimate use of auto-reconnect (a
long-running read-only poller) is still reachable by setting the attribute
deliberately. Honouring an explicit `connect_info` value rather than hard
-forcing off keeps the override path open without making the dangerous
behaviour the default.

## Consequences

- Both engines must keep this guard; the MariaDB subclass hooks
  `_run_connection_actions` while MySQL piggybacks on `_dbh_last_insert_id`
  (where it already touches the live handle). These are two different hook
  points for the same policy — a refactor must not drop either arm.
- An explicit user `auto_reconnect` in `connect_info` is respected by design;
  do not "fix" the `exists` check away.
- This is a driver-local safety default, not a core contract; core does not
  know about the DBD-specific attribute names.
