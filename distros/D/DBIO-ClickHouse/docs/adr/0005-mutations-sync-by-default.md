# ADR 0005 — Mutations wait by default (`mutations_sync = 1`)

- Status: accepted
- Date: 2026-07-26

## Context

ClickHouse has no `UPDATE` and no `DELETE` statement. Changing stored rows is a
**mutation**, issued as `ALTER TABLE t UPDATE col = expr WHERE ...` or
`ALTER TABLE t DELETE WHERE ...`. That is not a syntax quirk: a mutation is a
background job that rewrites every data part containing a matching row. The
statement that submits it and the work it describes are two different things.

By default (`mutations_sync = 0`) the statement returns as soon as the mutation
is *queued*. The rows change at some unspecified later point; an error during
the rewrite is never reported to the client that submitted it; and a `SELECT`
issued immediately afterwards over the same connection may still return the old
values. This is a sound default for a database whose bulk-mutation jobs run for
minutes — and it is incompatible with essentially every line of ORM code ever
written, all of which assumes that a write is visible to the read after it.

The setting has three values, and a mutation statement can carry its own:

- `0` — queue and return.
- `1` — wait until the mutation has been applied on the server the statement
  was sent to.
- `2` — wait until it has been applied on *all* replicas.

Three questions had to be answered together, because the answers constrain each
other:

1. **Do we wait at all, and how far?** Leaving the server default means DBIO
   would sometimes read stale rows right after writing them, on a driver whose
   whole selling point is that the ORM API works.
2. **Where does the setting live?** Session state (`SET mutations_sync = …` via
   `on_connect_do`) or a per-statement `SETTINGS` clause.
3. **What do `update` / `delete` return?** Core's `DBIO::Row::_update_body`
   throws on a `0` return ("row not found") and above `1` ("updated more than
   one row"), so the return value is not free-form — but ClickHouse reports
   nothing about how many rows a mutation matched. The affected-rows count on
   the wire is `0` whether the mutation touched a million rows or none.

## Decision

**1. Mutations are synchronous by default, at level 1.** Every `UPDATE` and
every `DELETE` this driver renders carries `SETTINGS mutations_sync = 1`.

`1`, not `2`. Level 1 is the guarantee an ORM session actually needs and the
only one it can verify: read-your-own-writes over the connection that did the
write. Level 2 is a *cluster* guarantee, it costs a round trip to every
replica, and it blocks — or fails — when any replica is unreachable, which
turns a routine `$row->update` into a availability dependency on machines the
caller never addressed. A single-server deployment (what a developer runs, and
what the live suite runs) cannot tell 1 and 2 apart anyway. Level 2 is the
right answer for read-after-write across replicas, and it is one connect-time
attribute away.

Not defaulting at all (`undef`, keep the server's `0`) was rejected on the same
grounds as the silent-no-op transaction option in ADR 0003: an API that
*appears* to have written is worse than one that is slow.

**2. The setting is rendered per statement, not set per session.** The
`SETTINGS mutations_sync = N` clause is emitted by
`DBIO::ClickHouse::SQLMaker`'s `update` / `delete`. A session-level `SET` would
depend on `on_connect_do` surviving every reconnect and every pooled handle,
and would be invisible in the SQL — where the statement itself carries it, what
was asked for is what was sent, and the offline tests can assert it.

**3. The value is a connect-time option with four states**, spelled
`mutations_sync` and routed to the SQL maker by extending
`_dbio_sql_maker_option_names` on the storage:

    MyApp::Schema->connect($dsn, $user, $pass, { mutations_sync => 2 });

`0`, `1` and `2` are rendered as given (an explicit `0` therefore *overrides* a
session default — asking for asynchronous is as explicit as asking for
synchronous). **`undef` emits no `SETTINGS` clause at all**, which is the
escape hatch that makes route 2's rejection non-absolute: a deployment that
manages the setting per session or in the server profile passes `undef` and
gets its own value back. Anything else throws when the SQL maker is built.

The extension point is `_dbio_sql_maker_option_names` rather than
`_dbio_storage_option_names` for a mundane reason: core's
`_normalize_connect_info` reads the storage-option list from a file-scoped
lexical captured at compile time and the SQL-maker list from a method call on
the live storage, so only the latter is overridable by a driver at all. That
also happens to be the correct home — the value is rendered into SQL, and
nothing on the storage consults it.

**4. `update` and `delete` return `-1`.** DBI's "number of rows is unknown".
Not `1` (a plausible-looking count that is a fabrication), not `'0E0'` (which
core's row-level path reads as "row not found" and throws on). `-1` satisfies
core's `0 < n <= 1` gate, so `$row->update` and `$row->delete` behave normally,
while being visibly not a row count anywhere a caller inspects it.

**5. Two constructs are refused rather than rendered.** `ALTER TABLE` can only
name one real table, so a mutation against a virtual view, a literal-SQL result
source or a join list throws with the subquery rewrite spelled out; and an
`UPDATE` with an empty column set throws, because `ALTER TABLE t UPDATE WHERE …`
has no valid form. An unrestricted `$rs->delete` is *not* refused — it renders
`WHERE 1`, ClickHouse's spelling of the "every row" that `DELETE FROM t` means
on every other driver.

## Consequences

- `$rs->update`, `$rs->delete`, `$row->update` and `$row->delete` work through
  the ordinary DBIO API, and a `SELECT` after one of them sees the new state.
- They are **slow**, in proportion to the part rewrite they now wait for. This
  is the cost of the decision and is documented as such: a mutation is a
  maintenance operation wearing DML clothing, and a per-request write path
  should append and read through a `ReplacingMergeTree` (or `FINAL`) instead of
  mutating. The driver makes mutations *correct*, not cheap.
- `if ($rs->delete > 0)` never fires. Code that needs a number must `count`
  before or after the mutation — the latter being meaningful precisely because
  of decision 1.
- A mutation is still not transactional and not atomic (ADR 0003). `mutations_sync`
  buys visibility, not atomicity: a mutation applied across several parts can be
  observed half-done by other readers, and there is nothing to roll it back with.
  Waiting only means *this* statement does not return before the work is done.
- Level 1 does not guarantee read-after-write for a client that reads through a
  different replica. Nothing in the driver can detect that topology, so it is a
  documented `mutations_sync => 2` case rather than an autodetected one.
- Unverified against a live server until the live suite (karr k8) runs: that
  ClickHouse's MySQL-wire handler accepts the trailing `SETTINGS` clause on an
  `ALTER TABLE ... UPDATE/DELETE`; that a mutation predicate may contain the
  `IN (SELECT …)` subquery core generates for complex resultsets; and that the
  affected-rows count really is `0` rather than something usable. The last one
  is the only finding that would reopen decision 4.

## Addendum (2026-10-17) — upgrade refuses a narrowing over NULL rows

- Status: accepted
- Extends: Consequences (a mutation is not atomic and cannot be rolled back)
- Ticket: karr k32

`MODIFY COLUMN c T` over a `Nullable(T)` column is the one upgrade statement
whose outcome depends on the data. The server accepts it, switches the column
metadata at once, and fails later in the background mutation if any part holds
a NULL (`CANNOT_INSERT_NULL_IN_ORDINARY_COLUMN`). Measured live on 25.3: the
column is then unreadable, every further mutation on the table hangs behind the
broken one, and the NULLs can no longer be counted (the type is already `T`).
Nothing rolls this back (ADR 0003), so the only safe moment is before.

Decision: `DBIO::ClickHouse::Deploy->apply` (and so `upgrade`) runs
`SELECT count() FROM t WHERE c IS NULL` for every such op **before the first
statement** of the plan and, on any NULL row, throws naming table, column, row
count and the by-hand remedy (`ALTER TABLE t UPDATE c = <value> WHERE c IS NULL
SETTINGS mutations_sync = 1`, then upgrade again). Nothing is executed. The diff
stays blind to data: the op only *answers* `needs_null_check` / `null_check_sql`;
`diff`, `as_sql` and `summary` never read a row.

Not decided, not built: filling the NULLs from the driver (a guessed value is
data the schema did not prescribe) and a `system.mutations` watcher after apply
(too late for this damage; useful only against a stale "up to date"). Only the
top-level `Nullable` (optionally under `LowCardinality`) is checked.
