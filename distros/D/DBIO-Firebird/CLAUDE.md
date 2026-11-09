# CLAUDE.md — DBIO::Firebird

This distribution tracks only its own files (`.claude/skilletor.json`, the `dbio-firebird*`
skills); the family skills, the shared agents and the house rules come from core through
skilletor, and everything named here refers to those. The family-wide house rules (discipline, delegation,
release) live in `.claude/rules/.local.dbio-rules.md` — auto-loaded by Claude Code for the main
agent and all subagents.

## Fresh clone — run `skilletor sync` first

The family skills, the shared agents (`dbio-adr-auditor`, `dbio-release-manager`,
`karr-coordinator`), the worker `dbio-worker-firebird` and the house rules
(`.claude/rules/.local.dbio-rules.md`) are installed and untracked, so a fresh clone or
worktree has none of them until `skilletor sync` has run (ADR 0058 in core). It needs the
`skilletor` plugin or CLI and network access to the sources in `.claude/skilletor.json`.
Run it before relying on a briefing and before `dzil build`. Never edit an installed copy:
change the source in core, then sync again.

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-firebird` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-firebird` (default), `dbio-release-manager`,
`dbio-adr-auditor`, `karr-coordinator`.

## Namespace

- `DBIO::Firebird` — Firebird schema component
- `DBIO::Firebird::Storage` — Firebird storage (via DBD::Firebird, inherits InterBase)
- `DBIO::Firebird::Storage::Common` — Shared Firebird/InterBase storage logic
- `DBIO::Firebird::Storage::InterBase` — InterBase storage variant (parent of DBIO::Firebird::Storage)
- `DBIO::Firebird::Storage::ODBC` — Firebird via DBD::ODBC (core ODBC storage + Storage::Common)
- `DBIO::Firebird::{DDL,Deploy,Introspect,Diff}` — schema mgmt, test-and-compare

## Usage

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('Firebird');

my $schema = MyApp::DB->connect('dbi:Firebird:dbname=app.fdb');
```

## Design Notes

### Storage

- **Built on DBD::Firebird** — DBD::Firebird is closely modeled on DBD::InterBase,
  so `DBIO::Firebird::Storage` inherits from `DBIO::Firebird::Storage::InterBase`.
- **Third transport: ODBC** — `DBIO::Firebird::Storage::ODBC` branches off
  `Storage::Common` (core ODBC storage first in the ISA), *not* off InterBase.
  The cut: SQL facts of the engine go on `Common` and reach all three
  transports; anything hanging off a DBD's own API (`ib_dialect`,
  `ib_softcommit`, `ib_time_all`, `func('ib_plan')`) stays with that DBD.
  ADR 0010. Reached by declaring it (`storage_type
  '+DBIO::Firebird::Storage::ODBC'`, on the class or a clone): core ADR 0067
  retired the connector-registry route, and the component / `-fb` declare
  `DBIO::Firebird::Storage`, which an ODBC DSN does not leave (open: k40).
- **Tests declare their driver** — core ADR 0067 refuses a schema whose
  storage is the generic `DBIO::Storage::DBI`; the shared `DBIO::Test::Schema`
  gets its storage via `->clone(storage_type => '+DBIO::Firebird::Storage…')`.
- **`ib_` through an AccessBroker** — `Storage::InterBase` declares `ib_` for the DBD
  `Firebird` (`_dbd_attribute_prefixes`), since DBI's registry has no entry for it;
  `Storage::ODBC` does not inherit it.
- **Statements the DBD destroys** — DBD::Firebird destroys every statement of a
  connection on the commit after DDL and on a hard rollback inside a transaction;
  the handles stay in `CachedKids` and neither read nor write, without an error.
  `Storage::InterBase::_prepare_sth` asks each handle from the cache
  (`_sth_is_alive`) and on a destroyed one empties the **whole** cache before
  preparing anew — one entry at a time takes the new handles off the DBD's own
  statement list (comment at the method). Not on `Storage::ODBC`. This repo's
  `docs/adr/0011-destroyed-statement-handles-leave-the-cache.md`.
- **A DDL commit the server refuses** (`DROP TABLE` of a table a live statement
  holds: `object TABLE ... is in use`) leaves the DBD's transaction as it was and
  every later statement on the handle fails, the ping's too. core's `dbh_do`
  would take that for a dead connection, reconnect and repeat the block
  (reporting success). `Storage::InterBase::_ping` therefore does `begin_work` +
  `rollback` once when its select fails and AutoCommit is on, and asks again
  (karr k49; ADR 0011 addendum). Not on `Storage::ODBC`.
- **Firebird 3 is the minimum** (maintainer, karr k36): `data_type boolean` is a `BOOLEAN` column. DBD::Firebird takes the Perl truth of a bound text, so `Storage::InterBase::_adjust_bind_values` (core's one seam, karr k63; for the single binds and for each row of `populate` in void context alike) translates `'true'`/`'false'`, reads `''` (what the DBD returns for FALSE) as FALSE and refuses other strings for a boolean column; the ODBC storage does neither. The storage overrides neither `_bind_sth_params` nor `_dbh_execute_for_fetch`; the seam returns new pairs and never writes to the caller's binds. `default_value` on a boolean is 0/1/`'true'`/`'false'` (any case), written `DEFAULT FALSE`/`TRUE` (the server accepts `DEFAULT '0'` and fails the insert); any other value dies at DDL time. The bulk path handles literal binds (`\['?', [on => 'false']]`) too. The Diff rules are measured on Firebird 5.0.4.
- **A refused commit keeps the server's error** (karr k35): `Storage::InterBase::_exec_txn_commit` raises `$dbh->errstr` when DBI dies with "DBD driver has not implemented the AutoCommit attribute" (CREATE UNIQUE INDEX over duplicates, refused at commit). `_use_transactional_ddl` stays 0.
- SQL dialect 3 is forced on connect for modern features and quoting.
  Without a broker it is `ib_dialect=3` in the stored DSN; with one `Storage::InterBase::_access_broker_dbi_args`
  adds it to every answer that is a Firebird/InterBase DSN (karr k43), one connect.
- **HostBound views** (Replicated): `Storage::InterBase::_bind_host_into_dsn` binds the view's host into
  `db=host[/port]:path`, `host=h[/port]`/`hostname=` + `port=` and a local name, declines the rest naming the
  form; `Storage::ODBC` declines every DSN (karr k50, core k276).
- **ISO dates are the default of every native connection** (karr k55):
  `Storage::InterBase::_run_connection_actions` sets `ib_time_all = 'ISO'` before the
  caller's actions (`datetime_setup` stays, idempotent). Not on `Storage::ODBC`.
- **Text is UTF8 on every native connection** (karr k60): `Storage::InterBase`
  adds `ib_charset=UTF8` to a `dbi:Firebird:` DSN and `ib_enable_utf8 => 1` to
  the attributes (non-broker: `_set_utf8_connection` in `_init`; broker:
  `_access_broker_dbi_args`; both through `_utf8_connection_defaults`), unless
  the connect info names an `ib_charset` or an `ib_enable_utf8` (0 opts out).
  Measured: works against a UTF8 and a NONE database, so no DDL change. The DBD
  encodes only strings Perl flags UTF-8, so `_utf8_bind_value` flags a text with
  a character above 0x7F when it binds (not `is_binary_type` columns), also in
  the bulk path (both through `_adjust_bind_values`). Not on `Storage::ODBC`, not on a
  DBD::InterBase DSN.
- **A BLOB compared with a bound value** (karr k60): DBD::Firebird dies on a
  BLOB parameter in a SELECT; `Storage::InterBase::_gen_sql_bind` writes the
  placeholder of a bound value against a text/binary BLOB column
  (`Type::lob_kind`) of a SELECT as `CAST(? AS VARCHAR(8191) CHARACTER SET
  UTF8)` / `VARCHAR(32765) CHARACTER SET OCTETS`, found by a placeholder
  scan that skips strings, identifiers and comments (count must match the
  binds). A longer value cannot be compared: refused (stem "refus", table and
  column) before the DBD. UPDATE/DELETE untouched. Conformance `bind-long-string`
  is declared `server` for that.
- **Numeric binds are checked** (karr k60): DBD::Firebird stores `''`, `'x'`
  as 0 and `'5x'` as 5 in a numeric column (the server would refuse);
  `_numeric_bind_check` refuses a non-number (`looks_like_number`) for a
  `Type::is_numeric_type` column, also in the bulk path. Not on ODBC.
- **Error text holds no value** (ADR 0014, core ADR 0075): `Storage::Common::_mask_error_values` runs `Util::mask_error_details` (key sentence, conversion error) then `next::method`; the own boolean/numeric refusals name the column only; `errstr` stays raw.
- Identifier quoting is `"` (double-quote).
- Datetime parser uses `DateTime::Format::Strptime` with ISO formats.

### Sequences / Generators

Firebird uses I<generators> (the Firebird term for sequences). Access via
`GEN_ID(name, delta)` called from `rdb$database`. Storage::Common maps
`auto_nextval` to this mechanism. The sequence name is derived from trigger
source parsing in `_dbh_get_autoinc_seq`.

`install_ddl` writes an `is_auto_increment` column as `GENERATED BY DEFAULT AS
IDENTITY` (Firebird 3+; no generator/trigger; karr k46). The insert's `RETURNING`
reads the key back, so the storage needs nothing for it. IDENTITY plus
`default_value`, or a type other than SMALLINT/INTEGER/BIGINT/NUMERIC(p,0)/
DECIMAL(p,0), is refused. The introspected model carries `is_auto_increment`
(`rdb$identity_type`), so a table or column created by `Deploy->upgrade` gets
IDENTITY too (shared `DDL::_firebird_column_clauses`, used by `install_ddl`,
`Diff::Table` CREATE and `Diff::Column` ADD); adding or removing it on an
existing column is refused by the diff before the first statement.

### Introspection

Introspection uses the `rdb$*` system tables:

- `rdb$relations` — tables and views
- `rdb$relation_fields` (incl. `rdb$null_flag`) + `rdb$fields` — columns
- `rdb$indices` + `rdb$index_segments` — indexes (excluding PK/UNIQUE constraints)
- `rdb$relation_constraints` (type `UNIQUE`) + `rdb$index_segments` — unique constraints
- `rdb$relation_constraints` + `rdb$indices` + `rdb$ref_constraints` — foreign keys (incl. on_update/on_delete/match)

Model shape: `{ tables, columns, indexes, unique_constraints, foreign_keys }`.
The shape is specified field-by-field in the `THE INTROSPECTED MODEL` POD of
`DBIO::Firebird::Introspect` — the single source of truth shared by Introspect,
Diff, and the `DBIO::Generate` contract. Column `data_type` is the bare SQL type;
size travels separately and is rendered via `DBIO::Firebird::Type`.

### Deploy

With an AccessBroker `Deploy::_live_connect_info` reads the storage's `_dbi_connect_info` (the storage's `connect_info` is `[ $broker ]`); core's `_temp_connect_info` reads the same `_dbi_connect_info`, so Deploy has no override of it (karr k42, k56). Coderef DSN answers stay refused.

`DBIO::Firebird::Deploy` — test-deploy-and-compare pattern:
introspect live DB → create temp DB → deploy desired schema to temp →
introspect temp → diff the two models → drop temp. Uses `DBIO::Firebird::DDL`
for DDL generation (a hand-rolled DDL emitter).

`apply` and `upgrade` are `DBIO::Deploy::Base`'s (core ADR 0080, this repo's ADR 0013, karr core k399): a drop or a lossy
column change runs only with `allow_destructive => 1` (call sites in tests say so), a refusal
(`Diff::Column::refusal`, the table/view clash) never gets released, `dry_run` executes nothing. The driver's
checks are `Deploy::_check_before_apply` (`as_sql`, then `_refuse_unfillable`); execution is core's `_execute_diff`.
`Diff::Column::lossy` answers through `column_change_lossy` with `%LOSSLESS_PAIRS` (smallint/integer/bigint/int128
widening, smallint/integer to double precision, date to timestamp, char to varchar / binary to varbinary of the same
length; a pair is listed only after `t/99-diff-column-lossless-live.t` read the values back unchanged). A `drop` that
is the first half of a change (changed index or constraint, view replaced) is marked `replaced` and is not destructive.

### Foreign Keys

Firebird supports FKs with `MATCH FULL` / `SIMPLE` and `ON UPDATE/DELETE`
actions. The introspector reads constraint metadata via `rdb$relation_constraints`
and `rdb$indices`. Composite FKs are grouped by constraint name.

`install_ddl` writes them (karr k34) after every CREATE TABLE as `ALTER TABLE
… ADD CONSTRAINT`: unique constraints first (`add_unique_constraint`, the
declared name, refused above 63 characters, none for the primary key's own
columns), then each `belongs_to` (`is_foreign_key_constraint`) as
`"<table>_<cols>_<target>_fk"` (cut to 31 *bytes* with an md5 suffix: Firebird
3's limit; Firebird 5 counts characters, so a declared name is refused above
63 characters), with `on_delete`/`on_update` the belongs_to's own where it
declares them (`exists`; `undef`/`''` switches the derivation off), else
derived from a has_many of the other side (`cascade_delete` → ON DELETE
CASCADE, `cascade_copy` → ON UPDATE CASCADE; DBIO deletes the parent first, so
the key needs it); RESTRICT or none: no clause, it is a syntax error on
Firebird; `is_deferrable` is refused (the shared CD declares it: tests clear it
on their copy). `Diff::Table` drops tables child before parent and, in a
cycle, the keys first. Shared helpers
`_firebird_add_foreign_key` / `_firebird_add_unique` in `DDL.pm`.
`Diff::Constraint` creates them for a new table (the CREATE TABLE of
`Diff::Table` has no inline key) and, for a table that exists, writes every
difference (karr k62, maintainer's decision; the diff refused it before, k34/k58):
`DROP CONSTRAINT` / `ADD CONSTRAINT`, a changed one (other columns, other
actions) as DROP plus ADD, the PRIMARY KEY included (compared by its columns in
key order, `is_pk`/`pk_position`; written `ADD PRIMARY KEY (…)`, dropped by
`tables->{t}{primary_key_name}`, the server's `INTEG_n`, which `Introspect::Tables`
reads; a model without it dies at `as_sql`). Order of the whole diff
(`Diff::_build_operations`): FKs to drop, tables, PK/UNIQUE to drop, indexes to
drop (before the column goes), columns, indexes to create, PK/UNIQUE to add, FKs
to add. A kept FK that points at a PK/UNIQUE dropped in the diff is dropped
before and added after (the server refuses "Cannot delete PRIMARY KEY being used
in FOREIGN KEY definition"). Check constraints are not in the model: untouched.
Tests `t/70`, `t/36`, `t/29`, conformance `t/89`.

### Diff — views are created, replaced and dropped (karr k61)

`Introspect::Tables` reads `rdb$view_source` into `tables.<view>.view_source`
(the query after `AS`, no semicolon; model shape in `THE INTROSPECTED MODEL`).
`Diff::View` writes `CREATE VIEW` for a new view, `DROP VIEW` for a view only
the database has, and for one whose definition differs (compared after
whitespace is collapsed and the ends cut, nothing else normalised) `DROP VIEW`
before the tables and `CREATE VIEW` after them (maintainer's decision: a
column the new definition no longer reads can then be dropped).
`Diff::_build_operations` puts the view drops before the tables and the view
creates after tables, columns, indexes and constraints; a view that
names another view in its definition is dropped before and created after it.
Nothing is guessed about what the server accepts: an unchanged view that
reads a changed one (it is not dropped with it) fails with the server's
error. `Diff::Column` skips a view's columns. The one refusal left is
`Diff::Table`'s: a name that is a table on one side and a view on the other
(`DBIO::Exception`, before the first statement). POD: `VIEWS` in
`DBIO::Firebird::Diff`. Tests `t/71`, `t/31`.

### DDL

DDL generation goes through `DBIO::Firebird::DDL`, a hand-rolled emitter that
builds Firebird SQL directly from DBIO Result classes (via
`DBIO::Firebird::Type::ddl_type_from_info`) — not SQL::Translator. Every
identifier DDL and Diff emit is double-quoted through
`DBIO::Firebird::DDL::_firebird_quote_ident`: Firebird folds a bare name to
upper case while the storage quotes every name, so core's `_quote_ident`
(bare for simple names) would create tables the ORM cannot find. The
`sqlt_type` (in `Storage::Common`) returns `'Firebird'`. `install_ddl` refuses
(`DBIO::Exception`, "refused", table and column) `bit`, `enum`, the TIME ZONE types
(DBD::Firebird 1.39 cannot bind or read them, t/88) and, on a server below Firebird 4,
`binary`/`varbinary` and a NUMERIC/DECIMAL of more than 18 digits (an INT128;
`DDL->server_major_version`, a seam tests replace; karr k60). On Firebird 4+ the
INT128 column is written but DBD::Firebird 1.39 can neither bind it (SQLDA
error) nor read it (`** unknown **`): conformance `bind-numeric-exact` is red
and not declared. The boolean
guards ask `Type::is_boolean_type`, so `bool` is guarded like `boolean`. DDL is used by
`Deploy::install` and `Deploy::_deploy_and_introspect_temp`.

### Diff — a default the schema dropped is removed; rows the server would refuse

`Diff::Column` compares `default_value` itself: the target is an introspected
model, which carries the key for every column, so `exists` + undef there means
"no default" (ALTER ... DROP DEFAULT); core's `changed_fields` would call it "no
opinion". A hand-made target without the key says nothing (karr k60).
`Deploy::_check_before_apply` renders the whole diff, then `_refuse_unfillable` asks the live
tables (before the first statement; `DBIO::Exception`, stem "refus", table and
column, all in one message): a NOT NULL column without a default (or `NULL`)
added to a table that holds rows, and a column that becomes NOT NULL over a NULL.
An empty table / a table with no NULL passes, a default or an identity column
is not asked. Conformance `diff-column-added-not-null-populated` and
`diff-not-null-over-nulls` are declared `server`.

### Diff — case-only names are refused

A database created unquoted holds `ARTIST` where the schema says `artist`.
`DBIO::Firebird::Diff::_build_operations` dies (`DBIO::Exception`, all pairs in
one message) when a dropped and a created table / column / index name differ
only in letter case, instead of handing out DROP + CREATE. Only unpaired names
count. No opt-out. POD: `NAMES THAT DIFFER ONLY IN CASE` in
`DBIO::Firebird::Diff`.

### Diff — column changes the server refuses

`DBIO::Firebird::Diff::Column::refusal` knows the type changes Firebird 5
always rejects (narrowing CHAR/VARCHAR, character to non-character, conversions
the server has none of, shrinking digits before the decimal point of a
NUMERIC/DECIMAL, a non-character into a too-short CHAR, any type change of a
PRIMARY KEY / UNIQUE / FOREIGN KEY column). `diff` still reports them;
`as_sql` (op and `Diff`) dies with a `DBIO::Exception` listing every such
column, so `apply`/`upgrade` die before their first statement. Lowering a
scale alone is NOT refused (the server takes it). No rebuild path. POD:
`COLUMN CHANGES THE SERVER REFUSES` in `DBIO::Firebird::Diff::Column`.

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::Firebird` | Schema component |
| `DBIO::Firebird::Storage` | Firebird driver registration (inherits InterBase) |
| `DBIO::Firebird::SQLMaker` | FIRST/SKIP limit dialect (no LIMIT/OFFSET in Firebird) |
| `DBIO::Firebird::Storage::Common` | Storage base: generators, savepoints, insert_returning, quote char, SQLMaker, exists query, set-op refusal, RAND() |
| `DBIO::Firebird::Storage::InterBase` | InterBase driver via DBD::InterBase |
| `DBIO::Firebird::Storage::ODBC` | Firebird via DBD::ODBC — transport branch off Storage::Common (ADR 0010) |
| `DBIO::Firebird::Deploy` | test-deploy-and-compare orchestrator |
| `DBIO::Firebird::Diff` | Compare introspected models |
| `DBIO::Firebird::Introspect` | Read live DB via rdb$ tables |
| `DBIO::Firebird::Introspect::Tables` | Table/view discovery |
| `DBIO::Firebird::Introspect::Columns` | Column metadata via rdb$fields |
| `DBIO::Firebird::Introspect::Indexes` | Index discovery (excludes PK/UNIQUE) |
| `DBIO::Firebird::Introspect::Uniques` | UNIQUE constraint discovery |
| `DBIO::Firebird::Introspect::ForeignKeys` | FK constraint discovery |
| `DBIO::Firebird::Type` | Firebird type mapping (rdb$/DDL directions, size rendering) |
| `DBIO::Firebird::Util` | `mask_error_details`: values out of the engine's error text (ADR 0014) |
| `DBIO::Firebird::Diff::Table` | CREATE/DROP TABLE diff ops |
| `DBIO::Firebird::Diff::Column` | ADD/ALTER/DROP COLUMN diff ops |
| `DBIO::Firebird::Diff::View` | CREATE OR ALTER / DROP VIEW diff ops (karr k61) |
| `DBIO::Firebird::Diff::Index` | CREATE/DROP INDEX diff ops |
| `DBIO::Firebird::Test::Conformance` | Driver half of core's shared DDL case table (ADR 0060; this repo's ADR 0012); the database is the case's namespace |
| `DBIO::Firebird::Diff::Constraint` | ADD / DROP CONSTRAINT for FK / UNIQUE / PRIMARY KEY, new tables and existing ones (karr k34, k62) |

## Tests

Every run goes through core's wrapper (house rule 9), recursive, from the repo root:

```
../dbio/maint/capped-test prove -lr t/                           # offline: no DSN, touches no database
../dbio/maint/live-preflight && ../dbio/maint/capped-test prove -lr t/   # live (live-preflight lives in core)
```

Without `DBIO_TEST_FIREBIRD_*` the live files skip themselves and only the offline files
run. `prove -l` only for one explicit file; never `prove -j` on a live suite.

Live files need a Firebird server and these variables: `DBIO_TEST_FIREBIRD_DSN`
(`dbi:Firebird:dbname=<host>:<path>/dbio_test.fdb`, the database the Firebird pod creates,
a file on the server), `DBIO_TEST_FIREBIRD_USER` and `DBIO_TEST_FIREBIRD_PASS` — SYSDBA, because the
suite creates and drops temporary databases (`t/17`, `t/19`, `t/21`) next to the live one.
`DBIO_TEST_FIREBIRD_INTERBASE_DSN` and `DBIO_TEST_FIREBIRD_ODBC_DSN` select the other two
transports; the ODBC leg also needs a Firebird ODBC driver on the test host and is otherwise
covered offline by `t/59-odbc-storage.t`. Where the server comes from, one run per database
and the resource caps: house rules, "Live testing". `maint/k8s/firebird.yaml` is a capped
Firebird 5 manifest for a server of your own.

End-to-end TAP tests:
- `t/00-load.t` — `use_ok` every DBIO::Firebird module
- `t/10-firebird.t` — connect, sequence, insert/select
- `t/20-firebird-core.t` — core schema functionality
- `t/30-datetime-firebird.t` — datetime inflation
- `t/15-introspect-live.t` — Introspect against a known schema
- `t/16-introspect-types-live.t` — one column per type: rdb$ type map + `Diff::Table` round trip
- `t/17-deploy-live.t` — temp-database create / connect / drop seams
- `t/19-deploy-roundtrip-live.t` — install → ORM → drift → upgrade → empty diff
- `t/21-diff-case-only-live.t` — unquoted (upper-cased) table / index / column vs lower-case schema: diff and upgrade refuse, data stays, each way out ends in an empty diff
- `t/34-deploy-broker-live.t` — Deploy on a broker schema: install, diff empty, drift, upgrade, diff empty, no temp database left (karr k42)
- `t/35-commit-error-live.t` — txn_do around CREATE UNIQUE INDEX over duplicates dies with the server's text, not DBI's AutoCommit text (karr k35)
- `t/22-broker-live.t` — `ib_` attribute from an AccessBroker reaches the handle; connect actions run once on the kept handle
- `t/26-boolean-live.t` — boolean column: install, introspect, ORM insert/select/update/search, 'true'/'false', `''`, copy/search on a read FALSE, populate bulk path (also literal binds), defaults 0/1/'true'/'false', refusal (karr k36)
- `t/24-index-declarations-live.t` — a declared index is created by `Deploy->upgrade`, the diff is empty afterwards (karr k51)
- `t/84-type-aliases-live.t` — one table per type alias `ddl_type_from_info` maps (tinyint, bool, string, string(n), real, mediumtext, longtext, int, binary and varbinary from Firebird 4, character, character varying, double): introspected base type and size, round trip for bool / string / text, character(10) refused at 11 characters through the ORM (karr k55)
- `t/85-conformance-foreign-objects-live.t` — a foreign table and view survive a conformance case whose namespace seam refused, and a cleanup with a mark of other names (karr k55)
- `t/86-bool-alias-live.t` — `data_type => 'bool'` through the ORM: create / populate (bulk) with 'true' / 'false', default 0 / 'true' (karr k55)
- `t/87-datetime-default-live.t` — a timestamp reads back ISO with no `on_connect_call`, also after a reconnect and with `datetime_setup` asked for (karr k55)
- `t/88-timezone-types-dbd-live.t` — DBD::Firebird 1.39 cannot bind or read TIME ZONE types (the reason install_ddl refuses them); red when a DBD release learns them (karr k55)
- `t/97-numeric-int128-dbd-live.t` — DBD::Firebird 1.39 cannot bind or read an INT128 (NUMERIC(20,4), raw table); the reason install_ddl refuses it; red when a DBD release can (karr k60)
- `t/25-default-literal-live.t` — a default with an apostrophe installs, applies on insert, reads back intact; introspected default and empty diff (karr k47)
- `t/31-diff-views-live.t` — a view in the diff against a server: new view created, same view (other whitespace) empty, changed definition replaced, removed view dropped, dependent view's server error loud, table/view kind change refused (karr k61)
- `t/36-pk-diff-live.t` — a table without the schema's primary key / with another one: introspection reads the key's name; diff reports, `upgrade` drops the old key by that name and adds the schema's, a new table beside it is created, empty diff after (karr k58, k62)
- `t/29-constraints-live.t` — install writes FK / UNIQUE (also a cycle), the server enforces them and ON DELETE CASCADE, upgrade creates a new table with its constraints, an existing table lacking one gets it by upgrade, one the schema dropped is dropped (karr k34, k62)
- `t/27-identity-live.t` — `Deploy->install` of an auto-increment column (IDENTITY, also numeric(9,0)), `create` without a key gives ids 1,2,3, empty diff; `Deploy->upgrade` of a new identity table / added identity column, a second upgrade empty, IDENTITY gained by an existing column refused (karr k46)
- `t/28-diff-column-refused-live.t` — refusal() against the server, type pair by type pair; key/unique/FK columns refused, index columns not (karr k38)
- `t/32-failed-ddl-no-reconnect-live.t` — a DDL commit the server refuses comes back as that error: block runs once, same handle, on_connect_do not repeated, session variable kept, table still there, connection usable (karr k49)
- `t/33-dbd-statement-list-live.t` — raw DBI facts of DBD::Firebird 1.39 the workarounds rest on: destroyed statement silent, a destroyed handle freed later empties the DBD's list, refused commit not rolled back (karr k48); red when a DBD release stops doing it
- `t/23-statement-cache-ddl-live.t` — one connection, caching on: ORM read and write across `Deploy->upgrade`, plain DDL and a rolled-back `txn_do`; the DBD answer `_sth_is_alive` relies on

- `t/89-conformance-diff-live.t` — core's Diff cases against a server (`conformance_upgrade` through `Deploy->upgrade`), same empty-database rule as t/80; every case is answered, none pending: the view cases (karr k61) and the constraint cases of existing tables (karr k62)
- `t/90-conformance-bind-live.t` — core's Bind cases against a server (karr k60); `bind-long-string` declared server, `bind-numeric-exact` red (INT128, DBD)
- `t/80-conformance-ddl-live.t` — the 20 DDL cases (table version 2) of core ADR 0060 against a server; the test database must hold no table or view, each case removes only the tables and views of its own sources (the mark of `conformance_namespace`), never anything else (karr k55). `ddl-view-declared` runs through core's hook `conformance_quote_ident` (default: the SQL maker's `"`), no refusal or pending any more (karr k56)

Offline TAP tests (no live DB — mock models / fixture introspector):

- `t/80-conformance-ddl.t` — the conformance declarations are whole (karr k55)
- `t/89-conformance-diff.t` — the Diff declarations are whole, every Diff refusal names a case of the table version answered (karr k60)
- `t/90-conformance-bind.t` — the same for the Bind list (karr k60)
- `t/91-deploy-unfillable.t` — `Deploy::apply` refuses NOT NULL added over rows / NOT NULL over NULLs before the first statement, with table and column; empty table, default, identity pass (karr k60)
- `t/92-diff-default-removed.t` — a default the target lacks becomes DROP DEFAULT; a target without the key says nothing (karr k60)
- `t/93-utf8-connection.t` — `ib_charset=UTF8` / `ib_enable_utf8` on native connections (plain, broker, own charset, opt-out, InterBase DSN, ODBC), unflagged text flagged on bind and in the bulk path, binary left (karr k60)
- `t/94-blob-compare.t` — `_gen_sql_bind` casts the placeholder of a BLOB comparison, placeholder scan, limits and refusal, UPDATE and ODBC untouched (karr k60)
- `t/95-numeric-bind.t` — non-numbers refused for numeric columns, also in the bulk path (karr k60)
- `t/96-ddl-numeric-precision.t` — NUMERIC/DECIMAL above 18 digits refused on every server (3, 4, 5, unknown), 18 digits written (karr k60)
- `t/81-ddl-conformance-answers.t` — sizes/type names, bit / enum / dotted-name / time zone refusals, binary on Firebird 3 (version seam), string / real / bool defaults, dotted view name, is_unique beside a unique constraint, no second index (karr k55)
- `t/82-deploy-class.t` — `dbio_deploy_class` on InterBase and Storage, ODBC unchanged (karr k55)
- `t/83-introspect-fk-constraint-name.t` — FK model key is `constraint_name` (karr k55)
- `t/18-deploy-live-db-location.t` — temp-database location from both DSN spellings
- `t/40-diff.t` — Diff op classes (Table/Column/Index) + orchestration
- `t/41-ddl-quoted-ident.t` — `install_ddl` identifier quoting
- `t/46-diff-case-only.t` — names differing only in letter case are refused, per object kind, with the non-conflicts beside them
- `t/47-ddl-nullable-default.t` — a column without `is_nullable` is NOT NULL in `install_ddl` (ADR 0043), agreeing with the compiled model
- `t/48-index-declarations.t` — canonical index declaration (idx, indices) in `install_ddl` and so the diff target model: plain/unique, name collision, refusals (karr k51)
- `t/49-default-literal.t` — string default with an apostrophe is doubled in `install_ddl`; scalar-ref untouched; Diff ops pass the introspected literal through (karr k47)
- `t/65-ddl-identity.t` — `install_ddl` IDENTITY for auto-increment columns; numeric(p,0) accepted, a type with a scale and default_value refused (karr k46)
- `t/71-diff-views.t` — views in the diff: CREATE OR ALTER VIEW / DROP VIEW, whitespace-normalised comparison, order against tables and between views, no column ALTER on a view, table/view kind change refused (karr k61)
- `t/69-ddl-constraints.t` — `install_ddl` FK / UNIQUE: order, cycle, actions, names (31 / 63), dedupe, refusals (karr k34)
- `t/70-diff-constraints.t` — `Diff::Constraint`: new table's ALTERs after all tables, DROP/ADD of keys on existing tables, their order in the whole diff, FK around a replaced key, PK by `primary_key_name`, names ignored (karr k34, k62)
- `t/68-diff-identity.t` — `rdb$identity_type` read as `is_auto_increment`; Diff CREATE / ADD write IDENTITY; gaining or losing it on an existing column is refused (karr k46)
- `t/66-diff-column-refused.t` — refused column changes per rule, with the accepted ones beside them; whole-diff refusal lists all (karr k38)
- `t/50-introspect-contract.t` — `DBIO::Introspect::Base` contract + `DBIO::Generate->dump`
- `t/60-broker-dbd-attributes.t` — `ib_` attributes through an AccessBroker over `dbi:Firebird:` (`_dbd_attribute_prefixes`)
- `t/61-deploy-mask-secrets.t` — Deploy errors do not quote the password
- `t/62-connection-actions-once.t` — `on_connect_do` / `on_connect_call` / OdbcFb override run once per connection
- `t/64-boolean-bind.t` — core's `_bind_sth_params` and `_dbh_execute_for_fetch` over the storage's `_adjust_bind_values`: 1/0/undef pass, 'true'/'false'/'' translated, the rest refused, ODBC untouched (karr k36)
- `t/72-ping-failed-ddl.t` — `_ping` on a stand-in handle: failing select then begin_work + rollback then alive; dead stays dead after two asks; AutoCommit off rolls nothing back; ODBC has its own (karr k49)
- `t/73-broker-sql-dialect.t` — `ib_dialect=3` in the DSN of every connection a broker's answer opens, once; an own dialect / ODBC DSN / coderef left alone (karr k43)
- `t/98-adjust-bind-values.t` — the value adjustments sit in `_adjust_bind_values` alone (no override of `_bind_sth_params` / `_dbh_execute_for_fetch`), the caller's binds are never written to, SCALAR refs kept, single and bulk path (literal binds too) agree (karr k63)
- `t/74-hostbound-dsn.t` — `_bind_host_into_dsn`: the three DSN forms bound, the rest declined without the DSN, through a storage, ODBC declined (karr k50)
- `t/63-statement-cache-dead-handle.t` — `_prepare_sth` on the native storages: a destroyed handle from the cache is replaced and the cache emptied; ODBC left alone
- `t/75-deploy-broker-coderef.t` — Deploy refuses a broker answer with a coderef DSN or a `dbh_maker`, loudly, no secret in the message (karr k42)
- `t/77-error-values.t` — `DBIO::Firebird::Util::mask_error_details` per sentence and the `_mask_error_values` hook on all three storages
- `t/99-diff-column-lossy.t` — `Diff::Column::lossy` per type pair and size; Deploy inherits `apply`/`upgrade`, `_check_before_apply`, a lossy change without `allow_destructive` dies before the first statement, `dry_run` (core k399)
- `t/37-error-values-live.t` — error text of a key violation (PRIMARY / UNIQUE / FOREIGN, composite, quotes, line break, UTF8, UPDATE, bulk), a conversion error and a refused commit holds no bound value; names, constraint and `with N bind values` stay; a literal of the statement stays
- `t/99-diff-column-lossless-live.t` (live) — every lossless pair keeps the stored values on a server; `char(5)` to `varchar(9)` changes them (core k399)

Shared test schemas (`DBIO::Test::Schema::*`) from dbio core are reused;
load via hashref syntax. No local inline Result classes.
