---
name: dbio-sqlite-database
description: "SQLite database knowledge for Perl driver development (DBD::SQLite, type affinity, SQLite-specific features)"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

SQLite knowledge for Perl DB driver development.

## DBD::SQLite

- Bundles SQLite — no external dep
- In-memory: `dbi:SQLite:dbname=:memory:`
- `sqlite_unicode => 1` — enable UTF-8
- Connections NOT shareable across threads

## Type Affinity (advisory, not enforced)

| Affinity | Trigger | Examples |
|----------|---------|----------|
| INTEGER | contains "INT" | INTEGER, BIGINT, SMALLINT |
| TEXT | contains "CHAR", "CLOB", "TEXT" | VARCHAR(255), TEXT |
| BLOB | "BLOB" or empty | BLOB |
| REAL | contains "REAL", "FLOA", "DOUB" | REAL, DOUBLE, FLOAT |
| NUMERIC | everything else | NUMERIC, DECIMAL, BOOLEAN, DATE |

Any column stores any type — affinity is preference only.

## WAL Mode

`PRAGMA journal_mode=WAL;` — concurrent readers + one writer, better read perf. Default: DELETE.

## Foreign Keys

OFF by default. Enable per-connection:
```perl
$dbh->do("PRAGMA foreign_keys = ON");
```

## Date/Time

No native type. Storage strategies:
- TEXT: `'2024-01-15 10:30:00'` (ISO8601, recommended)
- REAL: Julian day number
- INTEGER: Unix epoch (`unixepoch()` 3.38+)

## Key Functions

- `last_insert_rowid()` — auto-increment value (critical for DBIO)
- `changes()` / `total_changes()` — rows affected
- `typeof(x)` — runtime type
- `json()`, `json_extract()` — JSON support 3.9+

## Limitations

- No `ALTER TABLE DROP COLUMN` (<3.35.0)
- No `ALTER TABLE ALTER COLUMN` — recreate table
- No right/full outer joins (<3.39.0)
- No GRANT/REVOKE — file-system only
- No native BOOLEAN/DATE/DATETIME — use affinity

## Testing

In-memory DB: fast, no cleanup, no env vars needed.
```perl
$dbh = DBI->connect("dbi:SQLite:dbname=:memory:");
```