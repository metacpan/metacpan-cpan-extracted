# ADR 0060 — One shared case table for install DDL, Diff and Bind: a case is stated once in core and answered by every driver

- Status: accepted
- Date: 2026-10-08 (accepted 2026-10-09)
- Tags: testing, drivers, deploy, diff, ddl, bind, cross-driver, family-policy, live-testing, relates-0006, relates-0007, relates-0019, relates-0026

> **Accepted (karr k330).** The maintainer answered the ten questions of the
> draft on 2026-10-09; the answers are worked into the text below and are the
> rule. What neither the draft nor the answers settle stays under
> [Open](#open). The pilot is built in two steps (see
> [Pilot](#pilot)): the runner and the DDL list in core first, then
> dbio-sqlite, then dbio-postgresql.

## Context

The ticket sweep of 2026-10-07/08 closed 35 cards and produced 88 new ones.
162 of the family's 268 open cards fall into three themes — Diff/Deploy/DDL
(67), Async/Pool (56), Bind/types/quoting (39) — and in the first and the
third the cards of different drivers ask the same question, each found
separately in each driver (karr k330 lists the groups).

The code shows why. The faults are not similar, they are the same lines:

- **String DEFAULT.** `install_ddl` in `lib/DBIO/SQLite/DDL.pm` and
  `install_ddl` in `lib/DBIO/PostgreSQL/DDL.pm` both end their default
  rendering in the literal branch `" DEFAULT '$dv'"`. One apostrophe in the
  value breaks the statement (karr dbio-sqlite k57, dbio-postgresql k117,
  dbio-mysql k78, dbio-firebird k47, dbio-oracle k47).
- **Identifier quoting.** Both use `_quote_ident` from
  `lib/DBIO/SQL/Util.pm`, which quotes *on shape*: a name matching
  `/^[a-z_][a-z0-9_]*$/i` is returned bare. A reserved word has that shape.
  `lib/DBIO/PostgreSQL/DDL.pm` says so itself above `_quote_pg_ident` ("a
  separate concern whose family-wide home is `DBIO::SQL::Util::_quote_ident`")
  and patches two index sites only (karr dbio-postgresql k115, k110;
  dbio-mysql k77 and dbio-firebird k32 fixed it, each inside its own driver).
- **Views.** `DBIO::PostgreSQL::Diff::Table::diff` walks the table map and
  emits `create` / `drop` without looking at `kind`; a view is a table to it
  (karr dbio-postgresql k100; the same card exists as dbio-sqlite k67,
  dbio-mysql k79, dbio-mssql k45, dbio-firebird k33, dbio-clickhouse k31).

Measured for this ADR on 2026-10-08, DBD::SQLite in memory, one result class
with table `order`, a column `group`, a `char(5)` default `'007'` and a
`varchar` default `it's`: `DBIO::SQLite::DDL->install_ddl` returns

```
CREATE TABLE order (
  id INTEGER NOT NULL,
  group VARCHAR(10),
  code CHAR(5) NOT NULL DEFAULT 007,
  note VARCHAR(20) NOT NULL DEFAULT 'it's',
  PRIMARY KEY (id)
);
```

Three faults in one statement. Only the apostrophe has a card on that board.
The reserved word is carded in four other drivers and not in dbio-sqlite. The
digit default is carded in dbio-db2 only (k46) — and on SQLite it is not even
invalid SQL: with the reserved word quoted, the table is created and an insert
reads `code` back as `'7'`. That is the worst class, silently wrong, and no
per-driver review found it.

What the family has today against this is **copies**. `introspect-contract.t`
exists in eleven dists and `roundtrip-base-types.t` in three (dbio-sqlite
`t/36`, dbio-postgresql `t/28`, dbio-mysql `t/53`), each a hand-kept copy.
The roundtrip copies also do not test what their name says: they write the
`CREATE TABLE` by hand and never call `install_ddl`, so no fault of the DDL
generator can turn them red.

What the family has that works is the pattern of `DBIO::Test::AsyncHarness`:
the logic lives once in core, the driver ships a small subclass that declares
what is its own (`_harness_declaration`), and an extension reuses the
driver's subclass (`DBIO::PostgreSQL::EV::TestHarness` and its MySQL counterpart; the AGE dist
reuses the PostgreSQL one). The maintainer asked for the same for DDL, Diff and Bind: a
finding is stated once as a case and run live by every driver.

## Decision

Core carries one case table and one runner. A driver answers every case, and
there are exactly two acceptable answers.

### 1. What a case is

A case is data: a name, an input and an expectation that is checked against
the server. It never contains SQL the driver is expected to emit, and never
the name of a driver.

| Field | Meaning |
|---|---|
| `name` | Stable kebab-case id, prefixed by its area: `ddl-default-string-apostrophe`. A card cites it; a driver's answer is keyed by it. |
| `since` | The table version that introduced it (see §6). |
| `input` | Area-specific, in DBIO's own terms (below). |
| `expect` | Observable properties (below). |
| `cards` | The karr cards the case was distilled from. Documentation, not logic. |

**Input** is what an application would write:

- **DDL** — one schema declaration: result sources with `table`,
  `add_columns` in the base types of `DBIO::Schema::Type` (and `varchar`
  with a `size` for a bounded string, which every driver writes; `text` is a
  LOB on some servers, karr k366),
  `set_primary_key`, `add_unique_constraint`, relationships, indexes, and
  views as `DBIO::ResultSource::View` with a `view_definition`.
- **Diff** — two declarations, `from` and `to`, and optionally rows that are
  in the tables when the upgrade runs. A table that holds rows is a different
  case from an empty one (karr dbio-sqlite k65, dbio-clickhouse k32).
- **Bind** — one column declaration, a value, and the operations it goes
  through (`create`, `find` by that value, `update`, `populate`).

**Expectation** is stated as something the server shows, in one of three
forms, so that a driver is free in *how* it gets there:

- a **fact read back through the driver's Introspect** — the object is a
  view, the column has size 10, the unique constraint exists;
- a **behaviour** — an insert that leaves the column out reads `it's` back,
  a second row with the same key is rejected, a row is found by `'01234'`;
- a **value identity** — what is read is `eq` to what was written, compared
  as bytes.

A case never says "the DDL contains `''`". The provisional line of the
sessions working on these faults today — a string DEFAULT is a SQL literal
with the apostrophe doubled — is adopted and sharpened to exactly this: the
*expectation* is the value the server hands back; doubling the apostrophe is
the obvious way to meet it and stays each driver's own code.

Two **postconditions** hold for every DDL and Diff case without being
written into it, wherever the driver has a Diff:

1. *Install, then diff against the same declaration, is empty.* This alone
   covers the phantom-change cards (karr dbio-mysql k82, k83, dbio-firebird
   k38) and replaces the three `roundtrip-base-types.t` copies with a test
   that really goes through `install_ddl`.
2. *Upgrade, then diff, is empty* — and never "no changes" while the facts
   of the case are not there (karr dbio-sqlite k72, dbio-clickhouse k31).

### 2. Where it lives and how a driver runs it

- `DBIO::Test::Conformance::Cases::DDL`, `::Diff`, `::Bind` — the three
  lists, as Perl data. Perl and not YAML/JSON because inputs carry scalar
  refs (`\'CURRENT_TIMESTAMP'`) and binary values.
- `DBIO::Test::Conformance` — the runner. It builds the result classes of a
  case in a package of its own, calls the driver through the same public
  entry points an application uses (`$schema->deploy`,
  `DBIO::Deploy::Base::install` / `diff` / `upgrade`, the ResultSet API),
  checks the expectation, and removes what it created.
- In a driver: one subclass, `DBIO::<Driver>::Test::Conformance`, in `lib/`
  like `DBIO::PostgreSQL::EV::TestHarness`, so that an extension can reuse
  it. It declares the connection gate (the driver's `DBIO_TEST_*`
  variables), how to get an empty namespace for a case (§4), and the
  driver's answers (§3). And three test files of a few lines each:

  ```perl
  use DBIO::PostgreSQL::Test::Conformance;
  DBIO::PostgreSQL::Test::Conformance->run('DDL');
  ```

- An extension dist runs the driver's lists against its own composed
  storage and appends cases of its own — a list in the extension's `t/lib`
  handed to the same runner. The PostGIS and AGE findings (appendix D) are
  that kind of case: the runner is shared, the case is not.

### 3. The two answers

For every case a driver gives one of two answers, and there is no third:

- **correct** — the default; it needs no declaration. The case runs and its
  expectation holds on the server.
- **refuses** — the driver throws, and the exception names the object
  (table, and the column where the case has one) and the reason.

Silently wrong, silently doing nothing, and SQL the server rejects are never
an answer, and neither is a *declared deviation*: a driver whose server or
whose own design produces a result other than the case's expectation does not
get to write that result down and have it asserted. It **changes** so that the
result is the expected one, or it **refuses**. (Oracle's `''` that becomes
NULL, dbio-duckdb's install DDL without foreign keys, dbio-sqlite's plain
integer primary key without AUTOINCREMENT are such cases; each driver decides
per case which of the two it takes, and a standing driver ADR that records the
deviation is then revisited on that driver's board, not worked around in the
table.) A server error that reaches the caller unchanged is not a refusal
either: a refusal is the driver's decision, taken before it emits anything it
knows will fail — which is what `DBIO::Oracle::Deploy::_refusal` does today
for the whole Diff area.

**The form of a refusal is a message convention, not an exception class.** A
refusal is a DBIO exception, thrown through the schema's `throw_exception`,
that

1. is **not** a `DBIO::Exception::Server` and not a driver error passed on
   (those are the server's word, not the driver's decision),
2. contains the stem `refus` (`refuses`, `refused`, `refusal`; compared
   without regard to case),
3. names the table, and the column where the case has one, by the names the
   declaration gave them,
4. and matches the `reason` the driver declared for the case.

The runner checks exactly these four and nothing else about the text. A
dedicated class stays a possible later step; nothing in the table depends on
one.

A refusal is **declared** in the driver's subclass, and the declaration says
which of two kinds it is:

```perl
sub conformance_refusals {{
  'ddl-enum-value-apostrophe' => {
    kind   => 'server',                 # this engine cannot do it
    reason => qr/enum columns/,
  },
  'ddl-foreign-key' => {
    kind   => 'pending',                # not built yet
    card   => 'k34',                    # required for pending
    reason => qr/foreign keys are not emitted yet/,
  },
}}
```

- `server` — the engine cannot do it. Permanent; needs no card.
- `pending` — the driver does not do it yet. It **must** name a card of the
  driver's own board. That is the line between "not built" and "does not
  exist on this server", and it makes the backlog of a driver readable from
  its declaration.

The runner treats a declared refusal as a test, not as a skip:

- it runs the case and requires the exception — a DBIO exception that meets
  the four points above;
- a declared refusal that **succeeds** is a failure ("stale refusal"), so a
  declaration cannot outlive its reason;
- an undeclared case must be correct. There is no `skip` per case.

**A `pending` refusal passes.** It is a green test, and the runner closes the
run with one summary line naming them and their cards ("7 pending refusals:
`ddl-foreign-key` (karr k34), …"). There is no TODO and no release gate on
pending work.

A driver without a Diff declares the area once
(`conformance_refused_areas`, with the same `kind` / `card` / `reason`). The
runner then probes `diff` and `upgrade` once, requires the refusal, and
lists every Diff case as refused. For dbio-oracle that is `pending` with
karr dbio-oracle k36 and k37 — the table changes nothing for it today and
turns every Diff case red on the day the declaration is removed.

The runner does this for every list but DDL: a case of a refused area (`Diff`,
`Bind`) is driven and counts as a declared refusal of the area's kind, card and
reason, unless it has one of its own. The driver's seam has to throw a refusal
that meets the convention above, the result is `refused` or `pending`, and a
case of the area that runs through is a stale refusal. The DDL postcondition
"install, then diff, is empty" is the one place the Diff area still shows in
the DDL list.

### 4. Offline and live

- **Live** — against a server, every expectation is checked. This is the
  mode the table exists for. It follows the live-testing rules unchanged:
  one run per database, no parallel harness, `maint/live-preflight`, every
  run through `maint/capped-test`. Each case works in a namespace of its own
  that the driver's subclass provides (`conformance_namespace`: a schema on
  PostgreSQL, a database on MySQL, a table-name prefix where the engine has
  nothing else) — necessary, because `DBIO::Deploy::Base::diff` compares the
  *whole* visible database against the declaration, and anything another
  case or another test file left behind would come back as a `DROP`.
  `conformance_namespace` returns the mark of that namespace and
  `conformance_cleanup` removes only what the mark identifies. The runner
  calls cleanup only after `conformance_namespace` returned; when the
  namespace is refused, nothing is removed and the runner closes the
  connection itself.
- **Identifiers in SQL of a case.** The definition of a view is SQL of the user
  and the driver does not rewrite it. A case writes its identifiers as
  `{{name}}`; after the connect the runner replaces each by the name quoted
  through the seam `conformance_quote_ident($schema, $name)`, whose default is
  the quoting rule of the connected storage's SQL maker (`quote_char`; none,
  no quoting). A driver overrides the seam when its server needs another form.
- **Offline** — no server. The runner checks only what generated SQL can
  show without one: (a) the answer table is complete and well-formed (every
  declared refusal names a known case, every `pending` a card), (b) for a
  DDL case, `install_ddl` returns statements or throws the declared refusal,
  (c) refusals that are decided before a handle is asked for (the Oracle
  kind) are thrown. It does **not** compare SQL text; golden-SQL tests stay
  in the driver, where the dialect is known. Bind cases and the server half
  of Diff cases do not run offline, and the runner says how many did not.
- **SQLite and DuckDB** have no offline: an in-memory database is a server.
  There every case runs live in every plain `prove`.

- **A Diff case** runs install, rows, upgrade, expectation, second diff, in
  that order, through the seams. The runner installs `from` and loads
  `rows` through `conformance_create`. It then hands the driver the
  unconnected schema class of `to` — `conformance_upgrade($schema, $to_class,
  $case)`, which connects it to the same database (an in-memory SQLite shares
  its handle), upgrades through the driver's public entry point and returns
  the connected `to` schema. Expectations (`rows_kept` for the rows that had
  to survive, besides the DDL kinds) and the second postcondition are asked
  of that schema; cleanup is given that schema, and the `from` schema is
  closed last.
- **A Bind case** names a column, values and operations (`create`, `find`,
  `search`, `update`, `populate`), and every operation is a call of a data
  seam — `conformance_create`, `_find`, `_count`, `_update`, `_populate`,
  `_delete` — with a default over the ResultSet API. Nothing else of the
  database is touched, and no fact and no diff is asked. An async transport
  runs the list by overriding `conformance_connect` and these seams, waiting
  for the Future inside them (decision 7); the runner is the same.

Offline is deliberately weak. It keeps the declarations honest and catches
a generator that dies; that a statement is *valid* only a server can say,
and the measured SQLite case above is the proof — `DEFAULT 007` is valid SQL.

### 5. How the areas are cut

Three lists, by what goes in:

| Area | Input | Entry point under test | Measured by |
|---|---|---|---|
| DDL | one declaration | `install_ddl` via `install` / `deploy` | Introspect, behaviour |
| Diff | two declarations, rows | `diff` / `upgrade` | Introspect, behaviour, second diff |
| Bind | column, value | ResultSet / Row API | value identity |

- **Introspect is not a fourth area.** It is the measuring instrument of the
  first two. A case that is really about Introspect (karr dbio-mysql k83) is
  a DDL case whose postcondition 1 fails. The cost: a red DDL case does not
  say which of the two is wrong. Accepted — the alternative is a fourth
  list whose inputs would be hand-written SQL per driver, which is what the
  table is meant to end.
- **Async/Pool is out.** Its 56 cards are about ownership, ordering and
  timing of connections, not about what a declaration or a value turns into;
  `DBIO::Test::AsyncHarness` and the seam tests are built for that, and a
  case there is not data. One bridge is decided: the async transport
  dists (dbio-postgresql-ev, dbio-mysql-ev) run the **Bind** list over their
  transport, because the transport has a bind path of its own (karr
  dbio-postgresql-ev k84: `_transform_sql` rewrites `?` where the sync path
  does not). It follows the Bind list, which comes after the pilot.

### 6. A new case and a released driver

A case added in core turns red in every driver that is neither correct nor
declares a refusal. On the development machine that is the point. On a
user's machine it must not happen: a driver released against core N would
fail its install-time tests under core N+1.

The table has a version (`DBIO::Test::Conformance->table_version`); every
case carries `since`; a driver's subclass declares
`conformance_answered_through` — the table version its answers were written
against (0 when it declares none; per area, see the addendum of 2026-10-25).
Cases newer than that are run and
reported, but **are red only locally**: they fail the suite under
`AUTHOR_TESTING` / `RELEASE_TESTING` and run as `TODO` otherwise. Raising the
number is a deliberate act in the driver, done when its answers are complete,
and `dbio-release-manager`'s pre-release audit can require that it equals
core's table version.

### 7. The provisional line, as cases

The four rules the fixing sessions work under today are adopted; each is a
case or a rule above, and three are sharpened:

| Provisional line | In this ADR |
|---|---|
| String DEFAULT as SQL literal with doubled apostrophe | `ddl-default-string-apostrophe`; expectation is the value read back (§1). Sharpened by `ddl-default-digit-string`: a string default on a character column stays a string even when it looks like a number — today's numeric shortcut decides on the value alone, without the column type. |
| A declared view is created and removed as a view, never as a table | `ddl-view-declared`, `diff-view-added`, `diff-view-dropped`, `diff-view-definition-changed`. Model: karr dbio-sqlite k56. Unchanged. |
| Every identifier in DDL quoted by the server's rule | `ddl-ident-reserved-word`, `ddl-ident-mixed-case`, `ddl-ident-special-chars`, `diff-ident-drop`. Sharpened: the rule is tested by what it must achieve (the object is created and its name reads back exactly), and it applies to the Diff and to the `add_drop_table` prelude as much as to `install_ddl`. **The rule is a reserved-word list per driver** (the `_quote_pg_ident` pattern, extended by each driver for its own engine); a name that is neither reserved nor special is left as declared, and a mixed-case name is preserved exactly. There is no central always-quote. |
| What the Diff cannot do safely it refuses loudly, with table and reason | §3. Sharpened: the refusal follows the message convention, is declared, has a kind, and is itself tested. |

## Rationale

- **One statement of a fault.** A fault found in one driver becomes a case,
  and the next `prove` in every other driver says whether it has it. Today
  that takes one review session per driver and still misses (the SQLite
  measurement above).
- **Expectations on the server, not on the SQL.** A shared table of expected
  SQL would be eleven dialects of golden strings in core. A shared table of
  observable results is one row per fault, and it cannot be satisfied by
  SQL that merely looks right.
- **A refusal that is tested is not a skip.** A skipped case says nothing
  and is forgotten. A declared refusal is run, must throw, must name its
  object, and fails the day it is no longer true.
- **It follows a pattern that already carries weight.** Runner in core,
  declaration in the driver, reuse by the extension — `AsyncHarness` works
  this way for two transport dists and an extension on top of one of them.

### Alternatives considered

| Alternative | For | Against |
|---|---|---|
| **A. Keep per-driver tests, add a checklist document** (the list in appendix as prose) | No code, no coupling between core and driver releases. | It is what exists: eleven copies of `introspect-contract.t`. A checklist is not run. |
| **B. Golden SQL per driver in the shared table** (case = input + expected SQL per dialect) | Fully offline; fast. | Core would hold every dialect; valid-looking SQL passes (`DEFAULT 007`); a driver cannot change how it reaches a result. |
| **C. The table in a dist of its own** (`DBIO-Test-Conformance`) | Cases can be released without a core release; no core/driver version question. | One more dist to release and pin in eleven `cpanfile`s; the runner needs `DBIO::Test` internals anyway. |
| **D. A third answer: skip, or a declared deviation** | Easiest adoption; a driver can start with everything skipped; a server-defined result can be written down. | Skip is "silently nothing" at the level of the table; a declared deviation makes a result that is wrong by the table a tested answer. The maintainer excluded both (2026-10-09). `pending` gives the same on-ramp and stays visible. |
| **E. Chosen** — data and runner under `DBIO::Test`, two answers, declared refusals | See Rationale. | New case in core touches every driver (§6 bounds it); live runs get longer; a red DDL case may be an Introspect fault. |

## Consequences

- Core gains `DBIO::Test::Conformance` and three case lists; each driver
  gains one declaration module and three short test files. No driver
  behaviour changes by adopting the runner — the cases it turns red are the
  cards that already exist, plus the ones nobody has filed.
- `roundtrip-base-types.t` (three dists) is superseded by
  `ddl-base-types-roundtrip`. `introspect-contract.t` (eleven dists) stays: it
  pins the model shape against a fixture and needs no server.
- A driver's open work in these two themes becomes readable from one place:
  its `pending` refusals, each with its card.
- A new finding is filed as a case first. Whether the per-driver cards are
  then still written, or the red case in each driver *is* the ticket, is a
  board convention to settle when the pilot runs.
- Live runs grow. Diff cases on engines that build the target model in a
  temporary database (`DBIO::Deploy::Base::TempDatabase`, used by eight
  dists, PostgreSQL and MySQL among them) create and drop one per case; karr dbio-sybase k69 shows that this
  is not free. The runner may have to batch cases that do not interfere.
- The two-answer rule has teeth: a driver whose server or design yields
  another result than a case expects (`bind-empty-string` on Oracle,
  `ddl-foreign-key` on dbio-duckdb) changes or refuses; it cannot record the
  deviation. For dbio-duckdb that reopens ADR 0001's omission of foreign keys
  on its own board; for Oracle's `''` the refusal or the change is the
  driver's call. Neither is decided here.
- A reserved-word list lives in each driver and has to be kept as complete
  as the engine's own (`ddl-ident-reserved-word` finds a word that is
  missing; it is no proof that the list is complete).

## Pilot

**Decided: the DDL area in two steps, built on dbio-sqlite, accepted on
dbio-postgresql.** Core delivers the runner and the DDL list
(`DBIO::Test::Conformance`, `DBIO::Test::Conformance::Cases::DDL`) with a test
that runs the runner against a mock and shows every kind of answer. Then:

1. **dbio-sqlite** builds `DBIO::SQLite::Test::Conformance` on it: no server,
   no gate, the whole loop in a plain `prove`. Two faults there have no card
   yet (reserved word, digit default), so the pilot shows on day one what the
   table is for.
2. **dbio-postgresql** accepts it: the live half, namespaces, extensions. Its
   three open install cards are exactly DDL cases (karr dbio-postgresql k115,
   k116, k117), and the three extension dists run against the same pod and
   prove the reuse.

A runner fitted to SQLite alone would carry SQLite's assumptions (no
schemas, no gate, type affinity instead of types); the table is not called
stable before the second, server-backed driver has answered it.

The Diff and Bind lists follow the pilot; they are not part of it.

## Coverage estimate

Counted on 2026-10-08 from the open cards of the thirteen SQL boards
(dbio-graphql and dbio-informix left out), by title and, where the title was
not enough, by body. An estimate: a card counts as covered when one of the
cases below, run in that driver, would have been red for it.

| Board | Open | Shared cases | Driver-local cases | Cards |
|---|---|---|---|---|
| dbio-sqlite | 17 | 10 | 2 | k57 k61 k62 k65 k67 k68 k69 k70 k72 k74 · local k71 k73 |
| dbio-postgresql | 19 | 6 | 4 | k100 k101 k110 k115 k116 k117 · local k106 k107 k108 k109 |
| dbio-postgresql-ev | 14 | 1 | – | k84 |
| dbio-postgresql-postgis | 10 | – | 3 | local k12 k22 k23 |
| dbio-postgresql-age | 5 | – | 1 | local k14 |
| dbio-mysql | 22 | 13 | 1 | k78 k79 k80 k81 k82 k83 k84 k88 k89 k92 k93 k94 k95 · local k75 |
| dbio-oracle | 11 | 5 | – | k37 k41 k42 k46 k47 |
| dbio-firebird | 14 | 6 | – | k33 k34 k36 k38 k46 k47 |
| dbio-mssql | 20 | 9 | – | k45 k47 k49 k55 k58 k59 k60 k61 k63 |
| dbio-db2 | 6 | 4 | – | k39 k45 k46 k47 |
| dbio-sybase | 20 | 7 | – | k52 k70 k80 k81 k82 k83 k84 |
| dbio-clickhouse | 5 | 2 | – | k31 k32 |
| dbio-duckdb | 5 | 0 | – | – |
| **Sum** | **168** | **63** | **11** | |

So the shared table covers about **63 of 168** open driver cards (38 %),
**74** with driver-local cases on the same runner (44 %). Against the
figures of karr k330 — 106 open cards in the two themes Diff/Deploy/DDL and
Bind/types/quoting — that is roughly **60 to 70 %** of those themes. In the
maintainer's focus: **12 of 17** on dbio-sqlite and **10 of 19** on
dbio-postgresql.

What it does not cover, by design: Async/Pool, connect path and DSN,
AccessBroker, DBD defects that need an upstream fix, documentation drift,
`cpanfile`.

The estimate counts cards that exist. The SQLite measurement suggests the
larger effect is the cards that do not: every case below that is carded in
one driver is so far unasked in most of the others.

## Decisions of 2026-10-09

The ten questions of the draft and the maintainer's answers; each is worked
into the text above.

| # | Question | Answer | Where |
|---|---|---|---|
| 1 | A third answer next to correct / refuses? | No. Two answers; a driver with a real deviation changes or throws. | §3 |
| 2 | Form of a refusal | A message convention, no exception class. | §3 |
| 3 | How `pending` shows | Green, with a summary line. | §3 |
| 4 | Version coupling for new cases | `conformance_answered_through`; new cases are red only locally until the driver follows. | §6 |
| 5 | Quoting rule and its home | A reserved-word list per driver (`_quote_pg_ident` pattern, extended per driver); mixed case preserved exactly; no central always-quote. | §7 |
| 6 | A default that leaves the declaration | `upgrade` removes it (karr dbio-mysql k95). | U9 |
| 7 | Async transports and the Bind list | They run it over their transport (dbio-postgresql-ev, dbio-mysql-ev). | §5 |
| 8 | Constraint changes on an existing table | Refusal is the family answer until an apply solution stands. | U13 |
| 9 | Pilot | DDL, two steps: built on dbio-sqlite, accepted on dbio-postgresql. | Pilot |
| 10 | Names | `DBIO::Test::Conformance`, `DBIO::<Driver>::Test::Conformance`. | §2 |

## Addendum 2026-10-16 — a declared deviation (karr k338)

A case has three answers: correct, refuses, deviates. This replaces answer 1
of the decisions of 2026-10-09.

A deviation is declared in `conformance_refusals`, beside the refusals:

```perl
'ddl-type-size-passthrough' => {
  kind   => 'deviation',
  fact   => qr/accepted a row it must reject/,
  reason => 'the engine keeps the declared length but does not enforce it',
},
```

- `fact` is a regex over the failure text of the run: it says what the server
  does, so a different wrong result is not covered by the declaration.
- `reason` is a non-empty string: why the deviation is accepted. A deviation
  without one is rejected by `check_declarations`.
- The runner drives the case. The case must run without throwing and its
  expectation must fail in the declared way; the status is `deviation`, a
  passing test, and the summary line lists the case with its reason.
- A case that runs correctly under a declared deviation fails as a stale
  deviation. An exception is not a deviation. A refused area is never a
  deviation.
- A deviation answers the case: `conformance_answered_through` counts it like
  a correct answer or a refusal.

## Addendum 2026-10-25 — Diff and Bind in the runner (karr k330)

The runner drives the Diff and the Bind list (`DBIO::Test::Conformance::Cases::Diff`
and `::Bind`), with the seams, the upgrade flow and the async path of §4.

- **A table version per area.** `table_version($area)` answers 1 for each list
  (`DDL` without an argument). A case's `since` is a version of its own list.
- **`conformance_answered_through`** is a scalar, which counts for DDL only
  (every other area is 0), or a hash `{ DDL => 1, Diff => 1, Bind => 1 }` with a
  version per area; an area the hash leaves out is 0. `check_declarations`
  checks both forms. A driver whose version of an area is below a case's
  `since` stays green outside `AUTHOR_TESTING` / `RELEASE_TESTING`
  (`todo`).
- **Seams of the Diff list:** `conformance_upgrade($schema, $to_class,
  $case)`, which has no default and throws naming itself until a driver
  provides it. New data seams, each with a default over the ResultSet API:
  `conformance_find($schema, $source, \%cond)`, `conformance_update($schema,
  $source, \%cond, \%set)`, `conformance_populate($schema, $source, \@rows)`.
- **Expectation kinds** added: `rows_kept`, `count`, `bind_roundtrip`,
  `bind_lob_ops`, `bind_literal`. A fact about a source the upgrade dropped
  carries the table the case declared.
- **Refused areas** apply to `Diff` and `Bind` as in §3.
- **A refused area is one entry in the summary line**: area, kind, the card
  (pending) or the reason (server), and the number of its cases. Single cases
  are named only where they carry a refusal of their own.
- **A count seam that answers undef** fails the case (`conformance_count
  returned undef for <source>`); the runner never compares it as a number.
- **Diff cases in the list (19):** U1–U17, U19 and U20, named as in appendix B.
  *Not a case:* U18 (`diff-table-with-generated-column`) needs SQL of the engine
  for the generated column, which a declaration in DBIO's terms cannot
  carry; it is a driver-local case. U13 holds two of its three changes (a unique
  constraint, `on_delete`); a result source has no neutral declaration for a
  check constraint. U5, U6, U13, U15 and U16 are written for the applied
  outcome; a driver that refuses declares it.
- **Bind cases in the list (10):** B1–B10, named as in appendix C. *Not in a
  case:* the dollar-quoted half of B9 (PostgreSQL syntax; a driver-local case),
  the bigint half of B10 (the base types have no 64-bit integer), the float
  without a column in B3 (no declaration carries it). B6 and B7 use the base
  type `blob`; B7 asks no search by value, which LOBs do not offer on most
  engines.

## Addendum 2026-10-25 — D15 as two cases, table version 2 (karr k351)

D15 is two cases with the separate facts they state: `ddl-type-size-char`
(`data_type => 'character', size => 10`; Introspect reads size 10; an
11-character value is rejected or the driver refuses the type) and
`ddl-type-size-bit` (`bit`, size 8; Introspect reads size 8). Both carry
`since => 2`; the table version of the DDL list is 2.

- A case that is replaced is replaced by new cases with a higher `since`
  (answer 4, §6). The name `ddl-type-size-passthrough` is retired: it is not
  a case of the table and a declaration under it is reported by
  `check_declarations` as an unknown case.
- A driver that declared the retired name moves that declaration to the case
  it describes (a length that is kept but not enforced belongs to
  `ddl-type-size-char`) when it raises `conformance_answered_through` to 2.
  Until then both new cases run as `TODO` outside `AUTHOR_TESTING` /
  `RELEASE_TESTING`.
- A refusal names its column exactly: the column's name stands in the text as
  a whole identifier.

## Addendum 2026-10-25 — U13 split, Diff table version 2 (karr k369)

U13 is two cases, one change each. `diff-constraint-changed` states the unique
constraint; `diff-fk-action-changed` states the foreign key action. The
table version of the Diff list is 2; the new case carries `since => 2`.

| # | Case | From → to | Expectation | Cards |
|---|---|---|---|---|
| U13 | `diff-constraint-changed` | unique `child_code` on `code` added, on an existing table | unique added; rows kept; a duplicate is rejected. Refused, naming table and constraint — the family answer until an apply solution stands (decision 8); never "no changes" | sqlite k72, postgresql k101, firebird k34, oracle k37 |
| U13b | `diff-fk-action-changed` | foreign key `parent_id` without action → the same key with `on_delete` CASCADE | applied: deleting the parent deletes the child, rows kept. Refused, naming table and the foreign key column `parent_id` (decision 8) | the same |

- The subject of `diff-constraint-changed` is `Child.code`; the subject of
  `diff-fk-action-changed` is `Child.parent_id`. A refusal names the column of
  its own case exactly (the k351 rule).
- The check constraint of the original U13 stays outside the list, as in the
  addendum of k330.
- The case is replaced by cases with a higher `since` (answer 4, §6): a driver
  that answered the Diff list through 1 runs `diff-fk-action-changed` as
  `TODO` outside `AUTHOR_TESTING` / `RELEASE_TESTING`, until it raises
  `conformance_answered_through` for `Diff` to 2 and declares the outcome of
  the new case: applied, or refused naming table and `parent_id`.

## Addendum 2026-10-26 — U10 replaced, Diff table version 3 (karr k370)

The subject column of a case whose refusal hangs on a column has a
distinctive name, one that is no word of the language a refusal is written in.
U10 is `diff-indexed-column-dropped` (`since => 3`); its subject is
`Wide.drop_idx_col`, the unique key runs over `wide_uq_one` and `wide_uq_two`,
both NOT NULL (the case probes dropping a column under an index, not the NULL
semantics of UNIQUE).
The table version of the Diff list is 3, the list holds 20 cases.

- The name `diff-column-dropped-with-index` is withdrawn: `check_declarations`
  reports a declaration under it as an unknown case.
- A driver that answered the Diff list through 2 runs
  `diff-indexed-column-dropped` as `TODO` outside `AUTHOR_TESTING` /
  `RELEASE_TESTING`, until it raises `conformance_answered_through` for `Diff`
  to 3 and declares the outcome of the case: applied, or refused naming table
  `wide` and column `drop_idx_col`.

## Open

What the draft left open and the answers do not cover; not decided, not built.

- **Namespace per case.** How a driver provides an empty namespace for a case
  (`conformance_namespace`: a schema, a database, a table-name prefix) and
  whether the runner may batch cases that do not interfere. The DDL pilot
  settles it on dbio-postgresql; nothing is fixed before.
- **Where the reserved-word helper lives.** Decision 5 puts the list in each
  driver. Whether the family shares one helper that takes the list (so that
  `_quote_pg_ident` is not copied eleven times) or each driver keeps its own
  code is not answered.
- **A standing driver ADR that contradicts a case.** dbio-duckdb ADR 0001
  (no foreign keys in install DDL) and dbio-sqlite ADR 0004 (no AUTOINCREMENT
  on a plain integer primary key) stand against `ddl-foreign-key` and
  `ddl-auto-increment`. The two-answer rule makes the driver change or refuse;
  which of the two, and the ADR addendum, is each driver's board.
- **The card convention.** Whether per-driver cards are still written for a
  finding once the case exists, or the red case in each driver is the ticket.
- **Live run length.** Diff cases on engines that build the target model in a
  temporary database create and drop one per case; whether that is acceptable
  is measured by the Diff list, after the pilot.
- **A later exception class.** The message convention is the whole rule for
  now; whether applications ever need a class to catch is not asked.

## Appendix — first case list

Each case: input → expectation, then the cards it was distilled from.
*(done)* marks a card already closed whose fix the case would hold in place.
*(measured)* marks a fault found for this ADR that has no card.

### A. DDL — install

| # | Case | Input | Expectation | Cards |
|---|---|---|---|---|
| D1 | `ddl-default-string-apostrophe` | varchar column, `default_value => "it's"` | install runs; insert without the column reads `it's` | sqlite k57, postgresql k117, mysql k78, firebird k47, oracle k47 |
| D2 | `ddl-default-digit-string` | char(5) column, `default_value => '007'` | insert without the column reads `'007'`, not `7` | db2 k46; sqlite *(measured: reads `'7'`)* |
| D3 | `ddl-default-expression` | timestamp column, `default_value => \'CURRENT_TIMESTAMP'` | install runs; the default is evaluated, not stored as the string | mysql k78, sqlite k68, sqlite k56 *(done)* |
| D4 | `ddl-enum-value-apostrophe` | enum column with the value `it's` | install runs; the value can be stored and read (or the driver refuses enums, naming table and column) | postgresql k117 |
| D5 | `ddl-ident-reserved-word` | table `order`, columns `user`, `group`, `end` | install runs; insert and select by those names work | postgresql k115, oracle k42, mysql k88, mysql k77 *(done)*, firebird k32 *(done)*; sqlite *(measured: syntax error)* |
| D6 | `ddl-ident-mixed-case` | table `MixedCase`, column `camelCol` | Introspect reads both names back exactly (mixed case is preserved, decision 5) | postgresql k110, oracle k42 |
| D7 | `ddl-ident-special-chars` | table and column names with a space and with the server's own quote character | install runs; names read back exactly | mysql k77 *(done)* |
| D8 | `ddl-view-declared` | one table, one `DBIO::ResultSource::View` over it; one virtual view | the object is a view; selecting from it works; the virtual view creates nothing | sqlite k67, postgresql k100, sqlite k56 *(done)* |
| D9 | `ddl-unique-constraint` | `add_unique_constraint` over two columns | a second row with the same pair is rejected | db2 k39, firebird k34, oracle k46 |
| D10 | `ddl-foreign-key` | `belongs_to` to a second table | a child row without a parent is rejected | firebird k34, oracle k42 — *DuckDB: changes or refuses (decision 1)* |
| D11 | `ddl-fk-actions` | `belongs_to` with `on_delete => 'CASCADE'` | deleting the parent removes the child | sqlite k66 *(done)* |
| D12 | `ddl-fk-two-rels-one-column` | two `belongs_to` over the same column | install runs; one foreign key | sqlite k74 |
| D13 | `ddl-fk-table-order` | child whose source name sorts before its parent's | install runs | mysql k84 |
| D14 | `ddl-auto-increment` | integer primary key, `is_auto_increment => 1` | `create` without the key returns a row with a key; Introspect reports auto-increment | firebird k46, oracle k41, db2 k45 |
| D15 | `ddl-type-size-passthrough` | `data_type => 'character', size => 10`; `bit`, size 8 | Introspect reads size 10 / 8; an 11-character value is rejected or the driver refuses the type | postgresql k116, sybase k70 |
| D16 | `ddl-base-types-roundtrip` | one table with every base type of `DBIO::Schema::Type` | install runs; postcondition 1 (diff is empty) | sqlite `t/36`, postgresql `t/28`, mysql `t/53` (superseded); firebird k36, sybase k52, db2 k45 |
| D17 | `ddl-index-on-unique-columns` | unique constraint and an explicit index on the same columns; a foreign key column with an explicit index | install runs; no duplicate index | db2 k47, mysql k92 |
| D18 | `ddl-qualified-source-name` | `table('other.t')` | a table `t` in namespace `other`, or a refusal — never a table literally named `other.t` | mysql k89 |
| D19 | `ddl-unique-not-null-without-pk` | table without primary key, NOT NULL column with a unique constraint | postcondition 1: no primary key appears | mysql k83 |

### B. Diff — upgrade

Every case: install `from`, load the rows, upgrade to `to`; postcondition 2.

| # | Case | From → to | Expectation | Cards |
|---|---|---|---|---|
| U1 | `diff-view-added` | – → a declared view | created as a view | sqlite k67, postgresql k100, mysql k79, mssql k45, firebird k33, clickhouse k31 |
| U2 | `diff-view-dropped` | a view → – | removed as a view | the same |
| U3 | `diff-view-definition-changed` | view → same view, other definition | the new definition is live; never "no changes" | sqlite k67 |
| U4 | `diff-table-added-complete` | – → table with single-column primary key, unique constraint, index, foreign key with `ON DELETE CASCADE` | all four are there and behave | oracle k37, mysql k81, mysql k92, sqlite k56 *(done)* |
| U5 | `diff-column-added-not-null-populated` | table with rows → plus a NOT NULL column without default | applied (rows keep their data) or refused naming table and column | sqlite k65 |
| U6 | `diff-column-added-expression-default` | table with rows → plus a column with a non-constant default | applied or refused | sqlite k65 |
| U7 | `diff-default-changed-apostrophe` | default `a` → `it's` | new rows read `it's` | oracle k47, mysql k78, sqlite k68 |
| U8 | `diff-default-expression-kept` | `\'CURRENT_TIMESTAMP'` on both sides | no change reported; the default is still an expression | mysql k78 |
| U9 | `diff-default-removed` | default → none | `upgrade` removes the default (decision 6) | mysql k95 |
| U10 | `diff-indexed-column-dropped` | indexed column (single and as part of a unique key) → gone | upgrade runs | mysql k80 |
| U11 | `diff-fk-dropped` | foreign key → gone | upgrade runs; the key is gone | mysql k94 |
| U12 | `diff-fk-added-to-new-unique` | – → foreign key onto a unique key created in the same upgrade | upgrade runs | mysql k81 |
| U13 | `diff-constraint-changed` | unique added; `on_delete` changed; check changed, on an existing table | refused, naming table and constraint — the family answer until an apply solution stands (decision 8); never "no changes" | sqlite k72, postgresql k101, firebird k34, oracle k37 |
| U14 | `diff-ident-drop` | table `MixedCase` and table `order` → gone | both are dropped | postgresql k110, mysql k88 |
| U15 | `diff-not-null-over-nulls` | nullable column holding NULLs → NOT NULL | refused naming table and column, or the server's error surfaced and the next diff still reports the change | clickhouse k32 |
| U16 | `diff-column-type-change` | `integer` → `varchar(20)` with rows | applied with the data kept, or refused; never reported forever | firebird k38 |
| U17 | `diff-table-with-dependent-view` | table that a view reads → table with one more column | upgrade runs; the view still works | sqlite k69 |
| U18 | `diff-table-with-generated-column` | table with a generated column → one more ordinary column | upgrade runs; the generated column still computes | sqlite k70, postgresql k100 |
| U19 | `diff-auto-increment-kept` | auto-increment key, another attribute of the column changes | `create` without the key still works | mysql k93, db2 k45 |
| U20 | `diff-primary-key-order` | two-column primary key declared `(b, a)` | postcondition 1: order kept | sqlite k68 |

### C. Bind — value roundtrip

Every case: `create` with the value, read the row back, `find`/`search` by
the value, `update` to it.

| # | Case | Column, value | Expectation | Cards |
|---|---|---|---|---|
| B1 | `bind-empty-string` | varchar, `''`; integer column, `''` | reads `''` (not `' '`, not NULL); the integer case is rejected by the server, not turned into broken SQL — *Oracle: changes or refuses (decision 1)* | mssql k55, mssql k63 |
| B2 | `bind-digit-string-leading-zero` | text, `'01234'`, `'007'`; once after a statement that bound an integer | reads back unchanged; the row is found by the string | sqlite k61, sqlite k55 *(done)* |
| B3 | `bind-integer-string-in-expression` | canonical integer string against a text expression; a float without column | compares as the application wrote it | sqlite k62 |
| B4 | `bind-long-string` | 4 001, 8 001, 32 769 and 70 000 characters | byte-identical | mssql k47, mssql k40 *(done)* |
| B5 | `bind-non-ascii` | `Grüße €`, `日本語`, at 1 and at 5 000 characters | identical, or refused naming the column when the server's character set cannot hold it | mssql k49, mssql k58; postgresql `t/85utf8` |
| B6 | `bind-binary` | all 256 byte values; 9 000 bytes | byte-identical | mssql k59, mssql k61, mssql k50 *(done)*, mssql k56 *(done)*; postgresql `t/11` |
| B7 | `bind-lob-empty-and-large` | text and blob column: `''`, 100 000 bytes | identical; the empty value is empty | mssql k60, mssql k61, sybase k72 *(done)* |
| B8 | `bind-lob-row-operations` | table with a LOB column: `create({})`; `update` of the LOB only; `populate` mixing `undef` and values | each works; the caller's hash and the row object hold values, not placeholders | sybase k80, k81, k82, k83, k84, sybase k79 *(done)* |
| B9 | `bind-question-mark-in-literal` | literal SQL holding `?` in a quoted string, a comment and a dollar-quoted body, next to a real bind | the `?` inside stays; the bind lands | postgresql-ev k84 |
| B10 | `bind-numeric-exact` | `numeric(20,4)` `'1234567890123456.7890'`; bigint `9223372036854775807` | identical as strings | (postgis k22 is the extension form) |

### D. Driver-local cases (same runner, the driver's own list)

Not family-wide; listed because the cards exist and the runner should take
them.

- **dbio-postgresql** — a schema an extension created but does not own is
  not diffed as the application's (k106); companion objects of an extension
  member stay out of the model (k107); extensions drop in dependency order
  (k108); `DROP SCHEMA … CASCADE` is not followed by drops of its members
  (k109).
- **dbio-sqlite** — a rebuild leaves `PRAGMA foreign_keys` as it found it
  (k71); a comment-only alter is not sent as a statement (k73).
- **dbio-mysql** — a FULLTEXT index created by upgrade finds rows written
  before it (k75).
- **dbio-postgresql-postgis** — a geometry read from the server is bound
  back byte-identical (k22); a geometry without a writable form is refused,
  not bound as NULL (k23); introspection of a schema-qualified type still
  yields `geometry_type` / `srid` (k12).
- **dbio-postgresql-age** — `$$` inside the Cypher text does not end the
  dollar-quoting (k14).

## Future architecture work (tracked cross-repo, not here)

The core half of the pilot is karr k330 itself. What follows is one adoption
card per driver — dbio-sqlite first, then dbio-postgresql — and the Diff and
Bind lists. The fixes themselves stay on the driver cards named in the
appendix.
