# ADR 0011 — A statement handle DBD::Firebird has destroyed is replaced when it comes out of the cache

- Status: accepted
- Date: 2026-10-07
- Tags: storage, statement-cache, dbd-firebird, ddl, transactions

## Context

A process that read through the ORM, ran DDL on the same connection and read
again got no row and no error (karr k37): `find(1)` answered `undef`, with only
a `no statement executing` warning from `DBD::Firebird`. Every later call of
that statement stayed empty until the storage reconnected.

The cause is in the DBD, read from the source of `DBD::Firebird` 1.39
(`dbdimp.c`) and measured against Firebird 5.0.4:

- The DBD counts DDL statements per connection (`imp_dbh->sth_ddl`).
  `ib_commit_transaction` and `ib_rollback_transaction` then walk the
  connection's list of statements and call `dbd_st_finish` and
  `dbd_st_destroy` on **every one of them** — the statement is dropped on the
  server, its `in_sqlda` and `out_sqlda` are freed. This happens on the commit
  that follows any DDL (with `ib_softcommit` too: the retaining branch is taken
  only while `sth_ddl` is 0), on every hard rollback outside AutoCommit — so on
  every rolled-back `txn_do` of a connection without `ib_softcommit` — and in
  `ib_set_tx_param` under AutoCommit (read, not measured).
- The Perl handles know nothing of it. They stay in `$dbh->{CachedKids}`, and
  `prepare_cached` — which core's `_prepare_sth` uses unless
  `disable_sth_caching` is set — keeps handing them out.
- A destroyed handle fails quietly. `bind_param` answers false without an
  error. `execute` of a `SELECT` answers `0E0` and the fetch warns.
  `execute` of an `INSERT` or `UPDATE` answers `undef` (measured; not `0E0`
  and not an error), **writes nothing and reports nothing**. Only `INSERT ... RETURNING` dies (`invalid statement
  handle`).

It is any DDL on the connection, not DDL on the statement's own table, and
calling `finish` first changes nothing.

The card left three ways open: drop the statement cache after DDL, reconnect,
or make `disable_sth_caching` the default of this driver.

## Decision

**`DBIO::Firebird::Storage::InterBase` overrides `_prepare_sth`: when the
handle that comes out of the statement cache is one the DBD has destroyed, the
storage lets it go, empties `CachedKids`, and prepares the statement again.**
The cache stays on, and a handle that is alive is returned as it was.

Whether a handle is alive is asked of the DBD, locally, in `_sth_is_alive`:
`bind_param` for a placeholder number one above `NUM_OF_PARAMS`. `dbd_bind_ph`
answers that with true and binds nothing on a live handle
(`param > in_sqlda->sqld`), and with false on a destroyed one
(`!imp_sth->in_sqlda`). No statement goes to the server for it.

The override is on `Storage::InterBase` and not on `Storage::Common`: it is a
fact about the API of one DBD, not about the SQL of the engine
([ADR 0010](0010-odbc-transport-branches-off-storage-common.md)), and
`Storage::ODBC` does not get it.

## Rationale

- **Not a cache drop after Deploy.** DDL reaches a connection by other roads —
  `$storage->dbh_do(sub { $_[1]->do('ALTER TABLE ...') })` is ordinary user
  code — and the rollback case involves no DDL at all. A hook on the paths
  this distribution owns would fix its own test and leave the rest.
- **Not by recognising DDL in the SQL.** The DBD decides by the statement type
  the server reports; a pattern over SQL text would be a second, weaker copy of
  that decision. Asking the handle covers every cause with one question,
  including causes not listed here.
- **Not a reconnect.** The DBD leaves the connection intact. A reconnect would
  throw away the transaction and the session's state to repair something that
  one prepare repairs.
- **Not `disable_sth_caching` by default.** It would be complete, at the price
  of a prepare round trip for every statement of every user — and a user who
  switched caching back on would have the silent write loss back.
- **The whole cache, not the one entry, and the old handle first.** This is a
  second fact about the DBD's list, measured: `dbd_st_destroy` unlinks its
  statement unconditionally, and Perl runs it again when the handle is finally
  freed. For a statement that is already unlinked, that second run sets
  `first_sth = last_sth = NULL` — every statement prepared in between is alive
  but off the list. The DBD then no longer destroys it before a DDL commit, and
  a later `DROP TABLE` on its table over that connection fails with `object
  TABLE "..." is in use`. Evicting destroyed handles one by one, as their SQL
  comes up again, would do that to each handle prepared since; so all of them
  go at once, before the replacement is prepared. A live handle thrown out
  along the way costs one prepare.

## Consequences

- **Reading and writing through the ORM across DDL on one connection works**,
  and so does a rolled-back `txn_do` without `ib_softcommit`.
  `t/23-statement-cache-ddl-live.t` holds that — including that the write after
  DDL reaches the table, that the cache is still used, and that a table can be
  dropped afterwards — and `t/63-statement-cache-dead-handle.t` holds offline
  what `_prepare_sth` does.
- **One local XS call more per prepared statement.**
- **The check rests on undocumented DBD behaviour**, and the live test pins it
  by name: a prepared handle answers true, the same handle after DDL answers
  false. If a later `DBD::Firebird` answers false for a live handle, every
  statement is prepared anew — slower, not wrong; the override does not ask a
  second time. If it answers true for a destroyed one, the live test goes red.
- **`DBD::InterBase` is assumed, not measured.** The class serves that DBD
  too; that its `dbd_bind_ph` answers the same follows from the fork
  relationship only.
- **An open cursor is not rescued.** A result set that is still being read
  when the DBD destroys the statements ends there; the storage can re-prepare,
  it cannot resume. And a destroyed handle that something else still holds
  empties the DBD's list whenever it is freed — the storage cannot reach that.
- **The cause stays where it is.** Destroying statements the application still
  holds without marking them, and unlinking a statement twice, are
  `DBD::Firebird` matters; this ADR works around the first and steps around
  the second, and can be withdrawn when the DBD stops doing them.

## Addendum 2026-10-18 (karr k48, k49)

Measured on Firebird 5.0.4 / DBD::Firebird 1.39 with raw DBI
(`t/33-dbd-statement-list-live.t`, draft `maint/upstream/dbd-firebird-destroys-held-statements.md`):

- The second destruction of a handle the DBD has already destroyed empties
  its list of statements; a statement prepared since is then alive, off the
  list, and holds its table. It reaches the storage wherever something other
  than the statement cache holds a handle across DDL or a rollback -- a cursor
  being read, a handle taken from `$storage->dbh` -- and is freed later. The
  cache is kept clean (above); a `DROP TABLE` the server then refuses is loud.
- **A DDL commit the server refuses is not rolled back by the DBD.** The
  transaction stays, every later statement on the handle fails with the same
  error (the ping's `select` too), `rollback` under AutoCommit is "ineffective",
  `begin_work` + `rollback` clears it. core's `dbh_do` retries when
  `! $storage->connected`; with a `_ping` that only ran the select, the refused
  DDL read as a dead connection, was repeated on a new one where nothing held
  the table, and reported success -- session state and `on_connect_do` effects
  of the old connection gone (karr k49, `t/32-failed-ddl-no-reconnect-live.t`).
  `Storage::InterBase::_ping` now clears that state itself when AutoCommit is
  on (no transaction of the application is on the handle) and asks once more;
  a dead connection still fails the second time, or in `begin_work` (the
  second case is the code's guard against a handle that is already inside a
  transaction; it did not occur with DBD::Firebird 1.39 and is not measured). With
  AutoCommit off nothing is rolled back and a failed select is a dead handle
  as before. The retry rule in core is unchanged: it is right for a dead
  connection, and this driver no longer reports one for a live handle.
- Not reproduced deterministically: a process abort (`malloc(): unaligned
  tcache chunk`, `corrupted size vs. prev_size`) at the end of a process that
  used statements the DBD had destroyed (karr k45; see
  `maint/upstream/dbd-firebird-heap-corruption-notes.md`). The storage never
  executes a destroyed cached handle (`_sth_is_alive`), which is the only
  part of that lane it can close.
