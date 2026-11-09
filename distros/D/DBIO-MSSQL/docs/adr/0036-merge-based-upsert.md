# ADR 0036 — Atomic upsert on SQL Server: MERGE behind the same `$rs->upsert`

- Status: proposed, not implemented (design verified against a live server; `$rs->upsert` still throws on SQL Server, `supports_upsert` is the core default 0; no MERGE rendering in `DBIO::MSSQL::SQLMaker`, no test; checked 2026-10-19, karr k71)
- Date: 2026-07-26 (proposed) · 2026-10-19 (status checked against the code; still proposed, the maintainer has not accepted it)
- Tags: upsert, merge, sqlmaker, capability, adr-0036, identity, output, concurrency, mssql

## Context

Core ADR 0036 shipped `$rs->upsert` as a *tail on INSERT*: core normalizes the
caller's options into `{ target, action, set }`, hands it to `sql_maker->insert`
on the same options transport `RETURNING` already rides, and the driver SQLMaker
appends `ON CONFLICT` / `ON DUPLICATE KEY UPDATE`. PostgreSQL, SQLite and MySQL
have landed that. SQL Server has no INSERT tail; its upsert is `MERGE`, a
different statement shape. `supports_upsert` is therefore still at the core
default `0` here, which makes `upsert` throw — correct, but the feature does not
exist on this driver.

dbio-oracle did the same design pass first (its ADR 0036) and reached the same
top-level answer, so the interesting part of this document is where SQL Server
differs from Oracle. It differs in both directions: it is **better** at identity
and **worse** at getting the atomicity guarantee for free.

Four facts decide the shape, all verified against the code or the vendor
documentation rather than assumed:

1. **Core does not care what verb the SQLMaker emits.**
   `DBIO::Storage::DBI::_gen_sql_bind` calls `$self->sql_maker->$op(...)` and
   prepares whatever string comes back; `$op` is a method name, not a promise
   about the SQL. This is what lets MERGE ride the existing seam.
2. **`OUTPUT` works on `MERGE`, in every supported version.** MERGE, the OUTPUT
   clause on MERGE and the `$action` pseudo-column all arrived together in SQL
   Server 2008, and `INSERTED.*` on a MERGE reflects the row after the statement
   completes — on *both* branches. So ADR 0036 §4 rule 1 ("the engine returns
   it") holds here unconditionally, with no version split of the kind Oracle
   needs for its 23ai `RETURNING INTO`.
3. **A bare MERGE is not race-free, and this is not folklore.** Microsoft's own
   MERGE documentation states that "in some scenarios where unique keys are
   expected to be both inserted and updated by the MERGE, specifying the
   HOLDLOCK will prevent against unique key violations", and warns that "at
   scale, MERGE might introduce complicated concurrency issues". The canonical
   community write-ups agree and are older than that paragraph (Dan Guzman,
   *"UPSERT" Race Condition With MERGE*, 2009: "the HOLDLOCK hint was still
   needed, because MERGE otherwise releases the update key lock before the
   insert"; Michael J. Swart, *SQL Server UPSERT Patterns and Antipatterns*,
   2017, files the unhinted MERGE under **antipatterns** and the same statement
   with `WITH (HOLDLOCK)` under **patterns**).
4. **This driver already retrieves identity by reading a result off the
   statement handle.** `DBIO::MSSQL::Storage::_prep_for_execute` appends
   `SELECT SCOPE_IDENTITY()` to an insert and `DBIO::MSSQL::Storage::_execute`
   fetches that row back into `_identity`, which `last_insert_id` returns. That
   machinery is the thing a MERGE both *collides with* and *can reuse* — see §3.

## Decision

### 1. Same `$rs->upsert`, no SQL-Server-specific method

MERGE rides the existing API and the existing seam.
`DBIO::MSSQL::SQLMaker::insert` consumes `$options->{on_conflict}` and, when
present, builds a complete `MERGE` from scratch instead of delegating to
`next::method`; without the key it passes straight through. A separate
`$rs->merge` is rejected for the reason dbio-oracle gives: the `{ target,
action, set }` structure names an intent, not a grammar, and forking the public
API on engine identity is ADR 0021's anti-pattern in a new hat.

### 2. The statement, and how the option structure maps onto it

```sql
MERGE INTO [cd] WITH (HOLDLOCK) AS tgt
USING (SELECT ? AS [artist], ? AS [title], ? AS [year]) AS src
   ON tgt.[artist] = src.[artist] AND tgt.[title] = src.[title]
 WHEN MATCHED THEN UPDATE SET tgt.[year] = src.[year]
 WHEN NOT MATCHED THEN INSERT ([artist], [title], [year])
      VALUES (src.[artist], src.[title], src.[year])
OUTPUT INSERTED.[cdid];
```

| Core structure | SQL Server rendering |
|---|---|
| `target => \@cols` | the `ON` equality list |
| `target => { constraint => $name, columns => \@cols }` | **render the columns** — `ON` takes a search condition, never a constraint name. A bare `{ constraint => $name }` (pre-k104 core) has nothing to resolve it and throws |
| `target => 'any'` | typed exception, in **both** actions — `ON` is mandatory and explicit; there is no any-unique form. This is the case core ADR 0036 §1 was corrected for in core k108 |
| `action => 'update'` | both branches, `WHEN MATCHED` first |
| `action => 'nothing'` | `WHEN NOT MATCHED THEN INSERT` only — a single-branch MERGE is legal |
| `set => { c => { -attempted => $s } }` | `tgt.[c] = src.[$s]` — the direct analogue of `EXCLUDED.c`. The value names the *source* column, which need not be the column being written |
| `set => { c => \'expr' }` / `\[…]` | literal passthrough into the `WHEN MATCHED` branch |
| `set => { c => $plain }` | `tgt.[c] = ?`, bind in the `WHEN MATCHED` branch |

Four grammar facts the renderer has to respect, none of them optional:

- **The terminating semicolon is mandatory.** A MERGE without it raises error
  10713. Nothing else DBIO emits needs one, so it is easy to lose in a later
  refactor and deserves its own test.
- **`WITH (HOLDLOCK)` sits in the target's `<merge_hint>` slot**, before the
  alias — `MERGE INTO tgt WITH (HOLDLOCK) AS alias`. It is not a query hint and
  cannot be appended.
- **The USING source carries every attempted value exactly once**, and both
  branches reference `src.*`; nothing is bound twice. `(SELECT ? AS col, …)` is
  used rather than the table value constructor `(VALUES (…)) AS src(cols)`:
  both are legal on SQL Server, but the aliased-SELECT form places each
  attempted value next to its own column name, which matters because a value
  may arrive as an *expression* rather than a placeholder — see the MONEY note
  below. (It is also the form Microsoft's own single-row MERGE example uses,
  and the one Azure Synapse accepts, where the table value constructor is
  rejected outright.)
- **Bind order is forced, in two blocks:** (i) the USING binds, one per column
  of the row data in the driver's fixed column order; (ii) the `WHEN MATCHED`
  set binds, for literal and plain values only, in `sort keys %$set` order as
  `DBIO::PostgreSQL::SQLMaker::_insert_on_conflict` already does. Unlike Oracle
  there is no third block: `OUTPUT` returns a result set and has no out-binds,
  so `bind_param_inout` is not involved at all.

**MONEY values arrive as expressions, not placeholders.**
`DBIO::MSSQL::Storage::_prep_for_execute` rewrites a MONEY column's value to
`\['CAST(? AS MONEY)', …]` *before* the SQLMaker runs, so the USING renderer
must handle a literal-value field, not just a bind — `SELECT CAST(? AS MONEY) AS
[amount]`. A renderer that assumes one `?` per column silently corrupts the MONEY
path, which is the driver's oldest documented workaround (ADR 0003).

**Two things the SQLMaker cannot compute and the Storage must hand it**, the
dbio-mysql k27 lesson repeated: `insert` there receives `($table, $data,
$options)` and has no ResultSource. `DBIO::MSSQL::Storage::insert` overrides,
enriches a localized copy of the `on_conflict` structure with (a) the primary
key columns the `OUTPUT` list needs and (b) the column order the USING source
renders in, then calls `next::method`.

**No OUTPUT clause when nobody will read it — required, not an optimisation.**
`result => 'count'` / `'void'` reach the storage as core's `$opts->{no_retrieve}`,
and the enrichment step passes that through as an empty OUTPUT list. Two things
depend on it, and the first was only discovered by measuring: a MERGE carrying an
OUTPUT clause reports `$rv = -1` from `execute`, so `count` is **unimplementable**
while OUTPUT is present, and returns a real count once it is gone. Second, it is
what keeps those two shapes usable on a table with triggers (§4) — the restriction
is on `OUTPUT` without `INTO`, not on `MERGE`.

### 3. Identity — rule 1, but two driver-local traps first

ADR 0036 §4's obligation is "declare `supports_upsert` only if the identity you
hand back is provably the row that was written". `OUTPUT INSERTED.<pk>` proves
it on both branches, so SQL Server joins the row-returning camp and the §4
asymmetry does not grow. Getting there needs three driver changes, because
core's retrieval path and this driver's own identity path both assume an INSERT.

- **Suppress the `SELECT SCOPE_IDENTITY()` append.** `_prep_for_execute` adds it
  whenever `_perform_autoinc_retrieval` is set, and `_execute` then consumes a
  row off the handle to read it. Against a MERGE that consumed row would be the
  **OUTPUT row**, and the identity read would be a value from a different result
  set. Both methods must short-circuit when the options carry `on_conflict`.
  This is the SQL Server form of core ADR 0036 §2's second trap ("put
  `returning` back"): correct SQL whose result is fetched by the wrong reader.
- **Feed `_identity` from the OUTPUT row instead.** Once `_execute` knows it ran
  a MERGE, it reads the OUTPUT row and stores the primary key there. Everything
  downstream in core — `last_insert_id`, the follow-up SELECT for
  `retrieve_on_insert` columns — then works unchanged and, for the first time,
  provably names the row the statement wrote. This is why the design does **not**
  need `_use_insert_returning`: core would only ask for `RETURNING` on columns it
  does not already have, and (as dbio-mysql k29 found) that is not the same
  question as "which row was written".
- **Overwrite supplied primary key values with the OUTPUT ones.** Core's
  nameability test is "did every primary key column come back", and
  `%returned_cols` starts life as a copy of `$to_insert`. Two shapes therefore
  pass that test while carrying a value that is *not* the written row's:

  | Shape | Why the supplied value is wrong |
  |---|---|
  | a `uniqueidentifier` primary key | `DBIO::Storage::DBI::UniqueIdentifier::_prefetch_autovalues` consumes a `NEWID()` **before** the statement and folds it into the data. On a MERGE that took the matched branch it names a row that was never written |
  | a caller-supplied primary key with a conflict target that is *not* the primary key | the statement may have matched a row on that other unique constraint, whose primary key differs from the one supplied |

  Both are Oracle's `CURRVAL` trap with the same dangerous polarity — core's test
  *passes* and hands back a confidently wrong row. Since `OUTPUT` names the real
  one on both branches, the fix is not to withhold identity (dbio-mysql's
  delete-the-PK technique) but to **let the OUTPUT row win**: the `insert`
  override writes the returned primary key columns over whatever was in the
  hashref. Withholding stays the fallback for the one shape where OUTPUT is
  unavailable — see the trigger case in §4.

`action => 'nothing'` needs no extra signal here, unlike Oracle. A single-branch
MERGE that matches an existing row performs no action, so `OUTPUT` yields **zero
rows**, no primary key comes back, and core returns `undef` — the
PostgreSQL/SQLite answer, reached by construction rather than by inspecting an
affected-row count. The MySQL divergence tabled in core §4 does not grow a third
answer.

### 4. What atomicity can be promised — and the price of promising it

**With `WITH (HOLDLOCK)` the promise holds in full.** This is the substantive
difference from dbio-oracle, which has to document that a first concurrent
insert of the same key raises ORA-00001 and must be retried. HOLDLOCK is a
synonym for SERIALIZABLE on the hinted table: the range the `ON` condition read
stays locked for the duration, so a competing session cannot insert the same key
between this statement's match test and its insert. Microsoft documents exactly
this use, and it is what the community patterns settled on. SQL Server therefore
lands next to PostgreSQL in the guarantee it can make, not next to Oracle.

**Which makes the hint non-negotiable.** Without it the statement is the
*antipattern* Swart names, and it fails precisely under the concurrency the API
advertises protection against — ADR 0036 exists to stop a driver promising
atomicity it does not deliver. So `HOLDLOCK` is emitted unconditionally by the
renderer; it is not an option, not a `WITH (…)` passthrough, and not something a
caller can turn off. A test asserts it is in the generated SQL.

**The price, stated plainly: deadlocks instead of unique violations.** Range
locks under concurrency deadlock more readily than row locks, and two sessions
upserting different keys in the same range can pick each other. This is a
documented and widely reported cost of the pattern. POD must say it in those
words: *an upsert can be chosen as a deadlock victim and should be retried by
the caller*. It is a better failure mode than a lost update, and it is the same
class of thing PostgreSQL callers already handle for serialization failures —
but it is not free, and it is not "atomic means nothing can go wrong".

**Caveats that do not apply, and are worth recording as such:**

- **Msg 8672, "attempted to UPDATE or DELETE the same row more than once"**,
  needs a source with more than one row per target row. The USING source here is
  a one-row SELECT, so it is structurally unreachable — Oracle's ORA-30926 with
  a different number. It becomes real for a multi-row `USING` in a future
  `upsert_all`, which would have to deduplicate.
- **The worst open MERGE defect is a `DELETE` one** (Swart 2021: MERGE DELETE
  leaving an indexed view inconsistent). This design emits no `WHEN MATCHED THEN
  DELETE` and no `WHEN NOT MATCHED BY SOURCE` clause at all, so it is out of
  reach.
- **Oracle's ORA-38104 has no counterpart here.** dbio-oracle rejects a
  caller-supplied `update` that assigns a column named in `ON`, because Oracle
  refuses it. SQL Server accepts it (measured), so that validation is
  deliberately **not** copied — refusing what the engine allows would be this
  driver inventing a restriction.
- **Plan-cache hostility does not bite us.** Microsoft notes that simple
  parameterization is not applied to MERGE, so literal-carrying MERGE statements
  recompile; DBIO binds every value as a placeholder, which is exactly the
  parameterization Microsoft recommends in the same paragraph.

**Caveats that do apply, and cannot be checked from DBIO metadata:**

- **A table with an enabled INSERT or UPDATE trigger cannot use `OUTPUT` without
  `INTO`** (error 334). Since the identity story *is* OUTPUT, a triggered table
  cannot serve `row_or_undef` / `row_or_die` at all — only `count` and `void`,
  which need no OUTPUT clause. DBIO holds no trigger metadata, so this cannot be
  a static precondition the way MySQL's table-shape rule is; the driver catches
  error 334 and rethrows it as a typed exception naming the trigger as the cause
  and `count`/`void` as the way out — matching on the message **text**, since
  DBD::ODBC does not pass the number through (measured below). Routing OUTPUT
  through a table variable to
  dodge the restriction was considered and rejected: it turns one statement into
  a batch with its own declaration, and the identity would then have to be read
  from a second result set.
- **Table features MERGE is still weak on** — CDC, memory-optimized, columnstore,
  fulltext-indexed, partitioned and temporal tables, and *unique filtered
  indexes* (Swart's 2021 list, after retesting Bertrand's). None of these are
  visible to DBIO either. POD points at both write-ups rather than pretending to
  enumerate them, and says plainly that on such a table the caller should
  measure before adopting `upsert`.

### 5. Capability gate: on, unconditionally

`__PACKAGE__->_use_supports_upsert(1)` on `DBIO::MSSQL::Storage`, with no
version gate. ADR 0036 §4's rule is to hang the gate on the *identity fact*, not
on a version number: here the identity fact is `OUTPUT` on `MERGE`, and it
arrived in the same release as MERGE itself. There is no server this driver can
reach that has one without the other, so a version test would be a number with
nothing behind it. It goes on the transport-neutral base, not on `::ODBC` or
`::Sybase` — nothing in the design is transport-specific (ADR 0007).

## Rationale

Riding `$rs->upsert` is possible only because the seam is an options hash and a
method name rather than a statement template — fact 1 — so this is a
driver-local matter with no core change, as it was for Oracle.

The identity design is where the two MERGE drivers diverge, and the reason is
worth stating: Oracle had to *build* rule 2 (re-find by conflict target) because
its only identity channel reports a session value. SQL Server does not need it —
`OUTPUT` is rule 1 and costs no extra round-trip — but it does need the driver
to stop its own `SCOPE_IDENTITY` machinery from eating the answer, and to stop
core's "the caller supplied it, so it must be right" assumption from preferring a
prefetched GUID over the row the server actually named. Both are small; both are
silent if missed.

Emitting `HOLDLOCK` unconditionally rather than exposing it is the same call ADR
0036 made about the `fallback` option in reverse. A conflict-resolution
guarantee that a caller can accidentally switch off is not a guarantee, and
there is no legitimate use for the unhinted form behind this API: a caller who
wants the fast unsafe write can use `create`.

## Consequences

- No core change is required. `supports_upsert` flips on in
  `DBIO::MSSQL::Storage`; the structure crossing the seam is unmodified.
- One round-trip in every shape. `OUTPUT` returns the row with the statement, so
  unlike Oracle-below-23ai there is no second statement for identity, and unlike
  MySQL no follow-up SELECT beyond the one a plain `create` would also pay for.
- `conflict_target => 'any'` throws in both actions, as it does on Oracle. Core
  ADR 0036 §1 already carries the correction (core k108); this driver is the
  second engine that falsifies the original "works everywhere" claim.
- **`upsert` under concurrency can deadlock and must be retried by the caller.**
  Documented in POD, on the method, not only in an ADR.
- A table with enabled INSERT/UPDATE triggers supports only `count` / `void`.
- The GUID path (`new_guid('NEWID()')`, ADR 0001) keeps consuming a value per
  upsert including on the matched branch, exactly as Oracle's sequences gap;
  harmless, since the OUTPUT row overrides it, but the wasted value is real.
- MERGE needs `INSERT`, `UPDATE` and `SELECT` on the target: a grant that covers
  `INSERT` alone is enough for `create` and not for `upsert`.
- Azure Synapse is **out of scope** for this design and would need its own pass:
  it rejects the table value constructor in `USING`, and its `WHEN NOT MATCHED
  THEN INSERT` does not support tables with IDENTITY columns at all.
- `upsert_all` and `upsert_async` remain core-side questions. The multi-row
  `USING` a batch MERGE wants is where Msg 8672 stops being unreachable.

## Verified on a live server (2026-07-26)

Measured against MSSQL 2022 (16.0.4255.1, Developer Edition) in k3s `mssql-dev`,
over **both** transports — DBD::ODBC+FreeTDS and DBD::Sybase+FreeTDS — with
hand-written MERGE statements in the shape §2 specifies. The four points this
document originally listed as open are settled; two of the answers changed the
design rather than just confirming it.

| # | Claim | Result |
|---|---|---|
| 1 | `$sth->fetchrow_array` reaches the OUTPUT row | **holds, both transports, both branches.** Insert branch and update branch each returned the same `id`; the matched branch's update was really applied |
| 2 | `$sth->execute` carries MERGE's affected-row count | **only when no OUTPUT clause is rendered** — see below, this one bites |
| 3 | A column named in `ON` may also be assigned in `WHEN MATCHED` | **allowed.** No ORA-38104 equivalent, so no up-front validation is needed and dbio-oracle's check must *not* be copied |
| 4 | IDENTITY interaction on the not-matched branch | **the existing wrapper is both necessary and sufficient.** A supplied IDENTITY value is refused with error 544 ("Cannot insert explicit value for identity column … when IDENTITY_INSERT is set to OFF") and succeeds inside `SET IDENTITY_INSERT [t] ON/OFF` — i.e. `DBIO::Storage::DBI::IdentityInsert` keeps working over a MERGE, provided `_prep_for_execute` does not suppress it |

**The affected-row count and the OUTPUT clause are mutually exclusive, and that
promotes a §2 optimisation into a requirement.** With `OUTPUT` present, `execute`
returned `-1` on both transports for the branches that wrote a row (ODBC reported
`0E0` for a single-branch MERGE that wrote nothing, Sybase `-1`) — the statement
is result-set-shaped, so DBI has no count to give. With the OUTPUT clause removed
the same statements returned a usable `1` / `1` / `0E0` (insert / update / nothing
written) on both transports. So "no OUTPUT clause when nobody will read it" is not
merely a saved round-trip: without it `result => 'count'` cannot be implemented at
all. Core's `no_retrieve` flag is exactly the signal needed, and it already
arrives for both `count` and `void`.

**Further measurements, all on both transports:**

- **`OUTPUT $action` works** and returns `INSERT` / `UPDATE` correctly. Core ADR
  0036's deferred open question 8 ("was it an insert or an update?") is therefore
  free on this engine whenever it is picked up — noted, not built.
- **The single-branch MERGE behaves exactly as §3 designed.** `WHEN NOT MATCHED
  THEN INSERT` alone, hitting an existing row, yielded **zero OUTPUT rows** — so
  `on_conflict => 'nothing'` returns `undef` by construction, with no
  affected-row inspection anywhere.
- **The missing semicolon is caught, and the transports report it differently.**
  DBD::Sybase surfaces the server's own `10713 A MERGE statement must be
  terminated by a semi-colon (;)`, while DBD::ODBC only passes on the generic
  `Statement(s) could not be prepared`. Same for the trigger case: Sybase gives
  the numbered `334`, ODBC only its text. A driver that wants to rethrow error
  334 as a typed exception must therefore match on the **message text**, not the
  number — the number is not reliably available on the default transport.
- **The trigger restriction is real and its escape hatch works.** On a table
  carrying an `AFTER INSERT` trigger the MERGE with `OUTPUT … ` (no `INTO`) was
  refused verbatim with error 334; the identical MERGE without the OUTPUT clause
  succeeded. So `count` / `void` remain usable on triggered tables, as §4 claims.
- **MONEY survives the USING source.** `USING (SELECT ? AS [k], CAST(? AS MONEY)
  AS [m])` was accepted and stored `12345.6789` exactly — the expression form §2
  requires for `_prep_for_execute`'s rewrite is legal where the renderer needs it.
- **The SCOPE_IDENTITY trap is worse than §3 assumed.** With
  `SELECT SCOPE_IDENTITY()` appended to a MERGE, the *first* result set is the
  OUTPUT row and there is **no second result set at all** (`odbc_more_results`
  `0`; undef on Sybase). So `_execute` would not merely read the wrong thing — it
  would read the OUTPUT row *as* the identity and, for a single-column
  `OUTPUT INSERTED.[pk]`, get an accidentally correct answer that breaks the
  moment the OUTPUT list grows. Suppressing the append is not optional.
- **HOLDLOCK's mechanism is observable.** With `WITH (HOLDLOCK)`, a second
  session merging a *different, non-existent* neighbouring key blocked while the
  first session's transaction was open; without the hint the same statement went
  straight through. That is the key-range lock §4 relies on — and, in the same
  measurement, the deadlock exposure it costs, since unrelated keys serialize.

**Still not measured, and honestly so:** the race itself. Two sessions both
taking the not-matched branch cannot be forced deterministically from outside a
single statement, and reproducing it needs sustained concurrent load, which this
shared box will not get for a design document. The range-lock behaviour above is
the mechanism by which the documented guarantee works; the guarantee itself rests
on Microsoft's own statement plus Guzman and Swart, cited in References.

## Still open

- **Whether `_prep_for_execute`'s GUID-autoinc suppression (ADR 0001) needs the
  same MERGE-awareness as the SCOPE_IDENTITY append.** It sits in the same code
  path and was not exercised by these probes, which used IDENTITY tables only.
- **Everything about `upsert_all`.** A multi-row `USING` makes Msg 8672 reachable
  and needs the deduplication §4 mentions.

## Related

- core ADR 0036 (the API, the `{ target, action, set }` structure, the capability
  mechanism, the §4 identity rules this refines for a non-INSERT statement)
- dbio-oracle ADR 0036 (the other MERGE driver; same API decision, different
  identity and concurrency answers — read the two together)
- core ADR 0021 (capability flag instead of driver-name branch — why there is no
  separate `$rs->merge`)
- core ADR 0026 (the `use_dbms_capability` shape `supports_upsert` uses)
- ADR 0001 (GUID autoinc suppressing IDENTITY_INSERT and SCOPE_IDENTITY — the
  identity path a MERGE has to keep working)
- ADR 0003 (MONEY binds cast via `CAST(? AS MONEY)` — why the USING source must
  render expressions, not only placeholders)
- ADR 0007 (transport-neutral base — where the capability is declared)

## References

- Microsoft, *MERGE (Transact-SQL)* — grammar, the mandatory semicolon (error
  10713), the `<merge_hint>` slot, the HOLDLOCK paragraph under "Other
  considerations for concurrency", the parameterization note.
- Microsoft, *OUTPUT clause (Transact-SQL)* — `$action`, `INSERTED` semantics on
  MERGE, and the no-`INTO`-with-enabled-triggers restriction (error 334).
- Dan Guzman, *"UPSERT" Race Condition With MERGE* (2009).
- Michael J. Swart, *SQL Server UPSERT Patterns and Antipatterns* (2017) and
  *What To Avoid If You Want To Use MERGE* (2021).
- Aaron Bertrand, *Use Caution with SQL Server's MERGE Statement* — the original
  defect compilation Swart's 2021 post retests.
