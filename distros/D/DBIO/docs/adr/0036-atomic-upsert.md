# ADR 0036 — Atomic upsert API (ON CONFLICT / ON DUPLICATE KEY / UPSERT)

- Status: accepted
- Date: 2026-07-20 (proposed) · 2026-07-25 (accepted)
- Tags: feature, api, sql, capability, cross-repo, drivers

> **Accepted in maintainer review on 2026-07-25.** All nine open questions are
> settled — the numbered entries under [Open questions](#open-questions) record
> each verdict and point at the section holding it. Nothing here is implemented
> yet; no `.pm` was touched to produce this document. Implementation follows the
> cross-repo rollout in §7, core first.
>
> Two verdicts went *against* the draft's own recommendation and are worth knowing
> before reading further:
>
> - **Question 6 — nested relationships:** the flat-only restriction was rejected.
>   Nested data **cascades** and is in scope for v1 (§1).
> - **Question 1 — return shape:** neither the engine-dependent default nor a
>   uniform `'row'`. The values are `row_or_undef` (default), `row_or_die`,
>   `count`, `void`; there is no plain `'row'` (§4).
>
> Deferred by decision, not by omission: batch `upsert_all` (shape reserved in §1,
> implementation after v1) and insert-vs-update reporting (question 8).
>
> **Implementation split:** "v1" was delivered as two tickets, not one — k100
> is the **flat** upsert (landed 2026-07-25) and k101 the **cascade** on top
> (landed 2026-07-26). Two corrections that came *out* of implementing k100 are
> folded into §2 (split criterion sharpened) and §4 (driver obligation to name the
> written row); the corrections that came out of k101 are in §1, at the end of
> the "Nested relationships" subsection — all marked in place.
>
> **k105 (2026-07-26) added the conditional conflict branch**
> (`DO UPDATE ... WHERE`), which this document described in two places while the
> API could not express it. New subsection in §1 ("Conditional conflict branch");
> it also corrects §3 (a second capability, `supports_upsert_where`, with the
> criterion that keeps it from becoming a flag family) and §4 (`row_or_die` plus
> a condition is refused up front, not thrown at runtime).
>
> **k172 (2026-09-22) settled the MERGE question this ADR left open.** The
> maintainer's verdict is option (c): MERGE-based upsert (Oracle, DB2, SQL
> Server) is a deliberate, permanent non-goal, not a driver waiting to be
> written. `supports_upsert` stays INSERT-borne; a MERGE upsert would be its own
> capability with its own guarantees. New subsection in §3 ("MERGE-based upsert
> stays out of scope"); the §1 k205 boundary note and the §7 rollout rows for
> the MERGE engines now point at it.

## Context

### The over-promise this ticket closes

The driver READMEs (Pg, MySQL, SQLite) advertised "upsert via
`insert_or_update`". That was never true. `DBIO::Row::insert_or_update`
(`lib/DBIO/Row.pm`) is a bare alias:

```perl
sub insert_or_update { shift->update_or_insert(@_) }
sub update_or_insert { my $self = shift; return ($self->in_storage ? $self->update : $self->insert); }
```

It is a *client-side, two-step* helper: it looks at the in-memory
`in_storage` flag and issues either an `UPDATE` or an `INSERT`. It never
consults the server about whether a conflicting row exists, so it is subject
to the classic time-of-check/time-of-use race. The same is true of the
ResultSet-level composite writes that read-then-write:
`find_or_create`, `update_or_create` (`lib/DBIO/ResultSet.pm`), each of which
already carries a `B<Note>` in its POD warning that it "is subject to a race
condition ... use ... inside a transaction". These are honest, useful methods
— but none of them is an **atomic, server-side upsert**.

The README cleanup (audit 2026-07-20) stops the over-promise. This ADR is the
real feature: a cross-driver API for a single-statement upsert that pushes the
conflict resolution down to the engine — PostgreSQL / SQLite
`INSERT ... ON CONFLICT ... DO UPDATE|NOTHING`, MySQL
`INSERT ... ON DUPLICATE KEY UPDATE`.

### The seams (verified, so reviewers know the design is real)

**Insert SQL is generated through one chain.** `DBIO::Storage::DBI::insert`
(`lib/DBIO/Storage/DBI.pm`) assembles an options hash `$sqla_opts` — today its
only interesting key is `returning` — and calls:

```
Storage::DBI::insert
  -> _execute('insert', $source, $to_insert, $sqla_opts)
    -> _prep_for_execute -> _gen_sql_bind
      -> $self->sql_maker->insert( $from, $to_insert, $sqla_opts )   # <-- the seam
```

`$self->sql_maker->insert(...)` resolves to
`DBIO::SQLMaker::ClassicExtensions::insert($table, $data, \%options)`. That
method already reads `$options->{returning}` and, when set, appends the
RETURNING tail via `_insert_returning` before/around `next::method` (the
`SQL::Abstract` core). **This is the exact seam a driver extends for a conflict
clause** — it is the same shape as the RETURNING tail that is already bolted on
there. A driver's `DBIO::<Driver>::SQLMaker` subclass (e.g.
`DBIO::PostgreSQL::SQLMaker`, `DBIO::MySQL::SQLMaker`, `DBIO::SQLite::SQLMaker`
— all already exist) overrides `insert` to read a new `$options->{on_conflict}`
structure and append the engine-specific clause. No new core plumbing method is
strictly required; the options hash is already the transport.

**Capabilities are declared, never string-matched.**
`DBIO::Storage::DBI::Capabilities` holds a flat `@capabilities` list exposed
through `mk_group_accessors( dbms_capability => "_supports_$_" )` and
`mk_group_accessors( use_dbms_capability => "_use_$_" )`. A driver opts in with
`__PACKAGE__->_use_X(1)` or by defining `_determine_supports_X`; the default
`_determine_supports_*` returns `0` (conservative). This is the mechanism
ADR 0026 used for `transactional_ddl` / `supports_if_exists`, and the mechanism
ADR 0021 established the *anti*-pattern for (never branch on `$driver_name`).
The class also carries `$CONTRACT_VERSION` (currently `1.1`), guarded by the
`t/test/12_contract_version.t` tripwire per ADR 0024.

**RETURNING is already a per-engine capability.** `Storage::DBI::insert` only
sets `$sqla_opts->{returning}` when `$self->_use_insert_returning` is true
(`insert_returning` / `insert_returning_bound` capabilities). PostgreSQL
declares it version-gated (`_determine_supports_insert_returning` → `>= 8.002`);
MySQL does not declare it at all; the DBIO-SQLite driver does **not** currently
declare it either (even though SQLite has had RETURNING since 3.35). When
RETURNING is unavailable the insert path falls back to `last_insert_id` plus a
follow-up `SELECT` on the PK to retrieve autoinc/`retrieve_on_insert` columns.
That fallback is load-bearing for the upsert result story below.

**Conflict targets have an existing vocabulary.** `find`/`find_or_create`
already take `{ key => $constraint }`, resolved through
`DBIO::ResultSource::unique_constraint_columns($name)` (siblings:
`unique_constraints`, `unique_constraint_names`). The upsert conflict target
should reuse this idiom rather than invent a parallel one.

## Decision

The following is the recommended shape. Read each subsection as
"options → recommendation"; disagreements belong in [Open questions](#open-questions).

### 1. API surface

**Recommendation: a ResultSet-level `$rs->upsert(\%data, \%opts)` as the
primary (and, for the first cut, only) surface.** Defer a Row-level method.

Rationale: an upsert is inherently a *set* operation keyed on a unique
constraint of the table — it belongs beside `create`, `find_or_create`,
`update_or_create`, which all live on ResultSet and all read the ResultSource's
constraint metadata. A Row-level `$row->upsert` is awkward from both ends: a
Row that is not `in_storage` has no server identity to conflict on, and a Row
that *is* `in_storage` already has its PK, so a plain `->update` is the honest
call. If a Row-level convenience is wanted later it can delegate to
`$row->result_source->resultset->upsert({ $row->get_columns }, ...)`.

| Decision point | Options | Recommendation |
|---|---|---|
| Level | (a) ResultSet only; (b) Row only; (c) both | **(a)** for v1; revisit (c) after the ResultSet shape is proven |
| Conflict target | (a) `key => $constraint_name` (reuse find idiom, resolve via `unique_constraint_columns`); (b) `conflict_target => \@cols` (explicit columns); (c) default to primary key when neither given | **DECIDED 2026-07-25, see below:** accept `key` OR `conflict_target` (mutually exclusive, throw if both), plus the engine-native value `conflict_target => 'any'`; the PK default is conditional |
| DO UPDATE vs DO NOTHING | `on_conflict => 'update'` \| `'nothing'` | default **`'update'`**; `'nothing'` supported (see driver notes for MySQL emulation) |
| Which columns update | (a) all supplied non-target columns; (b) caller `update => \@cols`; (c) caller `update => \%exprs` for literal expressions | default **(a)**; allow (b) to restrict, (c) for `\'count + 1'`-style expressions |
| "attempted values" reference | engine differs: PG/SQLite `EXCLUDED.col`, MySQL `VALUES(col)` / aliased `new.col` | **core stays abstract**: default update-set means "set col to the value that was attempted to be inserted"; the *driver SQLMaker* renders the engine token. Caller-supplied literals pass through verbatim |
| Conditional update (`DO UPDATE ... WHERE`) | (a) not expressible; (b) `update_where => \%cond \| \'literal'` | **DECIDED 2026-07-26 (k105): (b), both forms** — see "Conditional conflict branch" below |
| Batch `upsert_all` | in scope / deferred | **shape reserved, implementation after v1** — see "Batch `upsert_all`" below |
| Nested relationships in `\%data` | flat only / cascade | **cascade, in v1** — see "Nested relationships" below |

Proposed signature and option keys (illustrative, for review):

```
$rs->upsert(
  \%data,
  {
    key            => 'name_uc',        # OR conflict_target => [qw/ team season /]
    # conflict_target => 'any',         # engine-native "any unique collision" (MySQL)
    on_conflict    => 'update',         # or 'nothing'
    update         => [qw/ score seen_at /],   # optional; default = non-target cols
    # update       => { count => \'count + 1', seen_at => \'NOW()' },  # expr form
    # update_where => { seen_at => { '<' => { -attempted => 'seen_at' } } },  # §1
    result         => 'row_or_undef',   # default; or 'row_or_die' | 'count' | 'void'  (§4)
    # fallback     => 'update_or_create',   # explicit, racy, per call only (§3)
  },
);
```

`upsert_all(\@rows, \%opts)` is named here only to reserve it; it is **not**
part of this ADR's decision (§7).

#### Conflict target — DECIDED 2026-07-25 (was open questions 4 and 7)

When neither `key` nor `conflict_target` is given, a three-way rule applies, all
of it decidable from the ResultSource before any SQL is built:

| Situation | Behaviour |
|---|---|
| source has a PK and `\%data` supplies **all** PK columns | default to the PK |
| source has a PK, `\%data` does **not** supply it | typed exception |
| source has **no** PK | typed exception |

The middle row is the one worth the code: with an AUTO_INCREMENT PK and no PK
value supplied, the statement cannot collide on the PK at all, so `upsert` would
silently degenerate into a plain `INSERT` — a feature that does nothing, with no
error to show for it. Ecto and ActiveRecord users hit exactly this.

Deliberately **not** done: defaulting to a lone unique constraint when there is
no PK. That is guessing among candidates, the DWIM class of behaviour ADR
0033/0034 already supplies enough of. No PK means: name a target.

**A demanded target the engine cannot honour is an error.** MySQL's
`ON DUPLICATE KEY UPDATE` has no conflict target and fires on any PK/unique
collision, so on a table with more than one unique constraint it can act on a row
the caller never targeted. Worked example — `player`, PK `id` (AUTO_INCREMENT),
unique `email`, unique `(team, season)`:

```perl
$rs->upsert(
  { team => 'A', season => 2026, email => 'x@y', score => 5 },
  { conflict_target => [qw/ team season /] },
);
```

With an existing row carrying `email = 'x@y'` under a *different*
`(team, season)`: PostgreSQL and SQLite raise a unique violation on `email` — the
clause does not cover that constraint, so nothing is quietly rewritten. MySQL
updates **the email row**, overwriting its `team`, `season` and `score`. One
source line: an exception on one engine, a silently corrupted unrelated row on
the other.

Hence:

| Caller's target | MySQL | PG / SQLite |
|---|---|---|
| a real target, table has further unique constraints | **typed exception** — the demanded guarantee is not deliverable | normal |
| a real target that is the table's only unique constraint | allowed, silently — the semantics provably coincide | normal |
| **`conflict_target => 'any'`** | allowed — this *is* `ON DUPLICATE KEY UPDATE` | exception with `DO UPDATE` (grammar requires a target); fine with `on_conflict => 'nothing'` |
| nothing given (PK default above) | treated as a real target | normal |

`'any'` earns its place because MySQL's "on whichever unique collides" is a
*legitimate* want, only not a portable one. Naming it lets a caller state the
intent instead of having it silently assumed, and the exception in row 1 names
`'any'` as the way to ask for it deliberately — teaching, not just complaining.

`carp_once` was rejected for row 1: a warning emitted once per process is the
wrong instrument for a semantic difference that can rewrite the wrong row.

`conflict_target => 'any'` together with `on_conflict => 'nothing'` is the very
common "insert unless it is already there, and do not care which constraint said
so", and it works across the three INSERT-tail engines: `ON CONFLICT DO NOTHING`
on PG/SQLite, a no-op set on MySQL.

**Not "everywhere", though — corrected 2026-07-26 (k108, found by the
dbio-oracle MERGE design pass).** An earlier version of this paragraph claimed it
worked on every engine. MERGE-based engines falsify that: Oracle's `ON` clause is
mandatory and must name columns, and the near-equivalent
`INSERT /*+ IGNORE_ROW_ON_DUPKEY_INDEX(tbl, idx) */` needs a specific index
*name* — neither is an "any" form. So on a MERGE engine `'any'` will have to
throw for **both** actions, not only for `DO UPDATE` the way the table above
records for PG/SQLite. Nothing to fix in code today: those drivers have
`supports_upsert = 0` and throw regardless. It becomes a real constraint the
moment one of them implements MERGE upsert, and the driver ADR should carry it
from the start.

#### Conditional conflict branch — DECIDED 2026-07-26 (k105)

Two earlier passages of this ADR described `DO UPDATE ... WHERE` — the §7
PostgreSQL rollout row and the `row_or_die` validation in §4 — while the flat
implementation (k100) gave a caller no way to express one. The decision closes
that gap by **building it**, because the use case carries it: "insert, or update
only if the incoming row is newer",

```sql
ON CONFLICT (id) DO UPDATE SET ... WHERE excluded.updated_at > table.updated_at
```

is the classic last-write-wins guard, and without it the caller must choose
between overwriting newer data and giving up atomicity. PostgreSQL and SQLite
share the grammar; MySQL has no equivalent.

**The option is `update_where`.** Not `where`: `upsert` already folds the
resultset's own condition into the inserted values through `new_result`, exactly
as `create` does, so a bare `where` at the call site would be indistinguishable
from the search condition it is not. `update_where` names the branch it belongs
to and sits next to `update`, which conditions the same clause.

**Both forms, and the abstract one is not a courtesy.** The interesting
conditions are precisely those comparing *both* rows, and both sides are sayable
without an engine token:

- an **unqualified column** is the **stored** row — the row the statement
  collided with. PostgreSQL and SQLite both define an unqualified reference in
  the `DO UPDATE` clause that way, and SQL::Abstract renders it already.
  **Corrected 2026-09-22 (k205): true of the *meaning*, false of the
  *rendering*.** A bare column is only unambiguous when one correlation is in
  scope; the moment the condition also references the stored row (which is the
  whole point of a conditional branch) two correlations are in scope and the
  bare reference is ambiguous. It has to be *qualified* with the target table —
  see the k205 amendment at the end of this subsection.
- `{ -attempted => $col }` is the value the statement **tried to insert**. That
  marker already exists in the normalized structure's `set`, where the driver
  renders it as `EXCLUDED.col` / `VALUES(col)`.

So the canonical guard is engine-neutral:
`update_where => { updated_at => { '<' => { -attempted => 'updated_at' } } }`.
A literal (`\'excluded.updated_at > artist.updated_at'`, `\[ $sql, @bind ]`)
stays available for what the abstract form cannot say and is engine-specific by
construction — the caller writes engine SQL knowingly, which is the honest
answer where no abstraction exists.

**Core validates the shape and nothing else** — hashref / arrayref / literal,
and non-empty. It does not walk the condition, exactly as `search` does not walk
its `\%cond`; a column that does not exist is the engine's error. The one
addition to the driver's job is that `{ -attempted => $col }` may occur at any
depth here, where in `set` it is only ever a top-level value: a driver has to
substitute it recursively before handing the condition to its `_recurse_where`.
If that walk turns out identical in the second driver, core is the place for a
shared helper — it is not written before there are two.

**Written, now that there are two — 2026-08-04 (k133).** The two halves
turned out *not* identical, which is what made the comparison worth having:
dbio-postgresql registered the marker as a SQL::Abstract operator for the
duration of the one call (`local $self->{expand_op}{attempted}` plus
`make_unop_expander`), dbio-sqlite hand-wrote a recursive walk substituting
`{ -ident => "excluded.$col" }`. Core lifts the PostgreSQL mechanism, as
`_upsert_condition_sql($cond)` → `($sql, @bind)` on `DBIO::SQLMaker`,
parameterized over the one engine-specific piece: `_upsert_attempted_sql($col)`,
which has **no core default** — core stays abstract about the token, so the base
class throws and names itself rather than guessing one engine's spelling for
another. Riding SQL::Abstract's own expansion pass is the reason: that pass
already visits every node, so "at any depth" — nested `-and`/`-or`, `-in` lists,
`-between`, function arguments — holds by construction instead of by
enumeration, and enumeration is exactly what a walk has to get complete.

SQLite's `-ident` choice **dissolves rather than being averaged in**. It existed
only because a `-literal` in the bare right-hand-side position
(`{ rank => { -attempted => 'rank' } }`) renders `col x` instead of `col = x` —
SQL::Abstract reads a literal on the right of a column as the operator itself.
That is a property of a hand-written walk: `make_unop_expander` turns the bare
right-hand side into a comparison *before* the node is rendered, so a `-literal`
is correct in every position. The visible consequence is that the condition now
spells the pseudo-row exactly as the `SET` list does, instead of letting
SQL::Abstract quote both halves of an `-ident`.

Only the condition half moves; each driver keeps its own `SET`-list rendering,
where the marker is only ever a top-level value and one `_SWITCH_refkind` covers
it. This is additive on the core side (a driver that keeps its own substitution
calls neither method) and therefore does not bump `$CONTRACT_VERSION` — it lands
inside the same unreleased 1.2 generation as the branch itself.

**The stored side has to be qualified — added 2026-09-22 (k205), the first
live run against real PostgreSQL.** The premise recorded above — a bare column
"is what SQL::Abstract renders anyway, so nothing here has to help" — held for
every mock test and failed the first time a conditional upsert met a real
server. `t/42-upsert-live.t` in dbio-postgresql died:

```
ERROR: column reference "score" is ambiguous
INSERT INTO "dbio_upsert_test" (...) VALUES (...)
  ON CONFLICT ("name") DO UPDATE SET ... WHERE "score" < EXCLUDED."score" ...
```

The reason is structural, not PostgreSQL-specific: inside `DO UPDATE` **two**
correlations are in scope — the target table and the `EXCLUDED` pseudo-row — and
both carry every column name. A bare `"score"` names neither, so the engine
refuses it. The abstract vocabulary was sound (`{ -attempted }` for the attempted
value, bare for the stored value); only the *rendering* of the bare half was
incomplete. The mock never caught it because the mock storage never resolves the
correlations — it captures the SQL string, and an ambiguous string is still a
string.

**Decision: in the conditional branch, a bare (stored-side) column is qualified
with the target table.** Not with `EXCLUDED` — that is the *other* correlation,
the attempted row, which the caller reaches through `{ -attempted }`. This is
**determinate for ON CONFLICT** precisely because there is exactly one target
correlation plus the one pseudo-row: "the unqualified stored column" can only
mean the target table. Explicit `EXCLUDED` references and already-qualified
columns are left exactly as written; the **unconditional** upsert (no `WHERE`)
never reaches this code and is byte-for-byte unchanged.

**Split.** The qualification is core's — it lives where the bare column is
rendered: `_upsert_condition_sql` on `DBIO::SQLMaker::ClassicExtensions` grows an
optional second argument, the target table, and when given one it installs a
`local` `ident` expander alongside the `-attempted` one already there. That
expander rides the same expansion pass, so bare columns are qualified at any
depth by construction, single-part idents only (an already-qualified column has
more than one part and is skipped), and the `-attempted` marker — which expands
to a `-literal`, never an ident — is untouched. The argument is optional, so a
caller that passes none renders exactly as before: additive, no
`$CONTRACT_VERSION` bump, same unreleased 1.2 generation. The **driver** half is
one line each: `DBIO::PostgreSQL::SQLMaker` and `DBIO::SQLite::SQLMaker` thread
the target table they already hold in `insert($table, …)` down through
`_insert_on_conflict` into the `_upsert_condition_sql($where, $table)` call.
Tracked cross-repo (§ below).

**Boundary with the broader k172 question, held deliberately.** k172 asks
whether the whole upsert vocabulary should carry *two named correlations*
(source/target aliases) the way `MERGE` does — a capability decision spanning the
MERGE engines (Oracle, DB2, SQL Server), `supports_upsert`, and a second alias
name. **Decided since — 2026-09-22 (k172): the answer is no.** MERGE-based upsert
is a deliberate, permanent non-goal; the vocabulary is *not* generalised to two
named correlations, and the MERGE engines stay without `$rs->upsert` under
`supports_upsert` (see §3, "MERGE-based upsert stays out of scope"). That verdict
does not disturb k205, which remains the strictly narrower, live-reproduced,
release-blocking case: the *conditional
ON CONFLICT* branch, where the two correlations are already fixed by the grammar
(target table + `EXCLUDED`) and the stored side is therefore determinable without
any new alias vocabulary. The two do not conflict — k205 qualifies against the
target table that ON CONFLICT already implies; k172, if ever accepted, would
generalise the naming for engines where the correlations are not implicit.

**Transport: a fourth key, present only when there is one.** The normalized
structure becomes
`{ target, action, set, where }`, and `where` is **omitted** when the caller
passed no condition, so a driver that never sees the key renders exactly what it
rendered before the option existed. The rest of the driver contract:
render the condition after the `SET` list and before `RETURNING`, and place its
bind values accordingly.

**Refused combinations, all at option-validation time, all engine-independent:**

| Combination | Why |
|---|---|
| `on_conflict => 'nothing'` | there is no update branch to put a condition on. Same shape as the existing refusal of `update` with `'nothing'` |
| `result => 'row_or_die'` | a conditional update writes no row when the condition does not hold |
| `fallback => 'update_or_create'` | the fallback writes unconditionally, so it would overwrite exactly the rows the condition protects. Joins the three combinations §3 already refuses there |
| per-relation entry in a cascade | `update_where` is a decision about the whole call, like `on_conflict`, `update` and `result` |
| top-level in a cascade, when rows depend on that row | a conditional update may write no row, and then there is no key to hand to the children — identical to the `on_conflict => 'nothing'` rule below, and refused in the same place |

`row_or_die` is the one the earlier text got wrong: §4 said this case "can only
be documented plus thrown at runtime". It cannot only be — and should not be.
The contradiction is in the *call*, not in the data: a conditional update exists
in order to possibly write nothing, which is verbatim the argument by which
`row_or_die` + `DO NOTHING` is already refused up front. Leaving it to runtime
would also **misdiagnose** it: the runtime `row_or_die` throw says the engine
could not name the row and that "this follows from the table shape, not from the
data", which is exactly the wrong explanation for a condition that held false.
§4 is corrected accordingly.

A cascade whose *top* row nothing depends on may carry a condition: the
`belongs_to` parts are written first and unconditionally, and the conditional
row may write nothing and return `undef`, precisely as it does flat. Refusing
that would be stricter than the rule for `on_conflict => 'nothing'`, which is
the same situation.

#### Nested relationships — cascading upsert, IN SCOPE for v1 (was open question 6)

**DECIDED 2026-07-25.** The draft restricted `\%data` to a flat single-table
column set. The maintainer's call is the opposite: nested data cascades, and
`upsert` upserts the parts. The work is volume, not guesswork — the ordering
machinery exists, the identity precondition is already settled in §4, and the
per-relation conflict targets are stated by the caller rather than inferred.

**What is promised, precisely.** No engine has a multi-table upsert, so a cascade
is inherently more than one statement. The guarantee is therefore:

> N atomic upserts, in dependency order, inside one transaction — all-or-nothing,
> and **every part** individually free of the read-then-write race.

That is strictly stronger than today's `update_or_create` cascade (which must
guess at every part) and strictly weaker than "one statement". POD must state it
in those words and must not call it "an atomic upsert".

**Ordering** reuses what `DBIO::Row::insert` already does for multicreate:
`belongs_to` parts run *before* the row (their PK becomes its FK),
`has_many`/`might_have` parts run *after* it (its PK becomes their FK).

**Targets per relation, never inferred.** The three-way default rule above applies
*per part*: a part whose data does not supply the related source's PK, and which
has no per-relation target, throws. Targets are given in a `relations` structure
mirroring the data:

```perl
$rs->upsert(
  { title => 'X', artist => { name => 'Y' }, tracks => [ {...}, {...} ] },
  {
    conflict_target => [qw/ title artist_id /],
    relations => {
      artist => { key => 'artist_name_uc' },
      tracks => { conflict_target => [qw/ cd_id position /] },
    },
  },
);
```

**Identity becomes a precondition, not a nicety.** Setting a child's FK requires
the PK of the parent part just written — literally the §4 problem. So every
`belongs_to` part needs `row_or_die`-grade identity; on an engine/table shape that
cannot name the written row (MySQL, no AUTO_INCREMENT PK, `conflict_target =>
'any'`) the cascade is impossible and throws. Since §4's rule reads static schema
metadata, this is checked **before the first statement runs** — the cascade fails
in development, not data-dependently in production.

**Two rules that had to be settled to make the above coherent:**

- **`result` is restricted when data is nested.** Only `row_or_undef` and
  `row_or_die` are valid; `count` and `void` throw at option-validation time. A
  count across a cascade has no well-defined meaning, and `void` would deny the
  cascade the identity it structurally needs. The return value is the **top-level
  Row only** — related rows are not collected, mirroring what `create` with
  nested data returns.
- **Transaction handling.** The cascade wraps itself in a `txn_scope_guard`. When
  the caller is already inside a transaction it *joins* it, so a failing cascade
  rolls back the caller's outer work too. No savepoint magic is invented here; a
  caller who wants the cascade isolated from surrounding work opens their own
  savepoint. Documented rather than clever.

**`has_many`: only the listed children are upserted, never deleted.** Children
absent from the list are left untouched. "Replace the set" is `set_$rel`
semantics and something else entirely; implicit deletion would be the nastiest
surprise this API could offer.

**`many_to_many` is out of scope and throws.** It would mean upserting bridge
rows, which reopens the deletion question above for the link table.

Cost, stated so it is not discovered later: the test matrix becomes relation type
× engine × identity case. Core covers the plumbing and the throws on mock storage;
each driver covers its own real round-trips.

**Six things implementing this (k101, 2026-07-26) settled or corrected.**

1. **The example above does not execute as written — corrected.** `artist => {
   name => 'Y' }` keyed on `name` supplies *only* its conflict target, so the
   default update set ("every supplied column that is not target or PK") is
   empty, and §1's own rule for the flat case refuses that, pointing at
   `on_conflict => 'nothing'`. In a cascade that pointer is not a choice the
   caller has: `DO NOTHING` may write no row, and a part something hangs off must
   be nameable. Yet the key-only lookup row is exactly what a `belongs_to` part
   almost always *is*. So in a cascade — and only there — a node whose conflict
   branch would set nothing **re-asserts its conflict target** instead:
   `col = <the value that was attempted>`. That is a no-op on the value and keeps
   the row returned, which is precisely the idiom §4 already blesses for MySQL's
   `pk = LAST_INSERT_ID(pk)` identity set. It applies to the top-level row of a
   cascade too, whose every column can equally be target-plus-foreign-key. The
   flat behaviour is untouched: there the caller has both alternatives and the
   exception teaches them.

   Without this the cascade would have been unusable for the pure link row as
   well (a bridge child whose every column is part of its composite key).

2. **A per-relation entry takes `key`, `conflict_target` and its own
   `relations` — nothing else.** `on_conflict`, `update`, `update_where` (core
   k105) and `result` are decisions about the whole call, and a per-part
   `on_conflict => 'nothing'` is incoherent with the identity precondition
   anyway. Correction 1 is what makes
   the narrow set sufficient. Nesting is recursive to any depth; the ADR only
   showed one level.

3. **"Checked before the first statement" is true of everything core can see,
   and that is not everything.** The whole tree is planned — split, classified,
   targets resolved, identity preconditions asserted — before a statement runs,
   including for a *sibling* part that would otherwise have been validated only
   after an earlier sibling was already written. What core cannot decide
   statically is whether a given engine can name the row for a given table shape;
   that is the driver's §4 rule and it surfaces as the part's own `row_or_die`
   exception, inside the transaction that then rolls back. Still deterministic,
   still first-call, just not core's check.

4. **A Result object in the nested data throws.** The ADR says "nested data",
   which left blessed rows open. `create` treats an `in_storage` row as "link
   this" and an unstored one as "insert this"; for `upsert` that same object
   would have to mean either "write these values" or "only link it", and picking
   is the DWIM this ADR refuses elsewhere. Pass `{ $row->get_columns }`, or set
   the foreign key.

5. **A `has_many`/`might_have` part whose relationship has no reverse throws.**
   `DBIO::Row::insert` derives the child's foreign key through
   `reverse_relationship_info`, and when there is none it silently inserts the
   children *unlinked*. Inherited into a cascade that would be an orphan write
   inside a committed transaction, so the cascade refuses instead. This is a
   place where the cascade is deliberately stricter than the multi-create it
   reuses.

6. **`upsert_all` throwing on nested data has nothing to attach to.** §1 reserves
   the batch shape including "nested data in `upsert_all` throws", but
   `upsert_all` is not implemented, so the rule cannot be coded or tested. Core
   pins it with an assertion that the name is still unclaimed, so that whoever
   implements it meets the requirement rather than discovering it.

#### Batch `upsert_all` — shape reserved, not implemented (was open question 5)

**DECIDED 2026-07-25: design the shape now, implement after v1.** The risk was
never the implementation, it was that the single-row API would bake in choices a
batch API then had to break. With the cascade in scope that argument got stronger,
not weaker: batch × nested data is a *list of trees*, each with its own per-part
targets and identity requirement — multiplicative, not additive.

So the shape is fixed here and the single-row API is built to fit it:

| Aspect | Reserved decision |
|---|---|
| Data | **flat rows only** — no cascade in batch. Nested data in `upsert_all` throws |
| `result` | only `count` / `void`. Per-row row-back is not offered (ordering of rows that wrote nothing has no good answer) |
| `conflict_target` / `key` | applies to **all** rows in the call, not per row |
| `fallback` | **forbidden** in batch — it would degrade into N separate racy `update_or_create` calls, i.e. worse than the original problem |
| `on_conflict`, `update` | as in the single-row API |

Nothing above needs to change in v1; it only needs v1 not to contradict it. The
name `upsert_all` is reserved.

### 2. SQLMaker seam per driver

**Recommendation: extend `DBIO::SQLMaker::insert` in each driver's SQLMaker
subclass**, reading `$options->{on_conflict}`, exactly parallel to how
`_insert_returning` appends the RETURNING tail today.

Core populates `$sqla_opts->{on_conflict}` (a normalized structure:
`{ target => \@cols | { constraint => $name, columns => \@cols } | 'any',
action => 'update'|'nothing', set => \%col_to_expr, where => $cond }`, the last
key present only when the caller passed `update_where`, k105) inside the
storage insert path when the ResultSet
`upsert` opts asked for it. The base `DBIO::SQLMaker` does **not** understand
`on_conflict`; only a driver override does. This is safe precisely because the
[capability flag](#3-capability-flag) gates emission — core never routes an
`on_conflict` options hash to a SQLMaker whose driver has not declared support.

**`key => $constraint` travels as both halves — corrected 2026-07-25 (k104).**
The target hashref carries the constraint *name* and the *columns core
resolved it to*. The first version passed the name alone, which made
`key => $constraint` unusable on any engine whose conflict-clause grammar knows
a column list only: `insert` in a SQLMaker receives `($table, $data, $options)`
and no ResultSource, so a driver cannot resolve the name itself — dbio-sqlite
had to throw on `key`, contradicting §1's promise that the `find` idiom is
reusable here. With both halves present every driver can pick what its grammar
takes.

Which half a driver *should* prefer is not symmetric. A DBIO constraint name is
**client-side metadata** from `add_unique_constraint` — it is a key in the
ResultSource's `unique_constraints` hash and need not name anything the server
knows; `primary` in particular never does. `ON CONSTRAINT <name>` is therefore
only correct when the schema was deployed from this metadata *and* the engine
kept the name. The column list is the portable half. A driver that renders
`ON CONSTRAINT` should treat it as an opt-in for schemas known to match, not as
the default reading of the hashref.

Driver-facing consequence: a hashref target now has **two** keys. A driver that
validated it with an exact `keys %$target == 1` check rejects the new shape and
must be adjusted.

| Engine | Clause the driver SQLMaker emits | Notes |
|---|---|---|
| PostgreSQL (≥ 9.5) | `INSERT ... ON CONFLICT (col, ...) DO UPDATE SET col = EXCLUDED.col ... [WHERE ...] RETURNING ...` | conflict target required for DO UPDATE; **the column list is what a resolved target renders as** — `ON CONSTRAINT name` is grammatically valid but names a *server-side* constraint, which a DBIO constraint name need not be (see below); `EXCLUDED` pseudo-row; RETURNING native. The `WHERE` became reachable with k105 (`update_where`) and needs `supports_upsert_where` |
| SQLite (≥ 3.24 upsert; ≥ 3.35 RETURNING) | `INSERT ... ON CONFLICT (col, ...) DO UPDATE SET col = excluded.col ... [WHERE ...]` | same grammar as PG, `WHERE` included; RETURNING only if driver declares `insert_returning` (currently it does not — see §4) |
| MySQL / MariaDB | `INSERT ... ON DUPLICATE KEY UPDATE col = VALUES(col) ...` (8.0.19-) / `... AS new ... col = new.col` (8.0.20+) | **no conflict target** — fires on *any* PK/unique collision; no RETURNING; affected-rows is 1=insert, 2=update |
| Oracle / DB2 / SQL Server | `MERGE ...` — a different statement shape, not a tail on INSERT | out of scope for v1; separate follow-up (§7). Default capability `0` → these throw, correctly |
| Everything else | none | capability `0` → throw |

Naming: a private builder on the driver SQLMaker, e.g.
`_insert_on_conflict(\%on_conflict)` returning `($sql_tail, @bind)`, mirrors the
existing `_insert_returning`. The core normalized structure is engine-neutral;
each driver's builder owns its own token choices (`EXCLUDED` vs `VALUES(...)`,
target-required vs target-forbidden, `DO NOTHING` availability).

**Two traps, learned the hard way in dbio-postgresql k43 and dbio-sqlite k18 —
every driver combining the clause with RETURNING walks into both.** The wording
"a tail like `_insert_returning`" above is right about the signature and wrong
about the placement:

1. **The conflict clause goes *before* RETURNING** (`INSERT … VALUES … ON
   CONFLICT … RETURNING …`), while the generic `insert` appends the RETURNING
   tail last. So the driver cannot append to what the base produced; it has to
   assemble in grammar order — hold `returning` back over the call to the base,
   then append both tails itself.
2. **Put `returning` back into `$options` afterwards.** `Storage::DBI::insert`
   reads `$sqla_opts->{returning}` *again after* `_execute`, to decide whether
   to fetch the returned row off the handle. A driver that deletes the key to
   suppress the base tail and forgets to restore it produces perfectly correct
   SQL whose result is never fetched — `result => 'row_or_undef'` then yields
   `undef` for a row that exists. Silent, and it looks like an identity problem
   rather than a plumbing one.

Both drivers now do exactly this, and both pin the options-transport contract in
a test (the `on_conflict` key consumed, the `returning` key still present) rather
than only in a comment.

**Which half of a resolved target a driver renders — settled 2026-07-25.** Core
sends `key => $constraint` down as *both* halves,
`{ constraint => $name, columns => \@resolved }`, and the rule is: **render the
columns.** A DBIO constraint name is client-side metadata from
`add_unique_constraint` and need not name anything the server knows —
`'primary'`, which `unique_constraint_names` returns for the primary key, exists
in no PostgreSQL database, so `ON CONSTRAINT "primary"` is a guaranteed runtime
error. The resolved columns name the very index the constraint names, and they
are correct whether or not the schema was deployed from this metadata.
dbio-sqlite has no choice anyway — its grammar knows a column list only — and
throws when the columns are absent; dbio-postgresql renders the columns when
present and falls back to `ON CONSTRAINT` for a bare `{ constraint => $name }`,
which is also what a pre-k104 core sends.

That fallback is currently the *only* route to `ON CONSTRAINT`, and it cannot be
reached from the public API: `$rs->upsert` takes `key`, a column list, a single
column name, or `'any'` — never a hashref. So the legitimate reasons to name a
server-side constraint (several constraints over the same column set; an
exclusion constraint, which PostgreSQL can only arbitrate by name) have no API
today. Recorded as a gap rather than papered over; the small fix is for core to
pass a caller-supplied `conflict_target => { constraint => $name }` through
untouched, landing exactly on the driver branch that already exists.

Engines with **no** native atomic upsert are handled entirely by the capability
gate (§3) — there is no driver-name branch anywhere (ADR 0021).

**Core plumbing — DECIDED 2026-07-25 (was open question 3):** ride the existing
`sql_maker->insert` options transport; no separate `Storage::DBI::upsert`.
Settling §4 strengthened this rather than weakening it. The MySQL identity path
decomposes into two pieces that both already exist: appending
`<pk> = LAST_INSERT_ID(<pk>)` to the conflict set is SQLMaker work at the very
place the `on_conflict` clause is built, and reading `last_insert_id` plus a
follow-up SELECT on the PK is *verbatim* the fallback `Storage::DBI::insert`
already runs when `insert_returning` is absent. A distinct `upsert` method would
have to duplicate or awkwardly tap that machinery.

Falsifiable split criterion, so this does not become an article of faith: **the
moment `Storage::DBI::insert` starts carrying result-handling logic that only
upsert needs** — as opposed to passing an option through — split it out. The §4
case distinction belongs in the ResultSet layer and in the driver, not in
`insert`.

Wording sharpened 2026-07-25 after k100. The first draft said "a branch that would
not exist without upsert", which the flat implementation trips immediately and
harmlessly: it adds an `on_conflict` passthrough with a capability assert, a
`no_retrieve` short-circuit for `void`/`count`, and writes the statement's return
value back for `count`. Three touch points, no duplicated identity machinery —
exactly the small diff this decision was taken to get. What the criterion is
really guarding against is `insert` growing its own copy of the retrieval logic.
Re-check it at k101, where transaction ordering joins the picture.

### 3. Capability flag

**Recommendation: one new capability, `supports_upsert`, default `0`**, on
`DBIO::Storage::DBI::Capabilities`, using the established
`mk_group_accessors( use_dbms_capability => ... )` shape (ADR 0026). Drivers opt
in with `__PACKAGE__->_use_supports_upsert(1)` or a version-gated
`_determine_supports_supports_upsert` (as PG does for `insert_returning`).

Deliberately **one flag, not a family.** The differences between engines
(conflict-target required vs forbidden, `DO NOTHING` availability, EXCLUDED vs
VALUES) are *dialect* facts that live naturally in the driver's SQLMaker
override — pushing each into its own capability flag would proliferate the
surface for no gain, the same lesson ADR 0026 drew ("no new abstraction",
"keeps the addition small"). The one place a second flag might earn its keep is
RETURNING, and that flag **already exists** (`insert_returning`) — §4 reuses it
rather than adding `supports_upsert_returning`.

**One exception, and it comes with a criterion — added 2026-07-26 (k105).**
The conditional conflict branch (`update_where`, §1) gets its own capability,
`supports_upsert_where`, default `0`, same shape. The criterion that makes this
an exception rather than the start of the family the paragraph above rejects:

> A part of the normalized structure needs its own flag exactly when a driver
> that does not know about it would **silently produce a valid statement with
> different semantics**. Dialect facts a non-implementing driver turns into
> invalid SQL or an exception need no flag.

Every example in the paragraph above fails that test, which is why one flag was
right: drop the conflict target and PostgreSQL rejects the statement; ignore
`action => 'nothing'` and there is no set to write. Drop the `WHERE` and the
result is a perfectly valid **unconditional** `UPDATE` — the last-write-wins
overwrite the condition was written to prevent, with no symptom whatsoever. Core
and driver ship as separate distributions with independent release cycles, so
"new core, older driver" is a configuration a user really can have; the default
of `0` is what keeps that user's guard from evaporating. `supports_upsert_where`
is checked in `ResultSet::upsert` (caller-facing message) and again in
`Storage::DBI::insert` (belt and braces, as `supports_upsert` already is).

Consequence for the engines: MySQL rejects `update_where` by **never declaring
the capability** — no code in `DBIO::MySQL::SQLMaker` at all, and core throws
before a statement is built. PostgreSQL and SQLite declare it when they render
the clause.

**What the flag *means* — pinned 2026-08-04 (k134).** "Declare it when they
render the clause" was written as the obvious reading and turned out not to be
the only one: the two drivers that render the branch arrived at opposite ones,
each argued in its own commit. dbio-sqlite declares it unconditionally and says
so explicitly — a fact about `DBIO::SQLite::SQLMaker`, decoupled from the
RETURNING gate on `supports_upsert`, because that gate is about *naming the
written row* and a condition that does not hold writes no row by design.
dbio-postgresql **derives** it: `_determine_supports_supports_upsert_where`
returns `$self->_use_supports_upsert`, on the argument that the `WHERE` belongs
to the same 9.5 `ON CONFLICT` grammar, so the flag should answer "can this
connection effectively do a conditional upsert". Behaviourally these agree
today — core consults both flags, `supports_upsert` first, so an upsert never
proceeds on the `WHERE` flag alone — but the third driver to implement the
branch would be copying one of two contradictory templates.

Core pins the **declared-fact** reading: `supports_upsert_where` is a plain fact
about the conditional branch itself, not a derived reading of `supports_upsert`.
Three reasons, in order of weight. A derived flag carries **no information** — if
it always equals `supports_upsert` it is redundant, and its whole justification
above is that it answers the one question the other flag cannot, the dialect
difference a driver can drop *silently*. Deriving **imports an unrelated
condition**: PostgreSQL's `supports_upsert` gate includes the RETURNING
requirement (§4), which is about naming the written row, so folding it in makes
this flag report a limitation the branch does not have. And the second `0` buys
nothing **diagnostically**, since core throws on the `supports_upsert` gate
first and a version-gated-off driver is already named there, by the right gate.

The rule, stated so the third driver cannot get it wrong:

> Answer about the **conditional branch itself**. A version probe is legitimate
> *when the engine's own support for the conditional branch is
> version-dependent* — that is the same fact, measured. What is not legitimate
> is deriving the answer from `supports_upsert`, or from anything else the
> conditional branch does not depend on: RETURNING, the identity transport,
> connection state.

For PostgreSQL this collapses to a static `1`. `ON CONFLICT` arrived complete in
9.5, `WHERE` included, so there is no PostgreSQL that has the upsert grammar and
not the condition — nothing is lost by declaring it, and the version question is
already answered by `supports_upsert`. dbio-postgresql therefore embodies the
reading core did not take, and correcting it (the derivation and the paragraph
of `DBIO::PostgreSQL::Storage`'s DESCRIPTION that argues for it) is a follow-up
ticket on that repo — picked, not blended.

The RETURNING interplay and the conflict-target-forbidden fact on MySQL are
handled without new flags:

- RETURNING: reuse `insert_returning` (already per-engine).
- MySQL-has-no-target: the **driver storage** validates the target and **throws**
  on a demanded target it cannot honour, per §1. Two corrections to what this
  bullet said before: an early draft suggested core might `carp_once` — void
  since the question-4 decision, the verdict is an exception and core does not
  inspect the target for engine compatibility at all. And the validation cannot
  live in the SQLMaker as claimed: `insert` there receives
  `($table, $data, $options)` and has **no ResultSource**, so it cannot read
  `unique_constraints` and cannot know whether the table has other unique indexes
  (dbio-mysql k27). It sits in `DBIO::MySQL::Storage`, still ahead of SQL
  generation, still a typed exception.

  Worth copying for any other targetless engine: the check compares **column
  sets**, not constraint names. A named constraint mirroring the primary key is
  one index to the engine, and "does the table have another unique index" is the
  only question that matters.

**Unsupported engines — DECIDED 2026-07-25 (was open question 2):** a driver that
does not declare `supports_upsert` makes `upsert` throw a typed
`DBIO::Exception`. `upsert` never silently degrades to a client-side two-step.

The reason it is worth being firm about, given that §4 *does* degrade (to
`undef`): the two degradations differ in kind. §4 weakens the **report** about a
write that was still guaranteed atomic. A two-step fallback would drop the
**guarantee itself** — and that is precisely the over-promise the driver READMEs
are being cleaned of (`insert_or_update` advertised as upsert while being a
client-side `in_storage ? update : insert`). Repeating that mistake inside the
core API would be worse than making it in a README.

Callers on an unsupporting engine have a clean, capability-based branch available
without any driver-name string match, which is the ADR 0021-conform way to write
portable library code:

```perl
$rs->result_source->storage->_use_supports_upsert
  ? $rs->upsert(\%data, \%opts)
  : $rs->update_or_create(\%data);   # documented as racy, visible at the call site
```

**The `fallback` escape hatch stays — DECIDED 2026-07-25 (was open question 9).**
`fallback => 'update_or_create'` is kept as an explicit, per-call opt-in:
upsert-with-fallback in a *single* call is not the same thing as a hand-rolled
wrapper, and the edge cases where that reads better are real. Two points this
pins down, so the option is not underspecified:

- **What it returns.** The fallback path runs the client-side
  `update_or_create`, which always yields a Row. So `row_or_undef` and
  `row_or_die` are satisfiable, `count` returns a synthetic `1` (POD states
  plainly that this is not a real affected-rows figure), `void` discards.
  Without this rule the same call would return different *types* depending on
  the engine — precisely what §4 exists to prevent.
- **Per call only.** `fallback` is never a schema- or storage-level default. A
  global switch is exactly the lever that would re-enable the race
  application-wide, including inside libraries that never asked for it — the same
  reasoning that keeps `result` per-call.
- **What it targets — added 2026-07-25 (k104).** This section pinned the
  fallback's return *type* but said nothing about its conflict *target*, and the
  implementation quietly passed only `key` on to `update_or_create`: a call
  carrying `conflict_target` fell back onto a different constraint than the
  atomic path would have used, and with no target at all it fell into `find`'s
  heuristics mode, which ORs every satisfiable unique constraint together. Both
  can write a different row than the engine would have. So: the fallback looks
  the row up by the target the atomic statement would have conflicted on —
  `key` when given, otherwise `'primary'` (which the §1 default rule guarantees
  is fully supplied). `conflict_target` **cannot** be expressed that way at all,
  since `update_or_create` takes a constraint *name*, never a column list; the
  combination therefore throws at option-validation time with a message pointing
  at `key => $constraint`, joining the two combinations already refused there
  (`on_conflict => 'nothing'` and a restricted `update`). Resolving the column
  list back onto a named constraint via `unique_constraints` was the alternative
  and was rejected: it succeeds or fails depending on schema metadata, so the
  same option pair would be legal in one source and illegal in the next, it has
  no answer at all for `'any'`, and picking among constraints with the same
  column set is the guessing §1 refuses elsewhere.

No warning is emitted when the fallback engages: it was explicitly requested, so
it is not a silent degradation.

Contract version bumps **1.1 → 1.2** (ADR 0024): `supports_upsert` is a new
entry in the public capability list that drivers extend, so
`t/test/12_contract_version.t` and `$CONTRACT_VERSION` update together.
`supports_upsert_where` and the `where` key land inside that same **unreleased**
cycle and are therefore part of what 1.2 *is*, not a 1.3 — the same in-cycle
rule the k104 target correction already recorded in that test ("one bump per
released contract generation, not one per commit"). The test's comment block
carries the addition.

#### MERGE-based upsert stays out of scope — DECIDED 2026-09-22 (k172)

`supports_upsert` is deliberately INSERT-borne, and the MERGE engines (Oracle,
DB2, SQL Server) stay **permanently** without `$rs->upsert` under it. This is
the option-(c) verdict of the k172 question the k205 amendment (§1) parked: not
"no driver has built it yet", but "this API does not cover that statement shape,
by decision". It is recorded here so the absence follows from a decision, not
silently from a default `0`.

Two structural facts make MERGE a *different feature* rather than one more driver
to write against this capability — the same two the §1 k205 amendment isolated
when it drew the boundary:

1. **Two correlation names, one vocabulary.** `update_where` (§1) names the
   stored row with a bare column and the attempted row with
   `{ -attempted => $col }`, and that is unambiguous *because* an
   `INSERT ... ON CONFLICT` has exactly one target correlation plus the one
   `EXCLUDED` pseudo-row — which is precisely what k205 leaned on to qualify the
   bare column against the target table. A `MERGE` has **two** named sides,
   source and target; the stored side is unqualified in this vocabulary and
   therefore ambiguous. Covering it needs a second, symmetric qualifier that does
   not exist here.

2. **The identity guarantee does not carry.** The §4 rule — declare
   `supports_upsert` only if the written row can be *proven* — rests, for the
   INSERT-borne engines, on an insert having happened. When a `MERGE` takes its
   `UPDATE` branch there was no insert and no generated key: verbatim the
   SQLite-below-3.35 failure mode §4 ("Driver obligation") rejects as "silent bad
   data, worse than `undef`". The guarantee has to be re-derived for MERGE, not
   inherited.

So a MERGE upsert, if it is ever wanted, is its **own** capability
(`supports_merge_upsert` or the like) with its **own** guarantees reasoned from
scratch — never a widening of `supports_upsert`, never a second alias bolted onto
this vocabulary. Until then the family is consistent and loud: no driver sets
`supports_upsert` on a MERGE engine (measured across the family — mssql, oracle,
sybase, firebird all `0`), so `$rs->upsert` throws there rather than degrading to
a racy read-then-write. The §7 rollout rows for those engines are settled by
this — see the note under the k205 driver follow-ups.

### 4. What `upsert` returns — DECIDED (maintainer review 2026-07-25)

This was Open question 1 and is now settled. The option values are:

| `result` | Contract |
|---|---|
| **`row_or_undef`** (default) | a fully-stored `DBIO::Row` when the written row can be *proven*; `undef` when nothing was written **or** when the engine cannot name the row it wrote |
| **`row_or_die`** | guarantees a `Row` — never `undef`. Throws a typed exception rather than hand back nothing |
| `count` | affected-row count, as a plain number — **not** DBI's zero-but-true `'0E0'` (corrected 2026-07-25, k104: `upsert` throws on failure, so the zero-but-true signal carries nothing here, while `if (my $n = ...)` reading true for "no row written" is a live footgun). The value itself is engine-specific (MySQL: 1 = inserted, 2 = updated) |
| `void` | returns nothing and spends nothing on obtaining it — no RETURNING tail, no follow-up SELECT, one round-trip. "Nothing" is the empty list, not `undef`: idiomatic `return;`, but in list context it contributes no element and silently eats an argument (`is $rs->upsert(...), undef, 'name'` becomes `is(undef, 'name')`). Documented in POD rather than changed — `return undef` would be worse in exactly that context (k104) |

There is deliberately **no plain `'row'`**: it would promise something that is
not universally deliverable (see the identity rule below), and every name in
this set states what happens in the hard case. `row_or_count` was also rejected
— a return that is *either* an object *or* an integer forces `ref` checks on the
caller. **Second premise corrected 2026-07-25 (k104):** this paragraph also
argued that `if ($r)` would read false for a legitimate `count == 0`. It would
not have — DBI reports zero affected rows as the string `'0E0'`, numerically
zero but boolean *true*, so the original `count` implementation handed back a
value that was true for "nothing happened". That was a bug in its own right and
is fixed (`count` now returns a plain number, see the row below); as an argument
against `row_or_count` it was simply wrong. The `ref`-checking objection stands
on its own and carries the decision.

Naming note: `void` is about **effort**, `row_or_undef` about **outcome**. The
option value is not renamed to `'undef'` (the string `'undef'` sitting next to
the real value `undef` is more confusing than clarifying), and not to
`'nothing'` (that word is already taken by `on_conflict => 'nothing'`).

#### When identity is knowable

The generalized rule, engine-independent, so future drivers slot in without
re-deciding: the written row can be named iff **at least one** of these holds.

1. **The engine returns it** — `RETURNING` / `OUTPUT`. PostgreSQL declares
   `insert_returning`; SQLite does since 2026-07-25 (≥ 3.35, dbio-sqlite k19);
   MariaDB does since 2026-07-26 (≥ 10.5, dbio-mysql k29); the MERGE engines
   (Oracle, DB2, MSSQL) have equivalents for their own later ADR.

   **Weaker than it sounds — corrected 2026-07-26 (dbio-mysql k29).** Declaring
   `insert_returning` does *not* by itself make every shape nameable, because
   core asks for `RETURNING` only for the columns it does not already have. Hand
   `upsert` a primary key and there is no returned column at all — and on a
   *targetless* engine that supplied value is still no evidence of which row a
   statement hit, since the collision may have been on another unique index. So
   on MariaDB the shapes resolved by rule 1 are the ones where the PK is *not*
   caller-supplied (autoincrement without a value, non-autoincrement without a
   value, PK assigned in the conflict set); the supplied-PK shapes stay
   unresolvable and keep the `carp_once`. Rule 1 is a property of the engine
   *and* of what core asked it for — the next driver with `OUTPUT` should expect
   the same.
2. **The statement pinned the conflict target.** PG and SQLite *require* a
   conflict target for `DO UPDATE`, so the collision can only have happened on
   that constraint — a follow-up `SELECT` on the caller-supplied target values
   provably finds the row that was written. This is why SQLite is sound even
   without RETURNING: declaring `insert_returning` there is a round-trip saving,
   not a correctness fix.
**Settled on real servers 2026-07-25** (live round, MySQL 8.0.46 and MariaDB
11.8.8 in throwaway pods). The two assumptions this ADR made without proof:

- **Assumption (i) holds, and more strongly than claimed.**
  `pk = LAST_INSERT_ID(pk)` reports the touched primary key even when the UPDATE
  changes no value at all (affected-rows 1, `LAST_INSERT_ID()` correct), and —
  the case that actually matters — **even when the collision happened on a
  different unique index than the one the caller named**. Measured: a row
  colliding on `email` while the statement listed `name` still came back with the
  colliding row's id. Rule 3 stands as written.
- **Assumption (ii) is WRONG.** MariaDB *does* accept
  `INSERT ... ON DUPLICATE KEY UPDATE ... RETURNING`, and returns the right row on
  **both** branches — insert and update (verified on 11.8.8: the update branch
  returned the pre-existing row with its new values). So MariaDB does not need
  the idiom or a follow-up SELECT at all; it belongs under rule 1 and should
  declare `insert_returning`. Tracked in dbio-mysql.
- Also measured, confirming the correction further down: on MySQL the
  `DO NOTHING` emulation reports **affected-rows 1 whether the row already
  existed or was inserted**, so that signal genuinely cannot distinguish them.

3. **The engine has an identity channel for the touched row.** MySQL's
   documented `LAST_INSERT_ID(expr)` idiom: the driver appends
   `<pk> = LAST_INSERT_ID(<pk>)` to the `ON DUPLICATE KEY UPDATE` set — a no-op
   on the value, but it makes `LAST_INSERT_ID()` report the PK of the row that
   was actually touched, insert or update, *regardless of which unique index
   collided*. Requires an AUTO_INCREMENT PK.

MySQL is the only engine where none of the three may hold, because it is the
only one whose grammar has **no conflict target** — `ON DUPLICATE KEY UPDATE`
fires on any PK/unique collision and the engine's choice of constraint is not
observable from the statement. Hence exactly three cases, all decidable from
static schema metadata (`column_info`'s `is_auto_increment` plus
`unique_constraints`), never data-dependent:

| MySQL table shape | `row_or_undef` | `row_or_die` |
|---|---|---|
| AUTO_INCREMENT PK | `Row` — rule 3, then SELECT by PK | `Row` |
| no AUTO_INCREMENT PK, effective target is the table's **only** unique constraint (PK counts) | `Row` — rule 2 reasoning holds: with a single unique index the collision must be on it | `Row` |
| no AUTO_INCREMENT PK, **two or more** unique constraints | `undef` + `carp_once` | typed exception |

Because the failing shape follows from the schema and not from the data, the
distinction surfaces on the first call in development, not after weeks in
production when the "other" unique finally collides.

**Refinement from dbio-mysql k27: the decision is static *plus* "was the key
supplied".** Two shapes the table above does not cover, both of which the driver
pushes into the unresolvable path rather than let core hand back a plausible
wrong row:

- **the caller supplies the AUTO_INCREMENT value explicitly.** `LAST_INSERT_ID()`
  is untouched on the insert branch (`mysql_insert_id()` reports 0), and with
  `conflict_target => 'any'` the collision may have been on a different key
  entirely — so the supplied id is not evidence of which row was written, even
  though core's nameability test (every PK column defined) would happily accept
  it.
- **the conflict set assigns the primary key itself.** Then the
  `pk = LAST_INSERT_ID(pk)` idiom does not carry the row's identity any more.

The driver enforces this by *deleting* the PK columns from the returned hashref,
which is precisely core's nameability test, so core's own contract does the rest:
`row_or_die` throws, `row_or_undef` returns undef. No new core mechanism was
needed — worth knowing for the next driver.

With the conflict-target rule settled (§1), that third row is reachable **only**
when the caller passed `conflict_target => 'any'` — a real target on a
multi-unique table now throws before any SQL is generated. So `undef` is not a
surprise there: it is the honest answer to a deliberately unspecific question.
The `carp_once` stays regardless, for the caller who typed neither option.

#### Driver obligation: declare the capability only if you can name the row

Added 2026-07-25 after implementing k100, which exposed a hole in the three rules
above: they describe when identity is *knowable*, but rule 2 (target pinned by the
statement ⇒ a follow-up SELECT on the target finds the row) had **no owner**.
Core's retrieval path is `last_insert_id` plus a follow-up SELECT **on the primary
key** — it does not, and will not, re-find by conflict target. Core's nameability
test is therefore exactly one thing: *did every primary key column come back for
the written row*.

That gap is not cosmetic. On SQLite below 3.35 (upsert grammar since 3.24,
RETURNING only since 3.35) an upsert taking the DO UPDATE branch performs no
insert, so `last_insert_rowid()` still reports the *previous* insert — core would
then SELECT that PK and hand back a confidently wrong, unrelated row. Silent bad
data, worse than `undef`.

So the rule for every driver, and it is a hard precondition:

> A driver may declare `supports_upsert` only if the identity it hands back is
> provably the row that was written. Three ways to satisfy it: RETURNING/OUTPUT
> (rule 1), the engine's own identity channel (rule 3, e.g. MySQL's
> `LAST_INSERT_ID(pk)` idiom), or a driver-implemented re-find by conflict target
> (rule 2 — whoever wants it must build it in the driver, core does not). A driver
> that can satisfy none of them must not declare the capability.

Concrete consequence for **dbio-sqlite**: gate `supports_upsert` at libsqlite
**3.35**, not 3.24, so it coincides with `insert_returning`. Losing 3.24–3.34 is
the honest trade against returning the wrong row there.

How both drivers ended up implementing that gate (2026-07-25, worth copying):
**they hang it on the identity fact, not on the version number.** dbio-sqlite
declares `supports_upsert` iff `_use_insert_returning` is true; dbio-postgresql
requires `>= 9.005` *and* `_use_insert_returning`. The version is only the
*reason* RETURNING is available — the capability is the *fact*. A second version
test would be a copy of the same number that goes wrong in the one case that
matters: someone switching `_use_insert_returning(0)` on a modern server would
keep being promised an upsert while core silently fell back to `last_insert_id`
and named the wrong row. Tying the flags together makes the promise withdraw
itself. An explicit `_use_supports_upsert(1)` stays available as a deliberate
override.

Note this makes the gate need a live connection (`_server_info`), which matters
for *offline* driver tests: they have to override `_server_info` on the fake
storage **after** that class is loaded, and `get_dbms_capability` caches per
storage instance, so each version case needs its own schema instance.

**"Nothing was written" — corrected 2026-07-25 after implementing dbio-mysql k27.**
With RETURNING, zero returned rows say it directly. The claim previously
made here — that MySQL can tell the two apart through affected-rows, 0 meaning
the row already existed — is **wrong**: DBD::mysql sets `CLIENT_FOUND_ROWS` by
default, so the server reports *matched* rather than *changed* rows and returns 1
where the reasoning above expected 0. Affected-rows cannot carry this signal on
MySQL at all.

What the driver does instead is better than guessing: on an AUTO_INCREMENT table
the `DO NOTHING` emulation is a no-op set, which *is* the identity idiom, so the
existing row's PK comes back and MySQL returns **the existing row**. That is a
real, documented engine divergence and it is the one place the uniform return
type from §4 does not mean a uniform return *value*:

| `on_conflict => 'nothing'` hits an existing row | result |
|---|---|
| PostgreSQL / SQLite | `undef` — `RETURNING` yields zero rows, nothing was written |
| MySQL, AUTO_INCREMENT PK | the existing `Row` — the no-op set names it |

Both answers are defensible and neither can be made to imitate the other without
lying: PG genuinely cannot hand back a row it did not touch, MySQL genuinely
knows which row collided. Documented in POD on both sides rather than papered
over. Core does not interpret affected-rows for this; the driver decides.

#### `carp_once` on the unresolvable path — required, not optional

The default is the one value nobody ever types, so its *name* cannot teach the
one caller who needs teaching. The runtime has to: on first use of the
unresolvable path, `carp_once` naming the table and the reason. That is the only
channel that reaches someone who never wrote `result` at all. Silenceable by
passing `result => 'row_or_undef'` explicitly, or by a warning filter.

**Only on the unresolvable path — corrected 2026-07-25 (k104).** The
implementation fired it for every `undef` return, including
`on_conflict => 'nothing'` hitting an existing row on PG/SQLite: `RETURNING`
yields zero rows, no primary key comes back, and the caller was told the engine
"could not name the row it wrote". Nothing *was* written — that is the outcome
this section itself documents as legitimate two paragraphs below, and the one
the caller explicitly asked for. `undef` there needs no warning; the warning
belongs to the case where the engine in principle cannot name a row it *did*
write.

#### `row_or_die` validation

To keep the name exact, `row_or_die` must throw in *every* case where no row
comes back, not only the unresolvable one. Two option combinations make that
outcome likely by construction and are therefore rejected at option-validation
time, before any SQL is generated:

- `on_conflict => 'nothing'` — a contradiction in terms: `DO NOTHING` exists in
  order to possibly write nothing.
- a conditional update (PG's `DO UPDATE ... WHERE`) — **corrected 2026-07-26
  (k105): also refused up front, not thrown at runtime.** The option exists
  now (`update_where`, §1), and the combination is refused at option-validation
  time like the one above it. The earlier "can only be documented plus thrown at
  runtime" was wrong twice over: the contradiction is in the *call* rather than
  in the data — a conditional update exists in order to possibly write nothing,
  which is verbatim the argument that already refuses `DO NOTHING` here — and
  the runtime throw would **misdiagnose** it, since it blames the table shape
  ("this follows from the table shape, not from the data") for a condition that
  simply held false.

`DO NOTHING` returning nothing is not an inability but the legitimate outcome:
on a conflict, PG/SQLite `RETURNING` yields **zero rows**. With
`row_or_undef` that is `undef`; with `row_or_die` the combination is refused up
front.

#### Cost, stated plainly

**Corrected 2026-07-25 after implementing dbio-mysql k27: the price is smaller
than this section originally claimed.** It said MySQL pays one extra SELECT on
every upsert. It does not. `last_insert_id` is a DBD *attribute* read off the
handle, not a statement, so the AUTO_INCREMENT case — the common one — is a
single round-trip like any other insert. A follow-up SELECT appears only when the
result class has additional `retrieve_on_insert` columns to fetch, which is
exactly when a plain `create` would pay for it too.

So the cost of the portable return type on MySQL is: the identity idiom appended
to the conflict set, and a SELECT only where a plain insert would need one
anyway. Still opt-out-able per call via `count` or `void` — a deliberate decision
at the call site rather than an engine-dependent surprise.

### 5. Relationship to the existing composite-write methods

Presented, not decided unilaterally:

| Option | What happens to `insert_or_update` / `update_or_insert` / `find_or_create` / `update_or_create` | Assessment |
|---|---|---|
| **A. Add sibling, remove nothing** | untouched; `upsert` is the new atomic sibling; their POD is tightened to state plainly "two-step client-side helper, subject to a race, **not** an atomic upsert" and cross-links `upsert` | **Recommended.** Surgical, non-breaking (house rule 3), aligns with the README cleanup already in flight. These methods have honest, distinct semantics (partial-column update, in-memory relationship cascade in `Row::insert`, `_find_lookup_cond` DWIM per ADR 0033/0034) that atomic upsert does *not* replicate |
| B. Deprecate `insert_or_update` | add a deprecation `carp_once`, steer docs to `upsert` | possible later, but premature — the alias is not wrong, only *was mis-advertised*. Deprecating a correct method to fix a docs bug is disproportionate |
| C. Re-point `insert_or_update` to atomic upsert when supported | silent behaviour swap | **Rejected.** Breaks callers who rely on the client-side update path (partial columns, relationship cascade, no unique-constraint requirement) and would silently change behaviour per-engine depending on `supports_upsert`. Exactly the kind of averaging ADR house rule 5 forbids |

**Recommendation: A.** Keep the aliases, sharpen their POD, add `upsert`
alongside. Note the `update_or_create` DWIM behaviour (ADR 0033/0034, where an
unresolvable relation sub-hash is split off the find-lookup) is a *client-side
find semantics* feature that `upsert` does **not** replicate. It does handle
nested data, but differently and by a different promise: the cascade in §1
upserts each part atomically against a target the caller *stated*, where
`update_or_create` resolves each part by reading first and guessing among the
constraints. Same input shape, different contract — which is why §5 keeps both
methods rather than re-pointing one at the other.

### 6. Prior art

| Framework | Conflict target | Update set | DO NOTHING | Returning | Batch |
|---|---|---|---|---|---|
| **SQLAlchemy** (PG dialect) | `on_conflict_do_update(index_elements=[...])` or `constraint=<name>` | `set_={...}`, `where=...`, `excluded` accessor for attempted values | `on_conflict_do_nothing(index_elements=...)` | `.returning(...)` | single `insert()` construct; values-list gives multi-row |
| SQLAlchemy (MySQL dialect) | — (implicit, any unique) | `on_duplicate_key_update(...)` | via no-op set | none | same construct |
| **Ecto** (Elixir) | `conflict_target: [...]` or `{:constraint, name}` | `on_conflict: :replace_all` \| `{:replace, cols}` \| `[set: [...]]` \| query | `on_conflict: :nothing` | `returning: true \| [cols]` | `Repo.insert_all/3` |
| **ActiveRecord** (Rails) | `unique_by:` (index name or cols) | `on_duplicate:` (SQL) / `update_only:` | via default no-op / `:skip_duplicates`-style | `returning:` | `upsert_all` first-class; `upsert` = 1-row |

Observations that shaped the recommendation: (a) every framework names the
conflict target with a *columns-or-constraint* union — validates reusing
`key`/`conflict_target`; (b) SQLAlchemy exposes the attempted values as
`excluded.*`, which is the abstraction §1 recommends (caller thinks "the value I
tried to insert", driver renders `EXCLUDED`/`VALUES`); (c) both ActiveRecord and
Ecto make **batch** (`upsert_all` / `insert_all`) first-class — reinforcing that
`upsert_all` is a real want, but also that it carries its own returning/ordering
semantics worth a dedicated pass (§7).

## Alternatives considered

- **Row-level upsert as the primary surface** — rejected (§1): a Row lacks a
  meaningful server identity in exactly the case where upsert matters.
- **A family of fine-grained capability flags** (`supports_upsert_target`,
  `supports_upsert_do_nothing`, `supports_upsert_returning`) — rejected (§3):
  dialect facts belong in the driver SQLMaker; RETURNING already has a flag.
  ADR 0026's "no new abstraction, keep it small" applies.
- **Re-pointing `insert_or_update` to atomic upsert** — rejected (§5, option C):
  silent per-engine behaviour change.
- **Silent two-step fallback when `supports_upsert` is false** — rejected as the
  *default*: it would resurrect precisely the over-promise the READMEs are being
  cleaned of (a method that claims atomicity but silently degrades to a racy
  read-then-write). Offered only as an *explicit, opt-in* `fallback =>
  'update_or_create'` flag for callers who knowingly accept the race; the
  default on an unsupporting engine is to **throw** a typed
  `DBIO::Exception` (F21 — never bare `croak`).
- **Doing conflict SQL in core with a `$driver_name` branch** — rejected: the
  ADR 0021 anti-pattern. The capability gate + driver SQLMaker override is the
  established replacement.
- **A brand-new core plumbing method `Storage::DBI::upsert`** separate from
  `insert` — considered; leaning against, because the options-hash transport to
  `sql_maker->insert` already exists and RETURNING already rides it. A thin
  wrapper that only sets `$sqla_opts->{on_conflict}` and reuses the existing
  insert result-handling (autoinc / RETURNING / follow-up SELECT) is less code
  and less drift. Flagged in Open questions in case the result-shape differences
  (§4) justify a distinct method.

## Consequences

- **New public API** (`$rs->upsert`, the `on_conflict` options-hash key on the
  SQLMaker insert seam, the `supports_upsert` and `supports_upsert_where`
  capabilities) → **contract version 1.1 → 1.2** per ADR 0024, with
  `t/test/12_contract_version.t` updated in the same change. The tripwire forces
  the bump to be deliberate.
- **Drivers that do not opt in stay correct by construction.** Default
  `supports_upsert = 0` means every un-updated driver (Oracle, DB2, MSSQL,
  Sybase, Firebird, DuckDB, ClickHouse, GraphQL, …) throws a clear
  "atomic upsert not supported" exception rather than silently doing the wrong
  thing. No family-wide sweep is required for correctness — only the three
  target drivers need work for the feature to *exist*.
- **The return *type* is uniform across engines** (§4): `row_or_undef` is the
  default everywhere. What differs is not the shape but whether a row can be
  named — on MySQL, one static table shape (no AUTO_INCREMENT PK plus two or
  more unique constraints) yields `undef` with a `carp_once`. Cost of the
  uniformity: one extra SELECT per upsert on MySQL, opt-out via `count`/`void`.
- **`DO NOTHING` can return `undef`** with `row_or_undef`, and is refused
  outright in combination with `row_or_die` — documented.
- **Mock-test coverage** lands in core: a `t/` test (mock storage only, per
  house rules) asserting (i) `supports_upsert` get/set/fallback plumbing, (ii)
  that with the capability off `upsert` throws, (iii) that with a fake
  supporting storage the emitted SQL carries the expected `on_conflict`
  structure through the seam. Per k55, any fake-storage cursor must keep
  using `$storage->_select_args` so captured SQL equals what a real cursor
  would run. Driver-specific SQL shape (actual `ON CONFLICT` / `ON DUPLICATE KEY`
  strings, real round-trips) is tested in each **driver** dist, not core.
- **Blast radius is cross-repo** — enumerated in §7.
- **No `upsert_async` is specified here, and that is an omission rather than a
  decision.** Noticed while implementing k100: every other writing ResultSet
  operation has an async twin per ADR 0030/0031 — `create_async`,
  `find_or_create_async`, `update_or_create_async`, `update_or_new_async`,
  `find_or_new_async`. `upsert` would be the only one without. Not folded into v1
  retroactively; it gets its own ticket so the async seam is designed rather than
  bolted on, and so the cascade's transaction handling (k101) is settled first —
  a cascade is inherently a multi-statement sequence, which is the interesting
  part of an async version.

  **Landed 2026-08-09 (k102).** `$rs->upsert_async` routes through the
  same private `_upsert_prepare` the synchronous method uses for option
  validation, conflict-target resolution and the capability gate, so the two
  cannot drift. The single-statement `row_or_undef`/`row_or_die`/`void` shapes
  are genuinely non-blocking: the write goes through the backend's
  `insert_async` and the result is inflated in the Future's `then`, exactly
  like `create_async` (ADR 0031). Three cases are not, and degrade to the
  synchronous `upsert()` wrapped in an immediately-resolved Future, the same
  precedent `create_async` sets for related-object multi-create: the
  **cascade** (already more than one statement, a whole transaction),
  `fallback => 'update_or_create'` (itself a client-side two-step), and
  `result => 'count'` (no async transport contract carries an affected-row
  count for INSERT SQL — sync reads it off a storage-specific side channel
  `DBIO::Storage::Async`'s generic CRUD builder does not populate). MySQL's
  §4 identity work (`LAST_INSERT_ID()` being session state under a
  multiplexing transport) is a driver-side question, tracked in
  dbio-mysql-ev rather than duplicated here. Mock-tested in
  `t/resultset/upsert_async.t`.

### Cross-repo rollout (§7) — follow-up tickets

The ADR is accepted, so these tickets exist on the respective boards as of
2026-07-25. `dbio-informix` is deliberately excluded (abandoned).

| Repo | Ticket (summary) | Notes |
|---|---|---|
| **dbio (core)** | Implement `$rs->upsert`, normalize `on_conflict` options structure, plumb into `Storage::DBI::insert` result-handling, add `supports_upsert` capability (default 0), base-SQLMaker guard/throw, the §1 conflict-target rules, the §1 **cascade** (dependency ordering off `Row::insert`'s multicreate split, `relations` targets, identity precondition, `txn_scope_guard`, `has_many` no-delete, `many_to_many` throw), POD, mock tests, **contract bump 1.1→1.2 + 12_contract_version.t** | the prerequisite; everything else depends on it. Split into two tickets — flat upsert (k100, landed 2026-07-25) and cascade on top (k101, landed 2026-07-26) — so the flat case could be reviewed and landed before the cascade's larger test matrix arrived |
| **dbio-postgresql** | `DBIO::PostgreSQL::SQLMaker` `_insert_on_conflict`: `ON CONFLICT (cols)\|ON CONSTRAINT DO UPDATE SET ... EXCLUDED.* RETURNING`; `_use_supports_upsert(1)` (or `_determine` ≥ 9.5); DO NOTHING; driver tests | RETURNING already supported → the row shapes are free. **Landed 2026-07-25.** The `WHERE` is a follow-up ticket since k105: render `$on_conflict->{where}` after the SET list and before RETURNING, substituting `{ -attempted => $col }` at any depth with `EXCLUDED.<col>`, and declare `supports_upsert_where` |
| **dbio-postgresql-ev / -age / -postgis** | verify inheritance from Pg base; likely no code, add a smoke test | should be free |
| **dbio-sqlite** | `DBIO::SQLite::SQLMaker` `ON CONFLICT` (≥ 3.24); version-gate `_determine_supports_supports_upsert`; **optionally also declare `insert_returning`** (≥ 3.35) to save the follow-up SELECT; tests | SQLite currently declares neither upsert nor returning. Correctness does not depend on RETURNING here — the required conflict target pins the constraint, so a target SELECT is provably right (§4 rule 2); declaring it is a round-trip saving. The `WHERE` (k105) is a follow-up ticket, same grammar as PostgreSQL: render `$on_conflict->{where}`, substitute `{ -attempted => $col }` at any depth with `excluded.<col>`, declare `supports_upsert_where` |
| **dbio-mysql** (+ **dbio-mysql-ev**) | `DBIO::MySQL::SQLMaker` `ON DUPLICATE KEY UPDATE` with `VALUES()` / aliased-`new` (8.0.20 split); the §1 target validation (demanded target + further unique constraints ⇒ throw naming `'any'`; sole-unique target ⇒ allow; `'any'` ⇒ native); `_use_supports_upsert(1)`; the §4 identity work: append `<pk> = LAST_INSERT_ID(<pk>)` for the AUTO_INCREMENT case, the three-case decision from `is_auto_increment` + `unique_constraints`, `carp_once` on the unresolvable shape; tests | the only engine that can fail to name the written row. **Live tests must verify two things this ADR asserts but has not proven on a real server:** (i) that the `LAST_INSERT_ID(pk)` assignment still reports the touched PK when the update changes no value (affected-rows 0), and (ii) whether MariaDB's `INSERT ... RETURNING` (10.5+) really cannot be combined with `ON DUPLICATE KEY UPDATE` — if it can, MariaDB skips the follow-up SELECT entirely. Nothing to do for the conditional branch (k105) beyond **not** declaring `supports_upsert_where`: `ON DUPLICATE KEY UPDATE` has no `WHERE`, a per-column `IF()` does not suppress the write, and core throws before a statement is built. Worth one test pinning that the capability stays 0 |
| **dbio-oracle** | *separate design* ticket for MERGE-based upsert; until then leave `supports_upsert = 0` (throws) | MERGE ≠ INSERT-tail; bigger scope |
| **dbio-db2** | same as Oracle (MERGE) — parked; default 0 keeps it correct | |
| **dbio-mssql** | MERGE available but with known caveats; audit-only ticket, default 0 until decided | |
| **dbio-sybase / -firebird / -duckdb / -clickhouse** | audit-only: confirm default 0 is correct; each engine's native upsert (if any) is its own follow-up | no correctness action needed to ship core |
| **dbio-informix** | **excluded** — abandoned driver, do not route work here | house rule |

**k205 stored-side qualification (2026-09-22) — driver follow-ups.** Core landed
the qualification in `_upsert_condition_sql($cond, $table)` (see §1, "The stored
side has to be qualified"). The two ON CONFLICT drivers must now pass the target
table they already hold in `insert($table, …)` down through `_insert_on_conflict`
into that call — one-line changes, tracked on their boards:

| Repo | Ticket (summary) | Notes |
|---|---|---|
| **dbio-postgresql** | thread `$table` from `insert` → `_insert_on_conflict` → `_upsert_condition_sql($where, $table)`; the live `t/42-upsert-live.t` conditional-upsert assertion (the `WHERE "score" < EXCLUDED."score"` case, ~line 274) is the acceptance gate | inherits the core helper; no rendering logic of its own to change |
| **dbio-sqlite** | same one-line threading; SQLite shares the `ON CONFLICT` grammar and the same `EXCLUDED`/two-correlation scope, so it needs the identical adoption | verify with a mock test asserting the target-qualified `WHERE`; add a live conditional-upsert case if one is not already present |

**MERGE engines — no rollout, by decision (2026-09-22, k172).** The Oracle / DB2
/ SQL Server rows above read "separate design", "parked" and "audit-only … until
decided" as of acceptance. k172 resolves them: MERGE-based upsert is a permanent
non-goal under `supports_upsert` (§3, "MERGE-based upsert stays out of scope").
Those drivers keep `supports_upsert = 0` not pending a design but by decision —
"parked" is permanent and "until decided" is now *decided: no*. Any future MERGE
upsert is its own capability on its own ticket, not a continuation of this
rollout.

## Open questions

1. ~~**Default `result` shape**~~ — **DECIDED 2026-07-25, see §4.** Neither of
   the two options originally offered: the return *type* is uniform
   (`row_or_undef` default, plus `row_or_die` / `count` / `void`), there is no
   plain `'row'`, and MySQL's identity gap is handled by the three-case rule
   plus a mandatory `carp_once` instead of by an engine-dependent default.
2. ~~**Unsupported-engine behaviour**~~ — **DECIDED 2026-07-25, see §3.**
   "Supported or throw" is the contract; `upsert` never silently degrades to a
   two-step. The explicit opt-in `fallback => 'update_or_create'` stays — see
   question 9.
3. ~~**New core method or reuse `insert`?**~~ — **DECIDED 2026-07-25, see §2.**
   Reuse the `sql_maker->insert` options transport; the MySQL identity path is
   exactly the `last_insert_id` + follow-up-SELECT fallback that
   `Storage::DBI::insert` already implements. Recorded with a falsifiable split
   criterion instead of as a preference.
4. ~~**`conflict_target` passed to a targetless engine (MySQL)**~~ — **DECIDED
   2026-07-25, see §1 "Conflict target".** None of the three options as posed:
   what matters is whether the caller *demanded* a target. A demanded target the
   engine cannot honour throws; MySQL's native any-unique behaviour gets a name of
   its own, `conflict_target => 'any'`. `carp_once` rejected as too weak for a
   difference that can rewrite the wrong row.
5. ~~**`upsert_all` timing**~~ — **DECIDED 2026-07-25, see §1 "Batch
   `upsert_all`".** Shape reserved now, implementation after v1: flat rows only,
   `count`/`void` only, one shared conflict target, `fallback` forbidden. v1 only
   has to avoid contradicting it.
6. ~~**Nested relationships in `\%data`**~~ — **DECIDED 2026-07-25, see §1
   "Nested relationships".** The draft's flat-only restriction is *rejected*:
   nested data cascades in v1. N atomic upserts in dependency order inside one
   transaction, per-relation targets stated not inferred, identity a checked
   precondition, `has_many` never deleting unlisted children, `many_to_many` out
   of scope. `result` restricted to the row shapes when data is nested.
7. ~~**Conflict target defaulting to PK**~~ — **DECIDED 2026-07-25, see §1
   "Conflict target".** PK default yes, but conditional: only when `\%data`
   supplies every PK column. No PK columns in the data, or no PK on the source at
   all, throws instead of silently degenerating into a plain `INSERT`. No mandatory
   explicit target on PG/SQLite needed once that hole is closed.
8. ~~**"Was it an insert or an update?"**~~ — **DECIDED 2026-07-25: deferred.**
   Not part of v1, and explicitly not folded into `result` (that is what made
   `row_or_count` a bad idea, §4). MySQL answers it for free through affected-rows
   (1 vs 2); PostgreSQL needs a trick (e.g. returning `xmax = 0` as a computed
   column); SQLite has no direct equivalent — portable enough to want, divergent
   enough to need its own design pass. Own follow-up ticket after v1 lands.
9. ~~**Should `fallback => 'update_or_create'` exist at all?**~~ — **DECIDED
   2026-07-25, see §3.** It stays: upsert-with-fallback in a single call is not
   the same thing as a hand-rolled wrapper, and the edge cases where it reads
   better are real. Pinned down with it: the return-type mapping for the fallback
   path, and per-call-only (never a global default).

Relates to ADR 0021 (driver-name string-match is the anti-pattern → capability
flag), ADR 0024 (contract-version mechanism records the 1.1→1.2 bump), ADR 0026
(the capability-flag structural precedent this reuses), and ADR 0033 / 0034 (the
`update_or_create` client-side DWIM semantics that atomic upsert deliberately
does *not* replicate).
