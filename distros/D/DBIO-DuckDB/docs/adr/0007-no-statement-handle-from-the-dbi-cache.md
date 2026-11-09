# ADR 0007 — This storage takes no statement handle from DBI's statement cache

- Status: accepted
- Date: 2026-10-07
- Tags: storage, statement-cache, dbd-duckdb, upstream-workaround

## Context

Core prepares through `_prepare_sth` in `DBIO::Storage::DBI`, which calls
`prepare_cached($sql, {}, 3)` unless `disable_sth_caching` is set. The same SQL
text therefore gets the same statement handle again: the second `create`, the
second `find`, the same search with another value.

A DBD::DuckDB 0.16 statement handle does not survive being used a second
time. Three defects in `DBD::DuckDB::st`, independent of one another, measured
on libduckdb v1.5.3 / DBD::DuckDB 0.16 / DBI 1.651 (karr k33):

1. **`finish` destroys the prepared statement.** It deletes `duckdb_stmt` from
   the handle; the handle stays in `CachedKids` and `prepare_cached` returns it
   dead. Core calls `finish` after an insert with `RETURNING`, in
   `select_single` (`find`, `single`) and after `execute_for_fetch`. Measured
   through the ORM: the second auto-increment `create`, the second `find` and
   the second `single` of one SQL shape die with `bind_param failed`; two
   `create` in one `txn_do` die the same way and the transaction rolls back;
   the second `populate` with the same columns ends the process with a
   segmentation fault (the failed execute is followed by a second `finish`,
   which hands libduckdb a `NULL` result).
2. **`execute` never sets `Active`.** `prepare_cached` with `if_active = 3`
   cannot tell a handle that is being read from a free one, so two open
   cursors of one SQL shape are given the same handle. Measured, read in turn:
   `x1 x1 -` and `x2 y1 -` where `x1 x2 x3` and `y1 y2 y3` were stored.
3. **`execute` keeps the chunk of the previous result.** `duckdb_chunk` and
   `duckdb_chunk_row` are only cleared when a chunk has been read to its end.
   A handle that is executed again before that goes on reading the old chunk.
   Measured, with no interleaving at all:
   `search({ rank => 1 }, { order_by => 'artistid' })->first` answers `x1`,
   then the same search for `rank => 2` answers **`x2`**, then `x3`. No error,
   no warning.

The third is the one that decides the matter: it returns wrong rows in
ordinary use, and nothing in the result says so.

The suite did not show any of it because no test ran a statement twice in a
way that mattered: over the whole suite the cache handed a used handle out
again in three files only — fully read `SELECT`s in
`t/43-random-and-explain.t`, an insert without `RETURNING` in
`t/45-numeric-bind-precision.t`, and one dead handle in
`t/47-disconnect-releases-file-lock.t`, whose `bind_param` error an `eval`
written for a different exception swallowed.

The card listed the mitigation as an open decision for the maintainer. It was
taken in the coordinating session of 2026-10-07 on the strength of the
measurements above, and is recorded here as that: a decision by measurement,
for the maintainer to overturn if he sees it differently.

## Decision

**`DBIO::DuckDB::Storage` takes no statement handle from DBI's statement
cache. Every execution prepares its statement afresh.**

It does so by answering core's own question: `disable_sth_caching`, the
accessor `_prepare_sth` reads, is overridden in `DBIO::DuckDB::Storage` as a
method that returns true whatever it is given.

- **A method, not a value.** A schema that declares no driver has its storage
  configured as the generic `DBIO::Storage::DBI` and reblessed into this class
  on the first use of the handle, and `connect_info` resets every storage
  option on each call (core ADR 0050). A value set by this class is not there
  on that path — measured for one set in `connect_info`: the DSN-resolved
  storage stays on the cache, and so does a storage that is told
  `disable_sth_caching(0)` afterwards. A method of the class has nothing to
  survive.
- **`disable_sth_caching => 0` is accepted and changes nothing.** The option
  is core's and a connect info shared between drivers may carry it; refusing
  it would break such a setup for no gain, and honouring it would hand back
  wrong rows on request. The accessor keeps answering true, so the state is
  visible to whoever asks.
- **No version bound**, unlike the statement release of ADR 0006. That one
  frees memory DBD::DuckDB owns and must not run against a release nobody has
  read. Not caching is correct against any release.

## Rationale — what was rejected

- **Recognising dead handles as they leave the cache** — the pattern
  dbio-firebird uses (`_sth_is_alive` in
  `DBIO::Firebird::Storage::InterBase`, its ADR 0011): ask the handle whether
  the DBD still has the statement, and prepare anew if not. There it is the
  whole problem; here it is a third of it. A handle that is alive but shared
  (defect 2) or alive but holding old rows (defect 3) passes that test.
- **A hybrid — reuse only handles that are clean.** It would have to read
  `duckdb_stmt`, `duckdb_index`, `duckdb_rows` and `duckdb_chunk` off the
  handle to judge it, and for defect 2 it would have to know that a handle is
  still held by a cursor, which nothing on the handle records. That is a
  second implementation of the DBD's own bookkeeping, resting on private
  state of a module that is about to change it, to save one prepare.
- **Clearing `CachedKids` after every `finish`.** Mends defect 1 only, for the
  same reason.
- **Leaving it to the setting**, documented. A default that returns the wrong
  row silently is not a default.

## Consequences

- The ORM claims hold on one connection: repeated `create`, `find`, `single`,
  `populate`, `first`, and cursors read side by side. Pinned in
  `t/49-statement-reuse.t`, on the declared storage, on the DSN-resolved one,
  and with `disable_sth_caching => 0` given at connect and set on the storage.
- **Cost: one `duckdb_prepare` per statement.** Alone it measured 0.24 to
  0.64 ms in-process. Through the ORM, on trivial statements against a
  2000-row table that took 3 to 5 ms each on a loaded shared machine, the
  uncached arm was 0.3 to 1.3 ms slower in eight of nine alternating pairs
  and faster in one: a consistent sign, of the size of one prepare, and of
  the same size as the spread between two runs of the same arm. Roughly a
  tenth on a statement that does next to nothing; statements that do real
  work were not measured.
- Statement handles now live only as long as their user. With ADR 0006 the
  statement behind each is freed when the handle is destroyed, so a
  long-lived connection no longer accumulates one prepared statement per
  distinct SQL text until `disconnect`.
- **Handles the application prepares itself are not covered.** Through
  `dbh_do`, a handle that is executed a second time, and any handle from
  `$dbh->prepare_cached`, has the defects above; the POD says so.
- **What is not mended here:** `finish` on a handle that has no result is a
  segmentation fault in DBD::DuckDB 0.16, cache or no cache. Core finishes
  after a bulk insert even when the insert failed, so a `populate` in void
  context whose rows are refused by the engine ends the process instead of
  throwing. That is a defect of its own with a remedy of its own, and is
  reported on the card, not decided here. (Mended since, karr k38: ADR 0006,
  addendum 2026-10-08.)

## When the cache can come back

Giving the cache back is a decision, not a version check that flips by
itself. It can be taken when a DBD::DuckDB release, measured against a
storage that caches, passes every ORM claim in `t/49-statement-reuse.t`. The
file carries a plain-DBI sentinel for the three defects as TODO tests; when
they pass unexpectedly, that release is due for the measurement.

Measured once already, to know the condition can be met: with the patch
proposed in `docs/upstream/dbd-duckdb-statement-handles-cannot-be-reused.md`
applied to a copy of DBD::DuckDB 0.16, and this storage as it was before this
ADR (cache on), every ORM claim in the file passes and the sentinel reports
three unexpected successes. Only the two assertions that this storage reports
the cache as off fail, which is the decision above and would be withdrawn
with it.

The report is drafted in that file and is sent by the maintainer, not from
this repo.
