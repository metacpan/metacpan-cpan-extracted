# CLAUDE.md — DBIO::Oracle

This distribution tracks only its own `dbio-oracle*` skills and its `.claude/skilletor.json`.
The family skills, the shared agents and the house rules are installed by skilletor from the
`dbio` core repo and are git-ignored: **a fresh clone has them only after `skilletor sync`**
(needs the `skilletor@getty` plugin and network access to the sources in `skilletor.json`).
Run it before relying on anything named here, and never edit an installed copy — change the
source in core. The family-wide house rules (discipline, delegation, release) then live in
`.claude/rules/.local.dbio-rules.md` — auto-loaded by Claude Code for the main agent and all
subagents.

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-oracle` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-oracle` (default), `dbio-adr-auditor`, `dbio-release-manager`,
`karr-coordinator`.

## Namespace

- `DBIO::Oracle` — Oracle schema component (component loaded into a schema via `use DBIO Schema => -ora` or `load_components('Oracle')`; `use base 'DBIO::Base'`)
- `DBIO::Oracle::Storage` — Oracle storage (declared by the component, the `-ora` shortcut or `storage_type`; the DSN does not choose it, core ADR 0067)
- `DBIO::Oracle::SQLMaker` — Oracle SQL dialect (hierarchical queries, PRIOR, identifier shortening)
- `DBIO::Oracle::Storage::WhereJoins` — Pre-9i Oracle `(+)` outer join syntax

**A source named `schema.table`** (`table('OWNX.item')`, karr k58) is a table in another schema — on Oracle a user. The text before the first dot is the schema, the rest the table, each quoted exactly as spelled (`"OWNX"."item"`; a user made unquoted is upper case). `DBIO::Oracle::DDL` writes CREATE TABLE/SEQUENCE/TRIGGER/INDEX and the foreign keys (either direction) with the schema; generated names come from the bare table name; only an empty half (`.t`, `x.`) is refused. `DBIO::Oracle::Deploy->install` checks `all_users` for every such schema before the first statement and refuses a missing one loudly (the driver creates no user; a lower-case spelling of an existing upper-case user gets a hint). The connected user needs the ANY privileges: CREATE ANY TABLE, CREATE ANY SEQUENCE, CREATE ANY TRIGGER, CREATE ANY INDEX, ALTER ANY TABLE (foreign keys, columns), and DROP ANY TABLE/SEQUENCE/INDEX for drops; measured: without them CREATE TABLE/SEQUENCE/TRIGGER/ALTER answer ORA-01031, CREATE INDEX ORA-41900. `DBIO::Oracle::Introspect` reads further schemas via the `schemas` attribute and names their tables `schema.table` (a foreign key to another schema's table is `owner.table`); `DBIO::Oracle::Diff` writes such keys qualified. `Deploy->diff`/`upgrade` of such a schema give each foreign schema a temporary user of its own, `DBIO_TMP_<pid>_<n>_<k>` (ADR 0011): the install DDL is written with the temp users as qualifiers (`Identifier::%SCHEMA_MAP`), each statement runs as the user whose schema it writes to, each user is introspected on its own connection and the models are merged and renamed back to the real schemas (second diff empty); all temp users are dropped on every path (a failed drop warns with its name). A schema named like the connected user is its own (no extra user, tables bare). Foreign keys across schemas: the driver writes no GRANT, a missing REFERENCES reaches the caller as the server error; only among its own temp users it grants REFERENCES, or the desired state could not be built. A table of the own schema whose name holds a dot (made by literal SQL) reads as a qualified one. The maintainer's database has the second users `dbio_x` and `"other"` and the ANY privileges for `dbio` (init script of `maint/k8s/oracle.yaml`); run the live tests with `DBIO_TEST_ORA_EXTRAUSER_*` set to `dbio_x` or the second-user rounds skip.

## Native Deploy Triad

Oracle has the three native classes and a working upgrade path (karr k36; new tables karr k37):

| Class | Role |
|-------|------|
| `DBIO::Oracle::Introspect` | Read live DB via `all_*` views (tables, columns, indexes, FKs) |
| `DBIO::Oracle::Diff` | Compare two introspected models → diff operations |
| `DBIO::Oracle::Deploy` | `install` (what `$schema->deploy` runs), `apply`, `diff` and `upgrade` (desired state in a temporary user) |

`install` and `apply` work, inherited from `DBIO::Deploy::Base`. `DBIO::Oracle::Deploy` derives from `DBIO::Deploy::Base::TempDatabase` (decided 2026-10-25, ADR 0010; the savepoint strategy of ADR 0002 cannot work on Oracle): `diff`/`upgrade` build the desired state in a temporary user `DBIO_TMP_<pid>_<n>` — `CREATE USER` (random password, quota on the caller's default tablespace) + the grants the install DDL needs, install DDL and introspection on a connection of that user, `DROP USER … CASCADE` on every path (a failed drop is warned about with the user's name). The connected user needs `CREATE USER` and `DROP USER` (checked via `session_privs`, a DBIO exception naming the missing one **before** anything is created) and must be able to grant `CREATE SESSION/TABLE/SEQUENCE/TRIGGER/VIEW`. `CREATE USER`/`GRANT`/`DROP USER` commit implicitly, so they run on a connection of their own (same credentials, AutoCommit), never on `$self->_dbh`: the caller's transaction is untouched. Pinned offline in `t/58-deploy-temp-user.t` (handle doubles), live in `t/54-deploy-live.t`. Every name the diff writes is quoted as the model spells it, the column ALTERs included (karr k61). The live test user gets its rights from the `maint/k8s/oracle.yaml` init script.

Storage class signals native deploy support:

```perl
# lib/DBIO/Oracle/Storage.pm
sub dbio_deploy_class { 'DBIO::Oracle::Deploy' }
sub deploy_setup { }
```

## SQLMaker Quirks

`DBIO::Oracle::SQLMaker` adds:

- `CONNECT BY` / `START WITH` / `ORDER SIBLINGS BY` hierarchical query support via `connect_by`, `connect_by_nocycle`, `start_with`, `order_siblings_by` resultset attrs
- `PRIOR` operator via `special_ops` regex `qr/^prior$/i`
- Automatic identifier shortening to fit Oracle's 30-char limit (MD5-based suffix)
- `RETURNING ... INTO ?` syntax for insert-returning

## Storage

```perl
__PACKAGE__->sql_quote_char('"');
__PACKAGE__->sql_maker_class('DBIO::Oracle::SQLMaker');
__PACKAGE__->datetime_parser_type('DateTime::Format::Oracle');
```

Connection defaults (`_default_dbi_connect_attributes`, karr k63): `LongReadLen` 16 MiB (`LongTruncOk` stays off), `ora_charset` and `ora_ncharset` `AL32UTF8`; a value in the connect_info wins. A bind for a character column (char, varchar, nchar, nvarchar, text, clob, long) is upgraded with `utf8::upgrade` on a copy (an unflagged `"\x{fc}"` is Latin-1, DBD::Oracle would send a byte); binary types and binds without a type are left alone (`Storage.pm`, `t/92`, karr k63).

LOB handling: split into 2000-char chunks for comparisons using `DBMS_LOB.SUBSTR` + `UTL_RAW.CAST_TO_VARCHAR2(RAWTOHEX(...))`. Disables `prepare_cached` for multi-part LOB comparisons to avoid cursor exhaustion.

Auto-increment: sequence detection via BEFORE INSERT trigger inspection on `ALL_TRIGGERS`. Single sequence / single trigger column → automatic; otherwise require explicit `sequence` in column_info.

Savepoints: supported. `_exec_svp_release` is a no-op (Oracle auto-releases on new savepoint with same name).

FK constraint deferral: `with_deferred_fk_checks { ... }` runs block between `ALTER SESSION SET CONSTRAINTS = DEFERRED/IMMEDIATE`. Requires `DEFERRABLE` constraints.

Connection parameters without a DSN: `_connect_params_dsn` (core ADR 0057, karr k33) builds the DSN for `{ dbname, host, port }` (AccessBroker::Static, or a connect-info hash without `dsn`); core's default `dbi:Oracle:dbname=..;host=..;port=..` is refused by DBD::Oracle. Without `host` → `dbi:Oracle:<dbname>` (a name the Oracle client resolves: tnsnames alias first, else read as an Easy Connect string; a SID needs a local instance; empty → `TWO_TASK`, or `ORACLE_SID` for a local instance, neither set → ORA-12162). With `host` → Easy Connect `dbi:Oracle://<host>[:<port>][/<dbname>]`, where `dbname` is the **service name**, not a SID; no port is written when none is given (client default 1521). `port` without `host` throws. An IPv6 host must be given in brackets. `Storage::WhereJoins` inherits it. Pinned offline in `t/37-connect-params-dsn.t`, live in `t/38-connect-params-live.t` (Oracle 23ai Free; not covered live: a local SID, a listener itself on 1521 or over IPv6 — a relay stood in for those).

## Introspection

Built on `all_tab_columns`, `all_tables`, `all_views`, `all_indexes`, `all_ind_columns`, `all_constraints`, `all_cons_columns`, `all_triggers`. Schema defaults to current user via `SELECT USER FROM DUAL`. Sequence detection through trigger body parsing. Rows are read with `fetchrow_hashref('NAME_lc')` (DBD::Oracle reports upper-case names), and `LongReadLen` is raised for the `LONG` columns (`data_default`, `trigger_body`). Live-verified in `t/57-introspect-live.t`; an IDENTITY column is not reported as auto-increment. The `schemas` attribute (ArrayRef) reads further schemas besides `schema`; their tables come as `schema.table` in every section of the model, a foreign key to a table of another schema names it `owner.table` (karr k58, live in `t/84`).

Sub-modules:
- `DBIO::Oracle::Introspect::Tables`
- `DBIO::Oracle::Introspect::Columns`
- `DBIO::Oracle::Introspect::Indexes`
- `DBIO::Oracle::Introspect::ForeignKeys`
- `DBIO::Oracle::Introspect::Keys` (primary and unique constraints)
- `DBIO::Oracle::Introspect::Views` (the `views` section: the defining query of each view from `all_views.text`, a `LONG` read with `LongReadLen` 16 MiB; karr k65)

## Diff

Generates operations in dependency order: foreign keys gone (`ALTER TABLE .. DROP CONSTRAINT`, the name from the source model), unique constraints gone, views gone (`DROP VIEW`), `CREATE TABLE` of every new table, `DROP TABLE`, columns, indexes (those of the new tables too), unique constraints new (`ADD CONSTRAINT .. UNIQUE`), then the foreign keys new, those of the new tables too, then the views new or changed (`CREATE OR REPLACE VIEW name AS definition`, karr k37, k64, k65). Tables, columns, indexes, foreign keys and unique constraints of tables both models have are compared (no sequences, triggers); a foreign key is its columns, target, `on_delete`, `on_update` and `is_deferrable` (the name does not count), a unique constraint its columns; a change is DROP plus ADD. A constraint over a column the target drops goes with the column (`CASCADE CONSTRAINTS`). An `ON UPDATE` action or `SET DEFAULT` is refused, naming table and column (karr k64). `on_delete RESTRICT` is written as `NO ACTION` (no clause), as the DDL does, and is no difference from it. A foreign key that stays over a unique constraint the target drops or changes (ORA-02273) is dropped first and created again, unchanged, after the constraint (order: key gone, constraint gone, constraint new, key new); when the target has no unique constraint and no primary key over the columns it points to, the diff refuses before the first statement, naming table and columns. Oracle lists the column pairs of a key in the order of the constraint it is bound to, so a key re-created over a constraint with its columns in another order reads back reordered (`t/96`). Views (karr k65): the model's `views` section holds the definition, the diff compares it after whitespace outside string literals and quoted identifiers is one space and a trailing semicolon is gone, otherwise as written (case included); a changed view is replaced whole and the columns of a view are never altered one by one. The statement is `CREATE OR REPLACE VIEW name (columns) AS definition`: a view entry holds `columns`, the names from `all_tab_columns` in `COLUMN_ID` order as Oracle has them (the text does not hold the ones a column list gave), written quoted so aliases survive; a different column list (name or order) with the same query is a change; a hand-written model without `columns` is written without a list and compared by its query only. A view whose text is missing (not set, `undef`, empty) in the target model, or in the source model of a view both have, is refused naming the view, before the first statement (the diff does not replace it every time; a view only dropped needs no text); a table that became a view (or the reverse) is refused too. Oracle stores only the query in `all_views.text`: `CREATE [OR REPLACE] [FORCE] VIEW .. AS`, a comment before the `SELECT` and a trailing semicolon are gone (a column list `(a, b)` is gone from the text too, and is kept in the model's `columns`), `SELECT *` is expanded to `"A","B"`, `WITH READ ONLY` stays (measured on 23ai, `t/95`). A view entry also holds `depends_on`, the views it rests on (`all_dependencies`; bare name in its schema, `owner.view` otherwise; renamed to the real schemas like a foreign key). Views written (created or replaced) go rest-on first in the order of the target model's dependencies, views dropped dependents first in the order of the source model's; a view resting on one the run does not write needs no edge; views resting on each other (a hand-written model) are refused naming them, before the first statement. Pinned offline in `t/94`, live in `t/95`. Pinned offline in `t/94-diff-view.t`, live in `t/95-diff-view-live.t` and the Conformance cases `diff-view-*` (`t/87`). A model key `schema.table` is written qualified by every operation (`"OWNX"."t"`; index, sequence and trigger names in the schema of the table; karr k58).

A table only the target has is created whole, as `DBIO::Oracle::DDL` writes the install: columns, primary key, `CONSTRAINT name UNIQUE`, then `CREATE SEQUENCE` and the `BEFORE INSERT` trigger for a column a sequence feeds, every name quoted as the model spells it; its indexes and foreign keys (constraint name from the model) follow. No `DROP INDEX` follows a `DROP TABLE` (ORA-01418); a `DROP TABLE` is followed by `DROP SEQUENCE` for the sequences the install made for it (source columns that are auto-increment with a sequence of the table's schema; not an IDENTITY, not one a target table still uses; karr k61). The model spells sequence names and schema as the server has them, not lower case; column ALTERs are quoted like everything else. The model carries the sequence of a column, not the trigger's name or text: the diff writes the install's trigger (`table_column_trg`). An auto-increment column without a sequence (`IDENTITY`), a sequence of another schema and a table without columns are refused. Pinned offline in `t/81-diff-new-table.t`, live in `t/55-diff-index-live.t` (A→B applied gives B, second diff empty; `Deploy->upgrade` over an empty schema equals `install`). Six sub-modules:
- `DBIO::Oracle::Diff::Table`
- `DBIO::Oracle::Diff::Column`
- `DBIO::Oracle::Diff::Index`
- `DBIO::Oracle::Diff::ForeignKey`
- `DBIO::Oracle::Diff::Unique`
- `DBIO::Oracle::Diff::View`

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::Oracle::Storage` | Driver storage, LOB bind attrs, FK deferral, datetime setup |
| `DBIO::Oracle::SQLMaker` | SQL dialect + hierarchical queries |
| `DBIO::Oracle::Introspect` | Live DB introspection (all_* views) |
| `DBIO::Oracle::Diff` | Model comparison |
| `DBIO::Oracle::Deploy` | Deploy orchestrator |
| `DBIO::Oracle::Storage::WhereJoins` | Pre-9i `(+)` join syntax |

## Build System

Uses `[@DBIO]` with `heritage = 1` (DBIO + DBIx::Class dual copyright). No `.proverc`: `prove -l` puts only this dist's `lib` first, so set `PERL5LIB` to the local checkouts of the family (`dbio`, `sql-abstract`, …) or install them (`dzil install` in core), otherwise an installed older dbio is used.

## Testing

Run every suite through the wrapper (house rule 9) and recursively (`t/sqlmaker/` holds tests):

```bash
../dbio/maint/capped-test prove -lr t/                       # offline, no database
../dbio/maint/live-preflight && ../dbio/maint/capped-test prove -lr t/   # live (maintainer's cluster)
```

Never `prove -j`; one run per database at a time. Live databases, caps and preflight are the house rules' business (`.claude/rules/.local.dbio-rules.md`, § Live testing and § Maintainer-only live infrastructure); the suite gets its database through the `DBIO_TEST_ORA_*` variables.

Offline tests (no DB): `t/00-load.t`, SQLMaker generation tests. Integration tests require `DBIO_TEST_ORA_DSN` env var (plus `_USER`, `_PASS`); besides the storage tests (`t/10`–`t/22`, `t/40`) these are `t/38` (connection parameters), `t/54` (deploy), `t/55` (diff), `t/56` (type round trip) and `t/57` (introspection) and `t/84` (tables in another schema; offline half `t/85`), and the shared case lists of core: `t/73` (DDL), `t/87` (Diff, offline half `t/86`) and `t/89` (Bind, offline half `t/88`; two Bind cases are declared deviations, karr k63; the Diff list's pending ones are the two view cases, karr k65). Their TODO tests name the card that decides them.

Values in error texts: `Storage::_mask_error_values` (docs/adr/0012-oracle-error-values-masking.md) runs `DBIO::Oracle::Util::mask_error_details` (the 23ai sentences; offline `t/100`) and then core's masking; `t/101` provokes every form live through the API (ResultSet, populate, insert_bulk) with a marker value and a short one, tables `FW_*`, and checks the code, column, constraint, table and bind count stay while no value does.

The database for a live run is described by `maint/k8s/oracle.yaml` (the maintainer's cluster serves it through `dbio-db`, see the house rules; elsewhere start any Oracle 23ai Free with a cpu and memory cap and export the `DBIO_TEST_ORA_*` variables): a capped pod (2 CPU / 3Gi) with Oracle 23ai Free, user `dbio` in `FREEPDB1`. `t/38` runs only on the DSN form `dbi:Oracle://<host>:<port>/FREEPDB1` and skips on `host=..;port=..;service_name=..`; every other live test takes either, so a full live verification runs the suite once with each. The manifest creates no second user — the cross-schema tests of `t/10` and `t/20` and the second-user round of `t/84` (`DBIO_TEST_ORA_EXTRAUSER_*`, plus the ANY privileges above for `dbio`) skip, saying why; the rest of `t/84` runs without a second user.
