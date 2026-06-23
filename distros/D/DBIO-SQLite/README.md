# DBIO::SQLite

SQLite driver for DBIO (fork of DBIx::Class::Storage::DBI::SQLite).

## Supports

- desired-state deployment via test-deploy-and-compare ([DBIO::SQLite::Deploy](https://metacpan.org/pod/DBIO::SQLite::Deploy))
- native introspection ([DBIO::SQLite::Introspect](https://metacpan.org/pod/DBIO::SQLite::Introspect))
- native diff ([DBIO::SQLite::Diff](https://metacpan.org/pod/DBIO::SQLite::Diff))
- native DDL generation ([DBIO::SQLite::DDL](https://metacpan.org/pod/DBIO::SQLite::DDL))

## Usage

    package MyApp::DB;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('SQLite');

    my $schema = MyApp::DB->connect('dbi:SQLite:myapp.db');

For in-memory testing:

```perl
my $schema = MyApp::DB->connect('dbi:SQLite::memory:');
```

DBIO core autodetects `dbi:SQLite:` DSNs and loads this storage automatically.

## SQLite Features

**Types**
- `INTEGER` - 64-bit signed integer (also used for PRIMARY KEY / AUTOINCREMENT)
- `REAL` - IEEE 754 64-bit floating point
- `TEXT` - UTF-8 text
- `BLOB` - binary data (stored as-is)
- `NUMERIC` - affinity for integer/real/decimal

**SQLite JSON (version 3.38+)**
- `JSON` type with `json_extract`, `json_array`, `json_object` functions
- `->` and `->>` operators for JSON path extraction
- Comparison operators work on JSON values

**Full-Text Search (FTS5)**
- `fts5` virtual table support via `DBIO::SQLite::Result::FTS5`
- `MATCH` operator for full-text queries
- BM25 ranking and relevance scoring
- Trigram tokenizers for fuzzy matching

**Indexes**
- `PRIMARY KEY` - integer primary key is an alias for rowid
- `UNIQUE` constraints create indexes
- `INDEXED BY` for query-time index selection
- Partial indexes via `WHERE` clause (SQLite 3.8.0+)
- Expression indexes via `GENERATED ALWAYS AS` columns

**SQLite-Specific Features**
- `INSERT OR IGNORE` - skip on constraint violation
- `INSERT OR REPLACE` - replace existing row on conflict
- `ON CONFLICT ... DO NOTHING` - conflict resolution
- `RETURNING` clause (SQLite 3.35+)
- `UPSERT` (INSERT ON CONFLICT) syntax
- Multiple schemas via ATTACH DATABASE
- Transaction savepoints with nested transactions
- `VACUUM` for database maintenance

**Introspection**
- `sqlite_master` for schema metadata
- `PRAGMA table_info`, `PRAGMA index_list`, `PRAGMA foreign_key_list`
- `sqlite_sequence` for AUTOINCREMENT tracking

## Deploy

[DBIO::SQLite::Deploy](https://metacpan.org/pod/DBIO::SQLite::Deploy) orchestrates test-deploy-and-compare:

1. Introspect live database via sqlite_master and PRAGMA ([DBIO::SQLite::Introspect](https://metacpan.org/pod/DBIO::SQLite::Introspect))
2. Deploy desired schema to a temporary in-memory database (`:memory:`)
3. Introspect the temporary database the same way
4. Diff source vs target ([DBIO::SQLite::Diff](https://metacpan.org/pod/DBIO::SQLite::Diff))

SQLite's `:memory:` database makes deploy testing extremely fast - no cleanup needed.

Install (`install_ddl`) creates fresh schema. Upgrade diffs live vs. desired.

## Testing

```bash
export DBIO_TEST_SQLITE_DSN="dbi:SQLite::memory:"
prove -l t/
```

SQLite is ideal for testing because `:memory:` requires no server process.
Offline tests (`t/00-load.t`) run without any database.

## Requirements

- Perl 5.36+
- [DBD::SQLite](https://metacpan.org/pod/DBD::SQLite)
- DBIO core

## See Also

[DBIO::Introspect::Base](https://metacpan.org/pod/DBIO::Introspect::Base), [DBIO::Diff::Base](https://metacpan.org/pod/DBIO::Diff::Base), [DBIO::Deploy](https://metacpan.org/pod/DBIO::Deploy)

## Repository

[https://codeberg.org/dbio/dbio-sqlite](https://codeberg.org/dbio/dbio-sqlite)