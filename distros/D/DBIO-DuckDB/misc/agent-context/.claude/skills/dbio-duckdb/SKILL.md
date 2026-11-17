---
name: dbio-duckdb
description: Load when working on the DBIO::DuckDB driver — storage, SQL generation, introspect/deploy/diff, Quack, extensions, native escape hatches (appender, Arrow).
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::DuckDB

DuckDB is an embedded analytical OLAP DB. DBIO::DuckDB sits on DBD::DuckDB (FFI, no XS compile). Synchronous only — no async path.

## Component Loading

```perl
package MyApp::DB;
use DBIO Schema => -du;                      # the shortcut
# or: use base 'DBIO::Schema'; __PACKAGE__->load_components('DuckDB');
# → sets storage_type to +DBIO::DuckDB::Storage automatically
```

## Storage

`DBIO::DuckDB::Storage` extends `DBIO::Storage::DBI`:

```perl
my $schema = MyApp::DB->connect('dbi:DuckDB:dbname=app.duckdb');
my $v = $schema->storage->duckdb_version;   # e.g. v1.0.0
```

### Key settings

```perl
__PACKAGE__->sql_maker_class('DBIO::DuckDB::SQLMaker');
__PACKAGE__->sql_quote_char ('"');
```

`DBIO::DuckDB::Storage` declares `supports_exists_query` (core's `EXISTS` form
passes unchanged, ADR 0037) and `transactional_ddl` as 1 (ADR 0005). It sets no
`datetime_parser_type`; the core default applies.

### Escape Hatches

```perl
# Bulk insert via DuckDB Appender API
my $app = $storage->duckdb_appender($table);
$app->append_row(id => $row->{id}, name => $row->{name});
$app->flush;

# Table function reads
my $csv = $storage->duckdb_read_csv('/path/to/file.csv');
my $pq  = $storage->duckdb_read_parquet('/path/to/file.parquet');
my $js  = $storage->duckdb_read_json('/path/to/file.json');

# Arrow fetch: the result as columns, read through libduckdb's Arrow interface
my $t = $storage->duckdb_arrow_fetch('SELECT id, name FROM t WHERE id > ?', [42]);
# $t->{names}   ['id', 'name']     $t->{formats} ['i', 'u']  (Arrow format per column)
# $t->{columns} [ [43, 44], ['a', 'b'] ]  one array per column, NULL = undef
# $t->{rows}    2
# values as selectall_arrayref, except DATE, TIME, TIMESTAMP and INTERVAL, which are
# DuckDB's own text (CAST(v AS VARCHAR)), and TIMESTAMPTZ (UTC); UNION, BIT, BIGNUM,
# TIME WITH TIME ZONE and a MAP with a nested key throw (decoder: DBIO::DuckDB::Arrow)

# Flush the WAL
$storage->duckdb_checkpoint;
```

### Statement handles

The storage releases its own connection's prepared statements through DBI
`ChildCallbacks` (`_duckdb_release_statements`, ADR 0006), so disconnect gives
the database file back. A handle that has no result gets an empty
`duckdb_result` first, so a void-context `populate` whose first row is refused
throws instead of crashing (`t/51-finish-without-result.t`; a plain DBI handle
outside the storage still crashes, so a test that needs the crash runs it in a
child process).

In driver code: `$dbh->prepare`, never `prepare_cached`, one execution per
handle. `disable_sth_caching` answers true always, `=> 0` changes nothing
(ADR 0007, `t/49-statement-reuse.t`).

## SQLMaker

`DBIO::DuckDB::SQLMaker` — no FOR UPDATE, `"` quoting.

## Introspection

`DBIO::DuckDB::Introspect` extends `DBIO::Introspect::Base` — reads via `information_schema` + DuckDB system views.

Model shape: `{ tables, columns, indexes, foreign_keys, unique_constraints }`.

## Deploy

`DBIO::DuckDB::Deploy` — test-deploy-and-compare via `:memory:` DuckDB.

## Foreign keys and table rebuild

FKs are **enforced by DuckDB and written in install DDL**, columns in the parent PK/unique order, tables after their parents. `ON DELETE/UPDATE CASCADE`, `SET NULL`, `SET DEFAULT` are refused loudly (DuckDB rejects them at parse time); `RESTRICT`/`NO ACTION` pass.

What DuckDB cannot ALTER -- a column dropped under an index/UNIQUE, a dropped UNIQUE, an FK added or dropped on an existing table -- is done by a table rebuild (`DBIO::DuckDB::Diff::Rebuild`, ADR 0010): new table under a temporary name, common columns copied, old dropped, renamed, indexes recreated, all in the apply's one transaction. Refused before the first statement: a table another table has an FK to, and a self-referencing table.

## Extensions

`__PACKAGE__->duckdb_extensions('httpfs', spatial => { class => '...' })` declares
the list (core ADR 0066, local ADR 0009); the only option is `class`, the default
class is `DBIO::DuckDB::Extension`. Every new connection runs `INSTALL x` + `LOAD x`
(an extension DuckDB lacks fails the connect), `Deploy` activates them in the
throwaway target DB, and the installed state comes from `duckdb_extensions()`
(`t/80`-`t/82`). `duckdb_install_extension($name, load => 1)` is the one-off.

## Quack

Quack is a DuckDB extension that serves an embedded instance over RPC (needs
libduckdb >= 1.5; `t/60`-`t/63`, ADR 0003). On `Storage`:
`quack_serve($addr, token => ...)`, `quack_attach($addr, as => $alias, token => ...)`,
`quack_detach($name)` and the on-connect hook `connect_call_quack_attach`.
The attached catalog is opaque to `information_schema` and `Introspect`: deploy on
the server process, and read client-side columns with `PRAGMA table_info('alias.tbl')`.
Errors carry no token. Full detail: `CLAUDE.md`.

## Auto-increment

Sequence per auto-increment column, `DEFAULT nextval('<table>_<col>_seq')`
(ADR 0004); UUID/GUID columns default via `uuid()`.

## Tests

`../dbio/maint/capped-test prove -lr t/` (offline, in-memory DuckDB; embedded,
so there is no server and no `live-preflight`). Another database:
`DBIO_TEST_DUCKDB_DSN`, one run per database. Rules and structure:
`dbio-driver-development` (section Testing, `references/live-testing.md`).

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::DuckDB` | Schema component |
| `DBIO::DuckDB::Storage` | DBI storage + escape hatches |
| `DBIO::DuckDB::SQLMaker` | SQL generation |
| `DBIO::DuckDB::Deploy` | test-deploy-and-compare |
| `DBIO::DuckDB::Diff` | Compare introspected models |
| `DBIO::DuckDB::Introspect` | Read live DB |
| `DBIO::DuckDB::Extension` | Plain extension class |
| `DBIO::DuckDB::Arrow` | Decoder behind `duckdb_arrow_fetch` |
