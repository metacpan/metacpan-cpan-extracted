# CLAUDE.md — DBIO::DuckDB

This distribution tracks only what is its own: `.claude/skilletor.json`, its `dbio-duckdb*`
skills and the settings. The family skills, the house rules
(`.claude/rules/.local.dbio-rules.md`) and the agents (`dbio-worker-duckdb`,
`dbio-release-manager`, `karr-coordinator`, `dbio-adr-auditor`) come from core through
skilletor and are git-ignored: **a fresh clone or worktree has them only after
`skilletor sync`** (plugin `skilletor@getty`, network access to the sources named in
`skilletor.json`). Run it before you rely on anything named here, and never edit an
installed copy -- change the source in core. The family-wide house rules (discipline,
delegation, release) are auto-loaded by Claude Code for the main agent and all subagents.

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-duckdb` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-duckdb` (default), `dbio-release-manager`,
`karr-coordinator`, `dbio-adr-auditor`.

## Namespace

- `DBIO::DuckDB` -- DuckDB schema component
- `DBIO::DuckDB::Storage` -- DuckDB storage (inherits `DBIO::Storage::DBI`)
- `DBIO::DuckDB::SQLMaker` -- DuckDB SQL generation
- `DBIO::DuckDB::{DDL,Deploy,Introspect,Diff}` -- schema mgmt, test-and-compare
- `DBIO::DuckDB::Util` -- `mask_error_details`, the engine's error text with values replaced by `***` (ADR 0012)
- `DBIO::DuckDB::Extension` -- plain extension class of the declared list (ADR 0066)
- `DBIO::DuckDB::Arrow` -- decoder behind `duckdb_arrow_fetch` (libduckdb's Arrow interface); loaded by the method, not by the storage class

## Usage

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('DuckDB');

my $schema = MyApp::DB->connect('dbi:DuckDB:dbname=app.duckdb');
```

## Design notes

- **Built on DBD::DuckDB** (FFI-based, no XS compile). We do NOT reimplement
  the DBI layer. DuckDB is embedded and synchronous, so there is no
  async-driven reason to go raw like dbio-postgresql-async.
- **Escape hatches for DuckDB-native features** live as methods on
  `DBIO::DuckDB::Storage`, bypassing DBI where DBI hurts:
  - `$storage->duckdb_appender($table)` -- bulk insert via DuckDB's
    Appender API (wraps DBD::DuckDB's `x_duckdb_appender`).
  - `$storage->duckdb_arrow_fetch($sql, \@binds)` -- reads the result
    through libduckdb's Arrow interface (`DBIO::DuckDB::Arrow`) and returns
    `{ names, formats, columns, rows }`: one array of values per column, NULL
    as `undef`. Values equal `selectall_arrayref` laid on its side, except that
    DATE, TIME, TIMESTAMP and INTERVAL are DuckDB's own text
    (`CAST(v AS VARCHAR)`: fraction without trailing zeros, `0044-03-15 (BC)`,
    `infinity` / `-infinity`) and TIMESTAMPTZ is UTC. UNION, BIT,
    BIGNUM, TIME WITH TIME ZONE, TIME_NS and a MAP with a nested key throw,
    naming column and format. ADR 0002 (addendum 2026-10-31).
  - `$storage->duckdb_read_csv($path, \%opts)` / `duckdb_read_parquet` /
    `duckdb_read_json` -- table-function helpers.
- **No statement cache.** `DBIO::DuckDB::Storage` overrides
  `disable_sth_caching` to always answer true, so core's `_prepare_sth` never
  calls `prepare_cached`; `disable_sth_caching => 0` changes nothing. A
  DBD::DuckDB 0.16 handle cannot be used twice: `finish` destroys the
  statement, `execute` never sets `Active`, and `execute` keeps the previous
  result's chunk -- which returns wrong rows without an error. In driver code
  use `$dbh->prepare`, one execution per handle. See
  `docs/adr/0007-no-statement-handle-from-the-dbi-cache.md`; the upstream
  draft is `docs/upstream/dbd-duckdb-statement-handles-cannot-be-reused.md`.
- **`finish` without a result.** DBD::DuckDB 0.16's `finish` segfaults on a
  handle that has no result (never executed, only refused executes, finished
  before), and core finishes the handle of a bulk insert whatever happened to
  it. The ADR 0006 callback gives such a handle an empty `duckdb_result`
  first, so a void-context `populate` whose first row is refused throws
  instead of ending the process. Bound to DBD::DuckDB <= 0.16; a plain DBI
  handle outside the storage still crashes. See the 2026-10-08 addendum of
  `docs/adr/0006-storage-frees-dbd-duckdb-prepared-statements.md` (karr k38).
- **Introspection** uses the standard `information_schema` plus
  `duckdb_indexes()` (tables, columns, constraints and views all come from
  `information_schema`).
- **Deploy** uses the test-deploy-and-compare pattern: introspect live,
  deploy desired into a throwaway in-memory DuckDB, introspect that,
  diff. Matches dbio-sqlite (simpler than PostgreSQL because DuckDB also
  supports `:memory:`). `apply`/`upgrade` are core's (ADR 0080): a drop or a
  lossy column change needs `allow_destructive => 1` (`Diff::Column::lossy`,
  ADR 0011); the driver hooks are `_check_before_apply` and `_execute_diff`.
- **Foreign keys** are enforced by DuckDB (an insert without a parent fails) and
  are written in install DDL, columns in the parent PK/unique order, tables
  after their parents. `ON DELETE/UPDATE CASCADE`, `SET NULL` and `SET DEFAULT`
  are refused loudly with table and column (DuckDB rejects them at parse
  time); `RESTRICT`/`NO ACTION` pass. A FK change on an *existing* table
  rebuilds the table (`Diff::Rebuild`, k50, ADR 0010; hub decision 2026-10-26,
  replacing the 2026-10-25 refusal); FKs of a table the diff creates are
  written. Introspected FKs carry the live name as `constraint_name`
  (ADR 0021), read via `duckdb_constraints()`. See
  `docs/adr/0001-foreign-keys-omitted-from-install-ddl.md` (addendum 2026-10-25).
- **Table rebuild** (k50, `docs/adr/0010-tables-are-rebuilt-for-what-alter-cannot-do.md`):
  what DuckDB cannot ALTER -- a column dropped under an index/UNIQUE on it or a
  later column, a UNIQUE constraint dropped, a FK added/dropped, a UNIQUE a FK
  of the target points to (DuckDB takes a key to a constraint, not to a unique
  index) -- is done by `DBIO::DuckDB::Diff::Rebuild`: new table
  `t__dbio_rebuild`, rows of the common columns copied, old dropped, new
  renamed, target indexes created again, all in the apply's one transaction.
  Refused before the first statement, naming both tables: a table another
  table has a FK to (`DROP TABLE` fails, measured 1.5.3) and a self-referencing
  table (the FK keeps the temporary name through the rename).
- **Indexes** are read from the canonical declaration
  (`$source->index_declarations_for('duckdb', ['expression'])`: Cake `idx`, `indices`)
  plus the hand-written `duckdb_indexes`; canonical wins on the same name.
  DuckDB refuses partial indexes and has no USING, so the only driver
  key is `expression`; `type` other than unique and `options` throw.
  An expression index is written and read back as its expression
  (Introspect::Indexes reads the `sql`). ADR 0008.
- **Extensions** are a declared list (core ADR 0066, karr k46):
  `__PACKAGE__->duckdb_extensions('httpfs', spatial => { class => '...' })`,
  the only option is `class`; classes are `DBIO::DuckDB::Extension` (plain,
  `activation` = `{ load => name }`, no family classes). `Storage::_extension_activation`
  / `_activate_extensions` run `INSTALL x` + `LOAD x` on every new connection
  (an extension DuckDB lacks fails the connect), and `Deploy::_build_target_model`
  activates them in the throwaway target DB. State comes from `duckdb_extensions()`
  (`Deploy::_extension_list`); no claims, no annotations, never a drop. An
  extension never determines the driver: `connection` only registers storage layers.
- **Sequences** are real. Auto-increment via `DEFAULT nextval('seq')`.
- **`SELECT ... FOR UPDATE`** is not supported -- SQLMaker disables it.
- **Identifier quoting** is `"` (same as PostgreSQL / SQLite).

## Quack (Client-Server RPC)

Quack is a DuckDB extension (v1.5+) that exposes an embedded DuckDB instance
over HTTP-based RPC, turning it into a lightweight server while keeping the
client a normal in-process DuckDB via `DBD::DuckDB`.

**Requires libduckdb >= 1.5.** `Alien::DuckDB` 0.04 (2026-09-13) bundles
libduckdb 1.5.3. dbio-duckdb requires `Alien::DuckDB` >= 0.04 itself at
runtime, because DBD::DuckDB 0.16 declares it only as a test prereq -- a
`cpanm --notest DBD::DuckDB` alone installs no libduckdb at all (karr k26).
Older `Alien::DuckDB` 0.03 shipped 1.2.2, which does NOT include quack; with
such an install, supply a newer libduckdb:

```bash
DUCKDB_NO_ALIEN=1 LD_LIBRARY_PATH=/path/to/1.5.x perl ...
```

DBD::DuckDB is pure FFI -- no rebuild required for a lib swap.

### Escape hatches on `DBIO::DuckDB::Storage`

- `$storage->quack_serve($addr, token => $tok)` -- loads quack extension
  then calls `CALL quack_serve(...)`. `$addr` must start with `quack:`.
- `$storage->quack_attach($addr, as => $alias, token => $tok, read_only => 0)`
  -- loads quack, then ATTACHes the remote as a named catalog. `as` is
  required and must be a valid SQL identifier. With `token`, the token goes
  into a temporary secret `dbio_quack_<alias>` with `SCOPE '<addr>'`; secret
  and ATTACH run in one `txn_do`, so a failed ATTACH leaves the secret store
  as it was. Without `token` no secret is touched.
- `$storage->quack_detach($name)` -- DETACHes the named catalog, then
  `DROP SECRET IF EXISTS dbio_quack_<name>`; other secrets stay. The DROP
  also runs after a failed DETACH, whose error is the one thrown. Works
  without quack loaded.
- Secret lookup limits (DuckDB): a scope is a prefix match, longest prefix
  wins; of two secrets with the same scope the name that sorts first wins.
- `connect_call_quack_attach` -- on-connect hook for `on_connect_call`:
  `[[ quack_attach => { addr => '...', as => 'remote', token => '...' } ]]`

### Introspection caveat

The remote quack catalog is **opaque to `information_schema`** and
`duckdb_indexes()`. `DBIO::DuckDB::Introspect` (and `Deploy->diff`) cannot
enumerate remote tables. Deploy the schema on the **server** process; do not
run `Deploy` against a quack-attached client catalog.

The client's view is a snapshot taken at ATTACH (libduckdb 1.5.3, `t/63`):
tables the server creates afterwards are invisible ("Table ... does not
exist") until `quack_detach` + `quack_attach` (or a second alias) re-reads
it; rows of known tables are live. `duckdb_databases()`, `PRAGMA
database_list` and `SHOW DATABASES` throw "InMemory not implemented yet"
while a quack catalog is attached; test for an alias with
`information_schema.schemata` (`catalog_name`) or `duckdb_schemas()`.

To verify columns on the client side use:
`PRAGMA table_info('remote.tablename')` -- returns `cid`, `name`, `type`,
`notnull`, `dflt_value`, `pk` and works correctly over quack.

The `catalog` attribute on `DBIO::DuckDB::Introspect` and
`DBIO::DuckDB::Deploy` is for **locally-attached file catalogs** (e.g.
`ATTACH '/path/x.duckdb' AS mycat`), not for quack remotes.

## Tests

End-to-end TAP tests under `t/`. DBD::DuckDB is a hard `requires`, so
tests assume libduckdb and DBD::DuckDB are present — no skip-fallbacks.

- `t/00-load.t`       — `use_ok` every DBIO::DuckDB module
- `t/08-shortcut.t`   — component / connect shortcut
- `t/10-smoke.t`      — connect, deploy, insert, join+prefetch query
- `t/11-exists-query-seam.t`, `t/12-set-operations.t` — EXISTS and set-operation seams
- `t/20-introspect.t`, `t/21-introspect-contract.t` — introspect a freshly deployed in-memory DB; contract
- `t/30-deploy.t`     — DDL generation + deploy round-trip
- `t/31-ddl-column-type.t`, `t/32-ddl-not-null.t`, `t/35-ddl-emit.t` — DDL emission
- `t/40-diff.t`       — diff empty DB → apply → diff idempotent
- `t/41-diff-drop-table-index.t` — drop table / index diffs
- `t/42-deploy-transactional-ddl.t`, `t/44-txn-rollback.t` — ADR 0005
- `t/43-random-and-explain.t`, `t/45-numeric-bind-precision.t`, `t/46-server-version.t`
- `t/47-disconnect-releases-file-lock.t` — ADR 0006
- `t/48-no-savepoints.t` — no savepoints: core's refusal, nothing sent to the engine
- `t/49-statement-reuse.t` — ADR 0007: the same create / find / single / first /
                        populate again on one connection, two cursors read in turn
- `t/36-ddl-literals.t` — quote in a default, ENUM values, reserved-word name, UNIQUE constraint (karr k49)
- `t/68-arrow-fetch.t` — `duckdb_arrow_fetch`: every type against the row path, the time types against DuckDB's text (row path as TODO), TIMESTAMPTZ in UTC,
                        refusals, hand-built arrays with offset, death in the middle of a block
- `t/69-arrow-storage-load.t` — the storage class loads without the Arrow module (and without libduckdb by name)
- `t/50-arrow.t`      — escape hatches: `duckdb_appender`,
                        `duckdb_arrow_fetch`, `duckdb_read_csv`
- `t/51-finish-without-result.t` — karr k38: a refused `populate` / a `finish`
                        on a handle without a result is an exception, not a
                        crash; every scenario runs in a child process
- `t/52-index-declaration.t` — canonical index declarations in install DDL and
                        the diff's desired model; refusals (ADR 0008)
- `t/54-fk-constraint-name.t` — introspected FKs carry `constraint_name` (ADR 0021), file DB
- `t/60-quack.t`      — quack RPC: `quack_serve`, `quack_attach`,
                        `quack_detach`, `connect_call_quack_attach`
                        (skips if libduckdb < 1.5 / quack unavailable)
- `t/61-quack-secrets-masked.t`, `t/62-quack-token-quotes.t` — quack errors
                        carry no token; a quote in a token is doubled, safe
- `t/63-quack-client-catalog.t` — what the attached catalog shows the client:
                        listings that throw, tables created after ATTACH, refresh
- `t/64-foreign-keys.t`, `t/65-diff-unique.t` — FKs in install DDL / diff; UNIQUE in the diff model
- `t/66-diff-rebuild.t` — table rebuild (karr k50, ADR 0010): dropped column under index/UNIQUE, dropped UNIQUE,
                        FK added/dropped, parent-first order, rollback of a failing copy, refusals
- `t/67-diff-lossy.t` — which column type changes keep every value (ADR 0011): widenings run, the rest needs `allow_destructive`
- `t/93-conformance-names.t` — the Names list (core k391): extension and library names, `schema` not applicable
- `t/90-conformance-ddl.t` — the core DDL case list through `DBIO::DuckDB::Test::Conformance` (ADR 0060, karr k49)
- `t/80-extension-list.t` — `duckdb_extensions` declaration, refusals, class resolution (ADR 0066)
- `t/81-extension-activation.t` — a declared extension is INSTALLed + LOADed per connection; unknown one fails connect
- `t/82-extension-installed-state.t` — installed state from `duckdb_extensions()`; diff target DB has the extension loaded
- `t/90-conformance-ddl.t`, `t/91-conformance-diff.t`, `t/92-conformance-bind.t` — shared
                        case lists of core (ADR 0060), answered by `DBIO::DuckDB::Test::Conformance`
- `t/71-error-values-masked.t`, `t/72-error-mask-unit.t` — the engine's error text names no bound value (`DBIO::DuckDB::Util::mask_error_details`, ADR 0012): every sentence form for statements, the appender and the Arrow path keeps type, column, constraint and the statement's LINE excerpt; unit table of the masker. `Storage::_mask_error_values` is core's hook (ADR 0075): the LINE excerpt is split off, the head passes `mask_error_details` and core's net (`next::method`) with the bound values core hands in (plus the UTF-8 form of non-ASCII ones), the excerpt is put back. The Arrow path masks through the same method; the appender has the sentences only
- `t/73-error-values-without-reader-callbacks.t` — the bound values stay out of the error text with the bind_param/fetch callbacks left out of the handle and with them: sentence form, sequence name, non-ASCII
- `t/70-exceptions.t` — exception behaviour

Round-trip tests use `DBIO::DuckDB::Test->init_schema(%opts)`: the core
`DBIO::Test::Schema` fixture, forced onto `+DBIO::DuckDB::Storage`, in-memory
unless `DBIO_TEST_DUCKDB_DSN` is set. Offline tests use
`DBIO::Test::Schema->clone` plus `storage_type('+DBIO::DuckDB::Storage')`.
No local `t/_Schema.pm`, no `FindBin`, no `use lib`.
Run every suite through the house-rule wrapper (rule 9), and recursively:

```bash
../dbio/maint/capped-test prove -lr t/        # offline (default): in-memory DuckDB
../dbio/maint/capped-test dzil test
```

`prove -l t/` without `-r` skips subdirectory tests; use it only on one explicit file.
Offline is the default and touches no server. For a run against a database file or
another DSN set `DBIO_TEST_DUCKDB_DSN` (see below); one run per database at a time,
never `prove -j`.

Tests default to `dbi:DuckDB:dbname=:memory:`; set `DBIO_TEST_DUCKDB_DSN`
(and optionally `_DBUSER`/`_DBPASS`) to point tests that go through
`DBIO::DuckDB::Test` at another database.
