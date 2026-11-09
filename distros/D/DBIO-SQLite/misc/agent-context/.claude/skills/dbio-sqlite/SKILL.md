---
name: dbio-sqlite
description: Load when working on the DBIO::SQLite driver — storage, SQLMaker, deploy, capabilities, foreign keys, WAL mode.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO SQLite driver — fork of DBIx::Class::SQLite.

## Components

| Class | Role |
|-------|------|
| `DBIO::SQLite` | Schema entry point |
| `DBIO::SQLite::Storage` | DBI storage (core) |
| `DBIO::SQLite::SQLMaker` | SQL dialect (disables FOR UPDATE) |
| `DBIO::SQLite::Deploy` | Native deploy (test-and-compare) |

## Connection

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('SQLite');
__PACKAGE__->connect("dbi:SQLite:dbname=myapp.db");
```

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

## Register Driver

```perl
package DBIO::SQLite::Storage;
use base 'DBIO::Storage::DBI';
__PACKAGE__->register_driver('SQLite' => __PACKAGE__);
```

## Capabilities

- `last_insert_id`: uses `last_insert_rowid()`
- `multicolumn_in`: supported since SQLite 3.14 (disable for <3.14)
- `insert_returning`: supported since SQLite 3.35 (`_determine_supports_insert_returning`); `supports_upsert` follows it
- `for_update`: NOT supported (SQLMaker disables it)

## Deploy

Uses native `DBIO::SQLite::Deploy` — introspect live DB, deploy desired schema to throwaway in-memory DB, diff the two. No SQL::Translator needed.

```perl
$schema->deploy;  # uses DBIO::SQLite::Deploy
```

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

`DBIO_TEST_SQLITE_DSN` is intentionally NOT defined -- nothing reads it
(see `lib/DBIO/Manual/Heritage.pod` and `t/storage/quote_names.t:62-67`).
Run the suite with `prove -lr t/`, not `prove -l t/`: most of it lives in
subdirectories of `t/` and the non-recursive form silently skips them.

## SQLMaker Override

```perl
package DBIO::SQLite::SQLMaker;
use base 'DBIO::SQLMaker';
sub _lock_select { '' }  # SQLite has no SELECT FOR UPDATE
```