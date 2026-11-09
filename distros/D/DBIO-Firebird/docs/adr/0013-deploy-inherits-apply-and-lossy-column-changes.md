# ADR 0013 — The Deploy class inherits `apply` and `upgrade`; checks sit in `_check_before_apply`; a column change is lossy unless its pair is listed

- Status: accepted (follows core ADR 0080, karr core k399)
- Date: 2026-10-30
- Tags: deploy, diff, lossy, guard, conformance, relates-core-0080

## Context

Core ADR 0080 makes `DBIO::Deploy::Base::apply` the one place that reads the
classification of a diff: a refusal always stops it, a destructive or lossy
operation runs only with `allow_destructive`. `apply` and `upgrade` are the
entry points of every driver's deploy class; a driver takes part through the
hooks `_check_before_apply($diff)` and `_execute_diff($diff)`, and a column
operation answers `lossy` through `DBIO::Diff::Compare::column_change_lossy`.

`DBIO::Firebird::Deploy` had its own `apply`: it rendered the whole diff, asked
the live tables with `_refuse_unfillable`, and called the base `apply`.

## Decision

1. **`DBIO::Firebird::Deploy` has no `apply` and no `upgrade`** of its own; it
   inherits both from `DBIO::Deploy::Base` (the shared conformance case
   `diff-deploy-inherited` holds the same code reference).
2. **The driver's checks are `_check_before_apply`.** It renders the whole diff
   (`as_sql`: a refused column change or a table that becomes a view dies there,
   a refusal of the diff itself comes before one that needs rows) and then runs
   `_refuse_unfillable` (NOT NULL without a default over rows, NOT NULL over a
   NULL) against the live handle. Both happen before the first statement.
   Execution stays core's `_execute_diff`.
3. **`DBIO::Firebird::Diff::Column::lossy`** is true for an `alter` whose type or
   size can alter or lose values. The answer is `column_change_lossy` with the
   pairs of `%DBIO::Firebird::Diff::Column::LOSSLESS_PAIRS`: `smallint` to
   `integer`, `bigint`, `int128`; `integer` to `bigint`, `int128`; `bigint` to
   `int128`; `smallint` and `integer` to `double precision` (a double holds 53
   bits exactly); `date` to `timestamp`; `char` to `varchar` and `binary` to
   `varbinary` of the same length (the server pads a CHAR to another length). Every other change is lossy:
   in doubt it is (`float` to `double precision`, `timestamp` to `date`, a number
   and a text, `numeric` and `decimal`, a larger scale). A change of
   `NOT NULL` or of the default alone is not lossy. A pair is listed only when
   `t/99-diff-column-lossless-live.t` reads the stored values back unchanged
   from a Firebird server.
4. **The conformance class releases what its cases state.**
   `conformance_upgrade` calls `upgrade(allow_destructive => 1)`;
   `conformance_deploy` returns `DBIO::Firebird::Deploy->new(schema => $to)` for
   the deploy cases, and the table version answered is 4.

## Consequences

- A caller that drops a table or a column, or changes a column in a way that is
  not on the list, says so with `allow_destructive => 1`; every call site in the
  tests that does so names the drop it expects.
- The refused column changes of `Diff::Column::refusal` stay refusals: they are
  not released by `allow_destructive`.
- The list grows by a pair only with a live measurement.
