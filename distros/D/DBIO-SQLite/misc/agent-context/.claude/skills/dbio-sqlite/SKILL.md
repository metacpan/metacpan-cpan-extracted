---
name: dbio-sqlite
description: Load when working on the DBIO::SQLite driver — storage, SQLMaker, deploy, capabilities, foreign keys, WAL mode.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO SQLite driver: synchronous storage, SQLMaker, native deploy, extensions.

## Components

| Class | Role |
|-------|------|
| `DBIO::SQLite` | Schema entry point |
| `DBIO::SQLite::Storage` | DBI storage (core) |
| `DBIO::SQLite::SQLMaker` | SQL dialect (no FOR UPDATE; `ON CONFLICT` upsert, `INSERT OR IGNORE/REPLACE`) |
| `DBIO::SQLite::Deploy` | Native deploy (test-and-compare) |
| `DBIO::SQLite::Result` | Result component: `sqlite_index` (partial and expression indexes) read by the DDL |
| `DBIO::SQLite::Extension`, `Extension::{FTS5,RTree,VirtualTable}` | Extension classes behind `sqlite_extensions` |
| `DBIO::SQLite::JSON`, `JSON::Op` | JSON path expression helpers (`json($col)`) |
| `DBIO::SQLite::Test`, `Test::Conformance` | Test helper; driver half of core's shared conformance cases |

## Connection

```perl
package MyApp::DB;
use DBIO Schema => -sqlite;   # pins DBIO::SQLite::Storage as the storage type
__PACKAGE__->connect("dbi:SQLite:dbname=myapp.db");
```

The explicit form is `use DBIO 'Schema'; __PACKAGE__->load_components('SQLite');`.
Core picks no storage class from the DSN (core ADR 0067).

`DBIO::SQLite::Storage` registers the DBD at load time:
`__PACKAGE__->register_driver('SQLite' => __PACKAGE__)`. Core reads the registry for
`DBIO->driver_for` and to check a declared storage against the DBD of its DSN.

In-memory: `dbi:SQLite:dbname=:memory:`

## Storage Setup

```perl
__PACKAGE__->connection("dbi:SQLite:dbname=:memory:", "", "", {
  sqlite_unicode => 1,
});
```

## FK Enforcement

NOT enabled by default. Enable per-connection:
```perl
$dbh->do("PRAGMA foreign_keys = ON");
```

Or at connect time: `{ on_connect_call => 'use_foreign_keys' }`
(`DBIO::SQLite::Storage::connect_call_use_foreign_keys`).

## WAL Mode (recommended for concurrency)

```perl
$dbh->do("PRAGMA journal_mode=WAL");
```

## Capabilities

- `multicolumn_in`: supported since SQLite 3.14 (off below)
- `insert_returning`: supported since SQLite 3.35 (`_determine_supports_insert_returning`); `supports_upsert` follows it, so `upsert` throws on 3.24-3.34 (ADR 0036)
- `supports_upsert_where` (`update_where` of `upsert`): always declared, it is a fact of the SQLMaker
- `supports_exists_query` (`results_exist`): always declared (ADR 0037)
- `for_update`: NOT supported (SQLMaker disables it)
- `transactional_ddl`: declared 0 on purpose (`__PACKAGE__->_use_transactional_ddl(0)` in `Storage.pm`).
  The rebuild of a table runs `PRAGMA foreign_keys` statements that only take effect outside a
  transaction; `t/42-deploy-transactional-ddl.t` pins value and declaredness

## Deploy

Uses native `DBIO::SQLite::Deploy` — introspect live DB, deploy desired schema to throwaway in-memory DB, diff the two. No SQL::Translator needed.

```perl
$schema->deploy;  # uses DBIO::SQLite::Deploy
```

## Extensions

```perl
__PACKAGE__->sqlite_extensions('fts5', 'rtree');
__PACKAGE__->sqlite_extensions(vec0 => { library => '/opt/sqlite/vec0.so' });
```

`sqlite_extensions` declares the list, `sqlite_extension_options` returns the options
(`library`, `class`). A `library` is loaded into every new connection; the deploy and diff keep
the shadow tables of FTS5 and R*Tree out of the model (ADR 0066 of core).

## Native Modules

```perl
use DBIO::SQLite::Introspect;  # schema introspection
use DBIO::SQLite::Diff;        # diff two schemas
use DBIO::SQLite::DDL;         # DDL generation
```

## Testing

```perl
# Offline (no server): DBIO::SQLite::Test connects to :memory: by default.
# The :memory: default and the env vars below belong to DBIO::SQLite::Test.
my $schema = DBIO::SQLite::Test->init_schema(no_deploy => 1);

# It declares DBIO::SQLite::Storage unless storage_type names another class
# (core ADR 0067: a schema always has a driver), also for replicated => 1.

# DBIO::Test->init_schema without dsn/connect_info builds a fake storage with
# no database at all -- use it only for offline SQLMaker checks. With a dsn it
# needs storage_type => 'DBIO::SQLite::Storage'.

# DBIO::Test::Schema keeps no driver in its class: a test that connects it
# directly declares one on a clone first.
my $s = DBIO::Test::Schema->clone;
$s->storage_type('DBIO::SQLite::Storage');
$s = $s->connect('dbi:SQLite::memory:');

# Integration (real DB): point the suite at your own DB.
DBIO_TEST_DSN=dbi:SQLite:dbname=/path/to/your.db
# or run against a temp file instead of :memory:
DBIO_TEST_SQLITE_USE_FILE=1
```

Environment variables: `DBIO_TEST_DSN` (+ `DBIO_TEST_DBUSER` / `DBIO_TEST_DBPASS`),
`DBIO_TEST_SQLITE_USE_FILE` (see `DBIO::SQLite::Test`).
Run the suite recursively through the cap wrapper from core, never `prove -l t/` (it skips the
subdirectories) and never `prove -j`:

```
../dbio/maint/capped-test prove -lr t/
```

## SQLMaker Override

```perl
package DBIO::SQLite::SQLMaker;
use base 'DBIO::SQLMaker';
sub _lock_select () { '' }   # SQLite has no SELECT FOR UPDATE
```

`insert` is overridden too: it consumes `$options->{on_conflict}` (the `ON CONFLICT` tail of the
atomic upsert, ADR 0036) and `$options->{insert_or}` (`INSERT OR IGNORE` / `INSERT OR REPLACE`)
before delegating to the generic `insert`.
