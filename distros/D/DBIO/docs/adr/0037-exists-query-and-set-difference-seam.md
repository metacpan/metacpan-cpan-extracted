# ADR 0037 — `results_exist` and `except`: a capability seam for the two engine-specific fragments left in core

- Status: accepted
- Date: 2026-07-26
- Tags: bug, api, resultset, capability, sql, cross-repo, drivers

> The core half is implemented (k111): the capability, both hooks, the
> exception contract, the `_determine_driver` registrations and the
> `@writer_methods` delegation. The driver halves are separate tickets on the
> nine driver boards (§7).
>
> Two implementation details this document left open, decided while building it
> and recorded here rather than silently: the complete statement is executed
> through `DBIO::Storage::DBI::_execute_rendered` (everything `_execute` does
> below the SQL-generation step — `dbh_do` retry, tracing, `redact_bind_value` —
> but no `sql_maker` op, because a `FROM`-less statement is not expressible as
> one), and its async twin runs on the transport's existing raw-SQL seam
> `_query_async`, the one `_execute_ddl_async` already uses for statements core
> rendered itself.
>

> Two things in it deviate from the brief that commissioned it, both deliberate
> and both argued below rather than smuggled in:
>
> - **`except` gets a hook, not a capability** (§3). The goals the capability was
>   asked for — no driver-name match, no connection at query-build time, the
>   driver owns its dialect — are all met. The mechanism cannot be a capability:
>   `get_dbms_capability` coerces every answer to `1`/`0`, so a *keyword* cannot
>   ride on one, and a boolean `set_difference_uses_minus` is the ADR 0021
>   name-match re-encoded as a flag.
> - **The rollout is nine driver tickets, not five** (§7). Five drivers have to
>   *render*; four more have to *declare*. A gate everyone must pass through is
>   only a gate if everyone passes through it.

## Context

### Two helpers in core still write engine-specific SQL

Both are always-on public API in a distribution that ships drivers for the very
engines they break on.

**A — `results_exist` / `results_exist_as_query` / `results_exist_async`**
(`DBIO::ResultSet`). Inherited from upstream character-for-character. Reproduced
against `DBIO::Test::Storage`, not taken on trust — this is the statement the
storage actually receives:

```sql
SELECT * FROM ( SELECT EXISTS (SELECT 42 FROM "artist" "me" WHERE ( "name" = ? )) ) AS _existence_subq
```

and `results_exist_as_query` on its own yields

```sql
( SELECT EXISTS (SELECT 42 FROM "artist" "me" WHERE ( "name" = ? )) )
```

That fragment stacks **three** separate portability assumptions:

1. `EXISTS (<subquery>)` used as a **scalar value expression** in a select list.
   Standard SQL has `EXISTS` only as a *predicate* — usable where a condition is
   expected, not where a value is. This spelling needs an engine with a real
   boolean value type.
2. A `SELECT` with **no `FROM`**.
3. `... AS _existence_subq` — `AS` before a **derived-table** alias, which Oracle
   rejects outright (ORA-00933).

| Engine | 1. `EXISTS` as a value | 2. `SELECT` without `FROM` | 3. `AS` on a derived table |
|---|---|---|---|
| PostgreSQL, MySQL/MariaDB, SQLite, DuckDB | yes | yes | yes |
| SQL Server, Sybase | no — needs `CASE WHEN EXISTS (…) THEN 1 ELSE 0 END` | yes | yes |
| Oracle | no — needs `CASE WHEN …` | no — needs `FROM DUAL` | **no** |
| DB2 | no — needs `CASE WHEN …` | no — needs `FROM SYSIBM.SYSDUMMY1` | yes |
| Firebird | no — needs `CASE WHEN …` | no — needs `FROM RDB$DATABASE` | yes |

No driver overrides `results_exist`; there is no capability check and no
fallback. `$oracle_schema->resultset('Artist')->results_exist` fails with
`ORA-00923: FROM keyword not found where expected`. Upstream got away with it
because the method was an opt-in component, usually in single-engine
applications; in DBIO it is always on.

A latent second defect rides along: `results_exist` reads the answer as
`$sth->fetchall_arrayref->[0][0] ? 1 : 0`. Whether a boolean-typed column
arrives in Perl as `0`/`1` or as `'f'`/`'t'` is a DBD setting — with
`pg_bool_tf => 1`, `'f'` is *true* in Perl and `results_exist` returns 1 for an
empty set.

**B — `except`** (`DBIO::ResultSet`) makes a **driver-name comparison** where the
family's answer is a declaration:

```perl
my $keyword = $self->result_source->schema->storage->sqlt_type eq 'Oracle'
  ? 'MINUS' : 'EXCEPT';
```

`sqlt_type` in DBIO is `$dbh->{Driver}{Name}` reached through `_get_dbh`
(`DBIO::Storage::DBI`), so **`$rs->except($other)->as_query` opens a database
connection** — purely to choose a keyword. Upstream at least cached the result
(`DBIx::Class::Helper::ResultSet::SetOperations`); DBIO dropped the cache when
the helper was folded in and re-derives it on every call. This is also the exact
anti-pattern ADR 0021 records and ADR 0026 replaced for `IF EXISTS`.

### These are not the same defect twice

They look alike (engine-specific SQL, no seam) and are not:

- A is a **SQL form**: a whole fragment whose shape differs per engine, with a
  portable alternative already in core (`has_rows`, which is
  `rows(1)->next` and works everywhere).
- B is a **single keyword**, with **no** portable alternative — a caller cannot
  emulate set difference in the ORM.

That difference decides the seam for each (§2, §3). Treating them as one axis
would give a flag that means two things and a hook that carries none.

### The seams that already exist (verified, so the design is not aspirational)

- **Capabilities are declared, never string-matched.**
  `DBIO::Storage::DBI::Capabilities` keeps a flat `@capabilities` list behind
  `mk_group_accessors( dbms_capability => "_supports_$_" )` and
  `mk_group_accessors( use_dbms_capability => "_use_$_" )`; a driver opts in with
  `__PACKAGE__->_use_X(1)` or by defining `_determine_supports_X`, and the
  default `_determine_supports_*` returns `0`. ADR 0026 established the shape;
  ADR 0036 reused it for `supports_upsert`.
- **A capability answer is a boolean, structurally.** `get_dbms_capability`
  stores `$self->$meth ? 1 : 0`. Nothing that is not a yes/no can travel this
  way. (`get_use_dbms_capability` returns whatever `_use_X` was set to, so a
  string *appears* to work through one door and is flattened by the other — a
  trap, not a feature.)
- **Engine-specific fragments consumed by `DBIO::ResultSet` are storage hooks
  today.** `_random_function` (`'RANDOM()'`) and `_explain_sql`
  (`"EXPLAIN $sql"`) on `DBIO::Storage::DBI`, called from `ResultSet::rand` and
  `ResultSet::explain` — a few dozen lines from `except` in the same file. ADR
  0017 blesses the driver's Storage class as the home for engine-specific
  behaviour.
- **Driver determination does not require a connection.**
  `DBIO::Storage::DBI::_determine_driver` reblesses from the DSN via
  `_extract_driver_from_connect_info`; it only connects when `connect_info` is a
  coderef. A parameterised `around` at the top of `DBIO::Storage::DBI` fires
  determination before a listed set of methods — `sqlt_type`, `sql_maker`,
  `cursor_class`, `get_dbms_capability`, `get_use_dbms_capability`, … — so a
  driver-owned answer is reachable on a never-connected storage **iff the method
  is on that list**. `_random_function` and `_explain_sql` are *not* on it, which
  is a live bug of its own (k112).
- **`DBIO::Replicated::Storage` delegates by an explicit list.** `sqlt_type` and
  `sql_maker` are in `@writer_methods`; `_random_function` and `_explain_sql`
  are in neither list.

## Decision

### 1. Two seams, one capability

| Defect | Rendering seam | Capability |
|---|---|---|
| A — `results_exist*` | `_exists_value_sql` on `DBIO::Storage::DBI` | **`supports_exists_query`**, default `0` |
| B — `except` | `_except_operator` on `DBIO::Storage::DBI` | none |

The cut is **what a caller can do with the answer**:

> A capability is public, caller-facing branch material. It earns its place when
> a portable application can *act* on it — the idiom ADR 0036 §3 blesses for
> `upsert`:
> `$storage->_use_supports_X ? $rs->fast_path : $rs->portable_path`.

`results_exist` is an *optimisation* with a portable alternative already in core
(`has_rows`), so "can I use the fast path on this engine?" is a real question
with a real answer, and a flag is the ADR-0021-conform way to ask it. `except`
has no alternative: a caller learning "no" can only stop. A flag nobody can
branch on is not a contract surface, it is a second place for the truth to live.

Both seams are **storage hooks**, not SQLMaker methods. `DBIO::ResultSet`
assembles this SQL itself — `results_exist_as_query` string-pastes around
`as_query`'s output and `_set_operation` joins operand SQL with a keyword;
neither passes through a `sql_maker` entry point, so there is no options
transport to extend the way ADR 0036 extended `sql_maker->insert`. Inventing a
SQLMaker method with no caller inside SQLMaker would put the renderer one object
away from every other fragment `DBIO::ResultSet` asks the storage for.
`_random_function` / `_explain_sql` are the precedent, in the same file, for the
same shape: string in, string out, no `$dbh`.

This stays inside the line k114 drew — engine-specific SQL belongs in the
driver dists behind a declaration, never as an `isa`-chain in core. It picks the
other blessed home for it (Storage, ADR 0017) rather than the one k114 named in
passing (SQLMaker), for the reason above.

### 2. `results_exist`: capability plus hook, and core's default becomes the standard form

**The hook.** `$storage->_exists_value_sql($inner_sql)` returns a **complete
statement** yielding `1` or `0`. The base implementation on
`DBIO::Storage::DBI`:

```
SELECT CASE WHEN EXISTS <inner> THEN 1 ELSE 0 END
```

This is the standard-conforming spelling and it is *strictly more portable than
what core emits today*: it is correct on PostgreSQL, MySQL/MariaDB, SQLite,
DuckDB, SQL Server and Sybase. Only the three engines that also refuse a
`FROM`-less `SELECT` override the hook, each appending its own dummy table —
Oracle `FROM DUAL`, DB2 `FROM SYSIBM.SYSDUMMY1`, Firebird `FROM RDB$DATABASE`.
The driver renders the whole fragment; core never composes it from parts and
holds no dummy-table knowledge.

Changing the default form is not core keeping a dialect: it is core moving *off*
one. `SELECT EXISTS (…)` without `FROM` is a PostgreSQL-ism that four engines
happen to accept; `CASE WHEN … THEN 1 ELSE 0 END` is what standard SQL offers for
a boolean-valued expression. It also settles the `'f'`-is-true footgun above by
construction: the column is an integer on every engine.

**Core adds parentheses and nothing else.**

- `results_exist_as_query` returns `\[ "( $stmt )", @bind ]`. A parenthesised
  scalar subquery is universal; that is the entire decoration core is allowed.
- `results_exist` / `results_exist_async` execute `$stmt` **as the statement**.
  The `SELECT * FROM ( … ) AS _existence_subq` wrapper is dropped: the fragment
  is already a complete statement, the wrapper is where assumption 3 (Oracle's
  `AS`) entered, and it forced one string to be grammatically valid in two roles
  at once — a derived table here, a scalar expression there.
- Execution stays on the storage's normal statement path, so the mock captures
  it and tracing / `redact_bind_value` (ADR 0025) still apply. Sync and async
  must keep resolving *identical* SQL; `t/resultset/async_parity_helpers.t`
  already pins that and is the tripwire.

**The capability.** `supports_exists_query` on
`DBIO::Storage::DBI::Capabilities`, default `0`, same
`mk_group_accessors( use_dbms_capability => … )` shape as ADR 0026 / ADR 0036.
Its meaning, in the wording the POD should carry: *the storage can render a
boolean-valued EXISTS query this engine accepts* — either because the base
rendering is right for it, or because the driver overrode `_exists_value_sql`.
Drivers declare with `__PACKAGE__->_use_supports_exists_query(1)`.

> **ADR 0041 addendum.** The driver rollout reported this recommendation as a
> trap: a class-level `_use_` declaration appeared to occupy the caller's force
> slot, so clearing a force with `undef` never handed the question back to the
> driver (k137). **The recommendation is right and stands.** The class-level
> declaration and the per-storage force were always two different slots — a
> package variable and the instance hash — and the defect was that `undef` on an
> instance wrote a tombstone instead of clearing. ADR 0041 fixes that in
> `set_use_dbms_capability` and records which slot is whose. A constant
> `sub _determine_supports_supports_exists_query` remains equally valid; pick by
> whether the fact is declared or probed, not by which one is safe.

The flag is not vacuous for a driver that does not override the hook: it asserts
that somebody *checked*. The engines nobody has checked — ClickHouse, GraphQL,
whatever is written next — are exactly the ones a default-on would ship broken
SQL to.

`_exists_value_sql` must be registered in the `_determine_driver` `around` list
at the top of `DBIO::Storage::DBI`, or a never-connected storage answers with the
base rendering no matter which driver the DSN names. (`get_dbms_capability` is
on the list already, so probing the capability determines the driver on its own —
but the hook must not depend on the probe having happened first.)

### 3. `except`: a storage hook, no capability

`$storage->_except_operator` returns the keyword. Base implementation:
`'EXCEPT'` — ANSI SQL-92, correct on PostgreSQL, SQLite, DB2, SQL Server, DuckDB
and MySQL ≥ 8.0.31 / MariaDB ≥ 10.3. `dbio-oracle` overrides it with `'MINUS'`.
`ResultSet::except` calls the hook instead of comparing `sqlt_type` to
`'Oracle'`. Like `_exists_value_sql`, it goes on the `_determine_driver` list.

Why no flag, beyond the mechanical fact that a capability cannot carry a string:

- **There is nothing to branch on.** Set difference has no portable fallback in
  the ORM, so a caller who learns "unsupported" has no second call to make. The
  flag would be read by nobody.
- **A boolean would have to encode the token.** `set_difference_uses_minus` is
  `sqlt_type eq 'Oracle'` with better manners, and it breaks on the third
  spelling exactly the way the name match breaks today.
- **The hook is already the refusal seam.** An engine with no set difference at
  all does not need a core flag to say so — its driver's `_except_operator`
  throws a typed exception naming the engine and the version, which is a better
  message than core could ever write. Refusal and rendering stay in one place.
- **A gate would regress every working engine.** `except` works today everywhere
  except where the name match already handles it. Defaulting a gate to `0` would
  break PostgreSQL, SQLite, MySQL, SQL Server, DB2 and DuckDB until each shipped
  a declaration — trading a real defect on one engine for an outage on six.

**Scope: `except` only.** `union`, `union_all`, `intersect`, `intersect_all` and
`except_all` keep their hard-coded keywords. They have the same *class* of
problem — SQLite and SQL Server have no `EXCEPT ALL` / `INTERSECT ALL`, and
Oracle has no `MINUS ALL` before 21c, so `except_all` is broken on Oracle in a
way this ADR does **not** fix — but no engine in the family spells them
*differently*, so there is nothing for a keyword hook to do; what they need is a
refusal, which is a different design and its own ticket. The hook is named
`_except_operator` and not `_set_operation_keyword($op)` for that reason: it is
single-use today (house rule 2). Falsifiable criterion for generalising it: the
moment a second set operation needs a per-engine spelling, replace it with a map
— it is a private method, so that is free.

> **Superseded by ADR 0039 (k135).** The generalisation happened, and the
> honest record is that the criterion above fired for a *neighbouring* reason:
> no second operation ever needed a second spelling, but `except_all` needed a
> per-engine **refusal**, and a refusal is per-operation, so it needs the same
> map. The criterion was written against the narrower of the two possibilities
> this very paragraph had already named. `_except_operator` is **replaced, not
> kept**, by `_set_operation_keyword($op)` — one seam for all six operations,
> asked with the canonical operation name, whose two jobs are to spell the
> operation or to refuse it. Three of the four bullets above transfer
> unchanged; the second ("a boolean would have to encode the token") does
> **not**, because the `… ALL` family has no second spelling and so a
> capability there would be mechanically possible — it is refused for the other
> three reasons instead. ADR 0039 §3 records that.

### 4. What a non-declaring engine does

No silent fallback. `results_exist` never degrades to `has_rows` on its own: that
is the silent degradation ADR 0036 refused for `upsert`, and the reason is the
same — the caller asked for the cheap server-side check and would get a different
query shape without being told.

**Contract.** When `supports_exists_query` is false, `results_exist`,
`results_exist_as_query` and `results_exist_async` all throw a typed exception
via `$self->throw_exception` (which routes to `DBIO::Exception`, F21 — never a
bare `croak`), **before any SQL is built or executed**. All three, because
`results_exist_as_query` is public and documented for correlated subqueries; if
only the executing pair threw, the fragment would be embedded in a larger query
and fail far from its cause.

The throw is **synchronous in the async twin too**. That is not a departure from
k109 (a refused *connect action* fails the Future): this is a static
precondition, decidable without I/O, and `_rs_run_async` already throws
synchronously for exactly that class of problem ("not an async connection").

The message must name five things:

1. the method the caller called;
2. the storage class, so the engine is identifiable;
3. the capability, `supports_exists_query`, spelled exactly as a driver would
   declare it;
4. why — this engine's driver has not declared that it can render a
   boolean-valued `EXISTS` query;
5. the portable alternative, `$rs->has_rows`, **and** the capability branch, so
   the exception teaches the ADR-0021-conform idiom instead of only complaining:

```
$storage->_use_supports_exists_query ? $rs->results_exist : $rs->has_rows
```

Rejecting a *silent* fallback is not rejecting the alternative. `has_rows` is the
right answer; the caller has to choose it.

### 5. `as_query` must not connect — and what that can honestly promise

After this change **core** needs no `$dbh` to build either fragment: no
`sqlt_type`, no `_get_dbh`, no `_server_info`. What remains is driver
determination, which both hooks trigger through the `around` list, and which is
DSN-based and connection-free — with two pre-existing exceptions this ADR does
not create and will not promise away:

- `connect_info` given as a **coderef**: `_extract_driver_from_connect_info` has
  no DSN to read and connects.
- a driver whose own **`_rebless` probes the server**. Verified, not assumed:
  `DBIO::Sybase::Storage::_rebless` runs `sp_server_info` through `_get_dbh` to
  decide which Sybase it is talking to. On that driver, determination connects —
  for every determined method equally, `sqlt_type` included, today and after.

**Driver obligation: `_except_operator` is a static class fact.** No `_get_dbh`,
no version probe. This is not a preference — `_set_operation` bakes the keyword
into a literal `from` clause at *construction* time, so a runtime-resolved
keyword is not expressible at all.

Checked across the family rather than assumed: **no engine needs a live handle to
name its set-difference keyword.** Oracle spells it `MINUS` on every version
including 21c+, which also accepts `EXCEPT` — so `'MINUS'` is a constant, not a
version question. Everywhere else the spelling is `EXCEPT` or the operation does
not exist; nobody has two spellings across versions. Where *availability* is
version-dependent (MySQL < 8.0.31 has neither), the spelling is still constant
and the refusal belongs at execution time or in the driver's own hook — never as
a build-time probe. `dbio-firebird` and `dbio-sybase` must establish whether their
engines have set difference at all; this ADR does not assert it for them.

### 6. Contract version: inside 1.2, not a 1.3

`$CONTRACT_VERSION` on `DBIO::Storage::DBI::Capabilities` is `'1.2'` and **1.2
has never been released**. The last CPAN release is 0.900002 (2026-07-13); 1.2
was introduced afterwards by the upsert work (k100), and no driver in the
family declares `$TESTED_AGAINST_CONTRACT` at all — checked across every
`dbio-*/lib`.

So `supports_exists_query` lands **inside 1.2**, by the same in-cycle rule
`t/test/12_contract_version.t` already records for the k104 and k105 additions:
*one bump per released contract generation, not one per commit.* A driver
reading 1.2 gets the whole generation at once. Bumping to 1.3 here would publish
two generations that no consumer can ever have seen apart.

The tripwire is not optional: `t/test/12_contract_version.t`'s comment block gets
the addition, so 1.2's contents are documented before 1.2 is published. That is
what ADR 0024 bought — the number moving without the test moving fails CI.

One observation, recorded rather than fixed: the capability is on a versioned
base class, but the two **hooks** live on `DBIO::Storage::DBI`, which carries no
`$CONTRACT_VERSION`. ADR 0024 chose its five classes deliberately and treats the
number as one family-wide signal, so the hooks ride along with the capability's
bump. If out-of-tree storage subclasses ever need to version-check hooks
independently, that is an ADR 0024 question, not this one's.

### 7. Migration: two defects, two rollout directions

The two seams roll out in **opposite order**, and the reason is worth stating
because it is not obvious:

> A **hook override** is inert against an older core — the old core never calls
> it. A **capability declaration** is not: `__PACKAGE__->_use_supports_exists_query(1)`
> dies at load time on a core that has not defined the accessor.

Hence:

**A (`results_exist`) — core first, and the window is real.**

| Engine group | Today | After core, before its driver ships | After its driver ships |
|---|---|---|---|
| Oracle, DB2, SQL Server, Firebird, Sybase | broken SQL (`ORA-00923` and friends) | typed `DBIO::Exception` naming `has_rows` | works |
| PostgreSQL, MySQL, SQLite, DuckDB | works | **throws** — regression | works |

The first row is the improvement the ticket is about: a wrong-SQL failure becomes
a diagnosable one. Callers who wrapped `results_exist` in a `try` catching DBI
errors now catch a `DBIO::Exception` — a change, not a silent one.

The second row is the price of the gate and must not be discovered at release
time: four working engines throw until each ships a one-line declaration. The
mitigation is scheduling, not code — **core and the four declaring drivers
release together**, and core's release notes name them. There is no core-side
way to shorten the window without weakening the gate to a default-on flag, which
is the alternative in §Alternatives.

**B (`except`) — drivers first, and the window is zero.** `dbio-oracle` can ship
`sub _except_operator { 'MINUS' }` *today*: current core never calls it, so the
override is dead code until core stops name-matching. Once it is released, core
drops the `sqlt_type` comparison and Oracle never regresses. Every other engine
sees no change at all except that `$rs->except($other)->as_query` stops opening a
connection.

**Core's own suite.** `DBIO::Test::Storage` declares no capabilities today and
must declare `supports_exists_query` (its `sqlt_type` is the placeholder
`'NULL'`, so it was never in the Oracle branch either). Three test files pin the
current strings and will move with the change:
`t/helpers/subquery_helpers.t` (the `as_query` fragment),
`t/resultset/async_parity_helpers.t` (sync/async SQL parity) and
`t/test/08_replicated.t` (a comment referencing the `_select` path).

## Alternatives considered

- **Silent fallback to `has_rows` when the capability is false** — rejected by
  the maintainer, and for ADR 0036's reason: a method that quietly becomes a
  different query on some engines is the over-promise that ADR's whole §3 exists
  to prevent. The alternative is *named in the exception* instead.
- **Exception only, no seam** — rejected: it would make `results_exist`
  permanently unavailable on five shipped engines for a fragment each of them
  can express in one line.
- **`supports_exists_query` defaulting to `1`** (a refusal switch rather than a
  gate) — the honest runner-up, and it is cheap: with the standard `CASE WHEN`
  base rendering, only three drivers would need any change at all, and no
  working engine would ever regress. Rejected because "declared, not assumed" is
  the family's whole answer to engine facts (every capability but
  `join_optimizer` defaults to `0`), and because the engines that would benefit
  from the default are precisely the ones nobody has verified. The cost of the
  rejection is stated plainly in §7 rather than buried: four working engines
  throw until they declare.
- **One capability covering both defects** ("engine renders engine-specific
  SQL") — rejected: the two axes do not co-vary. MySQL needs no help with A and
  has no `EXCEPT` before 8.0.31; Oracle needs help with both but for unrelated
  reasons. One flag would be false for engines that only fail one half.
- **Splitting A into two capabilities** (scalar-`EXISTS` and `SELECT`-without-
  `FROM`) — rejected: core would then *compose* a fragment out of flags, which is
  building engine SQL in core with extra steps. ADR 0036 §3's "one flag, not a
  family" applies; the driver renders the whole fragment.
- **Rendering in the driver's SQLMaker instead of its Storage** — considered
  seriously (it is what k114 names in passing, and what ADR 0036 chose).
  Rejected here because neither fragment passes through a `sql_maker` entry
  point: there is no options transport to extend, so it would mean a new
  SQLMaker method with no caller inside SQLMaker, one object away from
  `_random_function` / `_explain_sql`, which are the same shape and already on
  Storage.
- **A capability for `except`** — see §3. Not workable as asked
  (`get_dbms_capability` coerces to boolean) and not useful as a boolean.
- **Keeping the `sqlt_type` comparison but caching it**, as upstream did —
  rejected: caching a driver-name match makes it cheaper, not correct, and it
  still connects once.

## Consequences

- **New public capability** `supports_exists_query` (default `0`) and two new
  storage hooks `_exists_value_sql` / `_except_operator`, both registered in the
  `_determine_driver` `around` list. Contract stays **1.2** (§6);
  `t/test/12_contract_version.t` records the addition.
- **`DBIO::Replicated::Storage` must delegate both hooks** by adding them to
  `@writer_methods`, where `sqlt_type` and `sql_maker` sit today. Without it the
  fix *regresses* replicated setups, where `except` works now precisely because
  `sqlt_type` is delegated.
- **`results_exist` output shape changes on every engine**: `1`/`0` from a `CASE`
  expression instead of an engine-typed boolean. Fixes the `'f'`-is-true reading
  under `pg_bool_tf => 1`; visible in the captured SQL of any test that pins the
  string.
- **`results_exist_as_query` stays public and stays usable in correlated
  subqueries**; only the fragment's spelling becomes engine-specific.
- **`$rs->except($other)->as_query` stops connecting.** Driver determination
  still runs (DSN-based); on `dbio-sybase` determination itself connects, as it
  does for every determined method there (§5).
- **`except_all` on Oracle stays broken** — `EXCEPT ALL` on an engine that has no
  `MINUS ALL` before 21c. Named here so it is a known gap and not a discovery;
  its fix is a refusal design for the `… ALL` family, not a keyword hook (§3).
  *(Closed by ADR 0039: the refusal design turned out to belong in the same
  hook, generalised to `_set_operation_keyword($op)`. Core ships the seam; the
  Oracle refusal itself is `dbio-oracle`'s ticket.)*
- **Mock-only core tests**, per house rules: the capability's get/set/fallback
  plumbing, the throw when it is false (all three methods, sync and async), the
  base rendering, and a fake storage overriding `_exists_value_sql` to prove the
  seam is used. Real per-engine SQL belongs in the driver dists.
- **`_random_function` / `_explain_sql` are missing from both the
  `_determine_driver` list and `DBIO::Replicated::Storage`'s delegation lists.**
  Found while establishing that the new hooks need both. Not fixed here — it is
  k112's, and this ADR is the second reason to do it.

### Cross-repo rollout — nine driver tickets, not five

Core first for A, `dbio-oracle` first for B (§7). `dbio-informix` is excluded:
abandoned, unbuildable, never in a sweep.

| Repo | Work |
|---|---|
| **dbio (core)** | `supports_exists_query`; `_exists_value_sql` with the `CASE WHEN` base rendering; `_except_operator` returning `'EXCEPT'`; both on the `_determine_driver` list and in `@writer_methods`; drop the `SELECT * FROM (…) AS …` wrapper; drop the `sqlt_type` comparison in `except`; the §4 exception contract; POD; mock tests; `t/test/12_contract_version.t` comment block |
| **dbio-oracle** | `_except_operator` → `'MINUS'` — **ship before core**, inert until then. Then `_exists_value_sql` → `CASE WHEN … FROM DUAL` + declare `supports_exists_query` |
| **dbio-db2** | `_exists_value_sql` → `CASE WHEN … FROM SYSIBM.SYSDUMMY1` + declare. The dummy table is already known to the dist (`DBIO::DB2::Storage`, its own ADR 0002) — do not hard-code it twice |
| **dbio-firebird** | `_exists_value_sql` → `CASE WHEN … FROM RDB$DATABASE` + declare. Also establish whether Firebird has set difference at all; if not, `_except_operator` throws |
| **dbio-mssql** | declare `supports_exists_query`; the base `CASE WHEN` rendering should suffice (no dummy table needed) — verify, do not assume |
| **dbio-sybase** | same as MSSQL, plus the set-difference question. Note §5: this driver's `_rebless` connects regardless |
| **dbio-postgresql** (+ **-ev**, **-age**, **-postgis**) | declare `supports_exists_query`; verify the subclasses inherit the declaration rather than re-declaring |
| **dbio-mysql** (+ **-ev**) | declare `supports_exists_query`. Set difference is version-gated (`EXCEPT` ≥ 8.0.31 / MariaDB ≥ 10.3) — no keyword override, but worth a note in the driver's POD |
| **dbio-sqlite** | declare `supports_exists_query` |
| **dbio-duckdb** | declare `supports_exists_query` |
| **dbio-clickhouse** | audit: does the engine take the base rendering? Declare only if verified — the default `0` is correct until then |

**Rollout complete 2026-08-04.** All ten driver halves landed, together with
ADR 0039's, since both live on the same storage class. Four rows above were
wrong or under-specified and are corrected here rather than left standing:

- **The set-difference question this table left open is answered.** Firebird
  has **no set difference at all** — `UNION` and `UNION ALL` are the only set
  operators in the language, and `EXCEPT`, `INTERSECT` and `MINUS` are not
  keywords of the engine (5.0 Language Reference, Appendix C; the feature
  request FirebirdSQL/firebird#1194 has been open since 2004). Sybase ASE
  gained `INTERSECT`/`EXCEPT` in **16.0 SP03** and has never had their `ALL`
  forms; Cluster Edition lacks them in every version. Both refusals live in the
  ADR 0039 hook, which had not been designed when this table was written.
- **"Verify the subclasses inherit the declaration" is the wrong instruction**
  for `dbio-postgresql`, because there are no subclasses. Age and PostGIS are
  composition *layers* — `DBIO::Storage::Composed->compose` synthesises a class
  whose `@ISA` ends in the driver storage, and the capability accessors are
  `inherited` class data resolved along that linearisation, so a layer sees the
  declaration without mentioning it. The `-ev` transports are not subclasses
  either: async is a per-connection mode on the *sync* storage (ADR 0030), so
  the capability is probed and the statement rendered on `$schema->storage` and
  the backend only ever receives finished SQL. One declaration covers every
  transport, and nothing was needed in `-ev`, `-age` or `-postgis`. The word
  "subclass" should not be used for either mechanism in future capability work.
- **`dbio-mssql`'s "verify, do not assume" was the right instruction and paid
  off**: SQL Server takes the base rendering, sourced to the T-SQL `SELECT`
  synopsis (the `FROM` clause is optional), the `CASE` reference and the
  `EXISTS` reference — whose own example writes `CASE WHEN EXISTS (SELECT …)`
  verbatim. What T-SQL lacks is `EXISTS` as a bare *value* expression, i.e.
  exactly the PostgreSQL-ism §2 moved core's default off. The rewrite fixed
  SQL Server on its way past.
- **`dbio-mysql`'s row understated the work.** "No keyword override, but worth
  a note in the POD" was written before the refusal design existed; that driver
  now carries two capability declarations, because MySQL and MariaDB draw their
  boundaries at different *operations* (MySQL got `EXCEPT`/`INTERSECT` and both
  their `ALL` forms together in 8.0.31; MariaDB got the pair in 10.3 and the
  `ALL` forms only in 10.5.0).

One correction that is not about an engine: **`dbio-sqlite` declined to change
its declaration form, and was right to.** §2 names
`__PACKAGE__->_use_supports_exists_query(1)` in one sentence while the
`DBIO::Storage::DBI::Capabilities` POD blesses both that and a
`_determine_supports_*` sub. They are not interchangeable — `_use_X` is the
*caller's* force slot, so a driver declaring into it makes an instance-level
force unclearable — and §2 recommends the form with that trap. Measured, filed
as core k137, and not resolved here: §2 stays as written until k137
decides who owns the slot, because changing the recommendation without changing
the mechanism would only move the inconsistency.

Relates to ADR 0017 (Storage is the blessed home for engine-specific behaviour),
ADR 0021 (driver-name string match is the anti-pattern the capability replaces),
ADR 0024 (the contract-version mechanism and the 1.2 generation), ADR 0025 (the
executed fragment must stay on the traced/redacted statement path), ADR 0026 (the
capability-flag shape this reuses), ADR 0031 (the `select_single_async` contract
the async twin rides), and ADR 0036 (the precedent for a capability-gated seam
that throws rather than degrading, and for "one flag, not a family").

### Future architecture work (tracked, not here)

- **k112** — `_random_function` / `_explain_sql` are half-rolled-out *and*
  missing from driver determination and the Replicated delegation lists. Same
  seam family, same question ("should a non-declaring engine throw instead of
  inheriting a wrong default?"), separate ticket.
- ~~**The `… ALL` set operations** — `except_all` on Oracle, `intersect_all` /
  `except_all` on SQLite and SQL Server. A refusal design, not a keyword
  hook.~~ **Resolved by ADR 0039** (k135). It turned out to be a refusal
  design *and* a keyword hook: the same seam, generalised from
  `_except_operator` to `_set_operation_keyword($op)`, whose two jobs are to
  spell an operation or to refuse it — because refusal has to be written where
  the engine's version is known, which is the same place the spelling is.
