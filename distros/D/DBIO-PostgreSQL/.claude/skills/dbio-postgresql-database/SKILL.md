---
name: dbio-postgresql-database
description: Use when you need PostgreSQL specifics for driver work — DBD::Pg, pg_catalog introspection, PG-specific types and features.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

PostgreSQL knowledge for Perl driver development.

## DBD::Pg

- DBI driver for PostgreSQL
- Connect: `DBI->connect("dbi:Pg:dbname=mydb;host=localhost", $user, $pass)`
- Supports COPY, LISTEN/NOTIFY, prepared statements; a server-side cursor is
  `DECLARE` / `FETCH` by hand
- Array columns: Perl arrayrefs in/out (`pg_expand_array`, on by default); a
  NULL element comes back as `undef`, and with the attribute off the array is
  the string `{a,b,NULL}`
- JSONB: send/receive as JSON string (decode yourself)
- Bytea: bind with `{ pg_type => PG_BYTEA }` on the way in; comes back unescaped
- Placeholders: `?`, `$1` and `:name`. DBD::Pg finds them with a scanner of
  its own, which is not the server's in every corner (nested `/* */`, `e'...'`,
  a `$` inside an identifier)
- The DSN is edited as text before libpq sees it: `;` outside single quotes
  separates parameters, `db=`/`database=` becomes `dbname=`. A value with a
  blank, `;`, `'`, `\`, `=` or `"` has to be written quoted
  (`DBIO::PostgreSQL::Util::quote_dsn_value`)
- A failed `DBI->connect` quotes the DSN in its message — and a password the
  DSN carries

## pg_catalog Introspection

| Catalog | Purpose |
|---------|---------|
| `pg_namespace` | Schemas |
| `pg_class` | Tables, views, indexes, sequences (`relkind`, `relpersistence`) |
| `pg_attribute` | Columns (`attidentity`, `attgenerated`) |
| `pg_attrdef` | Column defaults and generation expressions |
| `pg_type` | Types (incl. enums, composites) |
| `pg_enum` | Enum values |
| `pg_range` | Range types |
| `pg_index` | Indexes (`indkey`: 0 where the position is an expression) |
| `pg_am` | Access methods (btree, gin, gist, brin, hash) |
| `pg_constraint` | PK, FK, UNIQUE, CHECK, EXCLUDE |
| `pg_trigger` | Triggers |
| `pg_proc` | Functions/procedures |
| `pg_extension` | Installed extensions |
| `pg_available_extensions` | Extensions the server could install |
| `pg_policy` | RLS policies |
| `pg_sequence` | Sequence params |
| `pg_inherits` | Partitions and inheriting tables |
| `pg_rewrite` | View rules — with `pg_depend`, what a view reads |
| `pg_depend` | What depends on what: deptype `e` extension member, `i` internal part, `n` normal |

### Functions

```sql
pg_get_indexdef(oid)        -- CREATE INDEX statement
pg_get_constraintdef(oid)   -- constraint def
pg_get_triggerdef(oid)      -- trigger def
pg_get_functiondef(oid)     -- CREATE OR REPLACE FUNCTION statement
pg_get_viewdef(oid)         -- view query; names are qualified only when the
                            -- session's search_path does not find them
pg_get_expr(node, relid)    -- expression from node tree
format_type(type_oid, mod)  -- human-readable type
```

For an object another session dropped in the meantime `pg_get_indexdef`,
`pg_get_triggerdef` and `pg_get_functiondef` return NULL; `pg_get_viewdef`
raises `could not open relation with OID ...`.

## Names

- A name written without quotes is folded to lower case: `CREATE TABLE
  UserAccount` makes `useraccount`. Quoted it is taken exactly.
- An identifier is at most 63 bytes; a longer one is truncated, with a notice.
- Index names are unique per schema, not per table and not per database.
- `quote_ident()` on the server quotes everything that is not plain lower case
  or is a key word of the reserved, col_name or type_func_name class.

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

A type without a modifier takes none: `integer(11)` is a syntax error.
`format_type` writes a time type's precision behind the first word:
`timestamp(3) with time zone`.

### Extension

| Extension | Types |
|-----------|-------|
| `vector` (pgvector) | `vector(n)`, `halfvec(n)`, `sparsevec(n)` — AI embeddings |
| `postgis` | `geometry`, `geography` |
| `timescaledb` | hypertables (table variant, not type) |

### User-Defined

- Enum: `CREATE TYPE status AS ENUM ('active', 'inactive')` — values can be
  added (`ALTER TYPE ... ADD VALUE`), not removed; a value added inside a
  transaction is unusable until commit
- Composite: `CREATE TYPE address AS (street text, city text)`
- Range: `CREATE TYPE floatrange AS RANGE (subtype = float8)` — creates its
  constructor functions along with it
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

- `pg_get_indexdef` does not print an operator class that is the default:
  `ivfflat` defaults to `vector_l2_ops` for `vector`, `hnsw` has no default.
- There is no `ALTER INDEX` for a predicate, an expression or the method: a
  changed index is dropped and created.
- `CREATE INDEX CONCURRENTLY` cannot run inside a transaction block.
- An index a constraint stands on (PRIMARY KEY, UNIQUE, EXCLUDE) is not
  dropped by `DROP INDEX`.

## Schemas (Namespaces)

```sql
CREATE SCHEMA auth;
CREATE TABLE auth.users (...);
SET search_path TO auth, public;
```

- Default: `public`
- System: `pg_catalog`, `information_schema`
- `search_path` controls unqualified name resolution — for tables and for
  types, functions and operators alike
- An extension depends on the schema it is installed in: `DROP SCHEMA ...
  CASCADE` takes the extension, and every column of a type it brings

## Transactions and DDL

- DDL is transactional: `CREATE TABLE` and friends roll back with the
  transaction around them.
- Not inside a transaction block: `CREATE DATABASE`, `DROP DATABASE`,
  `CREATE INDEX CONCURRENTLY`.
- PostgreSQL does not alter the type of a column a view reads, and does not
  replace a materialized view's definition.
- A column added, dropped or retyped at a partitioned table (or a table others
  inherit from) is carried down to the partitions and children.
- `ALTER DATABASE name SET ...` is a default for new sessions. It takes a name
  and nothing that stands for "this database": a script written without the
  name builds the statement in a `DO` block, around `current_database()`.

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
CREATE EXTENSION IF NOT EXISTS vector;        -- pgvector: vector similarity
CREATE EXTENSION IF NOT EXISTS postgis;       -- geographic
```

Extensions are database-level, and created and dropped in the order they
require one another (`postgis` before `postgis_topology`).

## Testing

- One temp database or schema per test
- `CREATE DATABASE` / `DROP DATABASE` for isolation
- Transactions with rollback for quick cleanup
- `pg_prove` for pgTAP (SQL-level testing)

How this distribution's own suite is run and written — `capped-test`,
`t/lib/LiveServer.pm`, private databases — is in skill `dbio-postgresql`,
section Testing.
