---
name: dbio-sqlite
description: "DBIO::SQLite driver: storage, SQLMaker, deploy, capabilities, usage patterns"
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

Or via connect attr: `{ sqlite_use_immediate_transaction => 1 }`

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
- `insert_returning`: NOT supported
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
# Offline (no DB)
my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::SQLite::Storage',
);

# Integration (real DB)
DBIO_TEST_SQLITE_DSN=dbi:SQLite:dbname=:memory:
```

## SQLMaker Override

```perl
package DBIO::SQLite::SQLMaker;
use base 'DBIO::SQLMaker';
sub _lock_select { '' }  # SQLite has no SELECT FOR UPDATE
```