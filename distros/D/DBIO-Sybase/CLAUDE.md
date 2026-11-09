# CLAUDE.md — DBIO::Sybase

This distribution ships its own `dbio-*` skills/agents and the shared `.claude/rules/`;
everything named here refers to those. The family-wide house rules (discipline, delegation,
release) live in `.claude/rules/.local.dbio-rules.md` — auto-loaded by Claude Code for the main
agent and all subagents.

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-sybase` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-sybase` (default), `dbio-release-manager`,
`karr-coordinator`.

## Namespace

- `DBIO::Sybase` — Sybase schema component
- `DBIO::Sybase::Storage` — Sybase storage (inherits `DBIO::Storage::DBI`)
- `DBIO::Sybase::Storage::ASE` — Sybase ASE-specific storage (reblessed at the first use)
- `DBIO::Sybase::Storage::FreeTDS` — FreeTDS connection fixups (mixed in automatically)
- `DBIO::Sybase::{Deploy,Introspect,Diff}` — native deploy triad
- `DBIO::Sybase::{Introspect,Diff}::` — sub-collections for introspected sub-models
- `DBIO::Sybase::Quote` — identifier quoting for DDL and Diff (`[name]`, ASE keyword list)

## Component Loading

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('Sybase');
# → sets storage_type to +DBIO::Sybase::Storage automatically
```

## Storage

`DBIO::Sybase::Storage` extends `DBIO::Storage::DBI` and is the class a schema
declares (the component and `-syb` pin it). At the first use that needs the
driver — not at `connect` — it reaches `DBIO::Sybase::Storage::ASE` by one
way (core ADR 0059, karr k64): the schema declares the driver (component /
`-syb`), and the hook `_adapt_to_access_path` moves only the declared base (or a
`DBIO::Storage::Composed` class over it) to `::ASE` on a `dbi:Sybase:` DSN,
without `sp_server_info`, and never to `DBIO::MSSQL::Storage::Sybase`. A
server DBD::Sybase found to be Microsoft SQL Server at login
(`syb_server_version_string`) goes to core's `_driver_mismatch`. A storage
pinned to `::ASE` itself (karr k78, k94) meets the server like the declared base
(Microsoft SQL Server at login goes to `_driver_mismatch` before anything is
probed; live against SQL Server 2022, 2026-10-25: warns, `driver_strict` throws,
otherwise Msg 195 in ASE's first `set`) and takes the same placeholder decision on its
one connection (`auto_cast`, or `::ASE::NoBindVars`: the class and `auto_cast`
of the declared base on that connection, never `auto_cast` across the board --
CAST(? AS ..) dies under FreeTDS with Msg 12828); a private subclass, a pinned
`::ASE::NoBindVars` or subclass of `::ASE`, and the writer/bulk storages (their
parent decided; `auto_cast` is copied) pass through unchanged; another DBD
leaves the storage the base class.

A schema without a declared driver is refused at `connect` by core (ADR 0067);
`DBIO->driver_for($dsn)` names this driver for a `dbi:Sybase:` DSN. The server
is never asked what it is (`sp_server_info`), and no other product's class
exists here.

`ASE::_adapt_to_placeholder_support` then decides once from the client
library (`auto_cast`, or `::ASE::NoBindVars`), and if DBD::Sybase was compiled
against FreeTDS, `_init` mixes in the `DBIO::Sybase::Storage::FreeTDS` fixups.
Assert a storage's class only after a first use. Under FreeTDS the trait class
is built over the base of a layered storage's composition and the layers are
composed again over it (`Composed->recompose`, karr k77): layers stay ahead of
the FreeTDS class, and `composition_of` knows the class (base
`<ASE class>::FreeTDS`, layers unchanged). `DBIO::MSSQL::Storage::Sybase`
inherits this `_init` (`t/59-component-rebless.t`).

Key settings:
```perl
__PACKAGE__->sql_maker_class('DBIO::Sybase::SQLMaker');  # set on the ASE subclass
__PACKAGE__->sql_quote_char ([qw/[ ]/]);  # on the ASE subclass; DDL/Diff quote with [ ] via DBIO::Sybase::Quote (karr k58, k92)
__PACKAGE__->datetime_parser_type('DBIO::Sybase::Storage::ASE::DateTime::Format');  # on the ASE subclass
```

`dbio_deploy_class` → `DBIO::Sybase::Deploy`.

### Connection parameters without a DSN

`DBIO::Sybase::Storage::_connect_params_dsn` (core ADR 0057, karr k59) builds the
DSN for `{ dbname, host, port }` (AccessBroker::Static, or a connect-info hash
without `dsn`): `dbi:Sybase:host=..;port=..;database=..`, parts not given left
out (`dbname` alone → `dbi:Sybase:database=..`, server from `$DSQUERY`). Core's
default wrote `dbname=`, which DBD::Sybase does not read. `host` without `port`
and `port` without `host` throw — DBD::Sybase sets the server address only when
it has both (`dbdimp.c`, 1.27) and ignores a lone one; no port is assumed. A
server reached by name goes in as the whole DSN (`dsn`, or a `dbname` starting
with `dbi:`). `Storage::ASE`, its FreeTDS trait class and the ASE writer storage
inherit the seam (pinned in `t/57-connect-params-dsn.t`). So does
`DBIO::MSSQL::Storage::Sybase`, which lists this class before
`DBIO::MSSQL::Storage`: the form here must stay the one dbio-mssql's
`t/59-connect-params-dsn.t` expects. Live-verified 2026-10-05 against ASE 16.0
SP02 with DBD::Sybase 1.27 on FreeTDS 1.3.17 (`t/60-connect-params-live.t`): the
full form lands in the database named (first connect, reconnect, writer
storage), `host` + `port` alone and core's `dbname=` form land in the login's
default database (the latter without an error), `dbname` alone reaches the
`$DSQUERY` server, and a lone `host` or `port` in a hand-written DSN is dropped
in favour of that server. Not verified with Open Client. Under FreeTDS the
`host=..;port=..` form cannot run a second statement while a cursor is open
(`Server name not found in configuration files`: DBD::Sybase opens a connection
of its own for it and looks the server up by name; the prepare dies of that
message); the `dbname`-alone form can. The second connection itself is made, and
a `$dbh->do` goes through on it, on another session — which is how `BEGIN TRAN`,
`COMMIT` and `ROLLBACK` miss the transaction's session once a statement handle
is active. The FreeTDS trait therefore finishes the active statement handles and
rolls back on the same connection, and throws on `BEGIN TRAN` and `COMMIT` before
sending anything; the failed `COMMIT` then ends the transaction by core's rule (rollback on the
same connection, depth 0; karr k99) (karr k65, `t/75-txn-open-cursor.t`, `t/64-txn-scope-guard-live.t`).

## Identifier quoting

`DBIO::Sybase::Quote::quote_ident` (karr k92) is the one place `DDL` and the
`Diff::*` operations write a name: bare when it is `/^[a-z_][a-z0-9_]*$/i` and
not on the keyword list, `[name]` otherwise (a `]` in it doubled). Core's
`_quote_ident` left `dummy` bare (Msg 156 -- the table of
`DBIO::Test::Schema::Dummy`) and wrote `"name"` for the rest, which ASE refuses
without `set quoted_identifier on` (Msg 102, the login's default). The list is
the server's own: the catalog `master..spt_values`, rows of `type = 'W'` (218 words
on ASE 16.0 SP02, read 2026-10-25), plus four words a measurement (2026-10-24, about
600 candidates sent bare and in brackets) found refused that the catalog does not
name: `called`, `log` (index name only), `unsigned` (column only), `identity_insert`.
The measurement had found 215 words, 211 of them in the catalog; the catalog had
seven it did not try. The list is fixed in the code, not read at run time;
`t/96-quote-ident-live.t` compares it with the server's catalog in both directions (a
catalog word missing fails; the four extras are kept and named). `t/95-quote-ident.t`
pins every emitter offline, `t/97-quote-diff-live.t` runs keyword names through
install/diff/apply. A word in neither source is Msg 156 as before. A name starting
with `#` or `@` (Msg 11717, 16366) or containing a dot (read as `owner.name`, Msg
2734) fails in brackets too: `quote_ident` refuses it itself with a `DBIO::Exception`
naming name and reason; the driver sends no temporary table through it. The summaries
of the diff operations stay unquoted.

## SQLMaker

`DBIO::Sybase::SQLMaker` extends `DBIO::SQLMaker` and overrides `apply_limit`
to use the `GenericSubQ` limit dialect — ASE has no single limit construct
that works across all query shapes, so pagination is sliced via a correlated
`WHERE (SELECT COUNT(*) ...) BETWEEN ? AND ?` over a stable main-source order
(the dialect DBIx::Class also uses for ASE). Wired via `sql_maker_class` on
`DBIO::Sybase::Storage::ASE` (not the base, which `DBIO::MSSQL::Storage::Sybase` inherits).
The rows-only case (no offset) does not reach `apply_limit`:
`Storage::ASE::_prep_for_execute` takes the limit out and wraps the statement
in `SET ROWCOUNT n` / `SET ROWCOUNT 0`. `-nulls => 'first'|'last'` in an
`order_by` is emulated by a leading `CASE WHEN col IS NULL THEN 0 ELSE 1 END`
(`_render_op_nulls`, karr k95; `t/98`, live `t/99`). Note: DBIO core replaced DBIx::Class's
`sql_limit_dialect` string dispatch with the `apply_limit` method override.

## Error texts without values

ASE writes the offending value into some of its messages and so does its client
library, also for a bind (core ADR 0075, this repo's ADR 0006). `DBIO::Sybase::Util::mask_error_details`
holds the sentences (Msg 247/249 conversion, `to_numeric() failed for`,
`cs_convert failed (to_money(x))`, `Primary key is '"x"'`) and replaces the value
by `***`; `Storage::ASE::_mask_error_values` calls it and then core's masking,
so the NoBindVars, FreeTDS, writer and bulk storages have it, the base
`DBIO::Sybase::Storage` (shared with `DBIO::MSSQL::Storage::Sybase`) does not.
The ways around core's error handler are wired separately: the cslib callback and
the final exception of `BulkInsert`, the errstr of the TEXT/IMAGE calls in
`LOBWriter` (and its "no row found" message, which names key columns only), and
the `cs_convert failed` warning, which DBD::Sybase issues with `warn`, no error:
`ASE::_execute_sth` passes it to the caller's `__WARN__` handler masked. The
caller's own `syb_err_handler` gets the text raw (its business); `errstr` stays
raw. `t/120-error-values-live.t` runs the forms through the real storage on a
table of its own (date, datetime, time, bigdatetime, smallint, tinyint,
decimal, money warning, string too long, check constraint, duplicate keys,
create unique index, populate, update, NoBindVars, TEXT); what the client library
sends differs (FreeTDS converts an int overflow, an unsigned value or `'ab'` for
an int silently), each case tests what arrives. `t/121-error-values.t` is the
offline half (bulk callback, LOB errstr, warning, the hook's contract) and
`t/119-mask-error-details.t` the sentences.

## Introspection

`DBIO::Sybase::Introspect` extends `DBIO::Introspect::Base` — reads the ASE
system catalog (`sysobjects`, `syscolumns` + `systypes`, `syscomments` for
default/view text, `sysindexes` + `index_col()`, `sysreferences`). SAP ASE has
**no** `INFORMATION_SCHEMA` views (Msg 208 live on ASE 16.0; karr k48). Both
sides of the deploy diff are introspected, so every value must read back
identically for two deployments of the same DDL: the server-named PK index
carries `origin => 'pk'` and `Diff::Index` skips it; a quoted default comes back
as its bare literal, an expression default as a SCALAR ref, which
`Diff::Column` compares by its SQL. Sub-modules:

| Sub-module | Fetches |
|------------|---------|
| `DBIO::Sybase::Introspect::Tables` | table list |
| `DBIO::Sybase::Introspect::Columns` | column defs per table |
| `DBIO::Sybase::Introspect::Indexes` | index defs per table |
| `DBIO::Sybase::Introspect::ForeignKeys` | FK defs per table |
| `DBIO::Sybase::Introspect::Views` | view definitions + view dependencies (karr k98) |

Model shape: `{ tables, columns, indexes, foreign_keys, views }`. A view is in
`tables` (`kind => 'view'`) with its columns, and in `views` (`DBIO::Sybase::Introspect::Views`,
karr k98) as `{ view_name, definition, depends_on }`: `definition` is the text after `AS` (the
`syscomments` rows joined in `colid2`/`colid` order, the `CREATE VIEW` head stripped),
`depends_on` the views it reads from (`sysdepends`).

A column's `size` is `syscolumns.length` for the character types (halved for
`unichar`/`univarchar`, divided by `@@ncharsize` for `nchar`/`nvarchar`) and for
`binary`/`varbinary` (bytes, karr k93), `[prec, scale]` for `numeric`/`decimal`.
A `VARBINARY` written without a size is ASE's length 1 on both sides of the
diff (live: `t/94-binary-size-live.t`).

## Deploy

`DBIO::Sybase::Deploy` — test-deploy-and-compare. Sybase ASE does not
support `:memory:` databases, so it creates a temporary database
(`CREATE DATABASE _dbio_tmp_<pid>_<time>_<n>`, `<time>` in minutes so the name stays within
the 30 characters ASE allows, karr k97), deploys the desired schema
there, introspects both live and temp, diffs them, then drops the temp DB.

`_create_temp_db` and `_drop_temp_db` need a handle with `AutoCommit` (CREATE/DROP
DATABASE do not run in a transaction); one without is refused with a `DBIO::Exception`
naming the method, before any statement -- they send no `COMMIT` and never switch
`AutoCommit` (karr k96, `t/100`).

`_create_temp_db` sets `abort tran on log full` on the temp database before
anything is deployed into it (karr k69): from `master`, by `sp_dboption`, which
runs the checkpoint itself; its two severity-10 messages go to a borrowed
`syb_err_handler`, and the option is read back (`status2 & 1` in
`sysdatabases`). A database it cannot be set on is dropped and the error
raised. A database copied from `model` lacks the option, and without it ASE
suspends the session that finds the database full (`LOG SUSPEND`) instead of
refusing the statement -- `diff`/`upgrade` never returned. With it a schema too
large for the temp database dies of Msg 1105.

The temp database is created `ON default = 'NNM'` at a size calculated from the
schema (karr k69, the maintainer's decision), not the server's `default database
size` (live: 24 MB, 686 free pages of 16K; DBIO::Test::Schema needs 733, so it
did not fit). `(2 * tables + other indexes) * 8` pages (a table, its PK and
every further index take an extent of 8 pages, measured), counted from the
sources as `DBIO::Sybase::DDL` writes them (`_temp_db_objects`: no view, a table
once, unique column/constraint/declared index not twice), plus a quarter and 64
pages of reserve (the formula alone hit 688 of the 733 pages), plus the pages
`model` has in use, in the server's `@@maxpagesize`, up to the next 4 MB and not
below `model` (`_temp_db_megabytes`). Measured: DBIO::Test::Schema, 38 tables and
15 further indexes, 32 MB; the install used 783 pages and left 415. The
constructor option `temp_db_size => 'NNM'` (K/M/G/T, a bare number is MB;
`temp_db_size` accessor) replaces the calculation altogether, is no minimum, and
spares the query on `model`. A server without the room (Msg 1810: the default
device) dies naming the size asked for and the option; making room (`disk init`)
is not this class's. `trunc log on chkpt` is deliberately not set (measured: no
difference). `t/71` makes a too-small temp database by `temp_db_size`; `t/93`
pins the calculation offline.

`_drop_temp_db` repeats `DROP DATABASE` on Msg 3702 ("currently in use"), and on
no other error: 40 tries, 0.25 s apart, ten seconds (`_drop_in_use_tries`,
`_drop_in_use_wait`; karr k74). Core drops the temp database the moment it has
closed the session into it and catches whatever the drop dies of, so one refusal
left `_dbio_tmp_<pid>_<time>_<n>` on the server without a word -- and after the last
try it still does. What is in a database need not be a client: the server's
checkpoint process was seen in one nobody was connected to.

`DBIO::Sybase::DDL` reads the canonical index declaration of the source
(`$source->index_declarations_for('sybase', [])`; Cake `idx`, `indices`,
`add_index_declaration`; ADR 0061, core k333, karr k88) and writes each as
`CREATE [UNIQUE] INDEX` after the table's unique indexes, before the FKs. The
sybase block has no allowed key (ASE has no partial or function index), so
`where`/`expression`, a block of only another driver, a `type` other than
`unique`, any `options` and more than 31 key columns throw, naming the index.
An index over the columns (same order) of a written unique index (column flag,
unique constraint, PK) is not written twice; the same name over other columns
throws. There is no hand-written index attribute for this driver. The diff
needs nothing of its own: its desired model is the temp DB this DDL deployed.
Live: `t/74-ddl-index-declarations-live.t`.

`install` is inherited from `DBIO::Deploy::Base` and executes the statements of
`DBIO::Sybase::DDL->install_ddl($schema)`; the FK constraints come last, one
`ALTER TABLE ... ADD CONSTRAINT` each, after every `CREATE TABLE`.
`apply` and `upgrade` are those of `DBIO::Deploy::Base` (`allow_destructive`, `dry_run`;
ADR 0080, core k399): a diff with a drop or a lossy column change runs only with
`allow_destructive => 1`. `Diff::Column::Alter::lossy` calls only the integer
widenings `tinyint` to `smallint`/`int`/`bigint`, `smallint` to `int`/`bigint` and
`int` to `bigint` lossless (and a same-type size that does not shrink); every other
type change, `unsigned` types included, is lossy. The NULL look of a NOT NULL change
(`_refuse_nulls`, Msg 515) is `_check_before_apply`.

## Diff

`DBIO::Sybase::Diff` extends `DBIO::Diff::Base`. Operations in dependency
order: FK drops → view drops (removed and changed) → tables → PK drops → index drops → columns → PK adds →
index creates/alters → FK adds → view creates (new and changed). Views on views are
ordered by `depends_on` (a cycle throws a `DBIO::Exception`); only removed and changed views
are dropped, a server error over an unchanged dependent view is not caught. `Diff::Table` and
`Diff::Column` skip `kind => 'view'`. Sub-modules:

| Sub-module | Compares |
|------------|----------|
| `DBIO::Sybase::Diff::Table` | tables + primary keys |
| `DBIO::Sybase::Diff::Column` | columns |
| `DBIO::Sybase::Diff::Index` | indexes |
| `DBIO::Sybase::Diff::ForeignKey` | FK constraints (create/drop) |
| `DBIO::Sybase::Diff::View` | views: `CREATE VIEW`, `DROP VIEW`, drop + create when the definition (white space reduced) changed (karr k98) |

## FK Behavior

FKs are read from `sysreferences` and emitted in diff output. ASE has no
declarative referential actions (`ON DELETE`/`ON UPDATE` is Msg 156 on 16.0);
introspection reports both rules as `NO ACTION`. Not even `NO ACTION` is accepted
as syntax, so nothing is ever written. A declared `on_delete`/`on_update` other
than `NO ACTION` (undef/`''` = none) on a relationship that becomes a constraint
(`CASCADE`, `SET NULL`, `SET DEFAULT`, `RESTRICT`, any other word) is refused by
`DBIO::Sybase::DDL::_table_foreign_keys` with a `DBIO::Exception` naming
relationship, table, event and value -- before the deduplication, so the second
relationship over the same columns is refused too (karr k91). That covers
`install`, `diff` and `upgrade` (the desired side is the DDL deployed to the temp
DB). `Diff::ForeignKey::Create->as_sql` refuses the same on a hand-built model.
A relationship that yields no constraint (`is_foreign_key_constraint => 0`,
coderef condition, target outside the deploy, no unique base) is not looked at.
Tests that deploy `DBIO::Test::Schema` (core; declares SET NULL/CASCADE/RESTRICT)
neutralise the actions first with `t/lib/AseNoFkActions.pm`.

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::Sybase` | Schema component |
| `DBIO::Sybase::Storage` | DBI storage, declared base of the ASE class |
| `DBIO::Sybase::SQLMaker` | SQL generation (GenericSubQ pagination) |
| `DBIO::Sybase::Quote` | identifier quoting for DDL/Diff: `[name]` for ASE keywords and non-simple names (karr k92) |
| `DBIO::Sybase::Deploy` | test-deploy-and-compare orchestrator |
| `DBIO::Sybase::Diff` | Compare introspected models |
| `DBIO::Sybase::Introspect` | Read live DB |

## Design Notes

- **FreeTDS detection**: `_using_freetds` checks `syb_oc_version`. If
  FreeTDS, the `FreeTDS` trait is mixed into the current class at `_init`
  time using a dirty "instance role application" pattern.
- **`maxConnect` / `bulkLogin` DSN parts**: `_set_max_connect` remembers the
  value (`_max_connect_value`), appends `;maxConnect=N` to the stored DSN and
  reconnects. `_finish_connect_dsn` (core's seam, karr k60) adds `;maxConnect=N`
  once a value is remembered and `;bulkLogin=1` for the bulk storage, to the DSN
  of every connect with a string DSN -- which is what carries them past an
  AccessBroker, whose answer forms the DSN anew for each connect. Idempotent
  (a part already there is not added again); a coderef is left alone. The
  stored-DSN patches stay (t/59, t/90). `t/58` pins it offline, `t/61` live.
- **`_ping`**: uses `select 1` (no `sp_go` needed for modern DBD::Sybase).
- **Temp DB DSN patching**: `Deploy::_temp_dsn` replaces `database=` in the
  DSN, or appends `database=<temp>` when the DSN names none; it never writes
  `dbname=`, which DBD::Sybase does not read. Core's `_temp_connect_info`
  (`DBIO::Deploy::Base::TempDatabase`) calls it.
- **`apply`**: inherited from `DBIO::Deploy::Base`, not implemented here (the
  Sybase check is `_check_before_apply`, `_refuse_nulls`). Core
  splits `$diff->as_sql` on `;` (`DBIO::SQL::Util::_split_statements`), drops
  comment-only fragments, and runs the rest through `$dbh->do` one after
  another. There is no explicit commit: `_use_transactional_ddl(0)` keeps core
  from bracketing the batch in `txn_do`, so each statement stands on its own as
  the connection's `AutoCommit` lets it, and a failure part way leaves
  everything before it applied. See `Deploy.pm`'s "Transactional DDL" POD.

## Conformance

`Storage::ASE::_run_connection_actions` sends `set string_rtruncation on` on every connection
(first connect, reconnect, writer and bulk storage; karr k97, `t/113`): ASE cut a string that
was too long without a word (`char(10)` took 11 characters), it is Msg 9502 now. A behaviour
change for every user; `ddl-type-size-char` is answered right.

`DBIO::Sybase::Test::Conformance` (karr k97) answers core's shared case table
(`DBIO::Test::Conformance`, ADR 0060); `answered_through` is `{ DDL => 2, Diff => 4, Bind => 1 }` (version 4: the deploy cases, through
`conformance_deploy`; `conformance_upgrade` runs `upgrade(allow_destructive => 1)`). The namespace of a case is a database of
its own, `dbio_cf_<pid>_<n>`, made by `conformance_namespace` with `abort tran on log
full` and `select into/bulkcopy/pllsort` and dropped by `conformance_cleanup` (the
token names it). DBD::Sybase goes on in the login's default database (a warning
only) when the database named in the DSN is not there yet, so `conformance_install`
asserts `db_name()` first and `conformance_quote_ident` needs no connection. The
connection sets `datetime_setup` (ASE's default text for a `datetime` has no
seconds). Refusals: `ddl-enum-value-apostrophe`, `ddl-type-size-bit`,
`ddl-base-types-roundtrip` (a nullable `boolean`/`bit` is Msg 2718), `ddl-fk-actions`
(k91), `ddl-qualified-source-name` (a dot is `owner.name`), all `server`; deviation
`ddl-default-digit-string` (`char(n)` is blank-padded). `DBIO::Sybase::DDL` refuses
the first three itself, before the server is asked (`_check_column_type`).
The Diff list: `server` refusals for a NOT NULL add without a default or with an
expression default (`Diff::Column::Add`, Msg 13918), for a CASCADE (`diff-table-added-complete`)
and for NOT NULL over NULLs (`_check_before_apply` looks first, Msg 515), `diff-default-removed`
is answered right since core k367 (`REPLACE col DEFAULT NULL`, `t/112`). `conformance_cleanup` also closes the
schema the upgrade started from (it keeps the database in use, Msg 3702). The three view
cases are answered right since k98 (`Diff::View`). One named TODO in `t/106`: `diff-constraint-changed` (waits
for core k369). Bind: `bind-empty-string` is a deviation (ASE keeps `''` as one space; `''` into
an int is 0). Over FreeTDS four Bind cases plus `bind-non-ascii` (a TEXT column) are `server`
refusals: `LOBWriter::_refuse_lob_content` refuses LOB content before the INSERT/UPDATE
(`t/111`; offline tests that fake FreeTDS replace it). A character beyond ASCII bound for a
varchar/univarchar column over FreeTDS is refused by `ASE::_refuse_non_ascii_binds` and the bulk
path (`t/114`, live `t/115`): the client library reports the conversion after the row was
written, with a blank in it. `ddl-qualified-source-name` is refused always (the DDL never writes
`owner.table`). `t/109`/`t/110` for Bind.
`t/101`/`t/105` offline, `t/102-conformance-ddl-live.t`/`t/106-conformance-diff-live.t` live.

## Live Testing

`t/09-create-database-live.t`, `t/10-sybase.t`,
`t/30-datetime-sybase.t`,
`t/31-introspect-roundtrip-live.t`, `t/32-diff-primary-key-live.t`,
`t/60-connect-params-live.t`, `t/61-broker-dsn-patches-live.t`,
`t/62-component-rebless-live.t`, `t/63-uniqueidentifier-live.t`,
`t/64-txn-scope-guard-live.t`, `t/66-drop-database-in-use-live.t`, `t/68-lob-placeholder-live.t`,
`t/70-lob-row-values-live.t`, `t/71-temp-db-log-full-live.t` and
`t/74-ddl-index-declarations-live.t`, `t/77-fk-actions-live.t`, `t/120-error-values-live.t`, `t/89-char-size-live.t`, `t/94-binary-size-live.t`, `t/96-quote-ident-live.t`, `t/97-quote-diff-live.t`, `t/99-order-by-nulls-live.t`, `t/102-conformance-ddl-live.t`, `t/106-conformance-diff-live.t` and `t/110-conformance-bind-live.t` connect to a real ASE server and `skip_all` unless `$ENV{DBIO_TEST_SYBASE_DSN}`, `_USER` and
`_PASS` are set. Every other file under `t/` is offline and always runs. `t/60`
and `t/61` also `skip_all` unless the DSN is exactly
`dbi:Sybase:host=..;port=..;database=..` — they take the broker's parameters
out of it.

Throwaway ASE 16 for a local live run:

```bash
docker run -d --name dbio-ase -p 5000:5000 -e SYBASE_DB=testdb datagrip/sybase:16.0
# wait ~1 min until initialised:
until docker logs dbio-ase 2>&1 | grep -q 'SYBASE INITIALIZED'; do sleep 3; done

TDSVER=5.0 \
DBIO_TEST_SYBASE_DSN='dbi:Sybase:host=localhost;port=5000;database=testdb' \
DBIO_TEST_SYBASE_USER=sa DBIO_TEST_SYBASE_PASS=myPassword \
prove -lv t/10-sybase.t

docker rm -f dbio-ase   # teardown
```

Notes:
- `TDSVER=5.0` is required — ASE speaks TDS 5.0; FreeTDS otherwise negotiates wrong.
- The image's DBD::Sybase is **FreeTDS-backed**, so the `::FreeTDS` trait applies. Under
  FreeTDS, BCP/bulk (`_insert_bulk` falls back to regular inserts) and active-cursor
  statement multiplexing are unsupported; those assertions `SKIP` on `_using_freetds`.
- The image by itself has no room for `CREATE DATABASE` (Msg 1810: `master`, the only
  default device, has 20 MB left and a database needs the 24 MB of `model`). The pod of
  `maint/k8s/ase.yaml` makes a default device of its own at start (`dbiotestdev`, 384M)
  and is Ready only once it is there (karr k73) -- nothing by hand. A `docker run`
  container, as above, still needs it once before the first run: the `disk init` /
  `sp_diskdefault` lines in README.md, "Live tests". `t/09-create-database-live.t` asks
  the server for that room first and names what is missing; without it that file fails,
  `t/31`, `t/32`, `t/63`, `t/66` and `t/71` die before their first test (the room probe, a plain
  `CREATE DATABASE` before `plan`, is refused with Msg 1810) and `t/62` loses five.
- A live file that makes a database drops it with `AseDatabase::drop` (`t/lib/AseDatabase.pm`),
  never with a bare `DROP DATABASE`: the server may refuse the drop for a moment (Msg 3702,
  karr k74), and one refusal ended `t/63` in a full run. The helper repeats it on that message
  alone, ten seconds at most, and returns what the server said instead of dying -- the file
  fails one test by name and goes on. It uses nothing of `lib/`.
- Connect as `sa`/`myPassword` (not the `tester` login) — the Deploy/temp-db path needs
  `CREATE DATABASE`. The container's server name is `MYSYBASE`; connect by `host;port`,
  never by server name (FreeTDS has no interfaces entry for it).
