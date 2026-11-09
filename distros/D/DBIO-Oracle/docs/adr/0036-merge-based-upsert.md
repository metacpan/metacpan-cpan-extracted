# ADR 0036 — Atomic upsert on Oracle: MERGE behind the same `$rs->upsert`

- Status: accepted, not implemented (design only; `$rs->upsert` still throws on Oracle, `supports_upsert` is the core default 0)
- Date: 2026-07-25 (proposed) · 2026-07-26 (accepted)
- Tags: upsert, merge, sqlmaker, capability, adr-0036, identity, oracle

## Context

Core ADR 0036 shipped `$rs->upsert` as a *tail on INSERT*: core normalizes the
caller's options into `{ target, action, set }`, hands it to
`sql_maker->insert` on the same options transport `RETURNING` already rides,
and the driver SQLMaker appends `ON CONFLICT` / `ON DUPLICATE KEY UPDATE`.
PostgreSQL, SQLite and MySQL have landed exactly that. Oracle has no INSERT
tail; the engine's upsert is `MERGE`, a different statement shape with its own
source, its own branches and its own bind order. `supports_upsert` is therefore
still at the core default `0` here, which makes `upsert` throw — correct, but
the feature does not exist on Oracle.

Three facts decide the shape of the Oracle answer, all verified against the
code rather than assumed:

1. **Core does not care what verb the SQLMaker emits.**
   `DBIO::Storage::DBI::_gen_sql_bind` (`Storage/DBI.pm:2366`) is
   `($sql, @$bind) = $self->sql_maker->$op(($from || $ident), @$args)` and then
   prepares whatever string came back. `$op` is a method name, not a promise
   about the SQL.
2. **`RETURNING ... INTO` does not work on `MERGE` before Oracle 23ai.** The
   clause is defined for `INSERT`/`UPDATE`/`DELETE`; 23ai is the first release
   whose `MERGE` grammar carries a `returning_clause`. So ADR 0036 §4 rule 1 —
   "the engine returns it" — is **version-conditional** here, not simply true
   as the follow-up ticket assumed.
3. **Oracle's own identity channel is unusable for an upsert.**
   `DBIO::Oracle::Storage::AutoIncrement::_dbh_last_insert_id`
   (`Storage/AutoIncrement.pm:107-115`) reads `<seq>.CURRVAL` — a *session*
   value, not the row the statement touched. Worse, for `auto_nextval` columns
   core's `_prefetch_autovalues` (`Storage/DBI.pm:2648-2672`) consumes a
   sequence value *before* the statement and folds it into `$to_insert`, whose
   copy is what core hands back (`%returned_cols = %$to_insert`). On a MERGE
   that took the matched branch that value belongs to a row which was never
   written. This is the SQLite-below-3.35 trap from ADR 0036 §4, with the
   dangerous default reversed: core's nameability test would *pass*.

## Decision

### 1. Same `$rs->upsert`, no Oracle-specific method

MERGE rides the existing API and the existing seam.
`DBIO::Oracle::SQLMaker::insert` consumes `$options->{on_conflict}` and, when
present, builds a complete `MERGE` from scratch instead of delegating to
`next::method`; without the key it passes straight through, exactly as the
other three drivers do.

A separate `$rs->merge` was rejected: the option structure core builds is
already engine-neutral (`{ target, action, set }` names an intent, not a
grammar), and forking the *public* API on engine identity is ADR 0021's
anti-pattern wearing a different hat — portable callers would have to branch on
the driver name to pick a method. The price is that the SQLMaker method named
`insert` may return a `MERGE`, and `_execute('insert', …)` labels it `insert`.
That is a naming cost, documented, not a behavioural one.

### 2. Mapping the option structure

```sql
MERGE INTO "cd" dst
USING (SELECT ? AS "artist", ? AS "title", ? AS "year" FROM DUAL) src
   ON (dst."artist" = src."artist" AND dst."title" = src."title")
 WHEN MATCHED THEN UPDATE SET dst."year" = src."year"
 WHEN NOT MATCHED THEN INSERT ("artist", "title", "year")
      VALUES (src."artist", src."title", src."year")
RETURNING "cdid" INTO ?              -- 23ai and up only
```

| Core structure | Oracle rendering |
|---|---|
| `target => \@cols` | the `ON` equality list |
| `target => { constraint => $name }` | **resolved to columns first** — Oracle's `ON` takes an expression, never a constraint name |
| `target => 'any'` | typed exception — `ON` is mandatory and explicit; Oracle has no any-unique semantics |
| `action => 'update'` | both branches, `WHEN MATCHED` first |
| `action => 'nothing'` | `WHEN NOT MATCHED THEN INSERT` **only**; a single-branch MERGE is legal since 10g |
| `set => { c => { -attempted => $s } }` | `dst."c" = src."$s"` — the direct analogue of `EXCLUDED.c` |
| `set => { c => \'expr' }` / `\[…]` | literal passthrough into the `WHEN MATCHED` branch |
| `set => { c => $plain }` | `dst."c" = ?`, bind in the `WHEN MATCHED` branch |

**The USING source carries every attempted value exactly once.** Unlike the
INSERT-tail engines, where the values are bound in `VALUES` and referred to
again through a pseudo-row, `SELECT ? AS col … FROM DUAL` *is* the pseudo-row.
Both branches reference `src.*`; nothing is bound twice.

**Bind order is forced, in three blocks:** (i) the USING binds, one per column
of the row data in the driver's fixed column order; (ii) the `WHEN MATCHED`
set binds, for literal and plain values only, in `sort keys %$set` order as
`DBIO::PostgreSQL::SQLMaker::_insert_on_conflict` already does; (iii) the
`RETURNING … INTO` out-binds, last. `_bind_sth_params`
(`Storage/DBI.pm:2617-2627`) binds positionally by array index and treats any
`SCALAR` ref as `bind_param_inout`, so out-binds are only correct while they
are the final placeholders — which MERGE's grammar guarantees, the
`returning_clause` being last.

**Two things the SQLMaker cannot compute and the Storage must hand it**, the
dbio-mysql k27 lesson repeated: `insert` there receives `($table, $data,
$options)` and has no ResultSource. `DBIO::Oracle::Storage::insert` overrides,
enriches a localized copy of the `on_conflict` structure (MySQL's `$plan->{extra}`
pattern) with (a) the columns behind a `{ constraint => $name }` target and
(b) the column order/type information the USING source needs, then calls
`next::method`.

### 3. Identity — rule 1 only from 23ai, rule 2 below it

ADR 0036 §4's driver obligation is "declare `supports_upsert` only if the
identity you hand back is provably the row that was written". Oracle satisfies
it two different ways, and the driver picks by server version:

- **23ai and up:** `MERGE … RETURNING <pk> INTO ?` — rule 1. Oracle joins
  the row-returning camp and the §4 asymmetry does not grow.
- **Below 23ai (11g–21c, i.e. today's installed base):** rule 1 is unavailable
  and rule 3 is *actively wrong* (Context, fact 3). Only rule 2 remains — the
  re-find by conflict target that ADR 0036 says "whoever wants it must build it
  in the driver". Oracle can: `MERGE`'s `ON` is always an explicit,
  caller-supplied target, so a follow-up `SELECT` on those values provably
  names the merged row. The driver therefore **builds rule 2** rather than
  gating the capability at 23ai.

That is rule 2 exactly as ADR 0036 §4 defines it, not a departure from it: the
section names three ways to satisfy the identity obligation and leaves rule 2 as
something "whoever wants it must build in the driver, core does not".
dbio-sqlite gates at 3.35 because nobody built it there, so only core's
`last_insert_id` path was left — not because the re-find was judged unsound; §7
of the same ADR calls a target SELECT on SQLite "provably right". Oracle builds
it, and the cost of not building it is the argument: gating at 23ai would drop
essentially every production Oracle in service.

Mechanically, below 23ai the Storage override sets `local $opts->{no_retrieve} = 1`
before `next::method`. That is core's existing one-round-trip switch and it
disables the `last_insert_id` path — which is the point: left enabled it would
call `CURRVAL` and name the wrong row. The driver then runs its own re-find and
merges the result in. Where it cannot prove the row it **deletes the primary key
columns from the returned hashref**, which is precisely core's nameability test,
so `row_or_die` throws and `row_or_undef` returns `undef` with no new core
mechanism — the technique dbio-mysql established.

`action => 'nothing'` needs one extra signal, because a re-find always finds
the pre-existing row whether or not the statement wrote anything. Oracle
supplies it honestly: a single-branch MERGE reports **0 affected rows** when the
row already existed and 1 when it inserted, and core writes that number back as
`$opts->{affected_rows}` (`Storage/DBI.pm:2831`). So on 0 the driver withholds
the identity and `upsert` returns `undef` — the PostgreSQL answer, not the MySQL
one. Oracle's row count is a real count; `CLIENT_FOUND_ROWS`, which made this
impossible on MySQL, has no analogue here.

### 4. What atomicity can be promised, and what cannot

**Can be promised:** the conflict is resolved by the server inside one
statement. No client-side read-then-write window, no lost update, and the
matched branch takes a row lock like any `UPDATE`. That is the guarantee ADR
0036 exists to make, and MERGE makes it.

**Cannot be promised: freedom from ORA-00001.** Two sessions merging the same
*not yet existing* key both take the not-matched branch, because neither sees
the other's uncommitted row; the second blocks on the unique index and gets
`ORA-00001` when the first commits. PostgreSQL's `ON CONFLICT` waits and then
takes the update path instead, so this is a real weakening against the
reference implementation and must be stated in POD in those words: *on a first
concurrent insert of the same key, one session gets a unique-violation and must
retry.* Oracle rolls the failed statement back on its own (statement-level
atomicity), and a retry finds the row committed and takes the matched branch,
so the retry is safe — but `DBIO::Oracle::Storage::_dbh_execute`'s existing
`BlockRunner` explicitly refuses to retry inside a transaction, so an automatic
retry is a separate decision, not a freebie. Not in this design.

**ORA-30926 is structurally unreachable.** "Unable to get a stable set of rows
in the source tables" requires a source with more than one row per target row;
`SELECT … FROM DUAL` has exactly one. It becomes a live concern only for a
multi-row `USING` in a future `upsert_all`, which would have to deduplicate.

**ORA-38104 is reachable and is a validation, not a runtime surprise.** Oracle
refuses to update a column referenced in `ON`. Core's default update set already
skips the target and primary key columns, but a caller-supplied
`update => { <target col> => … }` would hit it. The driver rejects that at
option time with a message naming the column.

**Single-branch MERGE** (`action => 'nothing'`) is legal from 10g and needs no
guard beyond the version floor the driver already carries.

## Rationale

Riding `$rs->upsert` is possible only because the seam is an options hash and a
method name, not a statement template — fact 1 above is what makes the whole
design a driver-local matter with no core change. Had core inspected or
assembled the SQL, MERGE would have needed its own plumbing method and the API
would have forked.

Building rule 2 rather than gating the capability is a choice the other drivers
did not make, but not one that overrules them: §4 leaves rule 2 open by design,
and meeting the identity obligation with a second statement is what MySQL
already does for its common case. The identity obligation is met either way; the
difference is only who pays for it and how much of the installed base gets the
feature at all. What is *not* negotiable is the `CURRVAL` path — a channel that reports a value from the
session rather than from the statement is exactly the "confidently wrong row"
ADR 0036 §4 was amended to forbid, and `auto_nextval` makes it the silent
default unless the driver disables retrieval explicitly.

Being explicit about ORA-00001 costs nothing and buys the API its honesty. ADR
0036 was written to stop a README promising atomicity a two-step helper did not
deliver; quietly shipping an upsert that raises a unique violation under the
very concurrency it advertises protection against would be the same mistake in
a new place.

## Consequences

- No core change is required. `supports_upsert` flips on in
  `DBIO::Oracle::Storage`; the structure crossing the seam is unmodified.
- Every Oracle upsert below 23ai costs two round-trips when a row is wanted
  (`row_or_undef` / `row_or_die`), one with `count` / `void`. On 23ai it is one.
- `conflict_target => 'any'` throws on Oracle in **both** actions. Core ADR 0036
  §1 advertises `'any'` + `on_conflict => 'nothing'` as the combination that
  "works everywhere"; Oracle falsifies that, and the claim needs correcting in
  core's POD and ADR. **Cross-repo follow-up, ticket to dbio.**
- `on_conflict => 'nothing'` returns `undef` on an existing row here, matching
  PostgreSQL/SQLite and not the MySQL divergence tabled in core §4. The
  three-way table in core §4 gains an Oracle row rather than a fourth answer.
- With `auto_nextval` columns a sequence value is consumed on every upsert,
  including ones that take the matched branch. Oracle sequences gap by design;
  documented, not fixed.
- Sequence-by-BEFORE-INSERT-trigger tables (ADR 0004) work unchanged: the
  trigger fires on the not-matched branch, and the re-find or `RETURNING` is how
  the assigned key comes back.
- MERGE needs `INSERT`, `UPDATE` and `SELECT` on the target; a grant that only
  covers `INSERT` is enough for `create` and not for `upsert`.
- **Open, needs a live server before implementation starts:** (a) the exact 23ai
  spelling — whether the returned columns may be alias-qualified, whether the
  `OLD`/`NEW` qualifiers 23ai adds are needed to get the post-merge value, and
  whether DBD::Oracle drives `bind_param_inout` against it at all, (b) whether
  `$sth->execute` reports MERGE's
  affected-row count as assumed for the single-branch case, and (c) how LOB
  values behave when bound inside `SELECT ? FROM DUAL` — there is no target
  column for DBD::Oracle to type the placeholder from, so a large CLOB may need
  binding directly in the branch value lists instead of through the USING
  source. `DBIO::Oracle::Storage::LOBSupport::_prep_for_execute` short-circuits
  on `$op eq 'insert'` and so never sees the MERGE; that stays safe for the `ON`
  condition, since Oracle cannot index a LOB column and a LOB can therefore
  never be a conflict target.
- `upsert_all` and `upsert_async` remain core-side questions; the multi-row
  `USING` that a batch MERGE wants is where ORA-30926 becomes real.

## Related

- core ADR 0036 (the API, the `{ target, action, set }` structure, the
  capability mechanism, the §4 identity rules this refines for a non-INSERT
  statement)
- core ADR 0021 (capability flag instead of driver-name branch — the reason
  there is no separate `$rs->merge`)
- core ADR 0026 (the `use_dbms_capability` shape `supports_upsert` uses)
- ADR 0004 (sequence detection via BEFORE INSERT trigger parsing — the identity
  path MERGE has to keep working)
- ADR 0006 (LOB chunked equality comparison — the `$op eq 'insert'`
  short-circuit a MERGE inherits)
