---
name: dbio-clickhouse-database
description: Use when you need ClickHouse specifics for driver work — MySQL wire protocol limits, MergeTree, async mutations, type system, catalog.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

ClickHouse for Perl DB driver development. The database counterpart to the
`dbio-clickhouse` driver skill. ClickHouse is a column-oriented, distributed
**OLAP** database — built for large analytical scans and bulk append, not
transactional row-at-a-time OLTP.

## Transport: MySQL wire protocol

ClickHouse exposes the **MySQL wire protocol on port 9004** (also HTTP 8123,
native TCP 9000). There is **no native `DBD::ClickHouse`** on CPAN, so the DBIO
driver connects with a MySQL-wire DBD:

```perl
DBI->connect('dbi:mysql:database=default;host=127.0.0.1;port=9004', $user, $pass);
```

`DBD::mysql` is the standard (verified live against a stock server — karr k15:
full suite green, 33 files / 1035 tests against 25.3.14.14); `DBD::MariaDB` is
supported but needs a server-side prefix. The server must have `mysql_port
9004` enabled (default in recent images).

**`DBD::mysql` connects to a stock ClickHouse.** It sends no SQL at all on
connect, so a stock server — and ClickHouse Cloud — needs no accommodation.
Connect it with `mysql_enable_utf8mb4 => 1` or character data comes back as
bytes (DBD::MariaDB decodes unconditionally).

**`DBD::MariaDB` does not connect to a stock ClickHouse.** It always issues
`SET character_set_server = 'utf8mb4'` on connect (hardcoded in the .so, no
attribute suppresses it) and ClickHouse rejects unknown settings:
`Code: 115 ... UNKNOWN_SETTING`. The server must register the prefix —
`<custom_settings_prefixes>SQL_,character_set_,collation_,sql_</custom_settings_prefixes>`
— readable only at **start**, not via `SYSTEM RELOAD CONFIG`; not possible on
ClickHouse Cloud. Verified against 25.3.14.14.
Identifiers are quoted with **backticks** (`` ` ``), MySQL-wire style.

### What the MySQL wire protocol does NOT give you here

The protocol advertises MySQL, but ClickHouse does not implement the semantics:

- **No transactions, no savepoints.** `BEGIN`/`COMMIT`/savepoints are not usable
  for real atomicity. The driver makes savepoints throw.
- **No `SELECT ... FOR UPDATE`** (no row locks). SQLMaker disables `_lock_select`.
- **No `INSERT ... RETURNING`.**
- **No auto-increment / `last_insert_id`.**

Because a ClickHouse DSN looks exactly like a MySQL DSN, DBIO **cannot** autodetect
the driver from the DSN — the storage must be pinned (component or `-ch`).

## Keys & identity

There is no identity/auto-increment column. A MergeTree table's **`ORDER BY`
key is its primary key** (`PRIMARY KEY` may be a prefix of it). Surrogate ids
are generated with `generateUUIDv4()` into a `UUID` column, not by a sequence.

## Mutations: UPDATE / DELETE are asynchronous

Row modification is not OLTP DML. You issue:

```sql
ALTER TABLE t UPDATE col = expr WHERE ...;
ALTER TABLE t DELETE WHERE ...;
```

These are **mutations**: non-transactional, executed in the background, applied
by rewriting affected parts. They are eventually-consistent and comparatively
expensive. Lightweight `DELETE FROM t WHERE ...` exists in recent versions but
is still asynchronous under the hood. The driver renders both forms and appends
`SETTINGS mutations_sync = 1` so the statement waits — see ADR 0005.

## Table engines: MergeTree family

Every table needs an **engine**. The workhorse is `MergeTree`:

```sql
CREATE TABLE events (
  id    UUID,
  ts    DateTime,
  name  String
) ENGINE = MergeTree
ORDER BY (ts, id);
```

Variants: `ReplacingMergeTree`, `SummingMergeTree`, `AggregatingMergeTree`,
`CollapsingMergeTree`, plus `Replicated*` for clusters, and `Log`/`Memory` for
small/ephemeral tables. `ENGINE` + `ORDER BY` have no MySQL analogue, so the DDL
layer emits them from `clickhouse_table`; DBIO's portable DDL cannot.

## Type system

ClickHouse types differ from MySQL's. Overview:

| Family | ClickHouse |
|--------|-----------|
| signed int | `Int8`, `Int16`, `Int32`, `Int64`, `Int128`, `Int256` |
| unsigned int | `UInt8`, `UInt16`, `UInt32`, `UInt64`, ... |
| float / decimal | `Float32`, `Float64`, `Decimal(p,s)` |
| string | `String`, `FixedString(n)` |
| date / time | `Date`, `Date32`, `DateTime`, `DateTime64(p)` |
| id / enum / bool | `UUID`, `Enum8`/`Enum16`, `Bool` |
| semi-structured | `JSON` (production-ready from 25.3; beta before that) |
| nullable | `Nullable(T)` (opt-in — columns are NOT NULL by default) |
| nested / compound | `Array(T)`, `Tuple(...)`, `Map(K,V)`, `Nested`, `LowCardinality(T)` |

Notes: columns are **NOT NULL by default** — nullability is explicit via
`Nullable(T)`. `LowCardinality(String)` is the idiomatic low-distinct dictionary
string. UTF-8 native; no charset/collation connection setup. The DBIO →
ClickHouse mapping and its rationale live in `DBIO::ClickHouse::DDL`.

## Catalog / introspection

ClickHouse does have `information_schema` views, but the authoritative catalog is
the **`system` database**: `system.tables`, `system.columns`,
`system.data_skipping_indices`, `system.parts`, `system.databases`.
`information_schema` has no column for the engine, the sorting key or the
partition key, which is exactly what a ClickHouse `CREATE TABLE` cannot be
rebuilt without — so `DBIO::ClickHouse::Introspect` reads `system.*` only.

## Pagination

Standard `LIMIT n OFFSET m` (and `LIMIT m, n`) — inherited from `DBIO::SQLMaker`,
no override needed; core emits them as bound placeholders (`LIMIT ? OFFSET ?`).
ClickHouse also has `LIMIT n BY expr` ("top n per group"), which the driver
exposes as the `limit_by` resultset attribute with the count **inlined**, not
bound. Both LIMIT clauses can appear in one statement, in that order.

## Live testing: env vars

`DBIO_TEST_CLICKHOUSE_DSN`, `DBIO_TEST_CLICKHOUSE_DBUSER`,
`DBIO_TEST_CLICKHOUSE_DBPASS` (`DBIO::ClickHouse::Test`). **No in-memory mode** —
there is no default DSN; every live file `plan skip_all`s when the DSN is unset,
and `init_schema` dies cleanly as a backstop.

Each test *process* creates its own database `dbio_ch_test_<pid>`, deploys
`DBIO::ClickHouse::Test::Schema` into it and drops it again in an `END` block.
The database named in the DSN is only used to issue `CREATE`/`DROP DATABASE`, so
the connecting user needs both rights (`DBIO::ClickHouse::Deploy`'s scratch
database needs them anyway). Consequences worth knowing:

- **Re-running the suite is safe.** Each file drops and recreates its own
  database first, so a previous aborted run cannot poison the next one.
- **A live file needs no table cleanup of its own** — the database goes, its
  tables go with it. Do not put a `DROP TABLE` on the last line and call that
  cleanup; a failed assertion never reaches the last line.
- Leftover `dbio_ch_test_*` / `dbio_deploy_tmp_*` databases from a killed
  process are safe to drop by hand, and vanish with the pod anyway.

## Live testing: running the suite against a server

**Read the "Live testing" section of `.claude/rules/.local.dbio-rules.md` first** (the
rules file exists after `skilletor sync`). Its rules hold unchanged here: one run per
database at a time, serial, never `prove -j`, every run through `../dbio/maint/capped-test`,
every DB container carries a cpu and memory cap. This skill does not start or delete a
server for you; how you get one is not a driver question.

A server is any ClickHouse with the MySQL wire port (9004) reachable. The checked-in
spec `maint/k8s/clickhouse.yaml` is a capped, stock single pod for that; on the
maintainer's own cluster the rules file's *Maintainer-only live infrastructure*
section describes who starts it. Hand the suite its server through the repo's
variables:

```bash
export DBIO_TEST_CLICKHOUSE_DSN='dbi:mysql:database=default;host=<host>;port=<9004 or forwarded port>'
export DBIO_TEST_CLICKHOUSE_DBUSER=<user>
export DBIO_TEST_CLICKHOUSE_DBPASS=<pass>

# THE RUN — serial, capped, one pass over everything
../dbio/maint/live-preflight || exit 1   # on the maintainer cluster
../dbio/maint/capped-test prove -lvr t/
```

Prerequisite, once: `cpanm DBD::mysql`. Without a MySQL-wire DBD the live
files do not skip — the gate is the DSN, not the DBD — they die at connect.

`-v` is worth it here: several live files `diag` facts that are the point of the
run (the server version, how the native `JSON` type came back over the wire, how
many rows a `ReplacingMergeTree` still held before `FINAL`). Those lines are the
answer to questions no assertion can phrase.

One file only, same env, when chasing a single failure:

```bash
../dbio/maint/capped-test prove -lv t/17-smoke-live.t
```

### What the live files answer

`t/17-smoke-live.t` first — nothing else is worth reading if it is red.

| file | the question only a server can answer |
|------|----------------------------------------|
| `t/14-insert-live.t` | multi-row `INSERT` binds positionally; `DEFAULT generateUUIDv4()` fires; a 2000-row batch fits one statement |
| `t/16-mutations-live.t` | `SETTINGS mutations_sync = 1` is accepted on `ALTER ... UPDATE/DELETE` and really waits; affected-rows is 0, hence the `-1` return (ADR 0005) |
| `t/17-smoke-live.t` | the whole fixture deploys; `LIMIT ? OFFSET ?` binds; joins, views, `create()` |
| `t/18-types-live.t` | every type in the map is accepted, reported back unchanged (`Bool`, not `UInt8`) and round-trips its values; native `JSON` probed separately |
| `t/19-dialect-live.t` | `FINAL` in the alias form (and under a join, and through a complex prefetch), `PREWHERE`, two `LIMIT` clauses in one statement |
| `t/20-introspect.t` | `system.tables` / `system.columns` report engine_full, the three keys, `default_kind`, `is_in_sorting_key`; `ORDER BY tuple()` reads back as `''` |
| `t/30-deploy.t` | the scratch-database dance, and a freshly deployed schema diffing empty against itself |
| `t/38-ddl-if-exists-live.t` | `IF [NOT] EXISTS` parses for table, column, index and database — the evidence behind `_use_supports_if_exists(1)` |
