# ADR 0046 — Mock cursor SQL mirrors real-cursor SQL via `_select_args`

- Status: accepted
- Date: 2026-09-09
- Tags: test-infra, storage, sqlmaker, cross-driver, family-policy

> Accepted with the implementation committed in karr k55 (2026-06-24).
> Captured here because every mock test in the family hangs on the invariant
> and it lived only in `CLAUDE.md` / the dbio-core skill.

## Context

The DBIO test infrastructure (skill `dbio-core`, `DBIO::Test::Storage`) drives
the entire mock-test suite with a single promise: **whatever SQL the mock
captures is the SQL the real storage would have executed.** Drivers and core
tests alike build their assertions off the captured string; the test passes
because the captured string and the real-executed string are the same value,
not because two implementations happen to converge.

The two SQL production paths in `DBIO::Storage::DBI` are:

1. `as_query` — walks `_select_args_to_query`. The query *object* the caller
   may inspect, ask for `->{where}` on, etc.
2. the executed path — the real cursor's `next` / `all` call
   `$storage->_select(@args)`, which runs `_select_args` (which performs join
   pruning and complex-prefetch rewriting) and hands the result to `_execute`,
   which calls `_prep_for_execute($op, $ident, \@select_args)`.

Paths 1 and 2 must agree on the SQL string. They agree today because the
*executed* path runs through `_select_args` and the *captured* path runs
through the same function (`as_query` already did, even before k55).

The failure mode that karr k55 records: `DBIO::Test::Storage::FakeCursor::new`
was generating the captured SQL by calling `_prep_for_execute("select", $ident,
[...])` on the **raw** `$attrs->{from}`, bypassing `_select_args` entirely. The
real cursor ran pruning, so the fake captured UN-pruned SQL — joins that a real
DB would strip (e.g. a `get_column` selecting one column over a prefetch) stayed
in the captured string. Tests asserted the captured shape; live code ran the
pruned shape; the assertions were lying about both.

The fallout was visible in `dbio-oracle t/30-sqlmaker-oracle.t`: the
"spurious LEFT JOIN" was not the real cursor emitting a spurious join, it was
the *mock* reporting one that the real cursor had correctly pruned away.

## Decision

`DBIO::Test::Storage::FakeCursor::new` builds its captured SQL the **same way**
`DBIO::Storage::DBI::_select` builds the executed SQL. The contract is
mechanical, not coincidental:

    # in DBIO::Test::Storage, FakeCursor::new
    my ($op, $ident, @select_args) = $storage->_select_args(@$args);
    my ($sql, $bind) = $storage->_prep_for_execute($op, $ident, \@select_args);

    # in DBIO::Storage::DBI, _select ...
    $self->_execute($self->_select_args(@_));
    # ... and the _execute it calls, with ($op, $ident, @args)
    my ($sql, $bind) = $self->_prep_for_execute($op, $ident, \@args);

Two consequences:

1. The captured SQL and the executed SQL **are the same value** for every
   `$attrs` the test passes, including the pruned cases. A test asserting
   `is($captured, $expected)` is asserting the real-DB SQL, by construction.

2. Routing through `_select_args` means the fake storage now faithfully throws
   the **same exceptions** a real DB would. `t/prefetch/with_limit.t` test 2
   used `lives_ok` for a literal-SQL `order_by` over a multiplying
   prefetch+limit; the real storage throws on that combination (verified
   against `DBIO::SQLite::Storage` and against `as_query`). The `lives_ok`
   was a transcription error: corrected to `throws_ok` with the upstream
   `Unable to programatically derive a required group_by` matcher.

## Rationale

The naive capture — render `$attrs` straight to SQL and store the string —
*looks* equivalent to "ask the real cursor what it would have run," but it
diverges at every layer that mutates the args: join pruning, complex-prefetch
rewriting, and any future layer added to `_select_args`. The two paths must be
the same code path, or they will drift. Forcing them to share `_select_args` is
the only invariant that survives a future refactor of `DBIO::Storage::DBI`'s
select pipeline: if the real cursor changes what it executes, the fake cursor
inherits the change on its next load.

The throw-symmetry argument is the same one for `DBI->execute_exception` /
`DBIO::Exception`: a mock test that `lives_ok`s where the real cursor throws
is not a passing test, it is a passing test about a different question
("does this not die in the mock?"), and the moment that question stops being
the right one, the assertion goes silent. Routing through the same code means
the mock and the real path agree on the exception too.

## Consequences

- Every mock test in the family asserts against captured SQL with the
  guarantee that "captured" and "executed" are the same string. Drivers that
  port tests across to a real DB keep the same assertions unchanged; the
  captured string and the live SQL differ only in whitespace conventions that
  each driver's tests already accommodate.

- The `FakeCursor` is now structurally a thin shim over
  `_select_args`/`_prep_for_execute`. Adding a new layer to the real-cursor
  select pipeline (a future join-pruning rule, a new prefetch-rewriter) is
  automatically picked up by the mock; the mock test surface does not need to
  grow.

- A mock test that exercises a code path the real cursor refuses must use
  `throws_ok` with the real exception text. `lives_ok` over such a path is a
  red flag during review and the rule that k55 documents — that the
  `with_limit.t` test was a transcription error — applies to any future
  contributor who reaches for `lives_ok` to make a green test green.

- A new failure mode becomes impossible: the mock cannot drift from the real
  cursor by a layer the real cursor runs but the mock does not. It can still
  drift by a layer that **neither** runs — those are caught by the live-DB
  driver dists (the source of the original `dbio-oracle` report), not by the
  mock suite.
