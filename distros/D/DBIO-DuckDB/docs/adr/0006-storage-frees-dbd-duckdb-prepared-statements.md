# ADR 0006 — The storage frees DBD::DuckDB's prepared statements itself

- Status: accepted
- Date: 2026-10-04
- Tags: storage, dbd-duckdb, locking, upstream-workaround

## Context

DuckDB locks a read-write database file exclusively from connect on; while
the lock is held no other process can open the file, not even read-only.
DuckDB keeps the database instance alive for as long as a prepared statement
on it exists.

DBD::DuckDB 0.16 never frees a prepared statement, for two independent
reasons (measured 2026-10-04 on libduckdb v1.5.3, karr k25):

1. `DBD::DuckDB::st::finish` calls `duckdb_destroy_prepare($stmt)` with the
   handle by value, where the C function takes a pointer to it.
   FFI::Platypus turns the non-reference argument into `NULL` without a
   warning, and libduckdb does nothing on `NULL`.
2. `DBD::DuckDB::st` has no `DESTROY`, and `execute` never sets `Active`, so
   a handle nobody called `finish` on -- every `$dbh->do` -- is not even
   attempted.

Consequence: any connection that has prepared anything keeps the file lock
after `disconnect` until the process exits. Handing a database file from one
long-lived process to another does not work.

The fix belongs upstream; the report is drafted in
`docs/upstream/dbd-duckdb-prepared-statements-never-freed.md` and is sent by
the maintainer, not from this repo.

## Decision

`DBIO::DuckDB::Storage` frees the statements of its own connection.
`_run_connection_actions` calls `_duckdb_release_statements`, which installs
DBI per-handle callbacks (`ChildCallbacks` for `finish` and `DESTROY`) on the
storage's `$dbh`. The callback takes the statement pointer out of the handle
and then calls `duckdb_destroy_prepare` on it by reference.

Bounds, all deliberate:

- **Own handle only.** Nothing in the `DBD::DuckDB` namespace is patched; a
  plain DBI handle elsewhere in the process behaves as upstream ships it.
- **Version-bound.** The callback frees memory DBD::DuckDB owns, so it is
  installed only up to the release whose `finish` has been read (0.16). On a
  newer DBD::DuckDB the storage installs nothing.
- **No double free.** The pointer is removed from the handle before it is
  freed, and DBI runs the callback ahead of the method, so a DBD that frees
  the statement itself finds nothing left to free.
- **Application callbacks are chained**, on a copy of the hash.
- **Not in a forked child**, in line with core's `_verify_pid`.

Rejected: redefining `DBD::DuckDB::st::finish` (process-wide patch of a
foreign module), and tracking pointers in the storage to free them at
disconnect (misses handles prepared through `dbh_do`, double-frees once
upstream is fixed).

## Consequences

- `$storage->disconnect` releases the database file, pinned by
  `t/47-disconnect-releases-file-lock.t` through a second process and
  `/proc/locks`.
- Two cases still keep the lock: a statement handle that outlives
  `disconnect` (an open cursor) until it is gone, and a connection opened
  with `AutoCommit => 0` -- DBD::DuckDB runs `BEGIN TRANSACTION` inside
  `DBI->connect`, before a callback can be installed.
- A DBD::DuckDB newer than 0.16 that still leaks turns
  `t/47-disconnect-releases-file-lock.t` red; someone then reads that
  release's `finish` and raises the bound. One that is fixed makes the
  test's upstream sentinel pass as an unexpected TODO success; the override
  can then be removed.

## Addendum 2026-10-08 — the same callback gives `finish` a result to destroy

The `finish` this ADR already stands in front of has a second defect
(karr k38, measured on libduckdb v1.5.3 / DBD::DuckDB 0.16): it calls
`duckdb_destroy_result($res)` unconditionally, and a handle has a result only
once an `execute` has succeeded. On a handle that was never executed, whose
only executes the engine refused, or that was finished before, `$res` is
`undef`, reaches C as `NULL`, and the process dies of a segmentation fault.

Core's `_dbh_execute_for_fetch` and `_dbh_execute_inserts_with_no_binds` in
`DBIO::Storage::DBI` finish the handle of a bulk insert whatever happened to
it. That is legitimate DBI and stays as it is. So a `populate` in void
context whose **first** row the engine refuses did not throw, it ended the
process; with the first row accepted and a later one refused it was an
exception all along. By hand through `dbh_do` the same three finishes crash.
Not affected: `create`, `populate` outside void context, and a handle that is
dropped without `finish`.

The maintainer's assignment of the card on 2026-10-08 was to do what the
driver can do rather than wait for upstream, and to leave core as it is.

**Decision.** In the `finish` callback of `_duckdb_release_statements`, a
handle without `duckdb_res` is given an empty `DBD::DuckDB::FFI::Result` — a
zeroed `duckdb_result`, the state `duckdb_destroy_result` itself leaves a
result in and does nothing on (measured, repeatedly). DBD::DuckDB's `finish`
then runs as written.

The bounds above hold unchanged — own handle only, version-bound to 0.16,
application callbacks chained — with one deliberate difference: **this part
does not stand down in a forked child.** An empty result frees nothing, and a
child that finishes a handle it inherited would crash just the same. There is
nothing to double-free: a release that guards its own `finish` gets no
callback, and would destroy an empty result harmlessly if it did.

Rejected:

- **Overriding core's two bulk-insert methods.** Measured as a prototype: it
  mends `populate` and leaves all three hand-driven finishes crashing. The
  defect is in `finish`, not in `populate`, and an override can only get
  between `execute` and `finish` by the same empty result or by copying the
  methods.
- **Skipping `finish` from the callback** (`undef $_`). It would have to
  redo what DBD::DuckDB's `finish` does and decide what an application's own
  `finish` callback still sees.

Consequences: a refused bulk insert is an exception carrying the engine's
reason, the transaction is rolled back and the connection carries on. Pinned
in `t/51-finish-without-result.t`, every scenario in a process of its own;
its upstream sentinel is a plain DBI handle that still crashes and passes as
an unexpected TODO success once DBD::DuckDB guards the call — the draft is
defect 4 in `docs/upstream/dbd-duckdb-statement-handles-cannot-be-reused.md`.
A plain DBI handle outside the storage keeps crashing until then.
