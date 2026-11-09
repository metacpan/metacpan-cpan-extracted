# ADR 0038 — The `is_pk` fold in `table_columns_info` is a model statement, not an engine fact

- Status: accepted
- Date: 2026-08-04 (SQLite condition corrected + `set_primary_key` interaction
  recorded 2026-08-05 — k143)
- Tags: introspect, canonical-model, drivers, cross-driver, family-policy

## Context

`table_columns_info` in `lib/DBIO/Introspect/Base.pm` — the default contract
implementation every driver whose model has the canonical shape inherits —
derives nullability from two fields of the canonical `columns` section
(ADR 0007, "CANONICAL MODEL" in the same file):

    is_nullable => (($col->{not_null} || $col->{is_pk}) ? 0 : 1)

The `is_pk` term was added in k126. The problem it solved is real and is
not in question here: `not_null` reports only whether the column carries a
`NOT NULL` attribute, engines keep the primary-key constraint separate from
that attribute, so SQLite's `PRAGMA table_info` says `notnull = 0` for a key
column and the base used to contradict its own `table_pk_info` about the same
column hashref. Generated result classes got a nullable primary key.

What k126 also recorded, in the commit message, in the inline comment and in
the POD, was a **factual claim** as the justification: *"no engine lets a key
column hold NULL."* That claim is false, and both counterexamples matter:

- **ClickHouse** (reported by dbio-clickhouse k19, the driver-side handoff
  of k126). MergeTree refuses a `Nullable` column in the sorting key only while
  `allow_nullable_key` sits at its default `0`; with `SETTINGS
  allow_nullable_key = 1` a nullable key column is legal.
- **SQLite** — the very engine k126 cites as its motivation. Reproduced here on
  SQLite 3.51.1 / DBD::SQLite 1.78: `CREATE TABLE t1 (name TEXT PRIMARY KEY)`
  reports `notnull=0 pk=1`, accepts `INSERT INTO t1 (name) VALUES (NULL)`
  twice, and both rows really hold NULL — the two NULLs do not even collide
  with each other, because the key index treats them as distinct. The same
  holds for a composite `PRIMARY KEY (a, b)` on a rowid table. This is SQLite's
  documented, deliberately-kept bug: *"the PRIMARY KEY … is allowed to contain
  NULL values … This is a bug, but by the time the problem was discovered it
  was widely deployed"* (`lang_createtable.html`). Two cases are **not**
  counterexamples and the distinction is load-bearing: the **rowid alias**,
  where `NULL` is an input token meaning "assign the rowid" and the stored
  value is never NULL; and a `WITHOUT ROWID` table, which reports `notnull=1`
  for its key itself, so the fold has nothing to change there.

  **Correction, 2026-08-05 (k143, from `dbio-sqlite` k29).** This
  bullet first named that first exception "`INTEGER PRIMARY KEY`", and as a
  rule about the *declared type* that is wrong in both directions — measured
  by the driver on SQLite 3.51.1 / DBD::SQLite 1.78, and stated by SQLite's own
  documentation:

  - Only the exact declared type `INTEGER` makes an alias. `id INT PRIMARY KEY`
    has integer affinity but is "an ordinary table column with integer affinity
    and a unique index, not as an alias for the rowid" — it accepts two NULL
    inserts and stores both.
  - A **column-level** `PRIMARY KEY DESC` is documented as not producing an
    alias either ("This quirk is not by design. It is due to a bug in early
    versions"), so `id INTEGER PRIMARY KEY DESC` stores NULL — while the
    table-constraint spelling `PRIMARY KEY(id DESC)` *does* produce an alias.

  `PRAGMA table_info` reports `type=INTEGER notnull=0 pk=1` for the alias and
  for the `DESC` non-alias alike, so it cannot separate them. What can, exactly
  and without parsing the stored `CREATE TABLE` text, is `PRAGMA index_list`:
  SQLite materialises every primary key as an automatic `origin = 'pk'` index
  **except** the rowid alias and the key of a `WITHOUT ROWID` table, which are
  the row's own storage. On a rowid table, "declares a key but has no
  `pk`-origin index" is the alias. That is what `DBIO::SQLite::Util::
  pk_is_rowid_alias` implements and `DBIO::SQLite::Introspect` overrides on.

  SQLite's own summary of the whole condition, worth quoting because it is
  shorter than any paraphrase: it allows the NULL "unless the column is an
  INTEGER PRIMARY KEY or the table is a WITHOUT ROWID table or a STRICT table
  or the column is declared NOT NULL". The `STRICT` case had not been named
  here at all.

Whether the fold stays unconditional is a contract question about the canonical
model, so it is core's to answer and not any driver's (the ownership rule of
ADR 0018 and ADR 0021). (core k129.)

## Decision

1. **The base formula stays exactly as it is.** No condition, no capability, no
   `_pk_implies_not_null` seam.
2. **Its justification is restated as a model statement.** `is_pk` marks the
   column `table_pk_info` names as the row's identity; an identity that can be
   NULL is not usable in the Row layer, so DBIO's canonical model has no
   nullable primary key. The base reports the model's answer. It is not
   claiming the engine would refuse the write.
3. **The cost is documented next to the formula**, in the `table_columns_info`
   POD, together with both counterexamples and their exact conditions.
4. **The escape is a driver override of `table_columns_info`**, not a flag in
   core. `DBIO::ClickHouse::Introspect` already is that override, deliberately
   and with its reasoning pinned in its own code and tests: it reads
   `is_nullable` out of the type string, which is where ClickHouse writes
   nullability (`Nullable(T)`), and never calls `SUPER`.

## Rationale

The claim that was there cannot stay, because it is falsified by two engines,
one of them the motivating one. The reason that survives falsification is the
model statement, and it is a stronger reason: it says what DBIO holds true of
its own abstraction, which no engine can refute.

**The rejected alternative — a capability or seam — would have zero users.**
A census of the family at the time of this decision:

- Drivers that **override** `table_columns_info` and never reach the base fold:
  ClickHouse, DuckDB, Oracle, PostgreSQL (and PostGIS, which subclasses
  `DBIO::PostgreSQL::Introspect`), SQLite, Informix (abandoned, see the house
  rules). Core's own `DBIO::Introspect::DBI` — the generic DBD fallback — also
  overrides, and folds `is_pk` in itself via `table_pk_info` (k124).
- Drivers that **inherit** the base unchanged: DB2, Firebird, MSSQL, MySQL,
  Sybase. Every one of them derives `not_null` from the engine's own
  nullability catalog (`SYSCAT.COLUMNS.NULLS`, `RDB$NULL_FLAG`,
  `INFORMATION_SCHEMA.COLUMNS.IS_NULLABLE`), and every one of those engines
  forces `NOT NULL` onto a key column itself — so `not_null` is already `1`
  there and the `is_pk` term never changes an answer.

The two engines that could trigger the fold wrongly both already override the
whole method; the five drivers actually sitting on the base are on engines
where the fold is a no-op. A flag would therefore be an abstraction with no
caller on the day it is written — house rule 2, nothing speculative.

Neither is this a case for rounding toward the permissive side, the way
k124 rounds an unknown `NULLABLE = 2` toward nullable. There is no unknown
here: the canonical model documents `not_null` as `0`/`1`, `is_pk` is
authoritative, and the answer given is the model's, deliberately.

## Consequences

- **No code changes.** The expression, the signature, the keys and the return
  type of `table_columns_info` are untouched, so the contract version stays
  where it is — ADR 0024 draws the bump line at the shape of the public
  surface, and nothing about the shape moved.
- **A driver on an engine that permits NULL in a key column must override
  `table_columns_info`**, and that is now written where a driver author looks
  for it. On such an engine, inheriting the base means `is_nullable => 0` for a
  column that holds NULLs, `DBIO::Generate` baking that into the regenerated
  result class, and a redeploy emitting a stricter column than the one
  introspected — on ClickHouse, the `Nullable(T)` wrapper silently falls away
  and the DDL ↔ Introspect round-trip the layer exists to keep is broken.
- **Taking the escape makes `set_primary_key` warn, and that is the intended
  end of the chain** (added 2026-08-05, k143). A driver that overrides
  `table_columns_info` to report the engine's real answer produces
  `is_nullable => 1` on a key column; `DBIO::Generate` bakes that into the
  generated result class; and `DBIO::ResultSource::set_primary_key` then
  `carp_unique`s that the key "includes the column '%s' which has its
  'is_nullable' attribute set to true. This is a mistake and will cause various
  Result-object operations to fail". It is a warning, not fatal, and it is
  **correct** — it is the same model statement this ADR restates the fold as.
  Naming it here so the next driver does not read it as a bug in its own
  override: the user learns at load time that the foreign table is not usable
  as a DBIO source, instead of learning it later from rows that cannot be
  found. Introspection tells the truth about the engine; the Row layer tells
  the truth about the model; the two disagreeing on such a table is the
  information, not the failure.
- **The invariant stays pinned by the test k126 already added.** The loop in
  `t/base-introspect.t` asserts that no column `table_pk_info` names is ever
  reported nullable, over every model in that file. That is the invariant the
  fold exists for, and it is what would fail if the fold were ever weakened
  without this decision being revisited. No new test: the restated *reason* is
  not a behaviour, and a test that cannot fail is not a test.
- **`DBIO::DuckDB::Introspect`, `DBIO::Oracle::Introspect` and
  `DBIO::PostgreSQL::Introspect` derive `is_nullable => $col->{not_null} ? 0 : 1`
  without the fold** in their own overrides. All three engines set `NOT NULL`
  on key columns themselves, so there is no gap — and after this decision they
  also have no core-side obligation to adopt the fold, since it is the base's
  answer for the base's model and not a rule about what an override must
  compute. No core action.

## Future architecture work (tracked cross-repo, not here)

- **dbio-sqlite**: `DBIO::SQLite::Util::column_is_nullable` computes the same
  `($not_null || $is_pk) ? 0 : 1` fold and is used on the live `PRAGMA` path by
  `DBIO::SQLite::Storage`, so the SQLite reproduction above is equally a
  finding about that driver — on SQLite the engine really does permit the NULL
  the fold denies. Whether SQLite should keep the fold (the model answer, same
  as here) or read the key's real nullability is the driver's call, on the
  driver's board; core states only that the base's answer is the model's.
  Handed off from core k129.

  **Answered** (`dbio-sqlite` k29, commit `b748b99`): the driver reads the
  real nullability. `column_is_nullable` took a third argument,
  `pk_is_rowid_alias` supplies it from `PRAGMA index_list`, and both the
  introspect path and the live `PRAGMA` path share the one rule so the driver
  cannot answer two different things about the same column. That is exactly the
  escape this ADR provides, and the report it sent back is the correction now
  folded into the Context bullet above (k143). No core change followed:
  the base formula, its signature, its keys and its return type are as they
  were, and the contract version with them.
