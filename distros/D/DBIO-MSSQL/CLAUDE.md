# CLAUDE.md — DBIO::MSSQL

This distribution tracks only its own `dbio-mssql*` skills; the agents, the house rules and
the other skills named here come from the `dbio` core repo. **Fresh clone: run `skilletor sync`
first** (needs the `skilletor@getty` plugin) — only then do `.claude/agents/.local.*`,
`.claude/rules/.local.dbio-rules.md` and the installed skills exist. Never edit those copies;
change the source in core and sync again. The family-wide house rules (discipline, delegation,
release) are in `.claude/rules/.local.dbio-rules.md`, auto-loaded by Claude Code for the main
agent and all subagents.

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-mssql` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-mssql` (default), `dbio-release-manager`,
`karr-coordinator`.

## Namespace

- `DBIO::MSSQL` — MSSQL schema component
- `DBIO::MSSQL::Storage` — MSSQL storage (transport-neutral base)
- `DBIO::MSSQL::Storage::ODBC` — MSSQL via DBD::ODBC (default connection path)
- `DBIO::MSSQL::SQLMaker` — MSSQL SQL dialect
- `DBIO::MSSQL::Storage::Sybase` — MSSQL via DBD::Sybase

**`-nulls` in `order_by` is emulated** (karr k78, maintainer's decision 2026-10-25; SQL Server has no
NULLS FIRST/LAST). `DBIO::MSSQL::SQLMaker` renders `{ -asc|-desc => col, -nulls => 'first'|'last' }` as
`CASE WHEN col IS NULL THEN 0 ELSE 1 END ASC, col ASC|DESC` (`last`: `THEN 1 ELSE 0`), the key always
ASC (`_render_op_nulls`, `render_op` copied in `new` as in dbio-mysql). The ROW_NUMBER limit takes the
order apart in one chunk per sort key (order supplement `ORDER__BY__nnn`), so `_chunkify_order_by` splits
a `-nulls` entry into the CASE key and the column; the inner select then holds the CASE as
`... AS [ORDER__BY__001]` and `OVER (ORDER BY ...)` orders by the aliases. There is no TOP limit dialect and
no reversed outer order in this driver (the only `TOP` is the ordered-subselect wrapper, which leaves the
order_by as it is). The expression is rendered twice (a bind in it is bound twice). t/113 offline, t/114 live.

## Native Deploy (test-and-compare)

`DBIO::MSSQL::Deploy` uses the same strategy as other DBIO drivers:

1. Introspect live DB via `INFORMATION_SCHEMA` + `sys.indexes`
2. Deploy desired schema to temp DB (`CREATE DATABASE _dbio_tmp_<pid>_<time>`)
3. Introspect the temp DB
4. Diff the two models via `DBIO::MSSQL::Diff`

Temp DB connections are derived by swapping the database name in the DSN.
Supports both scalar and hash `connect_info` formats.

## Introspect Sub-modules

- `DBIO::MSSQL::Introspect::Tables` — `INFORMATION_SCHEMA.TABLES`
- `DBIO::MSSQL::Introspect::Columns` — `INFORMATION_SCHEMA.COLUMNS` + PK/identity
- `DBIO::MSSQL::Introspect::Indexes` — `sys.indexes` / `sys.index_columns` (incl. `filter_definition`, karr k76)
- `DBIO::MSSQL::Introspect::ForeignKeys` — `REFERENTIAL_CONSTRAINTS` + `TABLE_CONSTRAINTS`
- `DBIO::MSSQL::Introspect::Views` — `sys.views` + `sys.sql_modules`; the stored text goes into `tables->{view}{definition}` (read in 4000-character pieces: an `nvarchar(max)` is cut at TEXTSIZE over DBD::Sybase), karr k82

## Diff Sub-modules

- `DBIO::MSSQL::Diff::Schema` — CREATE SCHEMA for a schema the target needs and the live DB lacks (karr k72); first op of the diff, never a DROP SCHEMA
- `DBIO::MSSQL::Diff::View` — `CREATE OR ALTER VIEW` for a new or changed view, `DROP VIEW` for a live view the classes lack (karr k82, replaces k45's omission; no `skipped_views` any more). Compared: the text after the header's `AS`, white space folded, case kept (`View->body/normalize`). One statement per batch; drops after the FK drops and before DROP TABLE, creates/alters last; `schema.view` quoted per part, `Diff::Schema` creates the schema; views among themselves by dependency: Introspect puts `depends_on` (view keys read, from `sys.sql_expression_dependencies`) into the model, creates go after what they read, drops before; cycle or unknown view read = DBIO::Exception "refused" before any statement; `DDL::_order_view_statements` orders install_ddl by the names the text mentions (t/125, live t/126)
- `DBIO::MSSQL::Diff::Table` — CREATE/DROP TABLE (no inline FK: keys are `Diff::ForeignKey` ops)
- `DBIO::MSSQL::Diff::Column` — ADD/ALTER/DROP COLUMN
- `DBIO::MSSQL::Diff::Index` — CREATE/DROP INDEX (clustered/nonclustered); a unique constraint
  (`is_unique_constraint` from `sys.indexes`) is `ALTER TABLE ... ADD/DROP CONSTRAINT`
- `DBIO::MSSQL::Diff::ForeignKey` — ADD/DROP CONSTRAINT, also for new and dropped tables
- `DBIO::MSSQL::Diff::PrimaryKey` — DROP/ADD CONSTRAINT `PK_<table>` on existing tables (karr k74; live name from `pk_constraint_name`; CLUSTERED/NONCLUSTERED (`pk_clustered`) is compared too -- the classes create the key clustered, a live nonclustered one is replaced, and the ADD says `CLUSTERED` out loud (without it the server makes the key nonclustered while a clustered index stands, measured); referencing FKs dropped/re-added around it; key dropped around a type change of a key column; a target without key DROPS the live one -- summary line `PRIMARY KEY DROPPED`, undeclared referencing FKs dropped first, a declared referencing FK without a unique key over the same columns is refused with DBIO::Exception; measured: server refuses the drop while an FK references it and cannot create an FK onto a table without PK/candidate key). `install_ddl` names the key `PK_<table>` too

## Schemas (karr k72, maintainer's decision 2026-10-25)

A table or view name `schema.table` is made in that schema; `dbo.t` is `t`; two or more
dots (database-qualified) or an empty part are refused (`DDL::_check_table_name`).
`DDL::_quote_table` quotes both parts on their own (`[my schema].t`); a bare name is
`dbo` and written bare, as before. `install_ddl` writes `CREATE SCHEMA x;` for every
schema the classes name, each a statement of its own (it has to be first in its batch;
`_execute_ddl` runs statement by statement, measured over DBD::ODBC and DBD::Sybase
2026-10-25, inside the `txn_do` bracket too), before the first object. Constraint
names are made from the *bare* table (`PK_t`, `FK_t_col`, `UQ_t_col`, `DF_t_col`) --
they live in the schema of their table, so `one.t` and `two.t` may both have `PK_t`;
`_check_constraint_names` and the unique-name check are per schema (`_schema_prefix`).
Foreign keys may cross the border both ways (`REFERENCES other.parent (id)`).

`Introspect` takes `schemas => [...]` besides `schema` (`dbo`): the tables of those are keyed
`schema.table` in the model (dbo bare, so existing models hold), a foreign key into another
schema says `schema.table` in `to_table` (`to_schema` carries the schema; the query joins
`uk_kcu` on the constraint schema too), `schemas => { name => {...} }` lists the requested
schemas that exist. `Deploy::_new_introspect` hands it the schemas the classes name
(`DDL::_schemas_of`), for the live and the throwaway database alike -- a schema no class
names is not looked at, its tables are neither compared nor dropped. `Introspect::Columns`
joins identity columns on the schema too (it used to mix same-named tables of two schemas).
`Diff::Schema` decides CREATE SCHEMA from the target's table keys against the source's
`schemas` and table keys (case-insensitively in a CI database); `Diff` puts it first.
A schema is **never dropped** (not decided). Open: a live `dbo` table whose name has a dot
(`[a.b]`) reads as table `b` of schema `a` in the model. Offline `t/111`, live `t/112`.

**Names follow the collation of the live database** (karr k77; measured 2026-10-25, MSSQL 2022,
server and tempdb `SQL_Latin1_General_CP1_CI_AS`): in a CI database `Foo`/`foo` as tables, columns, indexes
or constraints are duplicates (refused, Msg 2714/2705/1913), in a `_CS_` one they are two objects.
`Introspect` puts `collation => { name, case_sensitive }` (ComparisonStyle bit 1 = ignore case) into the
model; `Diff::_fold_names` writes the target's names in the live spelling when the source model is CI, so a
change of spelling alone is no operation (no `sp_rename`, which the server would accept for a table and a
column even in CI: not built, a recommendation on k77). A model without `collation` compares exactly.
`Deploy::_create_temp_db` creates the throwaway database `COLLATE`d like the live one (t/109, live t/110).

`DBIO::MSSQL::Diff` orders the ops itself (core's walk is alphabetical): FK drops, index/unique
drops, PK drops, DROP TABLE, column ops, CREATE TABLE, PK adds, index/unique creates, FK adds (t/92, live t/93, karr k71; PK: t/103, live t/104, karr k74).
One rule for FKs around a changing key or column (`Diff.pm`, k74; measured 2026-10-21): an FK that
references a key the diff drops (PK, unique constraint or unique index, from any source incl. the
unbinds-dependents extras) or stands on a column the diff retypes (`Diff::Column::retypes`, child
or referenced column, a width change of nvarchar too -- server: "object FK is dependent on column"; a
nullability change alone runs) is dropped in phase 1 and re-added in phase 7 if declared. A declared
FK onto columns no PK/unique key covers afterwards is refused with DBIO::Exception.

## DDL

`DBIO::MSSQL::DDL->install_ddl($schema)` generates a full DDL script from DBIO classes.
Handles: table creation with inline PK (FKs as `ALTER TABLE ADD CONSTRAINT` after all tables), unique constraints, `IDENTITY(1,1)` for auto-inc,
and standalone indexes via `mssql_indexes` class method and the canonical index
declaration of the ResultSource (Cake `idx`/`indices`, ADR 0061, karr k66) read
with `index_declarations_for('mssql', ['kind', 'where'])`; own block
`mssql => { kind => 'clustered'|'nonclustered', where => '<predicate>' }`, canonical wins on equal name,
foreign-only block / unknown key / invalid kind throw. `where` (also in a `mssql_indexes` entry) makes a
filtered index (karr k76): written as `... (cols) WHERE <predicate>`; empty/non-string `where` and a filter on a
`clustered` index are refused; a filtered index over the key's columns is written (the unfiltered duplicate is not).
Introspect reads `sys.indexes.filter_definition` as `filter`; the server returns its own form (`a = 1` as `([a]=(1))`),
so `Diff::Index::normalize_filter` compares (case, brackets, spaces, parentheses around numbers and the whole
predicate; literals exact), a changed/added/removed filter is drop+create (t/107, live t/108). A `clustered` index on a table with a primary key (the key is `CLUSTERED`) and a second clustered index on any table are refused (Msg 1902; karr k71, t/96); a string default that is no number on a numeric/bit type is refused, date/time types are not (open: live t/99). Deploy/Diff build the
desired model through `install_ddl`, so nothing else reads the declaration.

## MSSQL-Specifics

### Datetime Types

| Type | Range | Precision |
|------|-------|-----------|
| `datetime` | 1753-01-01 to 9999-12-31 | 3.33ms |
| `datetime2` | 0001-01-01 to 9999-12-31 | 100ns |
| `datetimeoffset` | 0001-01-01 to 9999-12-31 | 100ns + timezone |
| `smalldatetime` | 1900-01-01 to 2079-06-06 | 1 min |

Storage uses `DBIO::MSSQL::Storage::DateTime::Format` (Strptime-based).

### MONEY

`_prep_for_execute` auto-casts bind values to MONEY via `CAST(? AS MONEY)` to avoid DBI truncation.

### Ordered Subselects

MSSQL forbids `ORDER BY` in subqueries without `TOP`. `_select_args_to_query` intercepts and wraps with `SELECT TOP <max_int>`.

### Identity / Auto-Increment

`IDENTITY(1,1)` syntax. `last_insert_id` via `SCOPE_IDENTITY()` appended to INSERT, with `_identity_method` fallback.

**UNIQUEIDENTIFIER (GUID) columns that look like auto-increment are NOT real IDENTITY
columns** — they're populated by `NEWID()` via `DBIO::Storage::DBI::UniqueIdentifier::_prefetch_autovalues`.
`_prep_for_execute` inspects `data_type` for `uniqueidentifier`/`guid` and locally
suppresses `_autoinc_supplied_for_op` so the parent `IdentityInsert` wrapper is
skipped. Otherwise MSSQL rejects `SET IDENTITY_INSERT` with
"Table '...' does not have the identity property". The trailing
`SELECT SCOPE_IDENTITY()` is also skipped for GUID-typed autoinc (no real
IDENTITY column to retrieve from).

Note: non-PK GUID columns need `auto_nextval => 1` in the schema
(NOT `is_auto_increment => 1`) for `_prefetch_autovalues` to populate them.
PK GUIDs are populated unconditionally.

### Bulk Operations

No native bulk INSERT in DBIO. Use `OUTPUT` clause or direct `BULK INSERT` via `$dbh->do`.

### Connection parameters without a DSN

`DBIO::MSSQL::Storage::_connect_params_dsn` (core ADR 0057, karr k37) builds the
DSN for `{ dbname, host, port }` (AccessBroker::Static, or a connect-info hash
without `dsn`). The registered name `MSSQL` is no DBD, so the DSN always names
DBD::Sybase: `dbi:Sybase:host=..;port=..;database=..`, parts not given left out
(`dbname` alone → `dbi:Sybase:database=..`, server from `$DSQUERY`). `host`
without `port` and `port` without `host` throw — DBD::Sybase ignores a lone one,
and no 1433 is assumed. ODBC has no form these parts can fill:
`DBIO::MSSQL::Storage::ODBC` keeps core's ODBC refusal through its base order
(pinned in `t/59-connect-params-dsn.t`); the whole DSN goes in as `dsn` or as a
`dbname` starting with `dbi:`. All three forms are live-verified (2026-10-05,
MSSQL 2022, DBD::Sybase 1.27 / FreeTDS 1.3.17, `t/60-connect-params-live.t`);
that file needs `DBIO_TEST_MSSQL_DSN` in exactly the form
`dbi:Sybase:host=..;port=..;database=..` and skips on anything else. The seam
is asked at `connect_info`, on the declared base class, before the storage
has adapted to an access path (next section) — so the DSN it builds is what
decides the DBD, and connection parameters always lead to
`DBIO::MSSQL::Storage::Sybase`. After the adaptation every reconnect asks the
seam of the class the storage became: the same form over DBD::Sybase, core's
refusal over DBD::ODBC (pinned in `t/62-adapt-access-path.t`). Two defects
were found on the way, both fixed: the DBD::Sybase class read `@@identity`
over FreeTDS, which a trigger overwrites (k39, see "The key of a new row"
below), and bind values were cut to 4000 without an error (k40, see "Bind
values over 4000 bytes over DBD::Sybase" below).

### HostBound seam `_bind_host_into_dsn`

Core k276 (ADR 0013 addendum 2026-10-09), here karr k64. A
`DBIO::AccessBroker::HostBound` view asks the storage class
`_bind_host_into_dsn($driver, $dsn, $host, $port)`; it answers the DSN or
`(undef, $form)`, and the view then refuses the connection with the form in
its message (never the DSN). `DBIO::MSSQL::Storage` implements it, on the
base because the declared class is asked before the storage adapts and
`::ODBC`/`::Sybase` inherit it ahead of core's default (checked with
`mro::get_linear_isa`; `DBIO::Sybase::Storage` precedes the base for
`::Sybase` and would shadow it if dbio-sybase ever defines the seam). Dispatch is on the DBD of the
DSN: `ODBC` translates `Server=host[,port]` and `Server=host;Port=n`,
declines `DSN=`/`FILEDSN=`/bare names, `Servername=`, `Address=`, instance,
protocol and braced `Server`, both port forms, no `Server`, and a view port
where the DSN has no port form; every other DBD (`Sybase` host=/port=, which
declines `server=NAME`) is core's default via `next::method`. Offline in
`t/71-bind-host-into-dsn.t`; not run against a live replica.

### A declared storage adapts itself to the access path

Core ADR 0059 (core k301, maintainer decision 2026-10-06), here karr k37. The
`MSSQL` component and the `-ms` shortcut pin `DBIO::MSSQL::Storage` — that pin
declares the driver, and core never asks the DSN what the driver is. `DBIO::MSSQL::Storage::_adapt_to_access_path($dbd)` is what core
calls instead, at the first use that needs the driver:

- `ODBC` → `DBIO::MSSQL::Storage::ODBC`, from the DSN alone, no connection.
- `Sybase` → `DBIO::MSSQL::Storage::Sybase`, whose own hook makes the
  NoBindVars decision (`_adapt_to_placeholder_support`, the one body `_rebless`
  calls too). `DBIO::Sybase::Storage::_init` then mixes the FreeTDS class in,
  so the declared way ends in the class the generic way ends in. Without
  DBIO::Sybase installed the hook throws, naming it.
- `$dbd` undef: for a connection coderef the hook runs it and reads the DBD
  off the handle; connect info without a DSN is refused by core at connect (k306), so the
  hook never sees one.
- Only the declared base moves. A private subclass pinned through
  `storage_type` stays what it is (core throws if a hook moves a storage out
  of the class that was declared); a storage pinned to `::ODBC` or `::Sybase`
  itself is already there. **Over DBD::ODBC** core reports the private
  subclass's DBD as not its own (a warning). **Over DBD::Sybase it is
  refused** (karr k42, k43; `docs/adr/0008`): the hook throws, naming
  `DBIO::MSSQL::Storage::Sybase` as the class to derive from and DBD::ODBC as
  the other way, whatever `driver_strict`/`driver_warnings` say. This departs
  from ADR 0059 (c)/(d), where a mismatch only warns. A layer class core
  composes over the declared base is no private subclass. A pin on
  `::ODBC` (or a subclass of it) over `dbi:Sybase:` is refused too, with a
  message naming the contradiction (ODBC class over DBD::Sybase), not the
  "derive from ::Sybase" advice (pinned in t/62).
- Neither `_rebless` nor the connector registry is called, and the server is
  not asked what it is (`SQL_DBMS_NAME`, `sp_server_info`): the declaration says
  what the product is. Nothing the driver reads
  anyway names the product, so the driver calls `_driver_mismatch` nowhere;
  the DBD of another driver (`dbi:Pg:`) is reported by core.
- `DBIO::MSSQL::Storage::Sybase::_adapt_to_access_path` does **not** call
  `next::method`: `DBIO::Sybase::Storage` precedes `DBIO::MSSQL::Storage` in
  that class's linearisation, and a hook there (dbio-sybase k64) is the ASE
  dispatcher's.

Offline in `t/62-adapt-access-path.t` (DBI->connect replaced). **The ODBC
branch is also held live** (karr k54, `t/72-adapt-access-path-odbc-live.t`,
2026-10-17, MSSQL 2022 16.0.4295.3, DBD::ODBC 1.61 / tdsodbc 1.3.17, DSN
`dbi:ODBC:Driver=FreeTDS;Server=..;Port=..;Database=..;TDS_Version=7.4`):
a schema with the component is `DBIO::MSSQL::Storage` before the first use
and `DBIO::MSSQL::Storage::ODBC` after it, one `DBI->connect`, no warning.
Live over DBD::Sybase (2026-10-07, MSSQL 2022 16.0.4295.3, DBD::Sybase
1.27 / FreeTDS 1.3.17, TDS 7.4, DSN `dbi:Sybase:host=..;port=..;database=..`):
a schema with the component ends as `DBIO::MSSQL::Storage::Sybase::FreeTDS`,
and core's "Driver mismatch for declared storage class DBIO::MSSQL::Storage"
warning, which every declared MSSQL schema got at its first use before, is
gone.

What a declared schema over DBD::Sybase got with that class, measured in t/60
and t/61 against what the base class did there on 2026-10-05:

- gained: the server version, DateTime inflation with `datetime_setup`, the
  NoBindVars class when told the connection has no placeholders, statement
  caching turned off;
- **lost, then fixed, k39**: `create()` on a table whose trigger inserts into
  another IDENTITY table returned that table's identity (1000 where the row is
  1). The base class appends `SELECT SCOPE_IDENTITY()` and was right; the class
  does too now ("The key of a new row");
- **lost, then refused, k47**: the FreeTDS class sets `SET TEXTSIZE` to
  `LongReadLen` (32768 unless the connect info says otherwise), so a
  100000-character value came back cut to 32768, without an error. The base
  class left the TDS 7.4 default and read it whole. Since k47 a column of a
  result source is read behind a check the server runs and a value over
  TEXTSIZE is **refused**, not cut ("Values longer than TEXTSIZE" below); the
  raw handle is as it was;
- transactions with an open cursor: see the next section (decided and built, k43).

### Transactions with an active statement handle over DBD::Sybase

Decided by the maintainer 2026-10-18 and built in `DBIO::Sybase::Storage::FreeTDS`
(dbio-sybase karr k65, here karr k43); measured live in
`t/61-txn-freetds-live.t` (karr k41; MSSQL 2022 16.0.4295.3, DBD::Sybase 1.27 /
FreeTDS 1.3.17, TDS 7.4, both DSN forms, both ways: declared and pinned, one
expectation for both since k37). DBD::Sybase runs a statement on a database
handle with an active statement handle (an open cursor: a resultset read with
`->next`, not to its end) over a second connection, outside the transaction.
The FreeTDS class therefore never sends a transaction statement past one:

- **`ROLLBACK`** -- also that of a `txn_scope_guard` and of `txn_do` --
  finishes every active statement handle of the connection and rolls back on
  the same connection. The price: a cursor read across the rollback is over,
  its next `->next` returns nothing, without an error. Cases 6, 7 and 8b of
  t/61 are plain tests: the caller gets its own exception and no "ROLLBACK
  FAILED", the body of `txn_do` runs once, `transaction_depth` 0, nothing open
  or locked, the cursor over.
- **`BEGIN TRAN` and `COMMIT` throw** ("Cannot COMMIT while a statement handle
  of the connection is still active (an open cursor) ..."), before anything is
  sent; the storage is as it was. Open cursor *before* the transaction
  (cases 9, 10): `BEGIN TRAN` is refused, the body of `txn_do` does not run,
  the guard is never made, depth 0, no UPDATE anywhere -- the same on the
  host and port form and on the named server (the UPDATE that was committed
  outside any transaction there is gone). A refused `COMMIT` leaves the
  transaction open (depth 1, row locked) by decision; the way out is the
  storage's `txn_rollback` (case 8b, plain).
- **One test stays TODO, in four combinations (case 8, "SHOULD": a guard whose
  commit is refused):** core's `TxnScopeGuard::commit` marks the guard spent
  *before* it calls `txn_commit` (its own FIXME: a commit may fail and a
  rollback still be necessary), so the guard's DESTROY never rolls the open
  transaction back; it stays open and locked until the storage hangs up. Not
  fixable in this driver or in dbio-sybase; core's. The `IS` line beside it
  pins today's state.
- ASE's `txn_scope_guard` trigger -- a statement refused at prepare -- is
  harmless here: on TDS 7.4 the refused prepare leaves no statement handle.
- Before the decision (measured 2026-10-05, 2026-10-07): the three statements
  went out with `$dbh->do` on a second connection. SQL Server answered a stray
  COMMIT/ROLLBACK with Msg 3902/3903, the storage did not count down, the
  transaction stayed open and the row locked, and a `txn_scope_guard` + `die`
  told the caller nothing; with the cursor open before the transaction the
  UPDATE ran outside it on a named server and was committed for good. Since
  core of 2026-10-13 (k303, k65) the handle whose rollback failed was
  discarded and `txn_do` ran its block twice. All of that is gone.
- The base class `DBIO::MSSQL::Storage` on a DBD::Sybase handle -- what a
  declared schema had until k37 -- failed differently (COMMIT and ROLLBACK
  refused by the client library, `txn_do` ran its body twice; k42, k43). That
  pin is **refused** now (k42, k43; `docs/adr/0008`): the access path hook
  throws before anything runs, nothing of it is in t/61.

### Bind values over 4000 bytes over DBD::Sybase

karr k40, measured 2026-10-07 (MSSQL 2022 16.0.4295.3, DBD::Sybase 1.27 /
FreeTDS 1.3.17, TDS 7.4; client charset UTF-8, taken from the locale).

**The cause.** FreeTDS prepares with `sp_prepare` and declares every
placeholder `@Pn varchar(4000)` — read in a `TDSDUMP`. The execute carries the
whole value; the server cuts it when it assigns it to the parameter, without
an error. So the limit is 4000 **bytes** of the parameter (in a database with
a UTF-8 collation: 2000 `ä`), it holds for every column type, and it holds in
a condition too, where the cut value matches another row or none. No
`bind_param` type, no `CAST(? AS VARCHAR(MAX))` and no `syb_*` attribute
changes the declaration; an RPC to `sp_executesql` fails on Msg 214, because
DBD::Sybase cannot bind `nvarchar`.

**The fix** is in `DBIO::MSSQL::Storage::Sybase` alone, no `@ISA` change. A
value of more than 4000 bytes — as DBD::Sybase sends it: Perl's internal bytes
— goes into the statement as a literal; all other values stay binds.

- Core runs a statement as trace → prepare → bind (`_dbh_execute`,
  `_dbh_prepare`), and only trace and bind see the values. The class works
  out the statement to prepare in its `_dbh_execute`/`_dbh_prepare`, keeps it
  in a `local` slot, and swaps it in in `_prepare_sth` and `_bind_sth_params`.
  That keeps the trace as it was — placeholder, value through
  `redact_bind_value` (ADR 0025). Doing it in `_prep_for_execute`, as core's
  NoBindVars does, would put the value into the trace unredacted.
- **Not** after the prepare: a second `prepare` while a prepared statement
  with placeholders is alive makes DBD::Sybase open its second connection
  (measured: "Server name not found" on the host/port DSN form).
- The literal is plain for ASCII, `N'...'` for anything else, and assembled as
  bytes. Quotes are doubled. Two things the server reads in a literal and not
  in a bound value are written around: a backslash before a line break (the
  server drops both — line continuation) and a NUL (Msg 105). The pieces are
  joined onto `CAST('' AS VARCHAR(MAX))`: joined to each other alone they are
  cut at 8000 bytes.
- Such a statement is never cached (`disable_sth_caching` is on anyway with
  FreeTDS above 0.82 and on NoBindVars; for the rest `_prepare_sth` forces it).
- `_insert_bulk` (populate in void context) binds every row to one prepared
  statement; with a long value anywhere in the data it inserts row by row in
  one transaction.
- A statement with a `?` that is no placeholder, beside a long value, throws:
  the count of `?` and of bind values must agree.
- Core's `DBIO::Storage::DBI::NoBindVars::_interpolate_bind_values` was read
  and not used: it calls `interpolate_unquoted` and `_prep_interpolated_value`
  on the storage, which only a class inheriting it has; it interpolates every
  value; and it writes a plain literal without the two workarounds above.

**Not reached, measured:** a private subclass of `DBIO::MSSQL::Storage` on a
DBD::Sybase handle stored 4000 of 5000 — the base is transport-neutral and has
none of this; such a pin is refused since k42 (`docs/adr/0008`). NoBindVars
and DBD::ODBC do not have the defect (ODBC:
5000 and 100000 characters arrive whole as binds, plain DBI and through
`DBIO::MSSQL::Storage::ODBC`).

**Found on the way** (the NoBindVars literal is core's and only noted on k40;
k49 and k55 are decided and built, see "Strings beyond ASCII and empty strings"
below; k50, binary values, is fixed -- see "Binary values" below):

- k51, decided (left as it is): a statement run on the handle directly
  (`dbh_do`, `on_connect_do` with bind values) passes the storage by and is
  still cut, and it is as exposed to the two defects of the next section. The
  caller has the handle in hand. Documented in the POD and the matrix below.
- A plain literal — what core's NoBindVars writes for every value — has
  neither workaround: `'a\<LF>b'` is stored as `ab`, a NUL is Msg 105, a
  character the code page lacks becomes `?`. Measured on the literal with
  plain DBI, not through the NoBindVars class.
- Over DBD::ODBC a bound string with characters outside the code page was
  refused by the driver even for an NVARCHAR column (k58, fixed: "Strings
  beyond the code page over DBD::ODBC").

### Strings beyond ASCII and empty strings over DBD::Sybase

Maintainer's principle (2026-10-17): silently wrong behaviour (data corruption)
is refused loudly or fixed; DBD::ODBC is the supported access path; where
DBD::Sybase corrupts and the driver cannot repair it, the storage refuses with
a message that names DBD::ODBC, and that refusal is tested. Both cards in
`DBIO::MSSQL::Storage::Sybase`, in `_rewrite_binds` (the seam of k40/k50),
no `@ISA` change. Offline `t/81-nonascii-empty-binds.t`, live per access path
`t/82-nonascii-empty-live.t`.

**k49, refused.** A bound string with a character beyond ASCII is corrupted at
any length (measured 2026-10-08; MSSQL 2022 16.0.4295.3, DBD::Sybase 1.27 /
FreeTDS 1.3.17): FreeTDS sends it as a fixed CHAR of its length in client
bytes, converted to the server's code page, and the server pads it with
blanks (`ä` arrives as `ä` + one blank, `€` + two); a character the code page
lacks (CJK, beyond the BMP) is refused by the client library after the row has
been written, with blanks for the whole value. No bind type, `CAST` or setting
helps; the rewriting that works (hex of the UTF-16 bytes, a `nvarchar`
expression, options O1 to O4 of the card) changes what a condition compares and
whether an index is used, and was not built.

- The storage throws before anything is sent: **beyond ASCII is a question of
  characters** (a byte string with a byte above 0x7F counts), an object is
  looked at as its string form. The message gives the position among the
  binds and, when known, the column, the cause and DBD::ODBC /
  `DBIO::MSSQL::Storage::ODBC` as the way out; never the value, a password or
  the DSN.
- Holds for `INSERT`, `UPDATE`, `DELETE`, conditions, literal SQL with binds,
  `EXEC`; `populate` in void context refuses before its first row
  (`_bulk_text_values`).
- Not refused: NULL, a value for a binary column (k50: its hex form), a value
  of more than 4000 bytes (k40: a literal, exact), ASCII.
- Applied for the whole class, FreeTDS or not (only FreeTDS was measured).
  Introspection or deploy queries that bind a non-ASCII name over this
  transport are refused too.
- Not touched: the NoBindVars class (core's plain literal: `?` for a character
  the code page lacks, noted on k40), and a statement on the handle (k51).
- What was `t/63`'s "1333 euro signs are a placeholder" (3999 bytes, under the
  line) is a refusal now; the claim of that block, that the line is drawn in
  bytes, stands (1334 euro signs are a literal).
- Over DBD::ODBC on the test host (plain DBI, 2026-10-17, fresh connection per
  value): `€` is exact in `VARCHAR` (0x80) and `NVARCHAR`; `ä`, `aäb`, CJK and
  the emoji are refused by the FreeTDS ODBC driver with errors of its own
  ("Character set conversion is not available between client character set
  ... and server character set", "Error converting characters into server's
  character set"), the handle then answers "Invalid cursor state". Loud, not
  silent; the client character set is an environment matter (k58: "Strings
  beyond the code page over DBD::ODBC").

**k55, fixed.** DBD::Sybase binds an empty string as one blank
(`dbdimp.c`; ASE has no empty string). Bound, `''` was stored with `DATALENGTH`
1 in `VARCHAR`/`TEXT`, 2 in `NVARCHAR`, and `LIKE ''` found the row of the
blank. Option L of the card: `_rewrite_binds` writes the literal `''` where the
placeholder stood.

- Nothing of a value is in the statement; the trace is as it was (placeholder,
  value through `redact_bind_value`).
- `EXEC` with `''` throws (RPC drops what stands around the placeholder; the
  procedure would be handed a blank). A `?` that is no placeholder beside `''`
  throws (count check, as k40). `populate` in void context goes row by row in
  one transaction when a row has `''`. NULL stays NULL, a bound `' '` stays
  one blank.
- Measured live on both access paths, one set of expectations (t/82):
  `DATALENGTH` 0 in `VARCHAR`, `NVARCHAR`, `NVARCHAR(MAX)`, `TEXT` for create,
  update, populate (void and list); `LIKE ''` finds the empty row only; `= ''`
  and `IN ('', ...)` also find the blank row, by the server's ANSI padding,
  over ODBC as well. Other types as over ODBC: `INT` 0, `DATETIME`
  1900-01-01, `CHAR(5)` five blanks, `DECIMAL` Msg 8114.

### Support matrix

DBD::ODBC is the supported way; DBD::Sybase over FreeTDS is restricted. The
same table is in the POD of `DBIO::MSSQL::Storage::Sybase` and of
`DBIO::MSSQL::Storage::ODBC`. A card that changes a row changes it in all three.
Rows only with a measured answer; every row is held by a test (the card names
it).

| Case | DBD::ODBC (supported) | DBD::Sybase / FreeTDS (restricted) |
|------|-----------------------|-------------------------------------|
| Bind of > 4000 bytes | bound, whole | literal in the statement, whole (k40) |
| Bind beyond ASCII, into a column that is `NCHAR`/`NVARCHAR`/`NTEXT` **on the server**: declared `nchar`, `nvarchar`, `ntext` — and `text`, `varchar`, `string`, `char`, which DBIO deploys as national (`_server_data_type`) | exact: `SQL_WLONGVARCHAR`; the ODBC client character set must be UTF-8, else the string is **refused** (k58). A string that already is UTF-8 bytes is **encoded a second time**, silently — it cannot be told from text (documented, not fixable) | **refused**, naming DBD::ODBC (k49) |
| Bind beyond ASCII, into a real `VARCHAR`/`CHAR`: declared `varchar(n)`, `char(n)`, `varchar(max)` | what the code page has is exact; what it lacks is refused by the driver (loud; the driver's connection is then abandoned by core, with warnings; k58) | **refused** (k49) |
| Empty string `''` | exact | fixed: literal `''` (k55); `EXEC` refused |
| Binary values, writing | `SQL_LONGVARBINARY` (k50) | hex pieces, 2099 placeholders per statement; `EXEC` refused (k50) |
| Binary values, reading | bytes; `LongReadLen` 1 GiB unless set (k61) | bytes through `CAST AS IMAGE` up to `TEXTSIZE`; a longer value **refused** (k56, k47) |
| `TEXT`, `NTEXT`, `VARCHAR(MAX)`, `NVARCHAR(MAX)`, reading | whole by default (k61); an explicit small `LongReadLen` throws beyond it, but a value **at** the boundary comes back with a NUL for its last character (TODO tests, upstream draft) | whole up to `TEXTSIZE` = `LongReadLen` (32768); a longer value **refused**, exactly (k47). On the handle / in literal SQL: cut without an error (limit) |
| Empty LOB value, memory | none (k60) | `NTEXT`/`MAX` types (a declared `text` too): none; binary columns: `LongReadLen` bytes each (k60) |
| `SQL_VARIANT` column | read (a binary value as hex digits, as text) | **refused** (k59): rows with a binary base type are lost |
| `IMAGE` as hex above `TEXTSIZE`/2; `VARBINARY(MAX)` on `dbh_do` | n/a | row lost, no error (limit, k59; upstream draft) |
| `HIERARCHYID`, `GEOGRAPHY`, `GEOMETRY` | refused by the driver | refused (`ct_describe` failed), loud |
| Transaction with an open cursor | cursor before: commit and rollback right, core warns that it abandoned the handle; cursor inside: the next statement is refused, rolled back (t/78) | `BEGIN TRAN` and `COMMIT` throw, nothing is sent; `ROLLBACK` ends the cursor and rolls back on the same connection (dbio-sybase k65, k43; t/61) |
| Binds on `dbh_do` / `on_connect_do` | DBD binds as it is | not covered; the caller has the handle (k51, decided) |
| Private subclass pinned by `storage_type` | core warns | refused (k42, k43) |
| `$rs->explain` | refused, "no plan over ODBC": the prepared `SET SHOWPLAN_ALL ON` does not outlive its prepare and the query would run (k71; live 2026-10-19; t/56) | the 18-column plan for a query without placeholders; with placeholders it dies in execute (k71; live half of t/56 written, not yet run) |
| Key of a new row, trigger on the table | `SCOPE_IDENTITY()` | `SCOPE_IDENTITY()` (k39; was `@@identity` over FreeTDS: the trigger's key) |
| `populate` (void) with a row the server refuses (Msg 8114) | throws, nothing of the data set stays | same (k62; the tuples after the failing one used to stay) |
| NoBindVars class: `populate` in void context | n/a (binds) | row by row in one transaction (k57); core's fast path threw |
| NoBindVars class: pinned to `::Sybase` with storage layers | n/a | decision taken, layers kept (k48) |
| NoBindVars class: `''` for an `INT` column | exact (`0`) | core's literal is unquoted, the server refuses it (Msg 102, loud; k63, core's) |

### The key of a new row (k39)

`DBIO::MSSQL::Storage::Sybase::_init` used to set `_identity_method('@@identity')`
and `_no_scope_identity_query(1)` for FreeTDS above 0.82. `@@identity` is the
last identity of the *session*; a trigger that inserts into another IDENTITY
table overwrites it, and `create()` returned that table's key (1000 for the
row 1) — an existing row of the wrong number, nothing failing until the next
update or delete. `SELECT SCOPE_IDENTITY()` (the statement's own scope, the
base class's way) works over FreeTDS 1.3.17, measured live in t/60 part C with
the trigger, on both DSN forms. The workaround is removed for every FreeTDS
version; **only 1.3.17 is measured** — an older FreeTDS that cannot take the
trailing `SELECT` would show as a missing key, and a workaround for *that*
version would be a deliberate choice, not for everything above 0.82. Statement
caching stays off. Mutation: turning the appended `SELECT SCOPE_IDENTITY()`
into `@@IDENTITY` makes t/60 part C fail with 1000. DBD::ODBC was not
measured with a trigger (it never had the workaround).

### A refused statement rolls the transaction back (k62)

Measured 2026-10-17, plain DBI first, then through the storage; MSSQL 2022
16.0.4295.3, DBD::Sybase 1.27 / FreeTDS 1.3.17, DBD::ODBC 1.61 / tdsodbc
1.3.17 (`t/74-failed-populate-live.t`).

- **The server rolls the whole transaction back on Msg 8114** (a bound value
  that cannot be converted, `'abc'` for a `DECIMAL`): `@@TRANCOUNT` goes 1 to 0
  on the failing statement, over both DBDs; the rows before it in the
  transaction are gone, and a `ROLLBACK` after it is refused (Msg 3903). DBIO's
  `transaction_depth` still says 1. This mismatch is what k62 saw as "deferred
  rollback, every further operation throws" — core's discard of a handle whose
  rollback failed (core k303, 2026-10-13) makes the connection usable again:
  a failing single-statement `populate` or `create` leaves depth 0, no
  deferred rollback, `@@TRANCOUNT` 0, and the next statements, `populate` and
  `txn_do` work, on both access paths. **The card's symptom does not
  reproduce on today's tree**; not a driver defect.
- **What was a defect, and the driver's:** core's void-context `populate`
  executes the rows with `execute_for_fetch`, which DBI runs to the *end* of
  the data after a failing tuple. After the server's rollback the later
  tuples ran in autocommit and were committed: `populate([good, bad, good])`
  threw and left the third row (both access paths). `DBIO::MSSQL::Storage::
  _dbh_execute_for_fetch` hands core a `DBIO::MSSQL::Storage::StopAtFirstError`
  handle, which stops at the first tuple whose status is an error. Nothing of
  the data set stays. The row-by-row path of the DBD::Sybase class (empty
  string, long or binary value, NoBindVars) stops at the exception anyway.
- **Not changed:** a failing statement *inside a user's `txn_do`* whose
  exception the block catches: the server has rolled the transaction back,
  DBIO believes depth 1, the statements after it run in autocommit and the
  final `COMMIT`/`ROLLBACK` is refused (Msg 3902/3903; over ODBC the driver
  reports "has not implemented the AutoCommit attribute"). That is the
  catch-and-continue pattern against a server that dooms the transaction; core
  discards the handle on the failed rollback. Left as it is (measured in a
  script, not pinned by a test); do not catch such an exception inside the
  transaction block.

### The NoBindVars class (k57, k48, k63)

`DBIO::MSSQL::Storage::Sybase::NoBindVars(::FreeTDS)` is what a DBD::Sybase
connection without placeholders gets (`_adapt_to_placeholder_support`; live it
is reached by `_use_typeless_placeholders(0)` before the first use, t/84).

- **k57**: core's fast path of `populate` in void context threw "Unable to
  invoke fast-path insert without storage placeholder support" for every data
  set, pure ASCII included (measured offline t/83, live t/84): the values were
  interpolated, so `_prep_for_execute` returns no binds. `_insert_bulk` of
  `DBIO::MSSQL::Storage::Sybase` inserts row by row in one transaction there
  (`_insert_rows_in_transaction`, the way it already did for k40/k50/k55 data
  sets); a refused row rolls the data set back. None of the bind-based checks
  (non-ASCII refusal, k50 binary) apply: there are no binds, core's literal is
  what it is.
- **k48**: the decision used `ref $self ne __PACKAGE__`, true for a storage
  pinned straight to `::Sybase` with schema storage layers (a
  `DBIO::Storage::Composed` class). It now looks through the composition to
  its base; core recomposes the layers over the NoBindVars class after the
  hook. No `@ISA` change. t/83 and t/84 run declared, pinned and
  pinned+layered.
- **k63**: `''` for an integer column: core's `interpolate_unquoted` writes
  it unquoted (`VALUES ( )`), Msg 102, loud, no row, the connection stays
  usable. Left as it is -- the literal is core's and the same for every
  NoBindVars driver; narrowing `interpolate_unquoted` here would only
  patch one driver around core's rule. Pinned in t/83 and t/84; the
  recommendation for core is `maint/upstream/core-nobindvars-empty-number.md`.

### Binary values

karr k50, measured 2026-10-08 (MSSQL 2022 16.0.4295.3; DBD::Sybase 1.27 /
FreeTDS 1.3.17; DBD::ODBC 1.61 / tdsodbc 1.3.17), through a declared schema
with `VARBINARY(MAX)`, `VARBINARY(8000)`, `BINARY(16)` and `IMAGE` columns.

**Before:** neither storage class had a `bind_attribute_by_data_type`, so a
binary value was bound without a type -- text. Nothing arrived over either
access path: `INSERT`, `UPDATE`, `WHERE col = ?`, `find` on a binary key,
`populate`, at every size from 1 to 100000 bytes. Msg 257 (implicit conversion
from varchar refused) where the bytes happened to pass as characters, the
client library's conversion error where they did not. Over DBD::Sybase a value
over 4000 bytes was taken by the k40 rewriting (the error then came from
the prepare). One
silent case: an empty value in an `IMAGE` column over DBD::Sybase was stored
as one byte, a blank.

**The fix, a bind way on both, nothing of a value in a statement.** Which bind
is a binary one is decided by its data type (`sqlt_datatype` on the bind, from
the column or given in literal SQL), not by the value:
`DBIO::MSSQL::Storage::_is_binary_data_type` -- `binary`, `varbinary`,
`image` and the names `DBIO::MSSQL::DDL` renders as one (`blob`, `bytea`,
`tinyblob`, ...). Not core's `_is_binary_type`, which takes `bit` for binary.
A value is the bytes of the string whatever its UTF-8 flag
(`_binary_value_bytes`); a character above 255 throws before anything is sent.

- **DBD::ODBC** (`DBIO::MSSQL::Storage::ODBC`): `bind_attribute_by_data_type`
  returns `SQL_LONGVARBINARY`. Measured with plain DBI per type, position and
  size: it is the one type exact everywhere -- `INSERT`/`UPDATE` into all
  four column types, `=` against `VARBINARY(MAX)`, `VARBINARY(8000)` and
  `BINARY(16)`, 0 to 100000 bytes (and 4.2 MB through the schema).
  `SQL_VARBINARY` and `SQL_BINARY` cut at 8000 bytes without an error and fail
  on 100000 (HY090); `SQL_BINARY` stores an empty value as one byte;
  `SQL_BLOB` is "Invalid data type". The bytes matter here too: DBD::ODBC
  sends a string with the UTF-8 flag on as its UTF-8 form (600 bytes arrived
  as 862), so `_dbh_execute`/`_dbh_prepare`/`_insert_bulk` hand it the
  downgraded value. `populate` in void context stays one statement; the type
  bound with the first row holds for the rest.
- **DBD::Sybase** (`DBIO::MSSQL::Storage::Sybase`): the DBD ignores a bind
  type outside an `EXEC` (k49), so the value is bound as its hex form and the
  placeholder becomes `CONVERT(VARBINARY(MAX), ?, 1)`. Hooked into the k40
  seam (`_rewrite_binds`, formerly `_inline_long_binds`; computed in
  `_dbh_execute`/`_dbh_prepare`, applied in `_prepare_sth` and
  `_bind_sth_params`), because that is where bind list and statement are both
  at hand after the SQL is built -- which covers conditions, where
  `_prep_for_execute`'s MONEY rewriting of INSERT/UPDATE fields does not
  reach -- and where the trace stays what it was. No `@ISA` change.
  - Style 1 (`0x` + digits), not 2: the bound string is never empty. Style 2
    binds `''`, which DBD::Sybase turns into a blank (works by accident) or,
    with `syb_bind_empty_string_as_null`, into NULL (measured: NULL stored
    for an empty value).
  - One piece is 1999 bytes (4000 characters bound; 2000 bytes in one piece
    lose a byte silently). Pieces are `MAX` and joined as a **balanced tree**:
    joined left to right the server copies the partial result per piece --
    1000 pieces 6.2 s, 1500 pieces 77 s, 2099 not within 120 s; as a tree
    1000 pieces 0.8 s, 2099 pieces (4195901 bytes) 1.5 s.
  - At most 2099 placeholders per statement, all binds together (Msg 8003
    at 2100); the storage throws before sending, with the sizes.
  - Throws as well: an `EXEC` with a binary bind (sent as RPC, the procedure
    would get the hex string), and a statement whose `?` count differs from
    its bind count.
  - `populate` in void context goes row by row in one transaction when the
    data has a binary value (the placeholder count depends on the size).
  - `FORCESEEK` on a `VARBINARY(64)` primary key against the expression
    works: the index is still used.
  - k40's literal no longer sees a binary value; a hex piece is never over
    4000 bytes.

**Not covered, measured:** the NoBindVars class (core's text literal: Msg 257
or a conversion error for every value; only NULL and an empty `IMAGE` value
arrive).
A private subclass of `DBIO::MSSQL::Storage` on a DBD::Sybase handle bound as
text; it is refused since k42 (`docs/adr/0008`).

**Reading** was found on the way and is its own card: "Reading binary
values" below.

Offline in `t/64-binary-bind-values.t`, live per access path in
`t/65-binary-values-live.t`.

### Reading binary values

karr k56, measured 2026-10-08 (MSSQL 2022 16.0.4295.3; DBD::Sybase 1.27 /
FreeTDS 1.3.17; DBD::ODBC 1.61 / tdsodbc 1.3.17), through a declared schema.

**Before, over DBD::Sybase** (`find`, `next`, `all`, a cursor and
`get_column` alike; session `TEXTSIZE` 32768):

| Column | Value | Came back |
|--------|-------|-----------|
| any | NULL, empty | NULL, empty |
| `BINARY(n)`, `VARBINARY(n)` | 1 to 8000 bytes | hex digits, whole |
| `IMAGE` | 1 to 16384 bytes (`TEXTSIZE`/2) | hex digits, whole |
| `IMAGE` | more | **no row, no error** |
| `VARBINARY(MAX)` | 1 byte or more | **no row, no error** |

**The cause** (DBD::Sybase 1.27 `dbdimp.c`, DBI trace 5): the client library
describes `VARBINARY(MAX)` as `CS_BINARY_TYPE` with `maxlength` 2147483647;
`get_cwidth` makes room for the hex digits, `2 * maxlength + 2`, which is 0 in
32 bits, plus one: **a buffer of one byte**. `ct_fetch` answers a row with a
value with `CS_ROW_FAIL` (-203), and `syb_st_fetch` drops such a row unless
`LongTruncOk` is on (then the row comes with one hex digit). An `IMAGE` value
whose hex digits exceed `TEXTSIZE` fails the same way. No attribute changes
it: `syb_binary_images` makes bytes of an `IMAGE` column alone, `LongReadLen`
acts only through the `SET TEXTSIZE` of the FreeTDS class. Not looked at in a
`TDSDUMP`.

**The fix** is in `DBIO::MSSQL::Storage::Sybase` alone, no `@ISA` change:

- `_select` takes what `_select_args` returns and replaces every entry of the
  select list that is a plain column whose `data_type` is a binary one
  (`_resolve_column_info`, `_is_binary_data_type` -- the question k50 asks of
  a bind) by `CAST(<quoted column> AS IMAGE)`, in the list and in the
  `select` of the attributes (the limit dialect builds its subqueries from
  the latter). All binary types, the sized ones too: hex digits were the
  defect. **A caller that decoded hex digits itself now gets bytes.**
- `_execute_sth` has `syb_binary_images` on for the execute of such a
  statement alone (`local`; the DBD decides it when it describes the result,
  in the execute). The handle is as it was afterwards, after a failed execute
  too: what literal SQL and `dbh_do` read from an `IMAGE` column is unchanged.
- **Not in `_select_args`**, which `_select_args_to_query` shares: a subquery
  (`as_query`, `count`, `-in`, a set operation, the subquery of a joined
  `update`/`delete`) keeps the column as it is. An `IMAGE` cannot be compared.
- **A `VARBINARY(MAX)` result column that was not rewritten throws**
  (`_execute_sth`, after the execute, before a fetch, statement finished
  first): decided by how the handle describes it -- `TYPE` -2, `PRECISION`
  2147483647 -- and not by the rows, so a result of NULLs alone throws too.
  That is a function or an expression over such a column
  (`get_column('body')->max`), the column in literal SQL, a column without a
  declared `data_type`. The exception names what to select instead:
  `CONVERT(VARCHAR(MAX), <expression>, 2)`. The check costs one
  `NUM_OF_FIELDS` for a statement without a result (0.4 microseconds) and
  three attributes for a result (2.9 microseconds for 8 columns), against 5 ms
  for a `single()`.
- Nothing is decoded; no cursor class. The trace shows the statement as it is
  sent.

Measured through the schema, exact bytes (length and SHA-256 against the
server): `find`, `single`, `first`, `next`, `all`, `cursor->next`,
`get_column->all`, HashRefInflator; `rows`, `rows` + `offset`, `order_by` on
the binary column; prefetch over `belongs_to` and `has_many` (with `rows`
too), `join` + `+columns`, an alias; `distinct`, `group_by`, `union`,
`union_all`, `as_subselect_rs`; `retrieve_on_insert`; `create` +
`discard_changes`; a binary primary key -- `find`, `$row->update`,
`get_from_storage`, `find_or_create` (before: "Can't update", not found
again); `count` unchanged; `update`/`delete` by a binary value as k50 left
them; the NoBindVars class.

**Limits, measured:**

- A value arrives whole up to the `TEXTSIZE` of the session (`LongReadLen`,
  32768 unless the connect info says otherwise). It was **cut to it without an
  error** beyond; since k47 it is **refused** (the column is behind the guard,
  "Values longer than TEXTSIZE" below; t/65 and t/77 hold it). With
  `LongReadLen => 5000000`: 4195901 bytes exact.
- **An empty value costs `TEXTSIZE` bytes of memory**: the client library
  fills the whole buffer of an empty `IMAGE` (48 MB at `TEXTSIZE` 50000000;
  an empty `TEXT` four times that; `VARCHAR(MAX)` nothing). Nothing at 32768.
  With an unlimited `TEXTSIZE` -- plain DBI, a private subclass of the base
  class -- a row with an empty `TEXT` value was killed at a 1 GB cap. Kept for
  binary columns (they are IMAGEs); TEXT and NTEXT no longer pay it (k60).
- `IMAGE` is a deprecated type, and cannot be compared: a `DISTINCT` written
  in literal SQL beside a rewritten column is refused by the server (Msg 421;
  with a `VARBINARY(n)` column that statement ran before, and gave hex
  digits). `distinct => 1` is a `GROUP BY` over the column as it is, and
  works.

**Not reached, measured:**

- A `BINARY(n)`, `VARBINARY(n)` or `IMAGE` value that is not the column
  itself -- `get_column('sized')->max`, `HASHBYTES(...)`, literal SQL, a
  column without a declared `data_type`: hex digits, as before (lower case
  from the client library). A hand-written `CAST(col AS IMAGE)` too.
- `dbh_do`: hex digits, no rows for `VARBINARY(MAX)`, nothing refused (k59:
  pinned in t/77, a limit).
- An `IMAGE` read as hex digits (literal SQL, a function, a column without a
  declared type) above `TEXTSIZE`/2 bytes loses its row: 16384 bytes read,
  16385 do not (k59: pinned in t/77, a limit; a refusal would hit results that
  read right).
- A private subclass of `DBIO::MSSQL::Storage` on a DBD::Sybase handle: it
  read the same way; refused since k42 (`docs/adr/0008`).

**Other carriers, measured and not used:** `CONVERT(VARCHAR(MAX), col, 2)`
is exact to `TEXTSIZE`/2 bytes and cut without an error beyond (and would
need decoding at three fetch sites); `CAST(col AS VARBINARY(8000))` is cut at
8000 bytes by the server; `CAST(col AS VARCHAR(MAX))` goes through the
character set conversion.

**DBD::ODBC** reads every binary type as its bytes, up to `LongReadLen`, and
throws beyond ("long truncated"). The ODBC class set nothing here until k61;
it takes 1 GiB now unless the connect info names one ("LOB values over
DBD::ODBC"); t/65 still connects with one of its own.

**Found on the way** (plain DBI over DBD::Sybase), then measured by k59: a
`SQL_VARIANT` column loses its row the same silent way (refused since k59); a
`GEOGRAPHY` or `HIERARCHYID` column is not described at all ("ct_describe()
failed", loud). See "SQL_VARIANT and the other types" below.

Offline in `t/66-binary-read-values.t`, live per access path in
`t/65-binary-values-live.t`.

### Strings beyond the code page over DBD::ODBC (k58)

Measured 2026-10-17 (MSSQL 2022 16.0.4295.3, collation
`SQL_Latin1_General_CP1_CI_AS`; DBD::ODBC 1.61 **built without Unicode
support** — `odbc_has_unicode` is 0, a string goes to the driver as bytes, and
a string with the UTF-8 flag on as its UTF-8 form — over tdsodbc 1.3.17), first
with plain DBI on a fresh connection per value, then through a schema.
Offline `t/75-odbc-unicode-binds.t`, live `t/76-odbc-unicode-binds-live.t`.

- **Before:** a bound string is a CHAR to the driver, converted into the code
  page of the server whatever the column is. CJK, an emoji and anything the
  code page lacks were refused by the driver ("Error converting characters
  into server's character set") **even for an NVARCHAR column**, which could
  have held them; `€` and `ä` were stored (both are in code page 1252). After
  the first refusal the driver's connection answers "Invalid cursor state" to
  everything (core then abandons the handle with a warning, twice: during the
  failed statement's rollback and at the next statement).
- **Bind type:** `SQL_WLONGVARCHAR` (-10) carries the value exact into `NCHAR`,
  `NVARCHAR`, `NVARCHAR(MAX)` and `NTEXT`, from 1 to 100000 characters, in
  `INSERT`, `UPDATE` and conditions, flagged or not. `SQL_WVARCHAR` (-9) is cut
  at 4000 characters **without an error** from `NVARCHAR(MAX)` on, `SQL_WCHAR`
  (-8) pads. Into a `VARCHAR` column a Unicode bind turns what the code page
  lacks into `?` silently. So `bind_attribute_by_data_type` of the ODBC class
  answers `SQL_WLONGVARCHAR` for `nchar`/`nvarchar`/`ntext` only; `VARCHAR`
  keeps the driver's refusal (loud, no row).
- **A string is its characters.** A string made with `"\x{E4}"` has no UTF-8
  flag, and the driver would take its one byte for a broken UTF-8 sequence
  ("Character set conversion is not available ..."). The storage hands the
  driver every text bind beyond ASCII with the flag on (`utf8::upgrade` of a
  copy; binary values are bytes and untouched). Text that is already UTF-8
  bytes must be decoded first, or it is encoded twice.
- **The client character set decides, silently.** With `ClientCharset=ISO-8859-1`
  in the DSN — or a C locale, where FreeTDS takes it from the locale — the
  UTF-8 bytes are read as Latin-1: `ä` is stored as `Ã¤`, with or without a bind
  type, without an error. Measured with plain DBI. The storage asks the
  connection once per handle, when it is made (karr k81: before, ahead of the first
  string beyond ASCII; the answer decides `odbc_utf8_on` for reading too),
  `SELECT UNICODE(CAST(? AS NVARCHAR(10)))` with an a-umlaut bound as
  `SQL_WLONGVARCHAR`: 228 means UTF-8; anything else **refuses** every string
  beyond ASCII, naming `ClientCharset=UTF-8` (no value, DSN or password in the
  message, `t/75`, `t/76`). Never refused for ASCII, NULL, an empty string or a
  binary value; not asked at all of a DBD::ODBC built with Unicode support.
- **Reading returns characters (karr k81, t/123 live, t/124 offline):** the same
  DBD returned the UTF-8 bytes without the flag (`length` of an a-umlaut 2, CJK
  3 each) -- a silently wrong value. `DBIO::MSSQL::Storage::ODBC::_run_connection_actions`
  now sets `odbc_utf8_on` on the handle (every connection, reconnects too) once
  `_client_charset_is_utf8` says the client character set is UTF-8; not for a DBD::ODBC
  with Unicode support, not when the connect info names `odbc_utf8_on` (the caller's
  choice, `0` gives bytes). Binary columns stay bytes. Read-back of
  NVARCHAR/NTEXT/VARCHAR (code page) is the written string with the flag on.
- Core's DBI exception text carries `ParamValues` of the statement (the
  values), for every error. Core's, not looked at here.
- The refusal message of the DBD::Sybase class (k49) now says what ODBC does and
  does not take.

### Values longer than TEXTSIZE over DBD::Sybase (k47, k60)

Measured 2026-10-17 (DBD::Sybase 1.27 / FreeTDS 1.3.17, MSSQL 2022; plain DBI,
then through a schema). Live `t/77-long-values-live.t`, offline `t/66`.

- **The cut.** The FreeTDS class sets `SET TEXTSIZE` = `LongReadLen` (32768).
  The server cuts a longer value of `TEXT`, `NTEXT`, `IMAGE`, `VARCHAR(MAX)`,
  `NVARCHAR(MAX)`, `VARBINARY(MAX)` exactly at TEXTSIZE **bytes**: 32768
  characters of a VARCHAR(MAX), 16384 of an NVARCHAR(MAX) (value lengths
  32767, 32768 whole; 32769 cut). Sized `VARCHAR(n)`/`NVARCHAR(n)`/`VARBINARY(n)`
  (8000 bytes whole under a TEXTSIZE of 100) and `XML` (50007 characters under
  32768) are not subject to it. A sized binary column read as an IMAGE (k56) is.
- **The way built: a guard the server runs.** `_select` reads a column of a
  result source that is, **on the server**, an `NTEXT`, a `(N)VARCHAR(MAX)` or
  binary, behind
  `CASE WHEN DATALENGTH(col) > @@TEXTSIZE THEN <failing CONVERT(INT, 'message')>
  ELSE col END`. What the column is on the server is what the DDL deploys the
  declared type as, asked of the one table (`DBIO::MSSQL::Storage::_server_data_type`
  → `DBIO::MSSQL::DDL::_mssql_column_type` → `DBIO::MSSQL::Adapter`), shared
  with the ODBC bind type (k58): declared `text` is an **NVARCHAR(MAX)**, not a
  TEXT, and so is a `varchar`/`string` of size -1; only `varchar(max)` (the
  server's spelling) is a VARCHAR(MAX). A `text` column used to be read as TEXT
  through `CAST(.. AS VARCHAR(MAX))`: CJK and emoji arrived as `?`. Measured
  2026-10-18 (t/80): they arrive unchanged now. A real TEXT column cannot be
  declared; a `text` declaration over a legacy TEXT reads (CASE .. ELSE col)
  but pays the empty-value memory price of k60.
  **Bytes:** TEXTSIZE counts an NVARCHAR(MAX) at two bytes per character, so
  16384 characters fit under 32768 and 20000 are **refused** (not cut), read
  with a `LongReadLen` ≥ 40000 (t/80). Open question, not decided: reading
  more characters under the default would need a UTF-8 collation (SQL Server
  2019+).
  **NULL (2026-10-18):** `SESSIONPROPERTY('CONCAT_NULL_YIELDS_NULL')` is 1 on a
  fresh session over dbi:Sybase:, so the old concatenation guard kept NULL as
  NULL by default; with `SET CONCAT_NULL_YIELDS_NULL OFF` (on_connect_do) a NULL
  in a VARCHAR(MAX) or NVARCHAR(MAX) column became `''` (measured, plain DBI and
  through the schema). The guard returns the column itself in its ELSE branch now,
  of the failing branch's type, so NULL stays NULL under both settings (t/79, t/80). A value of exactly TEXTSIZE bytes is whole, one byte more
  fails the statement with Msg 245 whose text carries the message;
  `throw_exception` of the Sybase class puts it into words (column, size,
  "connect with a LongReadLen of at least ..."). No false alarm, and no fetch
  site to miss (cursor, `single`, `get_column`, HashRefInflator, prefetch, rows;
  a long value not in the first row fails the whole read).
  Measured while building: a `CASE` between a VARCHAR(MAX) and an NVARCHAR(MAX)
  branch hands the value over as NVARCHAR, which TEXTSIZE cuts at **half the
  characters the guard looks for** — a 20000-character VARCHAR(MAX) came back
  as 16384, silently. So VARCHAR(MAX)/NVARCHAR(MAX) stay the type they are
  (the type is known now, the failing branch is of that type: `CASE WHEN ...
  THEN CONVERT(<type>, <fail>) ELSE col END`). NTEXT is cast to NVARCHAR(MAX)
  (a CASE cannot return one).
- **Not reached (pinned as limits in t/77):** the handle directly (`dbh_do`),
  literal SQL, a function or expression over the column, a column without a
  declared LOB data type, subqueries. Cut to TEXTSIZE without an error, as
  before.
- **Ways measured and not taken:** raising the TEXTSIZE default (see k60 — an
  empty binary value then costs that much per column; unlimited killed the
  process at a 1 GB cap) and checking the length of fetched values on the
  client (the cut point depends on the type: TEXTSIZE/2 characters for
  national columns, and the client only sees UTF-8 bytes; three fetch sites).
  Recommendation, not a decision: keep 32768; `LongReadLen` stays the regulator
  and now says so when it is too small.
- **k60, the price of an empty value** (plain DBI, TEXTSIZE 50000000): empty
  TEXT +191 MB, NTEXT +95 MB, IMAGE +48 MB, VARCHAR(MAX)/NVARCHAR(MAX)/XML
  +0; one byte and NULL +0; nothing at 32768. Behind the guard NTEXT is a
  MAX type and pays nothing, and so is a declared `text` (an NVARCHAR(MAX);
  t/77: under 20 MB at LongReadLen 50000000). A binary
  column is an IMAGE and pays about LongReadLen bytes per column of a result
  while the handle lives (t/77 pins it as a documented limit); `NULLIF` would
  turn an empty value into NULL, hex digits need decoding at every fetch site.

### SQL_VARIANT and the other types over DBD::Sybase (k59)

Measured 2026-10-17, `t/77`, upstream draft `maint/upstream/dbd-sybase-row-fail.md`.

- `SQL_VARIANT` is described `TYPE` 1, `PRECISION` 8009 (no CHAR/VARCHAR/NCHAR/
  NVARCHAR has it: the client library gives four times the length). A variant
  with a text, number or date base type reads. A variant with a binary base type
  loses its row without an error when it is the first row of the result, comes
  back as the hex digits as text when rows were fetched before it; two of them
  alone: both lost. The base type of the rows is not known before they are, so
  `_execute_sth` refuses any result column described that way, after the
  execute and before a fetch, naming the position and the column and the forms
  to select instead (`CONVERT(VARCHAR(8000), x)`, `CONVERT(VARCHAR(MAX),
  CONVERT(VARBINARY(8000), x), 2)`, `SQL_VARIANT_PROPERTY`). A false alarm for a
  column that holds no binary variant is the price. DBD::ODBC reads the column.
- Not refused, documented limits with tests: an IMAGE read as hex digits above
  TEXTSIZE/2 bytes (16384 read, 16385: no row) — a refusal would hit results
  that read right; a VARBINARY(MAX) on the handle directly.
- Measured, nothing to do: `DECIMAL(38,x)` exact, `NUMERIC`, `MONEY`,
  `DATETIME2(7)`, `DATETIMEOFFSET`, `TIME(7)`, `DATE`, `UNIQUEIDENTIFIER`, `BIT`,
  `ROWVERSION`, `XML` (also past TEXTSIZE), `VARCHAR(8000)`, `NVARCHAR(4000)`.
  `HIERARCHYID`, `GEOGRAPHY`, `GEOMETRY`: "ct_describe() failed", the execute
  returns false; the storage's "execute() returned false" is the error, loud.
  A CLR type of an assembly of one's own: not measured (CLR is not on the test
  server).

### LOB values over DBD::ODBC (k61)

Measured 2026-10-17 (DBD::ODBC 1.61 / tdsodbc 1.3.17), `t/77`, upstream draft
`maint/upstream/dbd-odbc-longreadlen-boundary.md`.

- With DBI's `LongReadLen` 80 every LOB type — TEXT, NTEXT, VARCHAR(MAX),
  NVARCHAR(MAX), VARBINARY(MAX), IMAGE, XML — throws "long truncated" beyond it
  (XML already at 79 characters of content). Loud, but a schema with a LOB
  column was unreadable past 80 bytes.
- **At the boundary it is not loud.** `LongReadLen` N: a VARCHAR(MAX), TEXT or
  NTEXT value of N + 1 characters and an NVARCHAR(MAX) value of N come back with
  the last character replaced by a NUL, no error (N + 2 and N + 1 throw; binary
  types are exact at N, throw at N + 1). Measured at N = 10, 80, 32768.
- **A large `LongReadLen` cost nothing in the measurement** (no memory for an
  empty or short value at 50000000 and 2147483647, 5 MB values whole, 20000
  rows of TEXT no slower) -- **but it has a price, and only overcommit hides
  it** (hub check 2026-10-18): DBD::ODBC 1.61 allocates a buffer of
  `LongReadLen` bytes per LOB column per statement handle (`dbdimp.c`,
  `bind_columns`; twice that for NVARCHAR(MAX)/XML in the Unicode build). With
  `vm.overcommit_memory=2`, `ulimit -v`, or many LOB columns: "Out of
  memory!", not catchable; cached statements multiply it. Maintainer: 1 GiB
  stays the default; the POD says so ("The price of 1 GiB"). So `DBIO::MSSQL::Storage::ODBC::_run_connection_actions` sets
  `LongReadLen` to 1073741824 on every connection unless the connect info names
  one (`_dbio_connect_attributes` has the key). The storage becomes the ODBC
  class after the first connect, so the default attributes cannot carry it; the
  handle is set, a reconnect too. This takes the boundary out of reach; an
  explicit small `LongReadLen` brings it back (four TODO tests in t/77).
- The Sybase path has 32768 and refuses beyond; the ODBC path has 1 GiB and
  reads everything that fits memory. Both: no value is cut without being said.

## Conformance (core ADR 0060, karr k71)

`DBIO::MSSQL::Test::Conformance` answers core's shared DDL, Diff and Bind case tables (DDL: t/85 offline,
t/86 live, t/89 namespace token; Diff t/117 + t/118; Bind t/119 + t/120). `conformance_answered_through` is a hash,
`{ DDL => 2, Diff => 4, Bind => 1 }` (karr k81, core k399). `conformance_upgrade` connects the to-class to the database of the case
(`%DATABASE`, `_dsn_for`) and runs `upgrade(allow_destructive => 1)` of DBIO::Deploy::Base, whose checks the driver answers in
`_check_before_apply` (core ADR 0080); `conformance_deploy` runs the deploy cases. Its cleanup closes only its own connection. Diff (23 cases):
`diff-view-added/-dropped/-definition-changed` answered right (karr k82), `diff-column-added-not-null-populated` and `diff-not-null-over-nulls` server refusals
(`Deploy::_refuse_unfillable`: Msg 4901 / 515, before the server; without it the doomed txn made txn_do run twice and say
"disconnected"), `diff-default-removed` answered right (karr k83: `Diff::Column` drops the default constraint by its live name; core k367 reports it). Bind (10): deviation
`bind-empty-string` (`''` for int is 0 on SQL Server); `bind-non-ascii` is right over DBD::ODBC (reads characters, `odbc_utf8_on`, k81);
over DBD::Sybase it is a refusal (k49) and the connect names `LongReadLen` 1000000 (k47). `DBIO::MSSQL::Storage::Sybase` names
`DBIO::MSSQL::Deploy` as `dbio_deploy_class` (DBIO::Sybase::Storage precedes the base in the MRO and would deploy ASE DDL).
DDL: of the 20
cases 17 are right (`ddl-qualified-source-name` since karr k72: `other.t` is made in
the schema `other`, see "Schemas" below; `ddl-type-size-char`), `ddl-enum-value-apostrophe` and
`ddl-type-size-bit` are refused (no enum type; `bit` has no size) and
`ddl-default-digit-string` (`char(n)` pads) is a declared deviation. The namespace of a case is a
**database** `dbio_cf_<pid>_<n>`, not a schema: a connection cannot be bound to a
schema and a table without schema lands in `dbo`, so a schema would leave the diff
counting foreign tables. `conformance_namespace` creates it and returns a token; cleanup drops
only what the token names (core runs cleanup even after a refused namespace).
`install_ddl` writes FOREIGN KEYs (`ALTER TABLE .. ADD CONSTRAINT FK_..`), named
unique constraints, string DEFAULTs as literals (an expression is a scalar ref),
and quotes names through `DBIO::MSSQL::DDL::_quote_ident` (reserved words,
non-identifier names; case kept).

Refused before the server, all `DBIO::Exception` with the word "refus", naming
table and column or relationship: a table or view name with other than one dot (k72, a
name qualified with a database);
foreign keys SQL Server rejects with Msg 1785 (self-reference with an action,
cycles, two cascading paths to one table; rule measured in
`t/95-ddl-refusals-names-live.t`, run by `install_ddl` and by `Diff` over its
target model, `DDL::_check_cascade_paths`); `enum`; a size on `bit`/`bool`/
`boolean` (types are compared after lower-casing, folding blanks and taking off
`(n)`; the SQL standard spellings `char varying`, `national character
varying`, `binary varying` ... keep their size). Names: an undeclared unique
constraint (core's `<table>_<columns>`) is written `UQ_<table>_<columns>`, a
declared name stays; `FK_`/`UQ_` names over 128 characters end in 8 hex digits
of their SHA-1 (`DDL::_constraint_name`). A `belongs_to` to a view is skipped,
not refused: `belongs_to` defaults `is_foreign_key_constraint` to 1 itself, so
explicit and default cannot be told apart, and core's test schema declares one
(Track to Year1999CDs).

## No values in error texts (core ADR 0075, ADR 0009)

`DBIO::MSSQL::Storage::_mask_error_values` runs `DBIO::MSSQL::Util::mask_error_details` (form rules: conversion
failed / overflowed column / duplicate key value / truncated value / `near '...'` / JSON character, one rule each,
names stay) and then core's `next::method`. Offline `t/128` (rules) and `t/130` (override), live per access path incl.
NoBindVars `t/129`. `RAISERROR`/`THROW` texts of the application and `$dbh->errstr` stay raw.

## Storage Wiring

```perl
__PACKAGE__->datetime_parser_type('DBIO::MSSQL::Storage::DateTime::Format');
__PACKAGE__->new_guid('NEWID()');
sub dbio_deploy_class { 'DBIO::MSSQL::Deploy' }
sub deploy_setup { }   # no-op stub
```

## Testing

Offline tests use `DBIO::Test::Storage`, need no server, and run recursively under the
resource cap of the house rules (`t/` has subdirectories):

```bash
../dbio/maint/capped-test prove -lr t/
```

Live tests run against the database that `dbio-db env mssql` hands out (house rules,
*Live testing* and *Maintainer-only live infrastructure*); never `prove -j`:

```bash
eval "$(<cihq-ocp>/umgebungen/dbio/dbio-db env mssql)"
../dbio/maint/live-preflight && ../dbio/maint/capped-test prove -lr t/
```

Without that infrastructure, set the variables yourself against any SQL Server. Which
live files run depends on them:
```bash
# DBD::ODBC over the FreeTDS ODBC driver (t/11, t/21, t/30, t/65, t/82, t/72, t/76, t/77, t/78, live block of t/56)
DBIO_TEST_MSSQL_ODBC_DSN='dbi:ODBC:Driver=FreeTDS;Server=<host>;Port=1433;Database=tempdb;TDS_Version=7.4'
DBIO_TEST_MSSQL_ODBC_USER=sa
DBIO_TEST_MSSQL_ODBC_PASS='...'
# DBD::Sybase (t/10, t/20, t/30, t/60, t/61, t/65, t/82, t/77)
DBIO_TEST_MSSQL_DSN='dbi:Sybase:...'
DBIO_TEST_MSSQL_USER=sa
DBIO_TEST_MSSQL_PASS='...'
```

The ODBC DSN names the driver, not a data source: `Driver=FreeTDS` is the
`[FreeTDS]` entry of `/etc/odbcinst.ini` (package tdsodbc), so nothing has to
be in `odbc.ini`. `dbi:ODBC:DSN=<name>` works as well where a data source is
set up. The login is the one DBD::Sybase
uses. Both access paths run live, DBD::Sybase and DBD::ODBC.

`t/10-mssql.t` and `t/20-mssql-core.t` need DBD::Sybase (DBD::ODBC+FreeTDS won't
work for those). They need DBD::Sybase (compiled against FreeTDS) and a named
server in `freetds.conf`, see "Live test status" below.

### The test database

A crashed run leaves `_dbio_*` databases behind. They survive a server restart and nothing
cleans them up. Check with `SELECT name FROM sys.databases WHERE name LIKE '[_]dbio[_]%'`
and drop them. `maint/k8s/mssql-dev.yaml` is the
manifest `dbio-db` starts the standing database from.

### Generic DSN detection is gone

Retired by core ADR 0067 (core k308, here karr k69). A schema without a declared driver
is refused at connect; core calls no `_rebless` and has no connector registry.
`DBIO->driver_for` names the exact driver of a DSN: `dbi:ODBC:` throws (the DBD names no
driver), `dbi:Sybase:` answers `Sybase` (ASE) — the declaration is the only way into this
driver's classes (pinned in t/62 section 2). Every test schema declares the driver; the
shared `DBIO::Test::Schema` gets `storage_type('+DBIO::MSSQL::Storage')` in the live files.
`DBIO::MSSQL::Storage::Sybase::_rebless` stays for an older core only; it goes when the
core requirement is raised and dbio-sybase drops its `_rebless`.

### `on_connect_call` options

`t/11` + `t/21` loop over the `on_connect_call` options
`use_dynamic_cursors` / `use_mars` / `use_server_cursors` and `plain`. No DBIO
distribution has a `connect_call_*` handler for the first three (the
DBIx::Class ones were ODBC-only and were not ported, see karr k13 below), so
the test pre-skips them with a `can("connect_call_$_")` check and `last SKIP`
to abort the iteration cleanly (otherwise the iteration continues to `dbh_do`
and exits 255). Only `plain` runs, and with it the "multiple active
statements" block of these two files never does (measured over ODBC,
2026-10-07, karr k52: 4 skips per file). The TODO marker for "freetds with
dynamic cursors" in the MONEY section sat behind that skip and could not be
reached; it is gone.

### Live test status

**Last full run 2026-07-26** against MSSQL 2022 (16.0.4255.1) on the
standing test database, both transports wired: `../dbio/maint/capped-test prove -lr t/` →
**14 files, 547 tests, all PASS** in 7s wallclock, no temp databases left
behind. The per-file table below is from the 2026-06-25 run and still describes
the notable per-file details.

**DBD::Sybase-only run 2026-10-05** against MSSQL 2022 (16.0.4295.3) in a
docker container on another host, DSN `dbi:Sybase:host=..;port=..;database=..`
(no named server, no ODBC driver on the test host): **22 files, 608 tests, all
PASS**. Live: t/10 + t/20 (67 each, 14 skipped), t/30 (11, DBD::Sybase half
only), t/60 (106, 8 of them TODO: k37 ×5, k39 ×1, k40 ×2). Not run: t/11, t/21
and the live block of t/56 — ODBC only. Added the same day and run on its own,
not as part of that suite run: t/61 (161, 18 of them TODO: dbio-sybase k65 ×10,
k43 ×6, k42 ×2).

**DBD::Sybase-only runs 2026-10-07** (karr k37, with the declared storage
adapting to the access path) against MSSQL 2022 (16.0.4295.3), DBD::Sybase
1.27 / FreeTDS 1.3.17, no ODBC driver on the test host. Full suite on DSN
`dbi:Sybase:server=..;port=..`: **24 files, 633 tests, all PASS** — live t/10 +
t/20 + t/30; t/11 and t/21 skip (ODBC only), t/60 and t/61 skip (they need the
other DSN form). On DSN `dbi:Sybase:host=..;port=..;database=..`, the two
files alone: t/60 (110, 4 of them TODO: k39 ×2, k40 ×2) and t/61 (163, 20 of
them TODO: dbio-sybase k65 ×20), both PASS. The five k37 TODO of t/60 are
plain tests now; the k42/k43 TODO of t/61 are gone with the class they were
about (see "Transactions with an active statement handle"). Offline: 24 files,
488 tests.

**Runs 2026-10-07 with karr k40** (long bind values over DBD::Sybase), same
server, DBD::Sybase 1.27 / FreeTDS 1.3.17, and for the first time on this host
DBD::ODBC 1.61 over the FreeTDS ODBC driver (tdsodbc 1.3.17). All PASS:

- offline: 25 files, 548 tests (t/63 new, 60 tests);
- DBD::Sybase, DSN `dbi:Sybase:server=..;port=..`: 25 files, 693 tests — t/11,
  t/21 skip (ODBC only), t/60, t/61 skip (other DSN form);
- DBD::Sybase, DSN `dbi:Sybase:host=..;port=..;database=..`, the two files
  alone: t/60 (134, 2 of them TODO: k39 ×2) and t/61 (163, 20 of them TODO:
  dbio-sybase k65 ×20). The two k40 TODO of t/60 are plain tests;
- DBD::ODBC, DSN `dbi:ODBC:Driver=FreeTDS;Server=..;Port=..;Database=..;
  TDS_Version=7.4`: 25 files, 809 tests — live t/11 + t/21 (125 each), t/30;
  t/10, t/20, t/60, t/61 skip (DBD::Sybase only). 14 TODO tests of t/11 and of
  t/21 passed in that run ("Top-limit does not work when your limit ends up
  past the resultset"); karr k52, next paragraph, removed the markers.

**Runs 2026-10-07 with karr k52** (t/11, t/21 without the limit-dialect loop),
same server and client versions. All PASS, and no TODO test passes anywhere:

- offline: 25 files, 548 tests;
- DBD::ODBC, DSN `dbi:ODBC:Driver=FreeTDS;Server=..;Port=1433;Database=tempdb;
  TDS_Version=7.4`: 25 files, 713 tests — live t/11 + t/21 (77 each, 4 skipped
  each, see "`on_connect_call` options"), t/30; t/10, t/20, t/60, t/61 skip
  (DBD::Sybase only);
- DBD::Sybase, DSN `dbi:Sybase:server=..;port=..`: 25 files, 693 tests;
- DBD::Sybase, DSN `dbi:Sybase:host=..;port=..;database=..`, the two files
  alone: t/60 (134, 2 of them TODO: k39 ×2) and t/61 (163, 20 of them TODO:
  dbio-sybase k65 ×20).

The 96 tests fewer over ODBC are 2 × 48: t/11 and t/21 ran their LIMIT section
once as `Dialect:Top` and once as `Dialect:RowNumberOver`, handing
`limit_dialect` to `connect`. Nothing in DBIO reads that DBIx::Class
attribute — `DBIO::MSSQL::SQLMaker->apply_limit` always renders
`ROW_NUMBER() OVER()` — and both runs sent the same statements (measured over
ODBC: the 18 statements executed and the 7 `as_query` forms of the section,
per quoting, are identical with `Top`, with `RowNumberOver` and without the
attribute). The section runs once per quoting now, as plain tests; the TODO
markers described a `TOP` dialect this driver does not have.

**Runs 2026-10-08 with karr k50** (binary values over both access paths),
MSSQL 2022 16.0.4295.3, DBD::Sybase 1.27 / FreeTDS 1.3.17, DBD::ODBC 1.61 /
tdsodbc 1.3.17. All PASS, no TODO test passes:

- offline: 27 files, 673 tests (t/64 new, 125 tests; t/65 new, skips);
- both access paths in one run, DSNs `dbi:Sybase:host=..;port=..;database=..`
  and `dbi:ODBC:Driver=FreeTDS;Server=..;Port=..;Database=..;TDS_Version=7.4`:
  27 files, 1337 tests -- the 1155 of the same run before k50, t/64 (125) and
  t/65 (57: 28 per access path and one for the warnings). Not run on that
  day: the `dbi:Sybase:server=..` form.

**Runs 2026-10-08 with karr k56** (reading binary values over DBD::Sybase),
same server and client versions, the database in the HQ cluster (`dbio-db env
mssql`). All PASS, no TODO test passes:

- offline: 28 files, 752 tests (t/66 new, 79 tests); 8 files skip (the live
  ones), 4 tests skipped;
- both access paths in one run, DSNs as for k50: 28 files, 1462 tests, no
  file skipped -- the 1337 before, t/66 (79) and 46 more in t/65 (103: 57
  over DBD::Sybase, 45 over DBD::ODBC and one for the warnings). 36 tests
  skipped (t/10 and t/20 14 each, t/11 and t/21 4 each), 23 TODO tests: k39
  ×2 (t/60), dbio-sybase k65 ×20 (t/61) and, new, k47 ×1 (t/65: a value over
  the session's `TEXTSIZE` comes back cut). Not run: the
  `dbi:Sybase:server=..` form.

Against the storage classes as they were before k56, the new tests fail: 35
of the 79 of t/66, and 13 of the first 85 of t/65 -- every `find` of a
`VARBINARY(MAX)` value of one byte or more (no row), the bytes of the sized
types (hex digits), the key a row object holds -- before the file dies at
`$row->update` on a row found by its binary key ("row not found").

**Runs 2026-10-17 with karr k49, k55** (strings beyond ASCII refused, empty
strings written as `''` over DBD::Sybase), MSSQL 2022 16.0.4295.3, DBD::Sybase
1.27 / FreeTDS 1.3.17, DBD::ODBC 1.61 / tdsodbc 1.3.17, the database in the HQ
cluster (`dbio-db env mssql`). All PASS, no `_dbio_*` database left:

- offline: 32 files, 849 tests (t/81 new, 67 tests; t/82 skips);
- both access paths in one run (`dbi:Sybase:host=..;port=..;database=..` and
  `dbi:ODBC:Driver=FreeTDS;...`): 32 files, 1632 tests (t/82 new, 72: 36 per
  access path).

Against the storage class as it was before, t/81 fails 44 of its 67 tests and
t/82 32 of its 72, all of them DBD::Sybase (the empty-string and the refusal
tests; the DBD::ODBC half is green on both sides).

**Runs 2026-10-17 with karr k58 (Unicode binds over DBD::ODBC) and k47, k59,
k60, k61 (long values, both access paths)**, MSSQL 2022 16.0.4295.3, DBD::Sybase
1.27 / FreeTDS 1.3.17, DBD::ODBC 1.61 / tdsodbc 1.3.17, the database in the HQ
cluster (`dbio-db env mssql`), both DSNs in one run, through `capped-test`.
All PASS, no `_dbio_*` database and no test table left:

- offline: 40 files, 985 tests (t/75 new, 49; t/66 grew by 17);
- both access paths: 40 files, 2173 tests -- t/76 (90, ODBC), t/77 (198,
  both ways, the memory checks run in child processes), t/78 (34, ODBC);
  t/65's k47 pair ("IS: cut" and a TODO "SHOULD") became one test that
  passes. TODO tests now: k39 ×2 (t/60), dbio-sybase k65 ×20 (t/61) and, new, 4
  in t/77 (the DBD::ODBC `LongReadLen` boundary, upstream draft).
- Red before the fix, against the tree of the previous commit (new test files
  copied in): t/75 23 of 49, t/76 42 of 50, t/66 29 of 93, t/65 1 of 103
  (the refusal), t/77 over DBD::Sybase 31 of the first 80 (the file dies in
  the SQL_VARIANT part) and over DBD::ODBC 59 of the first 105 (it dies at the
  XML test, which throws at DBI's 80); t/78 passes there (it measures a row of
  the matrix, no fix).

**Run 2026-10-18 with karr k43** (t/61 on the decision of dbio-sybase k65,
DBIO::Sybase::Storage::FreeTDS of branch k65-txn in front), MSSQL 2022
16.0.4295.3, DBD::Sybase 1.27 / FreeTDS 1.3.17, DBD::ODBC 1.61, both DSNs in
one run through `capped-test`: offline 46 files, 1148 tests; live 46 files,
2443 tests, all PASS, no `_dbio_*` database left. t/61: 171 tests, 4 TODO
(case 8 in the four combinations, core's guard). Against the previous FreeTDS
class the new t/61 is red in cases 6 to 8b.

### Per-file detail (2026-06-25, MSSQL 2022)

| Test | Result | Notes |
|------|--------|-------|
| t/00-load.t | PASS | offline |
| t/40-sqlmaker-mssql-torture.t | PASS | offline |
| t/50-diff.t | PASS | offline |
| t/52-introspect-contract.t | PASS | offline |
| t/11-mssql-odbc.t | PASS | 125/125; 77/77 since karr k52 (2026-10-07), 4 of them skipped |
| t/21-mssql-odbc-core.t | PASS | same as t/11 (files are identical) |
| t/30-datetime-mssql.t | PASS | 1 skipped (no DBD::Sybase `syb_date_fmt`) |
| t/10-mssql.t | PASS | 53 pass, 14 skipped (MAS complex), 0 fail, exit 0 — needs a named server in `freetds.conf` + DSN `dbi:Sybase:server=<name>` |
| t/20-mssql-core.t | PASS | same as t/10 (files are identical) |

DBD::Sybase 1.27 compiled against FreeTDS v1.3.17 reaches the test database
(karr k12 / supersedes the DBD::Sybase-install note from karr k3).
The declared storage ends in `DBIO::MSSQL::Storage::Sybase` over `dbi:Sybase:`,
live-verified; see "A declared storage adapts itself to the access path" above.

Running t/10/t/20 over DBD::Sybase+FreeTDS needs a *named* server, because
several sections open a second concurrent server-side cursor — DBD::Sybase
then opens a second physical connection. That connection is made on a bare
`host=...;port=...` DSN too (measured, karr k41/k44: `use <db>` is answered
on it); what is left on the handle is client message 44 ("Server name not
found in configuration files"), which `$dbh->do` clears at its execute and
core's own `prepare` reports as an error. The named `[server]` block in
`freetds.conf` is what makes that message go away. Add to `~/.freetds.conf`:

    [<name>]
        host = <host of the test database>
        port = 1433
        tds version = 7.4

and set `DBIO_TEST_MSSQL_DSN='dbi:Sybase:server=<name>'`.

Even with the named server the "multiple active statements" complex cannot
pass over this transport, and this is a permanent limitation, not a pending
port (karr k13): the DBIx::Class `connect_call_use_dynamic_cursors` /
`use_mars` / `use_server_cursors` handlers were **ODBC-only** and self-throw on
FreeTDS by design (`use_mars` → "FreeTDS does not support MARS";
`use_dynamic_cursors` → unsupported with FreeTDS > 0.82; `use_server_cursors` →
Windows-only). DBD::Sybase has no real MARS — it only fakes a second active
statement via a child connection, whose separate session deadlocks on a
write-in-transaction. So both MAS blocks in t/10/t/20 are wrapped in a `SKIP`
with that reason — the files complete cleanly (exit 0) instead of dying on a
desynced COMMIT. The dialect/LIMIT
behaviour the old "RNO detection" block tried to probe via the removed
`sql_limit_dialect` API is covered offline by
`t/sqlmaker/limit_dialects/rno.t` and `t/40-sqlmaker-mssql-torture.t`; the live
files now just assert the storage is wired to `DBIO::MSSQL::SQLMaker`.
