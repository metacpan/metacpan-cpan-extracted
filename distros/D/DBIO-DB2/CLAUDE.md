# CLAUDE.md — DBIO::DB2

This distribution tracks only what is its own: `.claude/skilletor.json`, its `dbio-db2*`
skills and the settings. The family skills, the house rules
(`.claude/rules/.local.dbio-rules.md`) and the agents (`dbio-worker-db2`,
`dbio-release-manager`, `karr-coordinator`, `dbio-adr-auditor`) come from core through
skilletor and are git-ignored: **a fresh clone or worktree has them only after
`skilletor sync`** (plugin `skilletor@getty`, network access to the sources named in
`skilletor.json`). Run it before you rely on anything named here, and never edit an
installed copy -- change the source in core. The family-wide house rules (discipline,
delegation, release) are auto-loaded by Claude Code for the main agent and all subagents.

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-db2` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-db2` (default), `dbio-release-manager`,
`karr-coordinator`, `dbio-adr-auditor`.

## Namespace

- `DBIO::DB2` — DB2 schema component
- `DBIO::DB2::Storage` — DB2 storage (extends `DBIO::Storage::DBI`)
- `DBIO::DB2::{DDL,Deploy,Introspect,Diff}` — schema management via test-deploy-and-compare

## Usage

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('DB2');

my $schema = MyApp::DB->connect('dbi:DB2:database=mydb', $user, $pass);
```

## Storage

`DBIO::DB2::Storage` extends `DBIO::Storage::DBI`:

```perl
__PACKAGE__->datetime_parser_type('DateTime::Format::DB2');
__PACKAGE__->sql_quote_char('"');
__PACKAGE__->sql_maker_class('DBIO::DB2::SQLMaker');

sub dbio_deploy_class { 'DBIO::DB2::Deploy' }
```

Key methods:
- `sql_name_sep` — queries `SQL_QUALIFIER_NAME_SEPARATOR` from server (default `.`)
- `_dbh_last_insert_id` — uses `IDENTITY_VAL_LOCAL()` for auto-increment retrieval
- `deploy_setup` — no-op stub (DB2 does not need tablespace pre-allocation)
- `_connect_params_dsn` — DSN form for connection parameters without a DSN (AccessBroker::Static, core ADR 0057): `dbname` alone → cataloged `dbi:DB2:<dbname>`; `dbname`+`host`+`port` → uncataloged `dbi:DB2:DATABASE=..;HOSTNAME=..;PORT=..;PROTOCOL=TCPIP`; `host` without `port`, `port` without `host`, or no `dbname` throws
- `_bind_host_into_dsn` — HostBound seam (core k276, karr k50): `HOSTNAME=` (and `PORT=`) of the uncataloged form take the view's host/port, keys case-insensitive; a missing `PORT=` is put after `HOSTNAME=` when the view has a port, `PROTOCOL=` is never invented; a cataloged alias, a non-`key=value` part or a DSN without `HOSTNAME=` is declined with `(undef, $form)` (never a DSN value)
- `_connect` — wraps the `HandleError` core installs, so a DBI message of SQLSTATE class `01` is not an exception (ADR 0007, karr k43): `DBD::DB2` sets a true `err` for a server warning, and `DELETE`/`UPDATE` without `WHERE` (`01504`, SQL0513W) threw after changing the rows. Silent — `err`/`state`/`errstr` stay on the handle; every other state throws through core's handler as before; the return value is not looked at; with `unsafe` nothing is installed. The wrapper keeps core's blessing (`__DBIO__DBH__ERROR__HANDLER__`)
- `_connect` also takes SQL0605W (err 605, SQLSTATE `42S11`, `CREATE INDEX` over columns already indexed): not an exception, a `carp` naming index and table, from the statement text a `do` callback keeps (ADR 0010, karr k47). Other states, and err 605 under another state, throw as before
- limit/offset — `DBIO::DB2::SQLMaker::apply_limit` branches on whether an offset is present: `RowNumberOver` when an offset is given, `FetchFirst` otherwise (not server-version detection; see ADR 0003)

## Introspection

`DBIO::DB2::Introspect` extends `DBIO::Introspect::Base`. Reads live DB state via:

- `SYSCAT.TABLES` — tables and views; `SYSCAT.VIEWS.TEXT` — the `view_definition` of a view
- `SYSCAT.COLUMNS` — column metadata + primary key from `SYSCAT.KEYCOLUSE`/`SYSCAT.TABCONST`
- `SYSCAT.INDEXES` + `SYSCAT.INDEXCOLUSE` — index definitions
- `SYSCAT.TABCONST` + `SYSCAT.KEYCOLUSE` + `SYSCAT.REFERENCES` — foreign keys; `to_columns` are the columns of `REFKEYNAME` (the parent's primary key or `UNIQUE` constraint) via `KEYCOLUSE` in `COLSEQ` order (karr k45, ADR 0011)
- `SYSCAT.TABCONST` (type `U`) + `SYSCAT.KEYCOLUSE` — unique constraints

Model shape: `{ tables, columns, indexes, foreign_keys, unique_constraints }`;
`unique_constraints` is the optional section of the `DBIO::Introspect::Base` contract,
`{ $table => [ [ $name, \@columns ], ... ] }`, an entry for every table (karr k39, ADR 0009).
Db2 keeps an index of the constraint's name behind each `UNIQUE` constraint
(`system_required` 1); `Introspect::Indexes` leaves it out, it is the constraint.
`table_uniq_info` is overridden: constraints plus the unique `db2_indexes` indexes.

The index behind a primary key lives in schema `SYSIBM` (`UNIQUERULE='P'`), under a
server-chosen name, not in the table's schema. `Introspect::Indexes` reads it for the
introspected schema's tables and the model carries it with `origin => 'pk'` and the
primary key's columns (karr k45, ADR 0011). It is the primary key: `Diff::Index` skips
every index of origin `pk` on both sides (no `CREATE`/`DROP INDEX`), `table_uniq_info`
leaves it out (karr k53 first found it, `t/14`, `t/66`, `t/67`).

A view is an entry of `tables` with `kind => 'view'` and a `view_definition`: the text of
`SYSCAT.VIEWS.TEXT` after the view's name (`AS SELECT ...`, a column list in front when the
view has one), name and schema cut off so the live and the compare-schema view compare
by what they read (ADR 0011).

A column of the model carries two descriptions (karr k44, ADR 0013). The **normalized**
one is the `DBIO::Introspect::Base` contract that `DBIO::Generate` reads through
`table_columns_info`, as the other drivers hand it: `data_type` is the lower-case type a
result class writes (`char` for `CHARACTER`, `double precision` for `DOUBLE`, else
`TYPENAME` lower-cased); `size` is the declared length — a number for the character,
binary and LOB types, `[10, 2]` for a `DECIMAL(10,2)`, the precision for `TIMESTAMP`, the
digits 16/34 for `DECFLOAT` — and **absent** for what Db2 declares without one (`INTEGER`,
`SMALLINT`, `BIGINT`, `REAL`, `DOUBLE`, `DATE`, `TIME`, `XML`, `BOOLEAN`); `default_value`
is the value: a string literal unquoted (`'it''s'` is `it's`), a number as its text, an
expression (`CURRENT TIMESTAMP`, `USER`, ...) a SCALAR reference (`\'CURRENT TIMESTAMP'`),
no default and `DEFAULT NULL` `undef`. The **catalog** one is internal, for the diff only:
`catalog_type` (`TYPENAME`), `catalog_size` (`LENGTH`, the storage length for a type
declared without one, `10,2`, the `SCALE` alone for `TIMESTAMP`, 16/34 for `DECFLOAT`) and
`catalog_default` (`DEFAULT`, the SQL text: `'new'` with its quotes, `'it''s'`, `0`).

## Diff

`DBIO::DB2::Diff` extends `DBIO::Diff::Base`. Compares two introspected models.
Operations emitted in dependency order: the view drops, tables, columns, the `REORG` some column
changes need, indexes, unique constraints, foreign keys, the view creates.

`DBIO::DB2::Diff::View` (karr k45, ADR 0011): `CREATE VIEW "v" <view_definition>;` /
`DROP VIEW "v";`; a changed definition (whitespace set aside) is a `drop` marked `replaced`
plus a `create`; no definition on a side = unchanged, a `create` without one throws. All view
drops stand at the head of the diff, all creates at its end. A view is no table: `Diff::Table` and
`Diff::Column` leave kind `view` alone (the karr k36 refusal is gone). Views are ordered by what they
read (karr k54, ADR 0011 addendum, as mysql k110/k113): `DBIO::DB2::DDL::view_reads` reads the names
after `FROM`/`JOIN`/the comma of a definition (`"x"` as written, unquoted upper-case, schema qualifier
dropped), `order_views` puts a view after the views it reads, otherwise by name; `install_ddl` and
`Diff::View` create in that order and drop in reverse, a reader of a replaced view (transitively) is
replaced with it (its `drop` `replaced`), a cycle throws a `DBIO::Exception` naming the views before any
operation. Not recognised: a view of another schema, a CTE named like a view.

`DBIO::DB2::Diff::UniqueConstraint` handles tables present in both models: `ALTER TABLE
ADD CONSTRAINT ... UNIQUE`, `ALTER TABLE DROP UNIQUE`, a changed column list as
drop-then-add (identity by name). A new table gets its constraints inline from
`Diff::Table` (same clause as `install_ddl`, refusing a column that is not `not_null`).

Both models of a real diff come out of `SYSCAT` (live schema and compare schema), so
the op classes render and compare the internal catalog fields (`catalog_type`,
`catalog_size`, `catalog_default`; ADR 0013) and never the normalized `data_type`, `size`,
`default_value`: no length for the types Db2 declares without one (`_db2_column_type`), the
default text written as it is — never through `_db2_default_literal`, which is
`install_ddl`'s renderer for a result class value and would quote it a second time — and
`GENERATED ALWAYS AS IDENTITY` on a created table's `is_auto_increment` column. The
comparison is `DBIO::Diff::Compare::changed_fields` on those fields (what core's
`changed_column_fields` does for the normalized ones). A mock model in a diff test has to
carry the catalog fields (karr k41, k44).

Identity (karr k45, ADR 0012): `Diff::Column` compares `is_auto_increment` itself (core's
`changed_column_fields` does not). An added identity column is three statements (`ADD COLUMN
... NOT NULL DEFAULT 0`, `DROP DEFAULT`, `SET GENERATED ALWAYS AS IDENTITY`; existing rows
hold 0, the counter starts at 1); a changed flag is `SET GENERATED ALWAYS AS IDENTITY` (last
statement of the alter) or `DROP IDENTITY` (first), and what lets go of an identity goes first
within a table (one identity per table, SQL0372N). None asks for a `REORG`. The diff `croak`s,
naming table and column, for what the server refuses: a type other than `SMALLINT`, `INTEGER`,
`BIGINT`, `DECIMAL` without scale; a column not `NOT NULL`; a type change of a column that stays
identity. `START`/`INCREMENT` are not in the model.

`DROP COLUMN`, `SET NOT NULL`, `DROP NOT NULL` and a `SET DATA TYPE` leave a table in
reorg-pending state, where `INSERT`, `UPDATE` and `CREATE INDEX` fail with SQL0668N rc 7
(measured, ADR 0008). The exception is a change of length alone within `VARCHAR`,
`VARGRAPHIC` or `VARBINARY`; `ADD COLUMN` and a default never do. The rule is
`reorg_recommended` on `DBIO::DB2::Diff::Column`; unknown combinations answer yes. After
the column pass the orchestrator emits one `DBIO::DB2::Diff::Reorg` per such table —
`CALL SYSPROC.ADMIN_CMD('REORG TABLE "<table>"');`, unqualified like the `ALTER TABLE`s —
visible in `as_sql` and `summary`, run by `apply` like any statement. A table already
reorg-pending before the diff is not in the model, so the diff emits no `REORG` for it;
`Deploy::upgrade` covers it (see *Deploy*, karr k48). ADR 0008 is `proposed` until the
maintainer confirms the choice.

## Deploy

`DBIO::DB2::Deploy` implements test-deploy-and-compare:

1. Introspect live DB (source)
2. Deploy desired schema to a temporary schema in the same DB
3. Introspect the temp schema (target)
4. Diff source vs target via `DBIO::DB2::Diff`

Supports `install`, `diff`, `apply`, and `upgrade`; `apply` and `upgrade` are those of
`DBIO::Deploy::Base` (core k399, ADR 0080), `_execute_diff` too: a refusal always stops the run, a
destructive operation or a `lossy` one runs with `allow_destructive => 1` only, `dry_run => 1` executes
nothing. An upgrade whose diff holds a `REORG` (see *Diff*) rewrites that table as part of `apply`.

The Db2 checks are `_check_before_apply($diff)`, run by `apply` (so by `upgrade`) after the release and
before the first statement, in this order. First `_reorg_pending_before_apply` (karr k48, ADR 0008
addendum) reads `SYSIBMADM.ADMINTABINFO` (`TABSCHEMA` = `CURRENT SCHEMA`, `REORG_PENDING = 'Y'`) and runs
`CALL SYSPROC.ADMIN_CMD('REORG TABLE ...')` (rendered by `Diff::Reorg`) for every pending *table* that is in
both the source and the target model, sorted, with a `carp` naming them. Narrowest reading of "affected": a
table only in the source is dropped, one only in the target is created, a view is no `REORG` target; with no
table in both models the server is not asked. A diff without changes is not applied: nothing is asked or
reorganised. Second `_refuse_identity_on_rows` (karr k54, ADR 0012 addendum) asks `SELECT 1 FROM "<table>" FETCH
FIRST 1 ROW ONLY` for every table that gets an added identity column (`Diff::Column::adds_identity`, table in
both models) and croaks naming table and column when it holds a row (Db2 would set the rows to 0); it comes
after the `REORG` because a reorg-pending table cannot be read (SQL0668N rc 7). Third `_refuse_unfillable`
(karr k57). Nothing is executed when a check throws; `diff`/`as_sql` do not look.

`DBIO::DB2::Diff::Column::lossy` (ADR 0080) answers through `DBIO::Diff::Compare::column_change_lossy` on
`catalog_type`/`catalog_size`: the same type with a size at least the live one (scale equal), and the widenings
`smallint->integer`, `smallint->bigint`, `integer->bigint` keep every value; any other type change needs
`allow_destructive`. Nullability, default and identity changes are not lossy. Drops (column, table, index,
unique constraint, foreign key, view not `replaced`) are destructive by their `action`.

## DDL

`table('schema.table')` is the table in that schema (karr k57): `CREATE TABLE "schema"."table"`, Db2 makes the schema with its first table (implicit schema creation, needs that authority); FK targets and indexes name it, the FK constraint name keys on the table part. `diff`/`upgrade` compare such a table too (pattern of dbio-mysql k122): `Deploy::_introspect_current` reads the schemas of the declared qualified tables, **the declared tables of them only** (`DDL->qualified_tables`), and merges them into the model under the name `schema.table` (`_merge_schema_model`); the target is built per schema (`install_ddl` options `local_only` / `only_schema`, one compare schema each, `_build_target_model`); the op classes write `"schema"."table"` (`_db2_quote_table`), an index in the schema of its table. A table of such a schema the declaration does not name (or no longer names) is in no model and is never dropped. Refused before the first statement (`_refuse_cross_schema_keys`, `DBIO::Exception` naming both tables): a foreign key between tables of different schemas (`install` still writes it). Not covered: views named `schema.table`, and the reorg-pending check before an upgrade (`_reorg_pending_before_apply`) looks at the current schema only.

`DBIO::DB2::DDL` generates DB2 DDL from DBIO result classes. Handles:
- `CREATE TABLE` with inline PK and named foreign keys (see *Foreign Keys*)
- A source's `unique_constraints` as named `CONSTRAINT "name" UNIQUE ("col", ...)` inline
  in `CREATE TABLE` (name = the source's, `primary` skipped; karr k39, ADR 0009). A
  constraint over a nullable column is refused with a `croak` naming table and column
  (Db2: SQL0542N); a column without `is_nullable` is `NOT NULL`
- A `db2_indexes` entry over a column sequence the PK, a `UNIQUE` constraint or an earlier
  index (name order) already has is not written: Db2 answers SQL0605W and makes nothing.
  Non-unique is a duplicate of any cover, `unique` only of a unique one (`_index_is_duplicate`;
  a unique index over a non-unique one is made). `Diff::Index` applies the same rule and puts
  the `DROP INDEX` of a renamed index before the `CREATE` (karr k47, ADR 0010)
- Unique without a constraint as a standalone `CREATE UNIQUE INDEX`, from a `db2_indexes`
  entry with `unique => 1`
- `GENERATED ALWAYS AS IDENTITY` for auto-increment columns
- Topological sort for table creation order (FK dependencies)
- Index creation via `db2_indexes` method on result classes and the canonical index declarations of the result source (ADR 0061, `index_declarations_for('db2', [])`; a declaration of the same name wins; `type` other than unique and `options` refused)
- `CREATE VIEW <quoted name> AS <view_definition>` for every non-virtual
  `DBIO::ResultSource::View` source with a non-empty `view_definition`, emitted
  after all table and index statements, in the order of what they read (karr k54)

Type mapping: PostgreSQL-style types (serial, bigserial, timestamptz) mapped to DB2 equivalents;
`boolean`/`bool` are the native `BOOLEAN` (no length) and `binary` is `BINARY(n)` (bare valid, `VARBINARY`
needs a length), measured, ADR 0004 addendum (karr k54, k44).

## Foreign Keys

DB2 enforces referential integrity, so FKs are carried through the whole deploy
path (see ADR 0005). `DBIO::DB2::DDL` `install_ddl` emits each table's FKs as
**named** inline constraints in `CREATE TABLE`
(`CONSTRAINT fk_<table>_<cols> FOREIGN KEY (...) REFERENCES <reftable>(...)`,
plus `ON DELETE`/`ON UPDATE` when set and not `NO ACTION`). The name is
deterministic and relationship-derived, so the live DB and the test-deploy
compare schema carry the same stable name (name-based FK identity, Option 1,
MSSQL-aligned). New-table FKs are also emitted inline by the diff path
(`DBIO::DB2::Diff::Table` `create` ops). FK changes on existing tables are
handled by `DBIO::DB2::Diff::ForeignKey`: ADD/DROP via `ALTER TABLE`
(`ADD CONSTRAINT` / `DROP FOREIGN KEY`), and a definition change as a
drop-then-add pair (DB2 has no in-place FK alter). DROP uses the real
server-carried name. The FK pass runs last in the diff.

## Testing

Integration tests need a real DB2 instance, handed to the suite through its
`DBIO_TEST_*` variables. Run every suite through the house-rule wrapper (rule 9), and
recursively -- `prove -l t/` skips subdirectory tests; use it only on one explicit file:

```bash
../dbio/maint/capped-test prove -lr t/       # offline (default): no DB2, no DSN
export DBIO_TEST_DB2_DSN="dbi:DB2:database=mydb"
export DBIO_TEST_DB2_USER=db2admin
export DBIO_TEST_DB2_PASS=secret
../dbio/maint/capped-test prove -lr t/       # live: the same command, with the DSN set
```

One run per database at a time, never `prove -j`. Where the live Db2 comes from, and how
it is capped, is the live-testing rules of `.claude/rules/.local.dbio-rules.md`. Db2 needs a
privileged container, so it runs under Docker; `maint/` ships two specs for it, both
capped (rule 4):

- **`maint/docker/`** — `docker compose up --build` brings up an IBM DB2 community
  server plus a Perl container with `DBD::DB2` built against the IBM clidriver,
  then runs the suite. Needs no local DB2 client. Mounts dbio core + dbio-db2
  source, so editing tests needs no rebuild. (Note: `DBD::DB2`'s Makefile.PL
  needs `DBI` installed *first* — it does not declare it as a configure prereq.)
- **`maint/k8s/db2-pod.yaml`** — DB2 pod + Service for a cluster that admits a
  privileged container. Still needs `DBD::DB2` locally.

Tests (`t/`, 71 files). "Live" below means `DBIO_TEST_DB2_DSN` and `_USER` are set
(`_PASS` beside them) and `DBD::DB2` is installed; everything else runs offline, on
mock models, recording handles and storages that never connect.

Every schema a test connects declares its driver (core ADR 0067; core refuses one
left on the generic `DBIO::Storage::DBI`): a test schema of its own loads the `DB2`
component, and the shared `DBIO::Test::Schema` gets `+DBIO::DB2::Storage` as
`storage_type` on a clone, so the shared class stays driverless.

- `t/00-load.t` — every module of the distribution loads
- `t/08-shortcut.t` — `use DBIO 'Schema', -db2` pins `storage_type` to
  `+DBIO::DB2::Storage`
- `t/10-db2.t`, `t/11-db2-fk.t`, `t/12-db2-upgrade.t` — **live only; all three
  files are skipped entirely without it.** `10`: name_sep detection, auto and
  explicit PK, populate, count, limit with an offset (`ROW_NUMBER() OVER`) and
  without one (`FETCH FIRST`), `columns_info_for`. `11`: foreign keys end to end —
  the named constraint from `install`, RI enforced by the server, FK ADD / DROP /
  modify (drop-then-add) through `DBIO::DB2::Diff::ForeignKey`, and `$deploy->diff`
  against the real compare schema. `12`: `$deploy->diff` / `->upgrade` through the
  public `DBIO::DB2::Deploy` API only (no introspector, no diff class driven by hand) —
  no operations right after `install`; a missing column with a string default and a
  changed default; a missing table with identity PK, FK and index. Each ends on an
  empty follow-up diff and on a row holding the declared default (`it's`, not its
  SQL text). No `DROP COLUMN`, no nullability or type change — those are `13`
- `t/13-db2-upgrade-reorg.t` — **live only**, `->upgrade` through the public
  `DBIO::DB2::Deploy` API for the changes that leave a table reorg-pending (ADR 0008):
  a dropped column plus a new index on the same table, two changed types
  (`INTEGER`→`BIGINT`, `DECIMAL(10,2)`→`(12,2)`), `SET NOT NULL` with `DROP NOT NULL`.
  Each: the diff holds one `REORG` for the table, in its place; afterwards
  `SYSIBMADM.ADMINTABINFO.REORG_PENDING` is `N`, the follow-up diff is empty and an
  inserted row reads back. And the other half: a `VARCHAR` that only gets longer has no
  `REORG` in its diff and the table stays usable
- `t/14-diff-pk-index.t` — **live only** (karr k53): a new identity-PK table is one
  `CREATE TABLE` with the `PRIMARY KEY` inline and no index operation in
  `$deploy->diff`, and the follow-up diff after `install` is empty. Pins the reason:
  `SYSCAT.INDEXES` holds the PK backing index (`UNIQUERULE='P'`) in `SYSIBM`, under a name
  of the server's (the model carries it with `origin` `pk`, karr k45)
- `t/15-char-default-live.t` — **live only** (karr k46): after `install`, a `CHAR(5)`
  default `'00000'`, a `VARCHAR` default `'USER'` and `'NULL'` read back as text from an
  inserted row (the old bare `DEFAULT 00000` stored `0`, silently), and the follow-up
  diff is empty
- `t/30-diff.t`, `t/31-diff-compare-semantics.t`, `t/32-diff-drop-table-index.t` —
  diff. `30`: the four op classes (`Diff::Table`, `::Column`, `::Index`,
  `::ForeignKey`) and the orchestrator's ordering over mock models, including that
  `Diff::Table`/`Diff::Column` leave a view alone (karr k45); the create, add-with-default and string-default alter
  blocks feed the catalog shape, the rest a bare `catalog_type => 'integer'`. `31`: what the `DBIO::Diff::Compare` comparators
  return, as the op classes consume it. `32`: no standalone `DROP INDEX` for an
  index whose table is dropped in the same pass
- `t/33-diff-reorg.t` — the `REORG` operation (ADR 0008) over mock models in the
  catalog shape: one per table, after the column ops and before the index ops; the
  rule row by row as measured (`reorg_recommended`); the identifier quoted and `'`
  doubled inside the `ADMIN_CMD` literal; one statement through core's
  `_split_statements`
- `t/35-ddl-fk.t`, `t/36-ddl-quoted-ident.t`, `t/37-ddl-not-null.t`,
  `t/38-ddl-default.t`, `t/39-ddl-type-size.t` — DDL. `35`: `install_ddl` emits FKs
  as named inline constraints, tables in dependency order. `36`: every identifier is
  double-quoted at every emit site, DDL and diff alike. `37`: a column without
  `is_nullable` deploys `NOT NULL`. `38`: the `DEFAULT` clause on both paths —
  `_db2_default_literal(value, data_type)` for `install_ddl` (a result class value; on
  a character column every non-ref value is a string literal, `'00000'` on `CHAR(5)`,
  `'USER'`, `'NULL'`; a SCALAR ref stays raw; no type, no change — karr k46), the
  catalog text as it is for `Diff::Table` and `Diff::Column` — and `_db2_quote_ident` croaking on
  `undef`. `39`: `_db2_column_type` and the size — an array reference (`[10, 2]`)
  renders comma-joined (`DECIMAL(10,2)`), and a type Db2 declares without a length
  gets none, whatever size comes with it (the catalog's `INTEGER` 4, a result class's
  `integer` 11); `varchar`/`json`/`varbinary` without a size, `interval`, `enum` and `bit` are refused
  (a `DBIO::Exception` naming type and column); `text` without a size is a `CLOB` (karr k57), `char`/`blob`/`clob` bare stay valid, `decfloat` takes 16 or
  34 or none, and the character-type test (`_db2_mapped_type`) never refuses (karr k45); `boolean` is `BOOLEAN` without a length and `binary` `BINARY(n)` (karr k54)
- `t/40-introspect-contract.t`, `t/41-introspect-tables.t`,
  `t/45-introspect-columns.t` — introspect. `40`: the `DBIO::Introspect::Base`
  normalized contract over an injected model. `41`: the tables introspector scopes on
  `tabschema` only (SQL captured from a mock handle). `45`: what the columns
  introspector makes of `SYSCAT.COLUMNS` rows replayed from a mock handle — the normalized
  `data_type`, `size` and `default_value` (karr k44, ADR 0013) and the internal
  `catalog_type`, `catalog_size` (for `TIMESTAMP` the precision, not `LENGTH,SCALE`; for
  `DECFLOAT` the digits, `LENGTH` 8/16 → 16/34) and `catalog_default` as SQL text;
  `is_auto_increment`
- `t/42-deploy-transactional-ddl.t`, `t/43-deploy-qualify-ddl.t`,
  `t/44-deploy-loads-its-classes.t` — deploy. `42`: the storage declares
  `transactional_ddl` as `0`, and what a `1` would pull into the migration's unit
  of work. `43`: `_split_qualify_ddl` re-points every object position at
  `DBIO_TEST_<pid>`, and `_build_target_model` brackets the compare deploy in
  `CURRENT SCHEMA`. `44`: loading `DBIO::DB2::Deploy` alone loads the classes its
  three hooks name (the file loads nothing else of the distribution, on purpose)
- `t/50-results-exist.t`, `t/51-set-operations.t`, `t/52-explain-query.t` — storage
  hooks, **each with an offline half that always runs and a live half in a `SKIP`
  block.** `50`: `_exists_value_sql` over `SYSIBM.SYSDUMMY1` and the
  `supports_exists_query` capability, answered by the declared DB2 storage; the
  shared class keeps no driver, and the same DSN without a declaration is refused
  (core ADR 0067). A `TODO` pins a core defect: the first
  `_exists_value_sql` on a storage whose driver is not yet determined appends the
  dummy table twice (core's determination wrapper re-enters the override). `51`: all six set-operation keywords are
  inherited from core. `52`: `_random_function` (`RAND()`) and the two-statement
  `_explain_query`; its live half is also skipped when the Explain tables are not
  installed
- `t/53-connect-params-dsn.t` — `_connect_params_dsn`: the cataloged and the
  uncataloged DSN form, and the combinations it refuses
- `t/54-connect-params-dsn-live.t` — **live only**, the counterpart of `53`: a
  schema with the DB2 component connects through `DBIO::AccessBroker::Static` with
  the DSNs the seam builds. Uncataloged (the server accepts the form as built, the
  login is the broker's user), cataloged (an alias from a temporary
  `db2dsdriver.cfg`; skipped when `DB2DSDRIVER_CFG_PATH` is already set), a
  reconnect after the broker's host changed, and a whole DSN as `dbname`. `dbname`,
  `host` and `port` are read from `DBIO_TEST_DB2_DSN` when it is the uncataloged
  form, else from `DBIO_TEST_DB2_HOST`, `_PORT` and `_DBNAME`; without them only
  the whole-DSN part runs
- `t/55-sqlstate-warning.t` — the `_connect` wrapper (ADR 0007), on a real DBI
  handle (`DBD::NullP`, shipped with DBI) with `set_err` standing in for the DBD:
  class `01` does not throw and the return value arrives (database handle,
  statement handle, `dbh_do`); `42S02`, no state and class `02` still throw as a
  `DBIO::Exception`; class `01` beside `undef` passes, while `_dbh_execute` still
  throws on a false `execute`; DSN, coderef, broker and a repeated `_connect` all
  run through the seam; `unsafe` is left alone
- `t/56-sqlstate-warning-live.t` — **live only**, the counterpart of `55`, on a
  table of its own (`dbio_k43_<pid>`): `$rs->delete` and `$rs->update` without a
  condition — the update with a bind value (no warning from the server) and with
  literal SQL (`01504`) — the same inside `txn_do`, read back committed over a
  second connection, a raw `DELETE` through `dbh_do`, and real errors (`42S02`,
  `42703`) that still throw and still roll a transaction back
- `t/57-hostbound-dsn.t` — `_bind_host_into_dsn` (karr k50): `HOSTNAME=`/`PORT=`
  replaced (any case), `PORT=` added when missing, the rest of the DSN unchanged;
  alias, non-`key=value` part and DSN without `HOSTNAME=` declined naming the form
  and no DSN value; end to end through a HostBound view with `DBI->connect` mocked
- `t/58-unique-constraint.t` — offline (karr k39, ADR 0009): `install_ddl` emits the
  named `UNIQUE` constraints inline (order, quoting, `primary` skipped) and refuses a
  nullable column naming table and column; `Diff::Table` create renders the same clause;
  `Diff::UniqueConstraint` add / drop / changed / dropped table; the orchestrator;
  `Introspect::UniqueConstraints` over rows replayed from a mock handle; `Indexes` leaves
  the constraint's index out; `table_uniq_info` keeps constraints and unique indexes
- `t/59-unique-constraint-live.t` — **live only**, the counterpart of `58`, on tables of
  its own (`dbio_k39_<pid>`, `dbio_k39n_<pid>`): after `install` SYSCAT.TABCONST holds the
  type `U` rows, the server refuses a duplicate (23505), the follow-up diff is empty;
  `DROP UNIQUE` and `ADD CONSTRAINT` through `diff`/`apply` on an existing table, a missing
  table created with the constraints inline, each ending on an empty diff; a nullable
  column refused at render time, nothing created
- `t/61-duplicate-index-live.t` — **live only** (karr k47), tables `dbio_k47_<pid>`,
  `dbio_k47r_<pid>`: the server's 605 rule row by row on a raw handle; `db2_indexes` on the
  PK columns and a repeated sequence through `install` and `upgrade`, each ending on an
  empty diff; a raw 605 through the storage handle is a warning
- `t/62-duplicate-index.t` — offline counterpart: `install_ddl`, `_index_is_duplicate`, the
  diff over catalog-shaped models (left out, empty follow-up, rename order)
- `t/63-sqlstate-605.t` — offline: the `_connect` wrapper on a `DBD::NullP` handle, warning
  with index and table, other states still throw
- `t/60-decfloat-live.t` — **live only** (karr k45), on a table of its own (`dbio_k45_<pid>`):
  `DECFLOAT(16)`, `DECFLOAT(34)` and a bare `DECFLOAT` install, the model holds size
  16 / 34 / 34, the follow-up diff is empty

- `t/64-upgrade-reorg-pending-live.t` — **live only** (karr k48), tables `dbio_k48_<pid>_*`: a table
  made reorg-pending by hand (ADD then DROP COLUMN, no `REORG`), columns equal to the class, gets its
  new index through `upgrade`; afterwards `REORG_PENDING` is `N`, the follow-up diff empty, an insert
  reads back; a table that is not pending and one the diff drops get no `REORG`
- `t/65-upgrade-reorg-pending.t` — offline counterpart, on a recording handle and a deploy with a
  replaced diff, run through `upgrade` and `apply` (core k399): query shape and bind, the `REORG` before the diff, none when
  nothing is pending, the narrow reading (view, source-only, target-only), sorted and quoted, no query without a
  common table, an empty diff asks and runs nothing (`apply` returns before `_check_before_apply`), `dry_run` too
- `t/66-introspect-keys-live.t` — **live only** (karr k45, ADR 0011), tables `dbio_k45k_<pid>_*`:
  an FK onto a `UNIQUE` constraint has the constraint's columns as `to_columns` (one onto the
  primary key keeps the PK's); the model holds the `SYSIBM` PK index with `origin` `pk` and the PK
  columns, not the index behind a `UNIQUE` constraint; `table_uniq_info`; the follow-up diff is empty
- `t/67-diff-pk-index-origin.t` — offline counterpart: `Diff::Index` writes no operation for an
  index of origin `pk` (both sides, one side), real indexes beside it still compare; the
  introspector's query and its schema-and-name keying over a mock handle
- `t/68-diff-view.t` — offline (karr k45, ADR 0011): `Diff::View` create / drop / unchanged /
  whitespace / replaced / no definition, and the orchestrator: view drops at the head, creates at
  the end, no table operation for a view, a table turned view
- `t/69-diff-view-live.t` — **live only**, objects `dbio_k45v_<pid>_*`: missing, surplus and changed
  view through `diff`/`upgrade` and back, each ending on an empty diff
- `t/70-diff-identity.t` — offline (karr k45, ADR 0012), catalog-shaped models: the three
  statements of an added identity column, `is_auto_increment` 0→1 / 1→0 (default, nullable and
  type change beside it), the identity moving between two columns (`DROP IDENTITY` first), no
  `REORG`, the allowed types, and the refusals naming table and column
- `t/71-identity-live.t` — **live only**, tables `dbio_k45i_<kind>_<pid>`: install and empty diff;
  an added identity column (to an empty table, `t/77`), a plain `NOT NULL` column made identity, an identity made plain and a
  nullable column made identity through `upgrade`, each ending on an empty diff and on the
  server's identity value in a new row
- `t/72-diff-reads-catalog-fields.t` — offline (karr k44, ADR 0013): models whose normalized and
  catalog fields disagree on purpose; the diff, `Diff::Table`, `Diff::Column` and
  `reorg_recommended` follow the catalog fields only
- `t/73-generate-roundtrip-live.t` — **live only** (karr k44), tables `dbio_k44<class>_<pid>`, one
  per type class (`bol`: boolean and binary) plus a hand-made `BOOLEAN`/`BINARY(8)` one: install, introspect, `DBIO::Generate`
  writes result classes, drop, install from them, introspect again; every column equal in both
- `t/74-diff-view-order.t` — offline (karr k54, ADR 0011 addendum): `view_reads` and `order_views` (quoting,
  case, qualifier, strings and comments, `TRIM(.. FROM ..)`, cycle), creates in dependency order and drops
  reversed, a replaced base view folds its readers (transitively) and leaves others alone, a cycle throws
  from the diff before an operation, `install_ddl` in dependency order
- `t/75-diff-view-order-live.t` — **live only**, objects `dbio_k54v_<pid>_*`: a view reading a view
  reading a view (name order the wrong one) through `install` and `upgrade`, a replaced base view with its
  readers, the drop in reverse; each ending on an empty diff
- `t/76-identity-add-rows.t` — offline (karr k54, ADR 0012 addendum), recording handle as `t/65`: an
  identity ADD onto a table with rows is refused from `apply` and `upgrade` (`_check_before_apply`) naming table and column,
  nothing executed; every pending table is reorganised first (one rule for both, core k399); an empty table, a plain column, a column made identity and a new table are not asked
- `t/96-diff-lossy.t` — offline (core k399, ADR 0080): `Diff::Column::lossy` pair by pair (the three widenings,
  longer `VARCHAR`/`DECIMAL` free; shrinking, scale, family changes lossy; nullability, default, added column not),
  a dropped column destructive, `apply`/`upgrade` inherited from `Deploy::Base`, a lossy change refused without
  `allow_destructive` (nothing ran, no check) and run with it
- `t/97-explain-schema-identifier.t` — offline (core k391, ADR 0077): `explain_table_schema` is an identifier; `_explain_query` writes it through the driver's quoting (`"SYSTOOLS"."EXPLAIN_OPERATOR"` by default, `"` doubled, `;` and blanks inside the quotes, case as given)
- `t/77-identity-add-rows-live.t` — **live only**, table `dbio_k54i_<pid>`: rows -> exception and the
  table unchanged; emptied -> added, follow-up diff empty, a new row has its identity
- `t/78-identity-add-reorg-pending-live.t`, `t/79-boolean-default-live.t`, `t/80-binary-limits-live.t`,
  `t/81-view-order-cte-schema-live.t` — **live only** (karr k55): `apply` of an identity ADD onto a
  reorg-pending table reorganises first; a hand-made BOOLEAN `DEFAULT '1'` equals the class (empty diff);
  `binary` > 255 is `VARBINARY(n)`, > 32672 refused; views with a CTE / schema-qualified read install, empty diff.
  Offline halves in `t/39`, `t/45`, `t/74`, `t/76`. `view_reads`/`order_views` take an optional schema; a
  qualified read of a view of the set without a schema is refused (ADR 0011 addendum)
- `t/82-conformance-ddl.t`, `t/84-conformance-diff.t`, `t/86-conformance-bind.t` — offline (karr k57, core
  ADR 0060): `DBIO::DB2::Test::Conformance->check_declarations` for the list, the answered table version
  against core's. `t/83-`, `t/85-`, `t/87-conformance-{ddl,diff,bind}-live.t` — **live only**, the shared case
  lists of core run against the server, each case in a schema of its own (`DBIO_CF_<pid>_<n>`, `CURRENT SCHEMA`
  set on connect, dropped in the cleanup); `answered_through { DDL => 2, Diff => 4, Bind => 1 }` (Diff 4 = the deploy cases, answered
  through `conformance_deploy`; `conformance_upgrade` runs with `allow_destructive => 1`). Refusals and
  deviations are declared in the class (POD: *conformance_refusals*).
  Offline halves of what the cases showed: `t/39` (enum/bit refused as `DBIO::Exception`), `t/30` (a
  removed default is a change; new tables in foreign key order), `t/88-upgrade-refuses-unfillable.t` (`NOT NULL`
  ADD without a default, `SET NOT NULL` over a `NULL`: refused from `apply`/`upgrade` before the first
  statement), `t/89-insert-no-values.t` (`create({})` is `INSERT INTO t (col) VALUES (DEFAULT)`, not `DEFAULT VALUES`), `t/94-qualified-tables-diff.t` (offline) and `t/95-qualified-tables-diff-live.t` (live; schemas `dbio_k57q_<pid>`, `dbio_k57r_<pid>`): tables named `schema.table` in `diff`/`upgrade`, `t/93-diff-indexed-column-dropped.t` (no `DROP INDEX` / `DROP UNIQUE` for what covers a column the same diff drops: Db2 drops it with the column), `t/92-ddl-index-declarations.t` (canonical index declarations written like `db2_indexes`, same-name declaration wins, duplicate rule, `type`/`options` refused), `t/91-ddl-qualified-name.t` (a source named `s.t` is the table `t` in the schema `s`: `"s"."t"` in `install_ddl`, FK targets and indexes with it, left out of the compare deploy), `t/90-storage-lob-utf8.t` (CLOB bind type, UTF-8 decoding of the character columns by `DBIO::DB2::Storage::Cursor` and `select_single`, an empty string for a `blob` and a `clob` compared with more than 32672 bytes refused)

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::DB2` | Schema component |
| `DBIO::DB2::Storage` | DBI storage + driver registration |
| `DBIO::DB2::Deploy` | test-deploy-and-compare |
| `DBIO::DB2::Diff` | Compare introspected models |
| `DBIO::DB2::Diff::ForeignKey` | FK ALTER diff (ADD/DROP/drop-then-add) |
| `DBIO::DB2::Diff::UniqueConstraint` | `UNIQUE` constraint ADD/DROP (drop-then-add on change) |
| `DBIO::DB2::Diff::View` | `CREATE VIEW` / `DROP VIEW`, a changed definition as drop-then-create |
| `DBIO::DB2::Diff::Reorg` | `REORG TABLE` after reorg-recommended column changes |
| `DBIO::DB2::Introspect` | Read live DB via SYSCAT |
| `DBIO::DB2::DDL` | Generate DB2 DDL |
| `DBIO::DB2::SQLMaker` | DB2 SQL dialect (apply_limit: RowNumberOver / FetchFirst) |
| `DBIO::DB2::Type` | DB2 column type mapping |
| `DBIO::DB2::Test::Conformance` | Answers core's shared case table (ADR 0060) |
