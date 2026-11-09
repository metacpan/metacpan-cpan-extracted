# ADR 0008 — REORG is an operation of the diff, after the column pass

- Status: proposed
- Date: 2026-10-07
- Tags: diff, deploy, reorg, ddl

Implemented with karr k42; the choice among the three options below was made by
the coordinating agent on the measurements and is waiting for the maintainer's
confirmation. Until then this stays `proposed`.

## Context

Some `ALTER TABLE` statements leave a Db2 table in *reorg-pending* state. The
server then refuses data changes and further DDL on it with `SQL0668N`, reason
code 7 (SQLSTATE `57007`), until a `REORG` has run.

`DBIO::DB2::Diff::Column` writes such statements, and nothing in the diff or in
`DBIO::DB2::Deploy` wrote the `REORG`. An upgrade whose diff dropped a column
and created an index on the same table died at the `CREATE INDEX`; the storage
declares `_use_transactional_ddl(0)`, so the column was gone by then, and the
table took no `INSERT` afterwards. `t/11-db2-fk.t` and `t/12-db2-upgrade.t`
were written around the case.

Measured against Db2 12.1.5 with `DBD::DB2` 1.92 (2026-10-07), reading
`SYSIBMADM.ADMINTABINFO.REORG_PENDING` after each statement:

| Statement | reorg-pending |
|---|---|
| `DROP COLUMN` | Y |
| `SET NOT NULL`, `DROP NOT NULL` | Y |
| `SET DATA TYPE`: `CHAR(10)`→`CHAR(20)`, `CHAR`→`VARCHAR`, `VARCHAR`→`CHAR`, `SMALLINT`→`INTEGER`, `INTEGER`→`BIGINT`, `BIGINT`→`INTEGER`, `DECIMAL(10,2)`→`(12,2)` and `(12,4)`, `DECIMAL(12,2)`→`(10,2)`, `REAL`→`DOUBLE`, `DATE`→`TIMESTAMP`, `TIMESTAMP(6)`→`(12)`, `INTEGER`→`VARCHAR(20)`, `INTEGER`→`DOUBLE`, `INTEGER`→`DECIMAL` | Y |
| `SET DATA TYPE`, the length alone within one varying-length type: `VARCHAR(20)`→`(40)`, `VARCHAR(50)`→`(20)` and `(20)`→`(10)` with data that fits, `VARCHAR(20)`→`(30)` with an index on the column, `VARGRAPHIC(20)`→`(40)`, `VARBINARY(20)`→`(40)` | N |
| `SET DEFAULT`, `ADD COLUMN` | N |
| `VARCHAR(20)`→`CLOB` | refused by the server (`SQL0190N`) |

The card spoke of a *narrowing* `SET DATA TYPE`. That is not the line: a
shorter `VARCHAR` is not reorg-recommended, nearly every other change of type
is.

In reorg-pending state `INSERT`, `UPDATE` and `CREATE INDEX` failed with
`SQL0668N` rc 7, and so did a `SELECT COUNT(*)` in this measurement (the card
had `SELECT` going through; nothing here relies on either). Further
`ALTER TABLE` statements are accepted: ten reorg-recommended statements in a
row ran in autocommit without a `REORG` between them (`NUM_REORG_REC_ALTERS`
1 to 10).

`CALL SYSPROC.ADMIN_CMD('REORG TABLE "T"')` on the same handle ends the state,
in autocommit and inside a transaction; 0.1 to 0.4 s on a table of a few rows.
An unqualified name is resolved against `CURRENT SCHEMA` (under
`SET CURRENT SCHEMA SYSTOOLS` the call answers `SQL2211N`, table does not
exist), which is how the diff's unqualified `ALTER TABLE` statements are
resolved too. A name with a space, lower case and an apostrophe works once the
apostrophe is doubled in the string literal. A `REORG` on a table that needs
none is accepted.

## Decision

The `REORG` is an operation of the diff: `DBIO::DB2::Diff::Reorg`, rendered as

    CALL SYSPROC.ADMIN_CMD('REORG TABLE "<table>"');

with the table name through `_db2_quote_ident`, unqualified, and `'` doubled
for the literal.

`_build_operations` in `lib/DBIO/DB2/Diff.pm` emits, after the column pass and
before the index pass, one such operation for every table that has at least one
column operation answering true to `reorg_recommended` in
`lib/DBIO/DB2/Diff/Column.pm` — one per table however many there are, in the
order of the column pass. The rule lives on the column operation because it is
a statement about the SQL that operation renders, and it uses the conditions
`as_sql` there writes its statements on:

- `drop`: yes;
- `alter` with a change of nullability: yes;
- `alter` with a change of the rendered type: yes, unless the type name is the
  same and is `VARCHAR`, `VARGRAPHIC` or `VARBINARY` (only the length differs);
- `add`, and an `alter` of the default alone: no.

A combination that was not measured gets a `REORG`. One too many costs time;
one too few breaks the upgrade half way.

Three options were on the card:

1. **`REORG` automatically inside `apply`.** The same work at the same moment,
   but not in `$diff->as_sql` or `->summary`: an operator reading the diff
   before applying it would not see that a table is going to be rewritten.
2. **`REORG` as its own operation in the diff** (chosen).
3. **Document it and throw.** Does not meet the card's own criterion — a live
   run of `DROP COLUMN`, following DDL and an `INSERT` — and leaves every
   application with the same half-applied upgrade to finish by hand.

## Rationale

The `REORG` is not an avoidable extra. From the moment the diff contains one of
these `ALTER TABLE` statements the table is closed to writes until a `REORG`
has run; its duration and its locks are a cost of the change, not of the choice
made here. What the choice decides is whether the cost is shown, and a diff is
the place where an upgrade is read before it runs.

The position follows from what the state refuses. `ALTER TABLE` is still
accepted, so all column statements of a table can run first and one `REORG`
covers them; `CREATE INDEX` is not, so it has to stand before the index pass.
The foreign key pass comes later still.

## Consequences

- **Duration.** It is a classic `REORG TABLE` and rewrites the table; the time
  grows with the table. Only the minimal case is measured (0.1 to 0.4 s on a
  few rows). An upgrade that drops a column of a large table now takes as long
  as that rewrite, where it used to fail.
- **Locks and access during the `REORG` — not measured.** According to IBM's
  documentation of the `REORG TABLE` command for Db2 12.1 (read 2026-10-07),
  `ALLOW READ ACCESS` is the default for a nonpartitioned table and
  `ALLOW NO ACCESS` the default and only mode for a partitioned one, and an
  in-place reorganization is not allowed on a table in reorg-pending state — so
  the classic form is the one that applies. The statement is written without an
  access clause and takes the server's default. What a concurrent session
  actually sees was not tried.
- **Authority — not measured.** The same page lists, for `REORG TABLE`, one of
  SYSADM, SYSCTRL, SYSMAINT, DBADM, SQLADM, SCHEMAADM on the table's schema, or
  CONTROL on the table. Whether the `EXECUTE` privilege on
  `SYSPROC.ADMIN_CMD` is granted by default was not verified. The live suite
  runs as the instance owner, which proves nothing about a restricted user: a
  user who may `ALTER` a table but not `REORG` it gets the `ALTER` applied and
  the `REORG` refused, and is left with the reorg-pending table the upgrade
  used to leave everyone with.
- **Units of work.** `_execute_ddl` runs the statements in autocommit, the
  `CALL` among them. Whether `REORG` could be part of a transactional DDL batch
  is one more thing to measure before `_use_transactional_ddl` becomes `1`
  (see `DBIO::DB2::Deploy`).
- **A `REORG` that fails leaves the table reorg-pending** and the upgrade
  stopped there. The next diff does not repair it — see the next point.
- **A table that is reorg-pending before the diff** — not built at first; see the
  addendum of 2026-10-25, which `upgrade` now answers.
- **`as_sql` now holds a statement that is not DDL.** Anything that takes a
  DB2 diff's SQL for a list of `CREATE`/`ALTER`/`DROP` meets a `CALL`. In this
  distribution only `apply` consumes it. `_split_qualify_ddl` in
  `DBIO::DB2::Deploy` is not involved: it rewrites the install DDL, never a
  diff.
- **Data-partitioned tables** were not measured; IBM's page says such a table
  has to be reorganized as a whole to clear the state for all partitions, which
  is what the statement asks for.
- Tests: `t/33-diff-reorg.t` (offline: position, one per table, the rule row by
  row, quoting, one statement through core's splitter) and
  `t/13-db2-upgrade-reorg.t` (live, through `DBIO::DB2::Deploy` only).

## Addendum 2026-10-25 — upgrade reorganises a table that is already pending (karr k48)

The point "Not built: a table that is reorg-pending before the diff" is built, in
`upgrade` and nowhere else. The state is not in the introspected model, so the
diff cannot carry it: after an upgrade interrupted between `ALTER` and `REORG`,
a failed `REORG` or an `ALTER TABLE` by hand it holds no column operation, no
`Diff::Reorg`, and the `CREATE INDEX` of the same diff (like every `INSERT`)
dies with `SQL0668N` rc 7; "run upgrade again" did not heal it. The maintainer's
decision: `upgrade` asks the server and reorganises first.

- **Where.** `DBIO::DB2::Deploy::upgrade` (an override of the core method; core
  offers no hook between `diff` and `apply`, none was needed). Once the diff is
  built and before its first statement runs, the private
  `_reorg_pending_before_apply` runs. The models do not depend on the state, so
  this is equivalent to asking before the introspection, and costs one
  introspection less than doing it twice. `diff`, `install` and `apply` stay as
  they were: `diff` is a read, `apply` runs what it is handed.
- **Which tables.** The narrowest reading of "affected": a *table* (not a view)
  in the source model **and** in the target model, so one the diff can alter,
  index or constrain. A table only in the source is dropped by the diff; a
  `REORG` on it is wasted. One only in the target is created by it. If no table
  is in both models the server is not asked.
- **The question.** `SELECT tabname FROM sysibmadm.admintabinfo WHERE tabschema
  = ? AND reorg_pending = 'Y'`, the bind being `CURRENT SCHEMA` trimmed (the
  schema the source model is read from). Measured on Db2 12.1.5, 495 rows in
  `SYSCAT.TABLES`, nothing pending: 3 ms warm (16 ms first) with the
  `TABSCHEMA` filter, 53 ms without it; the filter reaches the table function
  through the view. A large catalog was not measured.
- **What runs.** For each pending table among them, in name order, the statement
  `Diff::Reorg->as_sql` renders (quoted identifier, `'` doubled), through
  `_execute_ddl` like `apply` runs it. It runs also when the diff turns out
  empty; `upgrade` then still answers `undef`. It runs even if the diff
  carries its own `Diff::Reorg` for the same table afterwards: after the column
  pass the state is pending again and that `REORG` stands.
- **Visible.** A `carp` names the tables before the first `REORG`, because the
  rewrite is work that is not in `$diff->as_sql`. No new public interface.
- **Still not covered.** Introspection does not read the state, so `diff` and
  `as_sql` do not show this `REORG`; a table pending in a schema other than
  `CURRENT SCHEMA` is not looked at; the cost of the rewrite, the locks and the
  authority stay as written under Consequences. A `REORG` that fails here
  throws before any statement of the diff ran, so nothing is half applied.
- Tests: `t/65-upgrade-reorg-pending.t` (offline: query shape and bind, REORG
  before the diff, none for a table that is not pending, the narrow reading,
  quoting, order, no query when no table is in both models, empty diff) and
  `t/64-upgrade-reorg-pending-live.t` (live, tables `dbio_k48_<pid>_*`: a table
  made pending by hand gets its index through `upgrade`, ends not pending,
  with an empty follow-up diff and a row that can be inserted).
