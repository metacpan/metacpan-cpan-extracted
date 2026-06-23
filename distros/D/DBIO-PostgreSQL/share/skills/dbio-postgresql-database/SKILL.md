---
name: dbio-postgresql-database
description: "PostgreSQL database knowledge for Perl driver development (DBD::Pg, pg_catalog, PG-specific types and features)"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

PostgreSQL knowledge for Perl driver development.

## DBD::Pg

- DBI driver for PostgreSQL
- Connect: `DBI->connect("dbi:Pg:dbname=mydb;host=localhost", $user, $pass)`
- Supports COPY, LISTEN/NOTIFY, prepared statements, server-side cursors
- Array columns: Perl arrayrefs in/out
- JSONB: send/receive as JSON string (decode yourself)
- Bytea: auto escaping/unescaping

## pg_catalog Introspection

| Catalog | Purpose |
|---------|---------|
| `pg_namespace` | Schemas |
| `pg_class` | Tables, views, indexes, sequences |
| `pg_attribute` | Columns |
| `pg_type` | Types (incl. enums, composites) |
| `pg_enum` | Enum values |
| `pg_index` | Indexes |
| `pg_am` | Access methods (btree, gin, gist, brin, hash) |
| `pg_constraint` | PK, FK, UNIQUE, CHECK, EXCLUDE |
| `pg_trigger` | Triggers |
| `pg_proc` | Functions/procedures |
| `pg_extension` | Extensions |
| `pg_policy` | RLS policies |
| `pg_sequence` | Sequence params |

### Functions

```sql
pg_get_indexdef(oid)        -- CREATE INDEX statement
pg_get_constraintdef(oid)   -- constraint def
pg_get_triggerdef(oid)      -- trigger def
pg_get_expr(node, relid)    -- expression from node tree
format_type(type_oid, mod)  -- human-readable type
```

## Type System

### Native

| Category | Types |
|----------|-------|
| Integer | `smallint`, `integer`, `bigint`, `serial`, `bigserial` |
| Float | `real`, `double precision`, `numeric(p,s)` |
| String | `text`, `varchar(n)`, `char(n)` |
| Binary | `bytea` |
| Boolean | `boolean` |
| Date/Time | `timestamp`, `timestamptz`, `date`, `time`, `timetz`, `interval` |
| UUID | `uuid` |
| JSON | `json`, `jsonb` |
| Array | `anytype[]` (e.g., `text[]`, `integer[]`) |
| Network | `inet`, `cidr`, `macaddr` |
| Geometric | `point`, `line`, `box`, `circle`, `polygon`, `path` |
| Range | `int4range`, `int8range`, `numrange`, `tsrange`, `tstzrange`, `daterange` |

### Extension

| Extension | Types |
|-----------|-------|
| `pgvector` | `vector(n)` — AI embeddings |
| `postgis` | `geometry`, `geography` |
| `timescaledb` | hypertables (table variant, not type) |

### User-Defined

- Enum: `CREATE TYPE status AS ENUM ('active', 'inactive')`
- Composite: `CREATE TYPE address AS (street text, city text)`
- Range: `CREATE TYPE floatrange AS RANGE (subtype = float8)`
- Domain: `CREATE DOMAIN email AS text CHECK (VALUE ~ '@')`

## Indexes

| Method | Use | Operators |
|--------|-----|-----------|
| `btree` | Equality, range, sorting (default) | `<`, `<=`, `=`, `>=`, `>` |
| `hash` | Equality only | `=` |
| `gin` | Arrays, JSONB, FTS, trigram | `@>`, `<@`, `?`, `?&`, `?\|`, `@@` |
| `gist` | Geometry, range, FTS | `<<`, `>>`, `&&`, `@>`, `<@` |
| `brin` | Large sequential tables | btree ops, physically ordered |
| `ivfflat` | pgvector ANN | `<->`, `<=>`, `<#>` |
| `hnsw` | pgvector ANN (better) | `<->`, `<=>`, `<#>` |

Features: partial (`WHERE ...`), expression (`ON lower(name)`), `INCLUDE` columns, `CONCURRENTLY`.

## Schemas (Namespaces)

```sql
CREATE SCHEMA auth;
CREATE TABLE auth.users (...);
SET search_path TO auth, public;
```

- Default: `public`
- System: `pg_catalog`, `information_schema`
- `search_path` controls unqualified name resolution

## Row Level Security

```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;  -- applies to table owner too
CREATE POLICY user_policy ON users
    FOR ALL
    USING (user_id = current_setting('app.user_id')::integer);
```

## Extensions

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";   -- uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS pg_trgm;       -- trigram similarity
CREATE EXTENSION IF NOT EXISTS pgvector;      -- vector similarity
CREATE EXTENSION IF NOT EXISTS postgis;       -- geographic
```

## Testing

- One temp database or schema per test
- `CREATE DATABASE` / `DROP DATABASE` for isolation
- Transactions with rollback for quick cleanup
- `pg_prove` for pgTAP (SQL-level testing)
