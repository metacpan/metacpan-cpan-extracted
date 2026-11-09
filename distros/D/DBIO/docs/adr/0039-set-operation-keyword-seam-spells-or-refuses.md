# ADR 0039 — One seam for all six set operations: `_set_operation_keyword($op)` spells it or refuses it

- Status: accepted
- Date: 2026-08-04
- Tags: api, resultset, sql, storage-hook, drivers, cross-repo

## Context

### Where ADR 0037 left the set operations

ADR 0037 §3 gave set difference a storage hook — `_except_operator` on
`DBIO::Storage::DBI`, returning `'EXCEPT'`, overridden to `'MINUS'` by
`DBIO::Oracle::Storage` — and scoped itself explicitly to that one operation.
The other five kept hard-coded keywords in `DBIO::ResultSet`:

```perl
sub union         { $_[0]->_set_operation('UNION'         => $_[1]) }
sub union_all     { $_[0]->_set_operation('UNION ALL'     => $_[1]) }
sub intersect     { $_[0]->_set_operation('INTERSECT'     => $_[1]) }
sub intersect_all { $_[0]->_set_operation('INTERSECT ALL' => $_[1]) }
sub except        { ... $storage->_except_operator ... }
sub except_all    { $_[0]->_set_operation('EXCEPT ALL'    => $_[1]) }
```

The reason given was precise and still correct: **no engine in this family
*spells* the other five differently**, so a keyword hook would have had nothing
to do for them, and house rule 2 forbids an abstraction for single-use code.
ADR 0037 also named the gap it was leaving open, in §3 and again in its
Consequences and its "Future architecture work" list: several engines do not
**have** the `… ALL` operations at all, and what those need is a *refusal*, not
a spelling. That was deferred to its own ticket, which is k135, which is
this ADR.

### The criterion fired — for a neighbouring reason, and this matters

ADR 0037 §3 wrote its own falsification condition:

> Falsifiable criterion for generalising it: the moment a second set operation
> needs a per-engine spelling, replace it with a map — it is a private method,
> so that is free.

**That is not literally what happened, and pretending otherwise would corrupt
the record.** No second operation needs a per-engine spelling; as far as anyone
has reported, `UNION ALL` is `UNION ALL` everywhere it exists. What fired is
the *neighbouring* need the same section described one paragraph earlier: a
second operation needs a per-engine **answer**, and the answer is "this engine
does not have it". The criterion was written against the narrower of the two
possibilities the section itself had already named, so it under-specified its
own trigger. The generalisation it authorised is the right one anyway — the
map is exactly what a refusal seam needs, because refusal is per-operation —
but the honest reading is that ADR 0037 *anticipated* this work in prose and
*mis-stated* its trigger in one sentence.

> **Falsified 2026-08-04, by the rollout this ADR started (`dbio-clickhouse`
> k21).** The paragraph above says no second operation needs a per-engine
> spelling. That was true of every engine reported at the time and is now
> false: **ClickHouse re-spells three of the six**, and not as a synonym the
> way Oracle spells set difference `MINUS`. A bare keyword there is not an
> operation at all — it is a lookup into a session setting.
> `union_default_mode` defaults to the empty string, so a bare `UNION`
> **throws**; `intersect_default_mode` and `except_default_mode` default to
> `ALL`, so a bare `INTERSECT` or `EXCEPT` **silently keeps duplicates**. Core's
> ANSI map is therefore a hard error for one operation and a silently larger
> result set for two, on *every* ClickHouse version rather than on old ones.
> The driver emits `UNION DISTINCT` / `INTERSECT DISTINCT` / `EXCEPT DISTINCT`,
> which also makes those statements immune to the three settings.
>
> So ADR 0037 §3's criterion fired **twice**: once for the neighbouring reason
> above, which is what authorised this ADR, and once literally, three weeks of
> work later. The record stands as written — the generalisation was *not* done
> because a second spelling appeared — and the second firing is stronger
> evidence for the same conclusion, not a correction to it. A per-operation map
> is what both needs want; a single-operation hook could have expressed
> neither.

### What is actually broken today

`$rs->except_all($other)` emits `EXCEPT ALL` on every engine, including the
ones that have no such operator, and the caller finds out from a syntax error
raised by the database several layers below the method they called.

**Engine facts are recorded here only where they can be sourced, and are
attributed.** Core cannot verify version tables and will not write a confident
per-engine matrix out of memory:

| Engine | Claim | Source | Status |
|---|---|---|---|
| Oracle | no `MINUS ALL` / `EXCEPT ALL` before 21c; `MINUS` itself since 8i | `dbio-oracle` k21 — its `Changes` entry states the SQL Language Reference for 8.1.7, 11.2, 19c, 21c and 23ai was checked; `DBIO::Oracle::Storage` POD carries it as a known gap | reported by the driver, verified there |
| SQLite | no `INTERSECT ALL` / `EXCEPT ALL` | `dbio-sqlite`'s own live test `t/resultset/set_operations.t` skips both, commented "SQLite < 3.39 lacks INTERSECT ALL / EXCEPT ALL" — but the skip is not version-gated, it is a `sqlt_type eq 'SQLite'` comparison, so the *version boundary* in that comment is unconfirmed | reported by the driver; the version cut-off is **to be verified by `dbio-sqlite`'s own ticket** |
| SQL Server | no `INTERSECT ALL` / `EXCEPT ALL` | k135 and ADR 0037 §3 | **to be verified by `dbio-mssql`'s own ticket** |
| Firebird | set difference availability | ADR 0037 §5 already assigned this question to `dbio-firebird` and asserted nothing | **open, not asserted here** |
| Sybase | set difference availability | ADR 0037 §5, same | **open, not asserted here** |

Anything not in that table, core does not know.

**Superseded 2026-08-04 — the rollout answered all of it.** Every row above was
either confirmed, corrected or filled in by the driver that owns the engine,
each against that vendor's own documentation, each cited in its own commit.
Core still does not verify these itself; what changed is that "to be verified"
now has an answer with a source behind it. The table as it stands after
k135's ten driver tickets:

| Engine | What it has | Boundary | Driver's decision |
|---|---|---|---|
| PostgreSQL | all six | none — the optional `ALL` is in the grammar back to the 7.1 manual | nothing to declare (dbio-postgresql k53) |
| DB2 (LUW, z/OS) | all six; `MINUS` accepted as a *synonym* for `EXCEPT`, but `EXCEPT` is the primary spelling of the syntax diagram in every version | none on the platforms this driver supports; **Db2 for i** has no `ALL` form of either, but the dist cannot run there at all (`SYSCAT` is LUW's) | nothing to declare (dbio-db2 k24) |
| DuckDB | all six | `ALL` on `INTERSECT`/`EXCEPT` was parsed and **silently ignored** before **0.10.0** (2024-02-13, duckdb#9636) — a wrong answer, not an error | nothing to declare; documented, not refused (dbio-duckdb k14) |
| ClickHouse | all six, but **three are re-spelled** — see the falsification note above | `UNION DISTINCT` since 21.1, `INTERSECT`/`EXCEPT` since 21.10, their `ALL`/`DISTINCT` modifiers since 22.9 | re-spells `union`, `intersect`, `except`; refuses nothing (dbio-clickhouse k21) |
| MySQL | all six from one boundary | `EXCEPT`/`INTERSECT` **and both their `ALL` forms** arrived together in **8.0.31** | opt-**out**, declared available (dbio-mysql k35) |
| MariaDB | all six from two boundaries | `EXCEPT`/`INTERSECT` in **10.3**; their `ALL` forms only in **10.5.0** (MDEV-18844) | second declaration, because one flag cannot express 10.3/10.4 (dbio-mysql k35) |
| Oracle | four before 21c, all six from 21c | `MINUS ALL` / `INTERSECT ALL` / `EXCEPT` / `EXCEPT ALL` added in **21c**; `MINUS` since 8i | opt-**in**, declared unavailable (dbio-oracle k25) |
| Sybase ASE | four; never the `ALL` forms | `INTERSECT`/`EXCEPT` **new in 16.0 SP03** (SAP note 2687392); Cluster Edition lacks them in *all* versions | split: opt-**out** for the pair, unconditional refusal for the `ALL` forms (dbio-sybase k30) |
| SQL Server | four | none — the grammar reads `{ EXCEPT \| INTERSECT }` from the 2008 R2 reference to the current one, while `UNION [ ALL ]` sits on the same page | unconditional refusal (dbio-mssql k24) |
| SQLite | four | none — the four arrived together **before 1.0** (2000-06-06) and the changelog to 3.53.4 contains no `INTERSECT ALL` / `EXCEPT ALL` | unconditional refusal (dbio-sqlite k30) |
| Firebird / InterBase | **two** — `UNION` and `UNION ALL`, nothing else | none; `EXCEPT`, `INTERSECT` and `MINUS` are not keywords of the engine at all (5.0 Language Reference, Appendix C; FirebirdSQL/firebird#1194 open since 2004) | unconditional refusal of four of six (dbio-firebird k19) |

## Decision

### 1. One hook replaces `_except_operator`: `_set_operation_keyword($op)`

On `DBIO::Storage::DBI`. `$op` is the **canonical operation name**, which is
the `DBIO::ResultSet` method's own name: `union`, `union_all`, `intersect`,
`intersect_all`, `except`, `except_all`. The base implementation answers with
that operation's ANSI spelling, from a map.

`_except_operator` is **replaced, not kept**. It is not deprecated, not
aliased, not left as a fallback. See §5 for why that costs nothing.

All six `DBIO::ResultSet` methods now pass their canonical name to
`_set_operation`, which resolves it through the storage. There is exactly
**one** call site asking, rather than five literals plus one hook call.

### 2. The hook has two jobs, deliberately in one place

- **Spell** the operation for this engine. `dbio-oracle` answers `'MINUS'` for
  `except`.
- **Refuse** it, for an engine that does not have the operation at all — by
  throwing, from the driver, naming the engine and the version, via
  `$self->throw_exception` (F21; never a bare `croak`).

The intended override shape, which is what the cross-repo tickets will ask for:

```perl
sub _set_operation_keyword {
  my ($self, $op) = @_;
  return $self->next::method($op) unless defined $op;   # let the base throw
  return 'MINUS' if $op eq 'except';
  $self->throw_exception("Oracle before 21c has no $op ...")
    if $op eq 'except_all' or $op eq 'intersect_all';
  return $self->next::method($op);
}
```

*(The `defined` guard was added 2026-08-04, reported from the dbio-firebird
rollout. The base handles an undefined `$op` — that is §5's core programming
error — but it only sees one if the override passes it down, and an override
opening with `$op eq 'except'` warns before it gets there. An example that is
copied literally has to be correct literally.)*

A driver names only the operations it has an opinion about and hands the rest
to `$self->next::method($op)`, inheriting every base keyword it did not
mention. Keeping the two jobs together is ADR 0037 §3's own argument
("refusal and rendering stay in one place"), and it is load-bearing rather than
tidy-minded: a refusal that has to name a version can only be written where
that version is known, and that is the driver.

### 3. No capability flag beside it — and one of ADR 0037 §3's four reasons does not survive the generalisation

ADR 0037 §3 gave four reasons for a hook rather than a capability. Three
transfer to all six operations unchanged. The fourth does not, and it is
recorded here rather than quietly re-used:

- **Nothing to branch on — transfers, with a sharper edge.** No set operation
  has a portable fallback in the ORM, so a caller who learns "unsupported" has
  no second call to make. For `except_all` there is something *adjacent* —
  `except` exists where `except_all` does not — but it is a different
  operation, not a fallback: it collapses duplicates, so substituting it
  returns a different set. Handing that over silently is precisely the
  degradation ADR 0036 §3 and ADR 0037 §4 both refuse.
- **A boolean would have to encode the token — does NOT transfer.** This was
  the *mechanical* impossibility for `except`: `get_dbms_capability` coerces
  every answer to `1`/`0`, so a keyword cannot ride on one, and any boolean
  would have to be `set_difference_uses_minus`, i.e. the ADR 0021 name match in
  disguise. The `… ALL` family has **no second spelling**, so a flag there
  would carry no token at all — it would be a pure availability question,
  `supports_except_all`, which a capability *can* express. Nothing mechanical
  rules a capability out here. What rules it out is the other three reasons
  plus the cost of a second parallel mechanism (§Alternatives).
- **The hook is already the refusal seam — transfers, and is now the primary
  reason.** For `except` this was the third argument; for the `… ALL` family
  it is the whole point. The driver writes a better message than core could,
  because it knows the engine and the version.
- **A gate would regress every working engine — transfers.** `union_all`,
  `intersect_all` and `except_all` work today on every engine that has them. A
  capability defaulting to `0` breaks all of them until each driver ships a
  declaration, trading a real defect on some engines for an outage on the
  rest — the same trade ADR 0037 §7 priced openly for `supports_exists_query`
  and the same one this ADR declines to repeat six times over.

### 4. Refusal timing is part of the contract

`_set_operation` resolves the keyword **before it assembles any operand SQL**,
not after the operand loop. A refusing engine therefore throws at query-build
time and never hands back a fragment that could be embedded in a larger query.
This is the same argument ADR 0037 §4 made for `results_exist_as_query`: a
seam that only refuses on execution lets the broken thing travel, and it then
fails far from its cause. It is pinned by a test that asserts a refused
operation issued **no SQL at all** against the mock storage's captured queries.

### 5. An unknown `$op` is a core programming error, not an engine fact

The base throws, naming the op and listing the six valid names, rather than
returning `undef` and letting a bare token reach the SQL. The throw lives at
the **base** of the hook chain, which is also where a driver's
`$self->next::method($op)` lands when it does not recognise a name — so one
implementation covers both the core typo and the driver typo, and neither can
produce a statement.

### 6. Contract version: inside 1.2, and this one needed arguing

`$CONTRACT_VERSION` stays `'1.2'`, and `t/test/12_contract_version.t`'s header
block records the reason — but unlike the four in-cycle entries before it, this
change is **not additive**: it renames a hook drivers extend. A driver that
overrode `_except_operator` and is loaded against this core does not fail
loudly; it silently stops being asked. That is the failure mode a version
number exists to warn about, so the non-bump is a decision, not an omission.

It is still 1.2 because **1.2 has never been released**. The last CPAN release
is 0.900002 (2026-07-13); the entire 1.2 generation was assembled after it, and
`_except_operator` was introduced by ADR 0037 *inside that same unreleased
cycle* and never left it. No consumer can have compiled against a 1.2 that
contained the old name. The one repo that overrode it, `dbio-oracle`, is
equally unreleased — the override sits in its own `{{$NEXT}}` — so the rename
is a workspace-wide edit, not a compatibility event. Had 1.2 shipped, this
would be a 1.3 and the argument would run the other way.

### 7. A version-dependent refusal still has to be decided without a connection

The hook inherits `_except_operator`'s hardest constraint, and every driver
ticket walks into it, so it is stated here rather than discovered nine times:
the hook must be a **static class fact** — no `$dbh`, no version probe.
`DBIO::ResultSet::_set_operation` bakes the keyword into a literal `from`
clause at construction time, and asking the database which word to use is
exactly what made `$rs->except($other)->as_query` open a connection before ADR
0037 (§5 there). A refusal is resolved on that same call, so it is under the
same constraint.

Every known gap is version-*bounded*: Oracle gained `MINUS ALL` / `EXCEPT ALL`
in 21c, MySQL gained `EXCEPT` / `INTERSECT` in 8.0.31. A driver therefore
cannot answer "does *this connection* have it" here without breaking the
promise the seam exists to keep. It has two honest options, and which one is
right is the driver's call on its own board:

1. **Refuse unconditionally**, with a message that names the version boundary
   *and says the refusal is unconditional*: "Oracle has no `MINUS ALL` before
   21c; this driver refuses `except_all` for every Oracle version, because the
   keyword is chosen without a connection (ADR 0037 §5)". Correct on every
   version, and it withholds the operation from 21c+, which is a real cost and
   must be stated rather than glossed.
2. **Split the decision off the connection entirely** — a class-level opt-in a
   deployment sets when it knows its server (`__PACKAGE__->_use_...`, or a
   dedicated subclass, as `dbio-mssql` does for its ODBC/Sybase rebless). The
   hook then reads a class fact, which is what it is allowed to read.

What is **not** an option is probing the server version inside the hook. It
would connect during query build, on the one path whose whole point is that it
does not — and it would connect in order to throw.

#### What the rollout did to this section — five shapes, not two

Written 2026-08-04, from all ten driver tickets of k135. The two options
above are still the two *mechanisms*, and no driver needed a third. What was
wrong is the framing: this section assumed the question is always "the gap is
version-bounded, so which option?", and in six of the ten repos it was not.

1. **Version-bounded, and the old version errors** → opt-in, declared
   unavailable. `dbio-oracle`: 21c gained the `… ALL` family, so refusing
   unconditionally would remove something that works on the current LTS.
2. **Not bounded at all — the engine has never had it** → refuse
   unconditionally, and **the choice between (a) and (b) is vacuous**, which is
   `dbio-sqlite`'s formulation and the sharpest thing this rollout produced. An
   opt-in would be a switch with no correct setting. Also `dbio-mssql` and
   `dbio-firebird`. Say in the message that the refusal is unconditional
   *because the fact is*, not as the price of deciding without a connection —
   otherwise the next reader takes it for a §7 compromise.
3. **Version-bounded, but the old version answers *silently wrong*** →
   `dbio-duckdb`, where `EXCEPT ALL` returned de-duplicated rows before 0.10.0.
   This is the shape ADR 0036 §3's flag criterion was written for, one level
   down: not a driver dropping something silently, the *engine* doing it. And
   yet **refusing is still wrong here** — it would withhold two operations from
   the entire 1.x line to protect users of a pre-1.0 beta, the trade §3 above
   declines. Document it; do not gate it.
4. **Bounded by *platform*, not version** → `dbio-db2`: Db2 for i has no `ALL`
   form of either operator, at any version. The mechanics are unchanged — a
   platform is no more askable without a connection than a version is — but the
   sentence "every known gap is version-bounded" was simply false, and a driver
   reading only that sentence would think this section did not apply to it.
5. **The boundary runs the other way** → `dbio-sybase` and `dbio-mysql`: the
   operators are the *new* thing, missing only on *old* servers. The mechanism
   is the same class-level switch, but declared **1** and used as an opt-*out*.
   Getting the polarity from a sibling driver rather than from the engine is the
   mistake to avoid here: `dbio-oracle` declares its flag 0 and `dbio-mysql`
   declares an identically-named one 1, and both are right.

Two further constraints the section did not anticipate, both from
`dbio-mysql`, which serves two server products through one driver:

- **A refusal cannot always name "the" version.** The hook may not ask *which
  product* it is talking to either, so the message has to carry a table of both
  products' boundaries rather than a single number.
- **One availability boolean per driver is not always enough.** MariaDB 10.3
  and 10.4 have `EXCEPT`/`INTERSECT` but not their `ALL` forms — a real
  deployment state that a single flag cannot express. That driver declares two.

**A capability shape is emerging and core does not own it.** Three drivers
independently invented a driver-declared capability for this
(`_use_set_operator_all_family` in both `dbio-oracle` and `dbio-mysql`,
`_use_intersect_except` in `dbio-sybase`). The convergence is a good sign about
the shape and a bad sign about its home: driver-declared capabilities carry the
two traps recorded in core k136 (the accessor does not exist before the
driver rebless) and k137 (`_use_X` is the *caller's* force slot, so declaring
into it makes the force unclearable). Whether core should own the name — and
which slot a driver ought to declare into at all — is those two tickets'
business, not this ADR's, but the rollout is why they are now urgent.

## Alternatives considered

- **Keep `_except_operator` and add per-operation hooks beside it** (an
  `_except_all_operator`, an `_intersect_all_operator`, …) — rejected. Six
  hooks where one map suffices, and a driver that refuses two operations would
  write the same refusal twice. It also leaves the asymmetry that started this:
  one operation reached through a seam and five through literals, so the next
  engine fact lands wherever the next author happens to look first.
- **A driver-declared list of unsupported operations**, e.g.
  `_unsupported_set_operations` returning `qw(except_all intersect_all)`, with
  core writing the exception — rejected, and this was the honest runner-up. It
  splits refusal from rendering, which is the exact split ADR 0037 §3 argued
  against: the driver would declare *that* an operation is missing while core
  wrote the message about *why*, and core cannot name the version boundary
  ("before 21c") that makes such a message useful. It also gives a driver two
  places to edit for one engine fact, which is how the two drift apart.
- **A capability per operation** (`supports_except_all`, …) — rejected. Unlike
  for `except` there is no mechanical obstacle (§3), which is why it is listed
  rather than dismissed: it would work. It is refused because a caller cannot
  branch on the answer, because it would put refusal a second object away from
  the rendering, and because six flags defaulting to `0` would break every
  engine that has these operations today until six drivers each shipped six
  declarations. Defaulting them to `1` — a refusal switch rather than a gate —
  removes the regression but keeps the split and adds a parallel mechanism that
  says nothing the hook cannot say.
- **Leaving the `… ALL` family alone and documenting the gaps** — rejected. It
  is what ADR 0037 did, deliberately and with a ticket; the ticket is now due.
  The status quo makes `$rs->except_all` a method that emits SQL the engine has
  no operator for, which is the class of defect ADR 0021 and ADR 0026 exist to
  remove from this codebase.
- **Substituting `except` for `except_all` where the latter is missing** —
  rejected outright: different semantics, silently. See §3, first bullet.

## Consequences

- **`_except_operator` is gone.** `_set_operation_keyword($op)` replaces it on
  the `_determine_driver` `around` list in `DBIO::Storage::DBI` and in
  `DBIO::Replicated::Storage`'s `@writer_methods`, in both cases in the slot
  the old name held. The Replicated delegation now carries the driver's
  *refusal* as well as its spelling — otherwise the one setup that hides the
  driver behind another storage would be the one that still emits the broken
  SQL.
- **No SQL changes for any engine that has all six operations.** Verified
  byte-for-byte, not by equivalence: the statement each of the five
  previously-hard-coded operations emits is character-identical to what it was
  before the routing change, and a test pins the exact strings rather than
  going through `is_same_sql_bind`, whose normalisation would have hidden a
  whitespace drift.
- **`except` keeps its behaviour exactly**, and becomes a one-liner like its
  five siblings. It used to forward `@args` where the others forward `$_[1]`,
  which was inert (`_set_operation` reads two arguments) and existed only
  because the keyword lookup lived in that body. With the lookup gone the
  asymmetry has no reason left, so it goes with it rather than surviving as a
  vestige the next reader has to explain.
- **One driver must be ported**: `dbio-oracle` is the only repo in the family
  whose `lib/` overrides `_except_operator` (verified by grep across every
  `dbio-*/lib`). `dbio-sqlite` references the old name in a test that asserts
  it does *not* override it. Both are unreleased. Cross-repo tickets, not this
  repo's work.
- **The migration is not silently safe**, and the tickets must say so: an
  unported `_except_operator` override is simply never called again. There is
  no error. `dbio-oracle` would quietly emit `EXCEPT` on an engine that wants
  `MINUS`. The mitigation is that both repos are unreleased and the port is one
  ticket each.
- **Core's own suite**: `t/helpers/set_operations.t` grows the routing,
  refusal, `next::method`-composition and unknown-op coverage;
  `t/test/23_exists_query_seam.t`, `t/test/08_replicated.t`,
  `t/test/24_driver_spelling_hooks.t` and `t/test/12_contract_version.t` move
  to the new name. Mock storage only, per house rules — real per-engine
  behaviour belongs in the driver dists.
- **Contract stays 1.2**; `t/test/12_contract_version.t`'s header block carries
  the argument (§6).

### Explicitly out of scope: Oracle's column-type restriction on set operators

k135 reports a second Oracle fact, from the SQL Language Reference for all
versions: set operators are not permitted on `BLOB`, `CLOB`, `BFILE`, `VARRAY`
or nested-table columns. **This seam does not and should not address it**, and
that is recorded here so the next reader does not re-open it:

- It is a **per-query fact about column types**, not a property of the
  operation. `$rs->union($other)` is legal or illegal on Oracle depending on
  what the two operands select, and `_set_operation_keyword` is asked for a
  keyword, given only an operation name.
- It is **not decidable at build time from the operation name**, which is the
  only input the hook has. Deciding it would mean core inspecting resolved
  column types against a driver-supplied type list at query-build time — a
  whole different mechanism, in a different place, for a different question.
- It **announces itself as an engine error** with a message that names the
  problem, which is the failure mode this ADR exists to *reach*, not to
  prevent. Unlike `EXCEPT ALL` on Oracle — a generic syntax error several
  layers below the method the caller called — a rejected LOB column produces a
  diagnosis a caller can act on.

If it is ever worth handling, it is a separate design about column-type
preconditions, and it belongs to whoever files it.

## Future architecture work (tracked cross-repo, not here)

Core ships first this time, and the window is **not** zero the way ADR 0037 §7's
`except` rollout was: the old hook is removed, so an unported driver loses its
override silently (see Consequences). Both affected repos are unreleased, which
is the whole mitigation.

| Repo | Work |
|---|---|
| **dbio-oracle** | port `_except_operator` → `_set_operation_keyword($op)`: `'MINUS'` for `except`, refuse `except_all` (and `intersect_all` if the same version boundary applies — verify against the reference, do not assume), `next::method` for the rest. Its `t/35-except.t` and its `DBIO::Oracle::Storage` POD move with it |
| **dbio-sqlite** | its `t/24-except.t` asserts the *absence* of an override by the old name; move it to the new one. Then decide whether the driver refuses `intersect_all` / `except_all` — its own live `t/resultset/set_operations.t` already skips them by a `sqlt_type eq 'SQLite'` comparison, which is the ADR 0021 anti-pattern this seam replaces, and the version boundary in that skip's comment ("< 3.39") is unverified |
| **dbio-mssql** | verify whether the engine has `INTERSECT ALL` / `EXCEPT ALL` and refuse from the hook if not. Core asserts nothing about it |
| **dbio-firebird**, **dbio-sybase** | ADR 0037 §5's open question — whether the engine has set difference at all — is now answered in the same hook, together with the `… ALL` family |
| **every other driver** | nothing. A driver with all six ANSI operations inherits the base map and needs no code |

`dbio-informix` is excluded: abandoned, unbuildable, never in a sweep.

Relates to ADR 0017 (Storage is the blessed home for engine-specific
behaviour), ADR 0021 (the driver-name string match this family of seams
replaces), ADR 0024 (the contract-version mechanism and the 1.2 generation),
ADR 0036 (the precedent for refusing rather than degrading silently), and
above all ADR 0037 §3, which designed the hook this generalises, named the gap
this closes, and wrote the criterion this ADR fires against — one clause too
narrowly.
