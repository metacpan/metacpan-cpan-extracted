# ADR 0010 — An index over columns that are already indexed is not written; SQL0605W is a warning

- Status: accepted
- Date: 2026-10-25
- Tags: ddl, diff, deploy, storage, index

Implemented with karr k47. Decided by the maintainer (via the hub, 2026-10-24).

## Context

`CREATE INDEX` over a column sequence that an index already covers is answered by
Db2 with `SQL0605W`: `$dbh->do` returns `undef`, `err` 605, SQLSTATE `42S11`, and
no index is made. The state is not class 01, so ADR 0007 does not take it, and
core's `Deploy::Base::_execute_ddl` threw. A `db2_indexes` entry on the primary
key columns, or two entries with the same column sequence, therefore killed
`install` halfway (DDL is not transactional here), and on `upgrade` the index
that never comes into being returned as missing in every diff.

Measured live (Db2 12.1.5, `DBD::DB2` 1.92, `t/61`). The existing cover is the
primary key, a `UNIQUE` constraint or an index; the server answers:

| New index over the same columns, same order | Result |
|---|---|
| non-unique, cover = PK / `UNIQUE` constraint / unique index / non-unique index | 605, nothing made |
| `UNIQUE`, cover = PK / `UNIQUE` constraint / unique index | 605, nothing made |
| `UNIQUE`, cover = a non-unique index | created, beside it |
| another column order, a longer or shorter sequence | created |

The index behind the primary key lives in schema `SYSIBM` and is not in the
model (karr k53); the model has no entry to compare with there.

## Decision

1. **The DDL emitters leave such an index out.** `DBIO::DB2::DDL::install_ddl`
   compares each `db2_indexes` entry's column sequence, before writing it, with
   what covers it, in the order the server meets it: the primary key, the
   `UNIQUE` constraints, then the indexes of the loop in name order that were
   written. The rule is `_index_is_duplicate` (table above: non-unique is a
   duplicate of any cover, unique only of a unique one). Nothing is written, no
   message: the columns are indexed.
2. **The diff leaves it out the same way.** `DBIO::DB2::Diff::Index` gets the
   target's `columns` (primary key) and `unique_constraints` and applies the
   same rule to every index it would create. The target model and the live
   database both come out of `install_ddl`, so a left-out index is missing on
   both sides and the diff after `upgrade` is empty. A `DROP INDEX` that frees a
   column sequence a created index takes over (a rename) is moved in front of the
   creates, or the server would refuse the create.
3. **A 605 that comes anyway is a warning.** `DBIO::DB2::Storage::_connect`'s
   `HandleError` wrapper (ADR 0007) answers err 605 with state `42S11` as
   handled and `carp`s with index and table taken from the statement. Anything
   else, including err 605 under another state, goes to core's handler as
   before. `DBD::DB2` leaves `Statement` empty on the handle for `do()`, so the
   wrapper keeps the text of the last `do()` through a DBI `do` callback.

## Rationale

The server's own rule is the only criterion that keeps the follow-up diff empty,
which is why it was measured instead of assumed: "unique over non-unique" looks
like a duplicate and is not. Doing it before the statement keeps install
deterministic; the warning handling is the net for what the comparison does not
see (an index that exists only on the live database, made by hand).

## Consequences

- A `db2_indexes` entry that is left out is silent. The index name declared for
  it does not exist in the catalog; the cover that did the job keeps its own.
- The comparison mirrors the server's order (name order), not an ideal one: of a
  unique and a non-unique entry over the same columns both are written when the
  non-unique one sorts first, and only the unique one when it sorts first.
- The `do` callback occupies the handle's `Callbacks{do}` slot (an existing one
  is called as before). Core does not use `Callbacks`.
- Not built: an index that exists only on the live database and covers a
  created one under another name is not seen by the diff when no `DROP INDEX`
  for it is in the same diff; the create then ends in the warning above.
- Tests: `t/61-duplicate-index-live.t`, `t/62-duplicate-index.t`,
  `t/63-sqlstate-605.t`.
