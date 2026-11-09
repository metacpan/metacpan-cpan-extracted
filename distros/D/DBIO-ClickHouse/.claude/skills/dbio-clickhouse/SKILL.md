---
name: dbio-clickhouse
description: Load when working on the DBIO::ClickHouse driver — storage, SQL generation, component pinning, or its offline and server-gated tests.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::ClickHouse

ClickHouse is a column-oriented OLAP DB. `DBIO::ClickHouse` reaches it over the
**MySQL wire protocol** (server port 9004) via `DBD::mysql` (standard, verified
live against a stock server — karr k15) or `DBD::MariaDB` (supported, needs a
server-side prefix) — there is no native `DBD::ClickHouse`. The storage is
a direct subclass of `DBIO::Storage::DBI`, NOT of `DBIO::MySQL::Storage` (shares
the wire protocol, none of the semantics). See `docs/adr/0001` and `0002`.
Design notes, namespace and test numbering live in `CLAUDE.md` and `docs/adr/`
(0001 transport, 0002 standalone, 0003 transactions, 0005 mutations, 0007 Native
bridge); this skill is the quick map. The driver is complete: Storage, SQLMaker,
DDL, Result, Introspect, Diff, Deploy and Native all exist.

## Component loading — must be pinned explicitly

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('ClickHouse');   # connection() pins +DBIO::ClickHouse::Storage

# or the shortcut:
use DBIO Schema => -ch;   # DBIO::Shortcut::ch
```

**No DSN autodetection.** A ClickHouse DSN is `dbi:mysql:`/`dbi:MariaDB:` on port
9004, indistinguishable from MySQL, so core's registry cannot pick ClickHouse.
Always pin the storage.

## Storage — `DBIO::ClickHouse::Storage`

Direct subclass of `DBIO::Storage::DBI`; backtick quoting; errors via
`throw_exception`, never `croak`.

- No `INSERT ... RETURNING`, no `last_insert_id`/auto-increment; PK is the
  MergeTree `ORDER BY` key; surrogate ids via `generateUUIDv4()`.
- **Transaction API is split (ADR 0003).** No-ops that warn once (`carp_once`):
  `txn_begin`/`txn_commit` (send nothing, depth bookkeeping kept), `txn_do`
  (coderef runs unwrapped, never retried, original exception re-thrown plus a
  per-failure warning), `txn_scope_guard` (`Storage::TxnScopeGuard`). Throws:
  `txn_rollback` and `$guard->rollback`. Savepoints (`_exec_svp_*`) throw.
- `update`/`delete` render `ALTER TABLE ... UPDATE/DELETE ... SETTINGS
  mutations_sync = 1` and return `-1` (ADR 0005).
- Also: `clickhouse_version`, `_ping`, set-operation keyword and `rand()`
  hooks, `dbio_deploy_class` (`DBIO::ClickHouse::Deploy`), `deployment_statements`.

## SQLMaker — `DBIO::ClickHouse::SQLMaker`

`_lock_select` is `''` (no `FOR UPDATE`). Resultset attributes: `final => 1`,
`prewhere => \%cond`, `limit_by => { rows => $n, by => $cols }`; `SAMPLE` is
not implemented (literal SQL only). Renders the mutation statements above.

## Tables

`ENGINE = MergeTree` + `ORDER BY` (default: primary key), set per result class
with `clickhouse_table({ engine, order_by, primary_key, partition_by, settings })`.
Engine, sorting/primary key and partition expression are immutable: Diff refuses
a change.

## Key modules

| Module | Purpose |
|--------|---------|
| `DBIO::ClickHouse` | Schema component (pins storage) |
| `DBIO::ClickHouse::Storage` (+ `Storage::TxnScopeGuard`) | DBI storage over MySQL wire |
| `DBIO::ClickHouse::SQLMaker` | SQL generation, dialect attributes, mutations |
| `DBIO::ClickHouse::DDL` (+ `DDL::Emit`) | type map and every rendered statement |
| `DBIO::ClickHouse::Result` | `clickhouse_table` |
| `DBIO::ClickHouse::Introspect` (+ `Tables`/`Columns`/`Indexes`/`Util`) | reads `system.*` |
| `DBIO::ClickHouse::{Diff,Deploy}` | diff ops, scratch-database deploy |
| `DBIO::ClickHouse::Native` | export bridge to `ClickHouse::Encoder` (never loaded by `lib/`) |
| `DBIO::ClickHouse::Test` (+ `Test::Schema`) | server-gated harness and live fixture |
| `DBIO::Shortcut::ch` | `-ch` shortcut |

## Tests

Offline by default, no server and no MySQL-wire DBD:

```bash
../dbio/maint/capped-test prove -lr t/
```

Numbering: `0x` load/shortcut/fixture/transport, `1x` storage and SQL
(sqlmaker, dialect, txn, insert, mutations, capabilities), `2x` introspect,
`3x` DDL and deploy, `4x` diff and set operations, `5x` Native bridge.

Gated: live files (`t/07-transport-dbd-live`, `14`, `16`, `17-smoke`, `18`, `19`, `38`, plus `t/20`,
`t/30` and `t/32` at their layer slots) `skip_all` without `DBIO_TEST_CLICKHOUSE_DSN`
(+ `_DBUSER`/`_DBPASS`); `t/51` skips without `ClickHouse::Encoder`. There is no
in-memory mode; `init_schema` dies cleanly without a DSN. Live runs follow the
"Live testing" discipline in `.claude/rules/.local.dbio-rules.md`; procedure in
skill `dbio-clickhouse-database`; pod manifest `maint/k8s/clickhouse.yaml`.
