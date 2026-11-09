# ADR 0040 — `explain` is a storage *operation*, not a statement string: `_explain_query($sql, \@bind) -> \@rows`

- Status: accepted
- Date: 2026-08-04 (§6 added the same day — k139; §7 and the table's
  Evidence column added 2026-08-05 — k140, k141)
- Tags: api, resultset, storage-hook, drivers, replicated, tracing, cross-repo

## Context

### The seam as it stood

ADR 0011 recorded the fork decision that `DBIx::Class::Helper::ResultSet::Explain`'s
`DBIx::Introspector` dispatch is replaced by a storage hook, so a driver declares
its own dialect in its own class. The hook it produced was a **string**:

```perl
sub _explain_sql { "EXPLAIN $_[1]" }        # DBIO::Storage::DBI
```

`DBIO::ResultSet::explain` asked the storage for that string, appended nothing,
and executed it with the original query's bind values. k112 later fixed
*how* it executed — it had been reaching past the storage layer straight to
`$storage->dbh->selectall_arrayref` — and routed it through
`DBIO::Storage::DBI::_execute_rendered`. That fix is load-bearing for this ADR
and §3 below is entirely about not losing it.

### The finding: a string cannot express four of the ten engines

`_explain_sql($sql) -> $stmt` encodes four assumptions at once, and each is an
engine fact rather than a universal one:

1. obtaining a plan is **one** statement,
2. that statement is **executed** with the query's own binds,
3. it **returns rows**, and
4. those rows **are** the plan.

That holds on PostgreSQL, MySQL/MariaDB, SQLite (`EXPLAIN QUERY PLAN`),
ClickHouse and DuckDB. The other half of the family breaks it in five
*different* places, which is why no widening of the string could have absorbed
them.

**Read the Evidence column before building on a row.** Every engine statement
in this ADR is documentation or driver-side reading, not a measurement core
made: core is mock-only and no server was run for any of it. Where a driver has
since confirmed or corrected a row, that is recorded — three of these rows were
wrong when first written, and the column is what makes a wrong one visible
before the next driver copies it.

| Engine | What obtaining a plan actually is | Which assumption breaks | Evidence |
|---|---|---|---|
| **Oracle** | `EXPLAIN PLAN FOR <query>` writes into `PLAN_TABLE` and returns **no rows**; the plan comes from a **second** query, `SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY)` | 1 and 3 | Oracle SQL Language Reference + `DBMS_XPLAN` doc; **no server**. Implemented in `dbio-oracle` (dbio-oracle k22, offline tests, live half a SKIP block) |
| **DB2** | the same two-statement shape — `EXPLAIN PLAN SELECTION FOR <query>` into the `EXPLAIN_*` tables, read back separately | 1 and 3 | DB2 SQL Reference; **no server**. Implemented in `dbio-db2`; the driver corrected the spelling to `PLAN SELECTION` (bare `PLAN` is z/OS syntax toleration on LUW). Still **unverified against an engine** |
| **SQL Server** | no `EXPLAIN` statement exists. `SET SHOWPLAN_ALL ON` is a **session setting** that must stand alone in its batch; the query then returns the plan *instead of running*; then `OFF`. Three round-trips plus session state | 1, and the query's own execution semantics | Microsoft `SET SHOWPLAN_ALL` reference; **no server**. Implemented in `dbio-mssql` (dbio-mssql k22) — the seam fitted, `OFF` from a `Scope::Guard` so a failure cannot poison the session |
| **Sybase ASE** | also no `EXPLAIN`, but **not** SQL Server's shape: `set showplan on` does not suppress execution, and the plan comes back as server **messages** rather than rows — the answer is on the connection, not the statement. See §7 | 3 — the answer is not on the statement handle | SAP ASE *Using set showplan with noexec* + `DBD::Sybase`'s own `syb_err_handler` POD; **no server**. The message-collection seam is built in core (k140); the driver's `_explain_query` over it is `dbio-sybase`'s work |
| **Firebird** | the plan is a property of the **prepared statement** (`isc_dsql_sql_info(isc_info_sql_get_plan)`) — read off the handle through the DBD's private `$sth->func('ib_plan')`, not executed at all | 1 and 2 — there is no statement to spell | `DBD::Firebird` 1.39 / `DBD::InterBase` 0.48 XS + POD, and the installed `Firebird.so`; **no server**. Implemented in `dbio-firebird` (dbio-firebird k17) over §6; the driver corrected the reading form (k141) |

Five engines, five different shapes, one return type. A string has nowhere to
put a second statement, a session setting, or a value read off a handle — and
as §7 records, one of the five answers on the connection rather than the
statement, which is what the seam built there collects.

k112's closing note asked for exactly this ticket if the reports piled up
("häuft sich das, ist der Hook-Zuschnitt eine Core-Frage und braucht ein eigenes
Ticket"). Four of its ten driver handoffs came back saying the shape did not
fit — which is what the tickets were told to do: **report, don't bend**.
k138 is that ticket.

### What was *not* wrong

`_random_function` — the other hook ADR 0011 built, and `_explain_sql`'s
constant companion in every list and every comment — is **not** affected and is
deliberately untouched. Its shape (one scalar-function name, dropped into an
`order_by` literal) fits all ten engines; only the spelling differs. Its
rollout continues unchanged. Symmetry between the two hooks was a convenience
of history, not a requirement, and this ADR breaks it on purpose.

## Decision

### 1. The hook widens from a spelling to the whole operation

`_explain_sql` is **removed**. Not deprecated, not aliased, not kept as a
fallback. In its place, on `DBIO::Storage::DBI`:

```perl
sub _explain_query {
  my ($self, $sql, $bind) = @_;

  my (undef, $sth) = $self->_execute_rendered("EXPLAIN $sql", $bind);

  return $sth->fetchall_arrayref;
}
```

- `$sql` — the query to be explained, already stripped of the parentheses
  `DBIO::ResultSet::as_query` wraps it in. Core keeps that strip because it is
  a property of `as_query`, not of any engine; it has been unconditional since
  the fork (upstream did it only in its SQLite branch).
- `\@bind` — the query's bind values, in the native `[ \%attrs, $value ]` pair
  format the statement path takes. Not unwrapped: unwrapping them by hand is
  the bug upstream shipped, which bound the stringified arrayref
  `ARRAY(0x…)` instead of the value.
- return — the plan as an arrayref of row arrayrefs, whatever the engine had to
  do to produce it.

The base implementation does **exactly** what happened before: the same
statement, on the same seam, with the same result. This is a contract change,
not a behaviour change, for the five engines the old shape fitted.

`DBIO::ResultSet::explain` becomes the delegation it should always have been —
strip the parens, hand `($sql, \@bind)` to the storage, return what comes back.
Core composes nothing around the result and holds no engine knowledge.

### 2. The return type is rows, and it was never portable

`\@rows` is `fetchall_arrayref`'s shape. Its **contents** are engine-specific
and always were: no two engines in this family name the same plan columns, and
nothing in DBIO has ever normalised them. Stating that plainly matters, because
it is the strongest argument for the alternative this ADR rejects in §Alternatives
(moving `explain` to the ADR 0017 escape hatch), and it should not be discovered
later as if it were new. What `explain` promises is *a plan, obtained the way
this engine obtains one* — not a portable structure.

### 3. The price, and the rule that pays it: every statement goes through the storage's statement path

Widening the hook hands the driver the **execution**, which is the one thing
the string form kept in core. A driver can now reach for `$self->dbh` directly —
and doing so loses, in one step, precisely what k112 restored:

- `_query_start` / `_query_end` **tracing**, and therefore the
  `redact_bind_value` hook (**ADR 0025**) — bind values reach the trace sink
  unredacted;
- `dbh_do` **retry over disconnects**;
- `DBIO::Storage::DBI::NoBindVars` **bind interpolation**, via
  `_prep_rendered_for_execute` — on an engine with no usable placeholders the
  statement arrives with its `?` intact;
- on a `DBIO::Replicated::Storage`, the **read handler** — `dbh` is a writer
  method, so the `EXPLAIN` of a *read* query goes to the master's handle.

So the contract carries a requirement, not a recommendation, written into the
`=method` POD of `_explain_query`:

> **Every statement an override issues MUST go through the storage's statement
> path** — `_execute_rendered` when the statement is executed,
> `_prepare_rendered` when the engine's answer is an attribute of the
> **prepared** statement and nothing is executed at all.

A driver needing a session setting issues the `SET` through it. A driver needing
a second query issues that through it too. Firebird, whose plan is a prepared-
statement attribute rather than a statement, is the one shape with nothing to
*execute* — and §6 is what it routes through instead of inventing a private
path. **The rule has no engine-named exceptions**, which is the whole of §6's
argument.

**What core can and cannot test.** Core cannot detect the bypass from inside: a
driver's `_explain_query` is opaque, and nothing in `DBIO::Storage::DBI` can
tell whether a method it called touched `$dbh`. What core *can* do is make the
bypass loud in the place every driver already tests — against
`DBIO::Test::Storage`, where `_execute_rendered` is the **only** point at which
a statement is recorded, traced or redacted at all. `t/helpers/explain.t`
therefore carries both halves:

- a driver-shaped override in the **Oracle** two-statement form, asserting that
  *both* statements appear in `captured_queries`, that *both* reach the trace
  callback, and that `redact_bind_value` was applied to a bind the **driver**
  supplied — an observable that only the traced path can produce; and
- a **control**: the same hook implemented the way k112 found `explain()`
  implemented, reaching for the handle. It answers, so the ORM cannot tell —
  and it captures nothing, traces nothing, redacts nothing. That is the
  preceding assertion inverted, which is what makes it a test rather than a
  decoration.

§6 adds the same pair for the prepare-only shape, which is the same test one
verb earlier.

The per-driver assertion is each driver's own to write. This file states the
shape it has to take.

### 4. The classification flips: `_explain_query` is a **reader**

`_explain_sql` sat in `DBIO::Replicated::Storage`'s `@writer_methods`, and that
was **right at the time**: the hook produced only the *spelling* the master's
driver dictates, and the resulting statement executed separately through
`_execute_rendered` — a reader — so the `EXPLAIN` still ran on the read handler.

Once the hook owns the operation, the same entry would run the `EXPLAIN` of a
**read** query on the master, undoing k112's own repair through the back
door. `_explain_query` therefore moves to `@reader_methods`, beside `_select`
and `_execute_rendered`.

**The move is only half the work, and the other half is not visible from the
list.** The read handler is a `DBIO::Replicated::Balancer`, which is *not* a
storage: it subclasses `DBIO::Base`, has no `AUTOLOAD`, and forwards only the
methods it names explicitly (`select`, `select_single`, `columns_info_for`,
`_select`, `_execute_rendered`, `_dbh_columns_info_for`). A method on
`@reader_methods` with no counterpart there **dies** on the read handler —
verified, not reasoned: removing the forwarder produces
`Can't locate object method "_explain_query" via package
DBIO::Replicated::Balancer::First`. So `DBIO::Replicated::Balancer::_explain_query`
exists, routing exactly like `_execute_rendered`: master inside a transaction, a
replicant otherwise. (No `force_pool` handling — like `_execute_rendered`, this
call carries no attrs hashref to read one from.)

`_random_function` **stays a writer**, and the asymmetry is now the correct
description of two different things: a spelling the master's driver dictates,
versus a read performed on the pool.

The decision is pinned in `t/test/08_replicated.t` against **both** ways of
getting it wrong, because each is invisible to the other:

- left on the writer list → the statements land on the **master** (assertion:
  master captured nothing);
- on **neither** list → `DBIO::Replicated::Storage` answers from the generic
  base class, so one plain `EXPLAIN …` runs on the replicant: the routing looks
  right while the driver's operation is gone (assertion: the replicant received
  the master driver's *two* statements, the first spelled `EXPLAIN PLAN FOR`).

Both mutations were run and both fail; so does removing the Balancer forwarder.

### 5. It keeps its slot on the driver-determination list

`_explain_query` stays on the `_determine_driver` `around` list at the top of
`DBIO::Storage::DBI`, in the slot `_explain_sql` held, for the reason k112
put it there: a never-connected storage must answer with the operation of the
driver its **DSN** names, not with the base rendering. That this hook now
connects anyway does not make the entry redundant — the driver must be
determined *before* its `_explain_query` is chosen, not as a side effect of the
first statement the base implementation happens to run.

### 6. The one engine with nothing to execute: `_prepare_rendered` (k139)

Reported out of §3 before the ten driver tickets were retargeted, which is what
those tickets are for: **report, don't bend**. Firebird's plan is
`isc_info_sql_get_plan`, surfaced by `DBD::Firebird` as the **private
statement-handle function** `$sth->func('ib_plan')` once the statement is
**prepared**. Nothing runs. `_execute_rendered` prepares *and*
executes, so §3's rule — as first written — had nothing to apply to on the one
engine that could not obey it.

**A driver that must break a rule is a finding about the rule.** The two ways
out were: expose prepare-without-execute in core, or write a named exception
for Firebird into §3. Core exposes the seam:

```perl
sub _prepare_rendered {              # DBIO::Storage::DBI
  my ($self, $sql, $bind) = @_;

  ($sql, $bind) = $self->_prep_rendered_for_execute($sql, $bind);

  $self->_populate_dbh unless $self->_dbh;

  my $sth = $self->dbh_do( _dbh_prepare =>
    $sql, $bind, $self->_dbi_attrs_for_bind(undef, $bind),
  );

  return $sth;
}
```

**The decomposition is exact, which is the first half of the argument.**
`_dbh_execute` is literally *prepare, bind, execute* over two helpers that
already existed as separate methods — `_prepare_sth` and `_bind_sth_params` —
with `$sth->execute` the one line between them. `_dbh_prepare` is that method
minus the last verb. It is **not** factored out of `_dbh_execute`: calling it
from there would move `_query_end` to before the execute, and the start/end
pair is what every profiler built on `DBIO::Storage::Statistics` measures a
statement's runtime with. Three duplicated lines are cheaper than changing what
a timing number on the hot path means.

**`dbh_do`'s retry still makes sense, which is the second half.** The concern
worth checking was whether a retried *prepare* can hand back a live `$sth` the
caller then owns. It can, and better than an execute can: `dbh_do` asks its
callers for no side effects outside the database, and a prepare re-run after a
reconnect leaves nothing behind — the returned handle simply belongs to the new
connection. What retry does **not** cover is whatever the caller does with the
handle after `dbh_do` has returned; but that hole is not new, because
`_execute_rendered` already hands back a `$sth` that is fetched from outside
the retry window in exactly the same way. Named in the POD rather than assumed.

**Firebird's implementation, so the driver ticket does not have to invent it:**

```perl
sub _explain_query {                 # DBIO::Firebird::Storage
  my ($self, $sql, $bind) = @_;

  my $sth = $self->_prepare_rendered($sql, $bind);

  return [ [ $sth->func('ib_plan') ] ];
}
```

**`func('ib_plan')`, not `$sth->{ib_plan}`** — corrected 2026-08-05 out of
`dbio-firebird` k17 (core k141), which is the driver reporting back on
this section after implementing it. `ib_plan` is a **private XSUB of the
statement handle** in both DBDs, not a fetchable attribute: `DBD::Firebird`
1.39 and `DBD::InterBase` 0.48 each define `char* ib_plan(sth)` in their XS
and document the call as `print $sth->func('ib_plan');` — an example with no
`execute` in it, which is independent confirmation of the "nothing runs" claim
above. Neither DBD handles an `ib_plan` key in `dbd_st_FETCH_attrib`; verified
here against the installed `DBD::Firebird` 1.39 by both routes —
`DBD::Firebird::st->can('ib_plan')` is true, and the string `ib_plan` occurs in
`Firebird.so` **only** as the XSUB name `DBD::Firebird::st::ib_plan`, while
every attribute the driver's FETCH really serves (`ib_dialect`,
`ib_softcommit`, `ib_time_all`, …) is present as a bare string constant.

This matters more than a spelling. `$sth->{ib_plan}` does not throw — DBI
answers `undef` for an attribute nobody serves — so a driver that copied the
line as first written would have returned `[ [ undef ] ]`: a plan row the
caller cannot tell from a real one. That is the same **silent wrong answer**
class as SQLite's bytecode, which is the defect this whole ADR exists to
prevent.

The statement prepared is the **query itself** — there is no `EXPLAIN` spelling
to get wrong on this engine — and the plan is one opaque string, so it is
wrapped as a single row of a single column. That is a wrapping, not a fit, and
§2 already licenses it: the return type is rows, their *contents* are
engine-specific, and nothing in DBIO normalises them. Drivers do not invent
columns to fill; a driver whose engine hands back a naturally line-oriented
plan may split it into one row per line, and that too is engine-specific.

**Which guarantees survive, stated rather than assumed.** Through
`_prepare_rendered` a driver keeps everything `_execute_rendered` gives it up
to the execute: `_query_start` / `_query_end` **tracing** and therefore
`redact_bind_value` (ADR 0025) — which matters most here, because the binds are
the WHERE-clause values of the user's own query; **`dbh_do` retry** over a
dropped connection; **`_prep_rendered_for_execute`** and therefore
`DBIO::Storage::DBI::NoBindVars` interpolation; `_dbi_attrs_for_bind` plus
`_bind_sth_params`, including `bind_param_inout` and `_prepare_sth`'s
silent-failure check; and on a `DBIO::Replicated::Storage` the **read handler**
(§4 applies unchanged — it is on `@reader_methods` beside `_execute_rendered`,
with the matching `DBIO::Replicated::Balancer` forwarder). What it does not
give: no execute, so attributes some DBDs only populate afterwards are not
there; the retry window closes when the handle is returned; the handle may come
out of DBI's `prepare_cached` pool unless `disable_sth_caching` is set, so it is
to be used and let go; and the trace does not distinguish a prepare from an
execute — the statement appears in `debugcb` exactly as an executed one would.
It did go to the server; it did not run.

**Is Firebird the only case? Yes, and the seam is taken anyway.** DB2 was the
open question — §3 and the k112 handoff both record it as unverified. Its
in-SQL forms are `EXPLAIN PLAN FOR <stmt>` (and the `EXPLAIN ALL WITH SNAPSHOT`
variants) writing into the `EXPLAIN_*` tables, read back with an ordinary
`SELECT`, optionally preceded by the `SET CURRENT EXPLAIN MODE` session
setting. Every one of those is an **executed statement**, so DB2 is the Oracle
shape and `_execute_rendered` covers it; the remaining DB2 route,
`db2expln` / `db2exfmt`, is an external OS command outside DBI entirely and no
core seam could route it either. Its own confirmation against a live server is
still `dbio-db2`'s to make (dbio-db2 k22) — this only settles whether it is a
second customer for *this* seam. It is not.

So `n = 1`, and that is a judgement call rather than a slam dunk. It is taken
because the alternative is worse in a specific way: a named exception in §3
would say "Firebird may reach for `$dbh`", and the thing it would then lose is
not stylistic — it is `redact_bind_value` on the user's own bind values, plus
the other three regressions k112 removed. The exception would also be
unenforceable and self-undermining: a rule one day old with an engine-named
hole in it teaches the *next* driver that finds an unanticipated shape to cut
its own hole rather than report. The seam costs about a dozen lines and no new
mechanism — it reuses `_prepare_sth` and `_bind_sth_params` verbatim — and it
plausibly has other customers (any driver wanting to read statement attributes
without running the query). Cheap, exact, and it keeps the rule exceptionless.

`_prepare_rendered` is **not** on the `_determine_driver` list, and that is
deliberate: that list carries driver-varying *spellings* (§5), and this is a
path, not a spelling. `_execute_rendered` is not on it either.

Pinned in `t/test/25_prepare_rendered.t` (the seam: prepared and **not**
executed, against counting stub handles, with `_execute_rendered` on the same
stub as the control that proves the assertion discriminates; plus tracing and
redaction, the retry, the NoBindVars reshaping, the statement cache, and the
mock's `op => 'prepare'`) and in `t/helpers/explain.t` §6/§7 (the driver-shaped
form and its bypass control, the same pair as §4/§5). The replicated routing
and both of its silent failure modes are in `t/test/08_replicated.t`; removing
the Balancer forwarder reproduces k138's `Can't locate object method
"_prepare_rendered" via package DBIO::Replicated::Balancer::First`, and
removing the `@reader_methods` entry makes the statement vanish from the
replicant with no error at all. Both mutations were run and both fail.

### 7. The engine that answers on the connection, not the statement: Sybase ASE (k140)

Added 2026-08-05, reported out of `dbio-sybase` k28 — the same
**report, don't bend** loop that produced §6, and the record of it is the
difference between the two outcomes. Firebird could not obey the rule, so the
seam widened (§6). ASE could not be expressed by the seam *at all*, and for a
year the honest entry was a limitation rather than a widening. The maintainer
unblocked the seam on 2026-08-16: the message-collection channel is now built,
and this section records both the boundary and the seam that crosses it.

**What this ADR said about ASE, and what is actually true.** The table above
originally put SQL Server and Sybase ASE in one row. Only the first sentence of
it held for ASE:

- **The spelling is different.** ASE has `set showplan on`; `SET SHOWPLAN_ALL
  ON` is Microsoft's, and ASE has no such statement.
- **It does not suppress execution.** SAP's *Using set showplan with noexec*:
  the plain form "prints the query plan but also executes the queries, which
  might be time consuming"; "if you include `set noexec`, you can view the
  query plan without running the query". So it is **five** statements bracketing
  the query, not three — and getting this wrong does not fail loudly, it runs
  the user's query while they thought they were only planning it.
- **The plan is not a result set.** ASE emits showplan as **server messages** —
  the channel Transact-SQL `print` and `dbcc` output use. `DBD::Sybase` exposes
  that channel through the `syb_err_handler` callback and nowhere else; its own
  POD names the use case ("handling PRINT statements …, showplan output, dbcc
  output") and its worked example traps message numbers 3612‥3615, 6201‥6299
  and 10201‥10299.

The first two are the driver's business — other words, more statements, all
sayable through `_execute_rendered`. The third is the boundary this section
exists for: `_explain_query` must return what `$sth->fetchall_arrayref`
produces, and on ASE that is empty however correctly the five statements are
issued. **The answer arrives on the connection, not on the statement.**

**The seam: `_execute_sth` and `_server_messages`.** Core routes the execute
verb of `_dbh_execute` through a new hook, `_execute_sth($dbh, $sth)`, whose
base is the bare `$sth->execute`. A driver that can collect server messages
overrides it to install its handler on the `$dbh` it was given — the handle
the statement actually runs on — execute, remove the handler, and return the
collected messages as the second value. Core stores them on the storage
(`_server_messages`), where the driver reads them back after the statement.
The ASE `_explain_query` therefore issues the five statements through
`_execute_rendered` as usual, reads `_server_messages` after the query
statement, and wraps the messages as a single-column rowset — the same
wrapping §6 blesses for Firebird's single opaque string.

The seam is deliberately shaped to make the two named workarounds
unnecessary, because both were defects, not style:

- installing `syb_err_handler` on `$self->dbh` and collecting: on a
  `DBIO::Replicated::Storage` `dbh` is a *writer* method, so the handler would
  sit on the **master's** handle while the statements go to a replicant — the
  exact failure §4 exists to prevent — and it does not survive `dbh_do`'s
  reconnect retry, leaving the handler on a dead handle. The seam installs the
  handler on the handle `_dbh_execute` received — the read handler's handle on
  a replicated storage, because `_execute_rendered` is a reader — and
  `_dbh_execute` re-runs on every retry, so the handler rides the retry;
- `sp_showplan @spid` from a **second** connection while the query runs: not
  expressible in this seam under any shape, and not needed.

The seam is a second return path alongside rows, on every statement — the
mechanism §6's argument explicitly did not carry. It was built on the
maintainer's go (2026-08-16) with the second-customer question still open:
Transact-SQL `print` and `set statistics io on` run on the same channel, and
PostgreSQL `NOTICE`/`RAISE` is a plausible third, but none of them is a
verified customer yet. The seam is generic — it is a hook on the statement
path, not an ASE-named special case — so a second customer is a driver
override, not another core change.

**So, plainly: `$rs->explain` works on Sybase ASE now, through the seam.** The
driver overrides `_execute_sth` to collect the messages and `_explain_query`
to issue the five statements and wrap them. A driver reading this ADR for its
own engine should take the ASE row as the worked example of the **fifth**
possible outcome, next to "the base fits", "override it", "core widens the
seam" and "the seam does not reach this engine": *the engine answers on the
connection, and the seam collects it*.

**None of the above was measured.** No ASE server was run — none is available
to this family. The spelling and the `noexec` requirement are SAP's
documentation; the message channel is `DBD::Sybase`'s POD, read from the
installed 1.26. The XML variants (ASE 15+ `set plan for show_exec_xml` /
`show_final_plan_xml`, `showplan_in_xml()`) were **not** checked: if one of them
returns a genuine rowset, the driver may not need the message seam at all —
but the seam is what makes the fallback expressible, and that is the first
thing to test on the day a server exists.

## Alternatives considered

- **A capability plus a refusal** — `supports_explain`, defaulting to 0, with
  the five engines that cannot use the prefix form throwing instead. Rejected.
  It withholds a feature from five engines that **have** query plans and, for
  four of them, merely obtain them differently; Oracle, SQL Server, Sybase, DB2
  and Firebird can all produce a plan, none of them with a bare `EXPLAIN`.
  (Sybase ASE is the one where a refusal would in fact be the right answer —
  §7, added later, records why its plan cannot travel through this seam. That
  is a per-driver refusal on a known engine fact, not the blanket capability
  rejected here.) That is exactly the trade
  **ADR 0039 §3** declines in its fourth bullet — a gate that turns a real
  defect on some engines into an outage on the rest — and the k135 rollout
  showed twice, independently, that refusing is the wrong answer where the
  capability actually exists: **`dbio-duckdb`** (ADR 0039 §7 shape 3: refusing
  would withhold two operations from the entire 1.x line to protect users of a
  pre-1.0 beta — document it, don't gate it) and **`dbio-db2`** (shape 4: the
  gap is bounded by *platform*, and the platform in question is one the dist
  cannot run on at all). A capability would also have to encode nothing but
  availability while the real per-engine difference is *shape*, which a boolean
  cannot carry — the mechanical point ADR 0039 §3 makes about
  `get_dbms_capability` coercing every answer to 1/0.

- **A two-tier model: keep `_explain_sql` for the engines it fits and add a
  second seam for the rest.** Rejected. Two declaration sites for one concept,
  which is the same "second parallel mechanism" shape ADR 0039's Alternatives
  rejected for `_unsupported_set_operations`: a driver would have two places to
  edit for one engine fact, and the two drift. It is also the worse half of the
  trade — the drivers that fit the string form are precisely the ones for whom
  overriding a method instead costs a three-line body, while the drivers that
  do not fit it would carry the entire burden of the split. And core would have
  to decide, per call, which tier a given driver is on: a dispatch on the
  presence of an override, i.e. the ADR 0021 name-match anti-pattern wearing a
  different hat.

- **Move `explain` to the native escape hatch (ADR 0017)** — drop the portable
  `$rs->explain` and let each driver expose `pg_explain`, `oracle_explain_plan`
  and so on. **This is defensible and is recorded as such**, not dismissed:
  the return value is engine-specific already (§2), `DBIO::ResultSet::explain`
  has no `=method` POD of its own, and ADR 0017 is the blessed home for
  features that are non-portable by nature. It was rejected for two reasons,
  in this order. First, it is a **breaking change to a feature DBIO promises**:
  `explain` is named in `DBIO::Manual::Features` and in
  `DBIO::Manual::Heritage`, the latter specifically as one of the two
  divergences worth knowing about the folded-in helpers. Second, the five
  engines where it works **today** would lose the portable call in exchange for
  a problem they do not have. If the plan *contents* ever need normalising,
  that is a different design and a different ADR; obtaining the plan is not the
  part that argues for the escape hatch.

- **Keep the string and let the four engines report unsupported** — rejected;
  this is the status quo k112 shipped with the explicit note that it might
  not survive contact, and four of ten drivers reported that it did not.

- **A named exception in §3 for Firebird instead of the seam in §6** —
  rejected, and it was the cheaper option. It would have let one driver reach
  for `$dbh`, which is not a stylistic concession: what that driver loses is
  `redact_bind_value` on the *user's own* bind values (ADR 0025), plus the
  three other regressions k112 removed. It is also unenforceable — core
  cannot see inside a driver's method (§3) — and self-undermining, because a
  rule with an engine-named hole teaches the next driver that meets an
  unanticipated shape to cut its own hole rather than report. The seam costs a
  dozen lines and reuses `_prepare_sth` and `_bind_sth_params` verbatim. The
  honest weakness of taking it is that the customer count is one: see §6 for
  why that was judged enough.

## Consequences

- **`_explain_sql` is gone**, replaced by `_explain_query` in the same slot on
  the `_determine_driver` list in `DBIO::Storage::DBI`, and moved from
  `@writer_methods` to `@reader_methods` in `DBIO::Replicated::Storage` (§4).
  `DBIO::Replicated::Balancer` gains `_explain_query`.
- **The migration is not silently safe**, and the driver tickets must say so:
  an unported `_explain_sql` override is simply never called again. There is no
  error — the driver's engine gets the base `EXPLAIN` prefix, which on Oracle
  is an ORA-00900 and on SQLite is VM bytecode presented as a query plan. The
  two repos that override it today (`dbio-mysql`, `dbio-postgresql`) are
  unreleased, which is the mitigation.
- **No behaviour change for the five engines the old shape fitted.** Same
  statement, same seam, same rows.
- **`DBIO::ResultSet::explain` no longer knows what an `EXPLAIN` is.** It
  strips `as_query`'s parens and delegates. The strip stays in core because it
  is a fact about `as_query`.
- **The route-through-`_execute_rendered` rule is now part of the contract**
  and is stated as a requirement in the `=method` POD, with its four named
  consequences. Core enforces it where it can — at the mock — and says plainly
  where it cannot (§3).
- **Core's own suite**: `t/helpers/explain.t` grows the two-statement driver
  shape, the redaction observable and the bypass control;
  `t/test/24_driver_spelling_hooks.t` moves its `_explain_sql` half to the new
  name and keeps its `_random_function` half untouched;
  `t/test/08_replicated.t` replaces the writer-delegation assertion with the
  reader pin plus its `execute_reliably` counterpart. Mock storage only, per
  house rules.
- **No contract-version bump.** `DBIO::Storage::DBI` carries no
  `$CONTRACT_VERSION` (ADR 0024 puts it on `Introspect::Base`, `Diff::Base`,
  `Deploy::Base`, `SQLMaker` and `Storage::DBI::Capabilities`), and none of
  those five change shape here.
- **`_random_function` is untouched** — same name, same shape, same lists,
  same rollout. The two hooks stop being a pair.
- **`DBIO::Storage::DBI` gains `_prepare_rendered` and `_dbh_prepare`** (§6),
  the statement path stopped one verb short. `_prepare_rendered` joins
  `@reader_methods` in `DBIO::Replicated::Storage` beside `_execute_rendered`,
  and `DBIO::Replicated::Balancer` gains the matching forwarder — the k138
  trap, which is fatal on the read handler when missed. It is deliberately
  **not** on the `_determine_driver` list: that list carries spellings, not
  paths.
- **`DBIO::Test::Storage` captures a prepare** the way it captures an execute,
  marked `op => 'prepare'` in `captured_queries`. On a storage that never
  executes anything that mark is the only observable distinguishing the two
  seams, and it is what lets a driver assert offline that its `_explain_query`
  went through the storage.
- **The routing rule reads "the storage's statement path", not
  "`_execute_rendered`"** (§3), and still has no engine-named exceptions.
  Drivers already retargeted against the earlier wording lose nothing: the
  wording widened, the requirement did not.
- **`$rs->explain` has one engine that answers on the connection: Sybase ASE**
  (§7). The plan arrives as server messages rather than rows, and the seam that
  collects them is now built — `_execute_sth` wraps the execute verb of
  `_dbh_execute`, core stores the collected messages on `_server_messages`,
  and the driver reads them back and wraps them as a rowset. The reasoning is
  in §7; the standing request was k140.
- **The engine claims in this ADR carry their evidence** (the table's fourth
  column). Core measured none of them; three rows were wrong as first written
  and were corrected by the drivers that built on them (DB2's `PLAN SELECTION`,
  Firebird's `func('ib_plan')` — k141 — and ASE's whole row — k140).
  A row without a driver behind it is a reading, and is labelled as one.

## Future architecture work (tracked cross-repo, not here)

Core ships first, and the window is not zero: the old hook is removed, so an
unported driver loses its override **silently** (see Consequences).

The ten k112 handoff tickets already open in the driver repos each cover
both hooks. Their `_random_function` half is unaffected and continues as
written; their `explain` half needs retargeting from `_explain_sql` to
`_explain_query($sql, \@bind) -> \@rows`, and for the engines in the table it
stops being "spell the prefix" and becomes "implement the operation, routing
every statement through `_execute_rendered`". Retargeting those ten tickets is
the maintainer's own work under k138, not core's.

The shapes this ADR names are core's best current reading, not core's
verification — that is what the table's Evidence column says row by row, and it
has already paid for itself: three of those rows were corrected by the driver
that built on them (`dbio-db2`'s `PLAN SELECTION`, `dbio-firebird`'s
`func('ib_plan')`, and the whole Sybase ASE row, §7). Each driver confirms its
own engine against that vendor's documentation and a live server, per the
family's live-test discipline, and reports back — including reporting that
`($sql, \@bind) -> \@rows` still does not fit, if that is what it finds. That
last case has now happened once, and §7 is what it looks like when the answer
is "the plan is not a rowset at all" — and, since 2026-08-16, what the seam
that crosses it looks like too.

`dbio-firebird` was named here as the one to watch — the only engine with **no
statement at all** to route — and it reported before the retargeting ran. That
is §6, and core's half of the item is closed: `dbio-firebird` can implement
`_explain_query` over `_prepare_rendered` in the shape §6 spells out, without
an exception. **It has** — dbio-firebird k17, offline and green, and the report it
sent back is the `func('ib_plan')` correction now folded into §6. The driver's
own half is still not closed: what remains is confirming that `ib_plan`
answers on a **live** handle after a bare prepare, which is a SKIP block in
`dbio-firebird` `t/58-explain-query.t` waiting for a server — like every other
driver confirms its engine, DB2 included, whose shape is settled as Oracle's on
the evidence in §6 but not yet against a server.

`dbio-informix` is excluded: abandoned, unbuildable, never in a sweep.

Relates to ADR 0011 (the hooks replaced `DBIx::Introspector`), ADR 0017 (the
escape hatch this decision declines to use), ADR 0025 (`redact_bind_value`, the
concrete thing the routing rule protects), ADR 0037 and ADR 0039 (the same
declaration-site pattern, and the capability trade this decision reuses),
k112 (which routed `explain` through `_execute_rendered` and asked for this
ticket), k138, k139 (§6, the prepare-only seam Firebird reported the
need for).
