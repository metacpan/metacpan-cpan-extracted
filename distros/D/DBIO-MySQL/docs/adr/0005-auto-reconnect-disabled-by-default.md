# ADR 0005 — `auto_reconnect` is forced off by default

- Status: accepted
- Date: 2026-06-20
- Tags: storage, transactions, safety, mariadb, backfill

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
