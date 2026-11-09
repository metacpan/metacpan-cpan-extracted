# CLAUDE.md — DBIO::ClickHouse

This distribution tracks only what is its own (`.claude/skilletor.json`, its `dbio-clickhouse*`
skills, the repo-specific rules). The family skills, the shared agents (`dbio-adr-auditor`,
`dbio-release-manager`, `karr-coordinator`), the standard worker and the shared
`.claude/rules/` are installed from core by skilletor and git-ignored. The family-wide house
rules (discipline, delegation, release) live in `.claude/rules/.local.dbio-rules.md` —
auto-loaded by Claude Code for the main agent and all subagents.

**Fresh clone or worktree: run `skilletor sync` first.** Until then the installed skills,
rules and agents named here do not exist. It needs the skilletor CLI/plugin and network
access to the sources in `.claude/skilletor.json` (github.com/Getty/skills, Getty/karr,
codeberg.org/dbio/dbio). Never edit an installed copy (`.claude/agents/.local.*`,
`.claude/rules/.local.*`, an installed skill dir) — change the source in core, then sync.

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, and the later
Introspect/Deploy/Diff/DDL, types) to this repo's `dbio-worker-clickhouse` instead of
touching them yourself. Lane and principle: `.claude/rules/.local.dbio-rules.md`. Repo agents:
`dbio-worker-clickhouse` (default), `dbio-adr-auditor`, `dbio-release-manager`,
`karr-coordinator`.

## Namespace

- `DBIO::ClickHouse` -- ClickHouse schema component
- `DBIO::ClickHouse::Storage` -- ClickHouse storage (inherits `DBIO::Storage::DBI`)
- `DBIO::ClickHouse::SQLMaker` -- ClickHouse SQL generation
- `DBIO::ClickHouse::Test` -- test harness (server-gated, no in-memory mode)
- `DBIO::Shortcut::ch` -- the `-ch` shortcut
- `DBIO::ClickHouse::DDL` (+ `DDL::Emit`) -- type map and every rendered
  statement shape, shared with the Diff
- `DBIO::ClickHouse::Result` -- `clickhouse_table` options on result classes
- `DBIO::ClickHouse::Introspect` (+ `Tables`/`Columns`/`Indexes`/`Util`)
- `DBIO::ClickHouse::Util` -- `mask_error_details`: the engine's error text with every value replaced by `***`
- `DBIO::ClickHouse::{Diff,Deploy}` -- diff ops and scratch-database deploy
- `DBIO::ClickHouse::Native` -- export bridge to `ClickHouse::Encoder`: renders a
  source as the `[name, type]` pairs the encoder takes and the rows as arrayrefs
  in that order. A translation, not a transport -- nothing in `lib/` ever loads
  the encoder (ADR 0007)
- `DBIO::ClickHouse::Test::Conformance` -- the driver's half of core's shared case table (ADR 0060)
- `DBIO::ClickHouse::Test::Schema` -- the live fixture (not `DBIO::Test::Schema`,
  whose auto-increment keys this driver refuses)

## Usage

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('ClickHouse');

my $schema = MyApp::DB->connect(
  'dbi:mysql:database=default;host=127.0.0.1;port=9004', $user, $pass,
  { mysql_enable_utf8mb4 => 1 },
);

# or, using the -ch shortcut:
package MyApp::DB;
use DBIO Schema => -ch;
```

## Design notes

- **Transport is the MySQL wire protocol.** ClickHouse speaks the MySQL wire
  protocol on server port **9004**. There is no native `DBD::ClickHouse` on
  CPAN, so the driver rides `DBD::mysql` (standard, verified live against a
  stock server — karr k15) or `DBD::MariaDB` (supported, needs a server-side
  prefix). See `docs/adr/0001-mysql-wire-protocol-transport.md`.
- **No DSN-based driver detection — the consequence of the transport choice.**
  A ClickHouse MySQL-wire DSN is `dbi:MariaDB:...` (or `dbi:mysql:...`), which
  is indistinguishable from a real MySQL DSN and would resolve to the MySQL
  storage via core's driver registry. So there is **no** `register_driver`-based
  autodetect route for ClickHouse the way there is for e.g. DuckDB
  (`dbi:DuckDB:`). The storage MUST be pinned explicitly, either by
  `__PACKAGE__->load_components('ClickHouse')` (whose `connection()` sets
  `storage_type('+DBIO::ClickHouse::Storage')`) or by the `-ch` shortcut. This
  is documented prominently and is the subject of ADR 0001.
- **Both MySQL-wire DBDs are this driver's own access path.** Core (ADR 0059)
  holds a declared storage's DSN against its driver registry and reports a DBD
  registered for an unrelated class as a "Driver mismatch" — which `mysql` and
  `MariaDB` are here, since the storage does not inherit the MySQL one.
  `DBIO::ClickHouse::Storage` declares exactly those two through core's
  documented `__PACKAGE__->register_access_path_dbd('mysql', 'MariaDB')`, so a
  `dbi:Pg:` DSN is still reported by core. Not `_adapt_to_access_path` (would
  need the `@ISA` ADR 0002 refuses), not `register_driver('mysql')`, not
  `driver_warnings(0)`, and no override of core's private check method (the
  first solution, replaced — karr k38). ADR 0001, addenda 2026-10-07 and
  2026-10-14; pinned by `t/07-transport-dbd.t` and `t/07-transport-dbd-live.t`.
- **Standalone dist, not a MySQL subclass.** ClickHouse shares only the wire
  protocol with MySQL, none of the semantics. Making it a MariaDB-style storage
  subclass inside dbio-mysql would inherit a lying API (transactions, FKs,
  auto-increment, `RETURNING`). See
  `docs/adr/0002-standalone-dist-not-mysql-subclass.md`.
- **No transactions, no savepoints.** ClickHouse has neither. The savepoint
  hooks (`_exec_svp_begin` / `_exec_svp_release` / `_exec_svp_rollback`) throw
  via `throw_exception`. `SELECT ... FOR UPDATE` is likewise unsupported —
  `DBIO::ClickHouse::SQLMaker` disables `_lock_select`.
  The **transaction API is split** (ADR 0003): everything that only *promises*
  atomicity is a no-op that warns once per interpreter (`carp_once`) —
  `txn_begin` / `txn_commit` send nothing (`_exec_txn_begin` /
  `_exec_txn_commit`, core's `transaction_depth` bookkeeping stays intact), and
  `txn_do` runs its coderef unwrapped, never retried, re-throwing a failure's
  original exception unchanged plus a loud per-failure warning that nothing was
  rolled back. Everything that *claims work was undone* throws: `txn_rollback`
  always `throw_exception`s (after unwinding the depth), because a silent
  rollback is the one no-op that manufactures a wrong belief about the data.
- **No `INSERT ... RETURNING`.** `_determine_supports_insert_returning` returns
  0.
- **No auto-increment / `last_insert_id`.** There is no identity column concept:
  the primary key is the MergeTree `ORDER BY` sorting key. Surrogate identity is
  done with `generateUUIDv4()` on UUID columns.
- **UPDATE / DELETE are async mutations** — `ALTER TABLE ... UPDATE` /
  `ALTER TABLE ... DELETE`, non-transactional, applied in the background.
  Rendered through SQL::Abstract's clause renderers, so WHERE, placeholders and
  bind attributes stay inherited machinery. `mutations_sync = 1` is emitted per
  statement (ADR 0005); `update`/`delete` return `-1`, because a mutation
  acknowledges the `ALTER`, not a row count.
- **Identifier quoting is the backtick `` ` ``** (MySQL-wire compatible),
  set on the storage via `sql_quote_char('`')` and applied to the SQLMaker.
- **Dialect attributes on the resultset.** `final => 1` (→ `FROM t FINAL`,
  primary table only), `prewhere => \%cond` (→ `PREWHERE` before `WHERE`, real
  SQL::Abstract binds) and `limit_by => { rows => $n, by => $cols }` (→
  `LIMIT n BY cols` between `ORDER BY` and `LIMIT`) live in
  `DBIO::ClickHouse::SQLMaker`; they need no core change because
  `_resolved_attrs` passes unknown keys through. `SAMPLE k` is **not**
  implemented — literal-SQL escape hatch only.
- **Tables need `ENGINE = MergeTree` + `ORDER BY`.** `DBIO::ClickHouse::DDL`
  emits it, defaulting `ORDER BY` to the primary key; override per result class
  with `clickhouse_table({ engine, order_by, primary_key, partition_by,
  settings })`. Sorting key, primary key, partition expression and engine are
  immutable — the Diff refuses a change instead of recreating the table.
- **Skipping indexes come from the canonical declaration only.**
  `DDL::install_ddl` reads `$source->index_declarations_for('clickhouse',
  [qw(type granularity expression)])` and renders `INDEX n expr TYPE t
  GRANULARITY g` inline via `Emit::index_def` (the Diff's own renderer; the
  desired model reaches it through the scratch-database deploy). `type` is
  mandatory — there is no plain index; `unique`, a missing/empty/foreign block
  and generic `options` are refused loudly, never degraded. No hand-written
  source exists to compete with. Cake `idx` cannot carry the block's keys yet
  (core's key table has no `clickhouse`); use `add_index_declaration`.
- **`DBD::mysql` is the transport of record** — it sends no SQL at all on
  connect, so a stock server (and ClickHouse Cloud) needs no accommodation;
  the manifest in `maint/k8s/clickhouse.yaml` is stock for that reason.
  `DBD::MariaDB` is supported but needs a server-side prefix registration to
  connect at all — it always sends `SET character_set_server`, which a stock
  ClickHouse rejects with `UNKNOWN_SETTING`; that prefix is only settable at
  server start. Both reach the same pinned storage; see ADR 0001.
- **Error paths** route through `$self->throw_exception(...)`, never bare
  `croak` (family rule).
- **`clickhouse_version`** escape hatch on the storage runs `SELECT version()`.

## Tests

Offline TAP under `t/`. They need DBIO core installed but **no ClickHouse
server** and not even a MySQL-wire DBD — nothing here connects.

Numbering: `0x` load/shortcut/fixture, `1x` storage and SQL generation
(sqlmaker, dialect, txn, insert, mutations, capabilities), `2x` introspect,
`3x` DDL and deploy, `4x` diff (plus the set-operation, rand and explain storage hooks in `t/42`-`t/43`), `5x` the `ClickHouse::Encoder` export bridge, `6x` the conformance lists of core (`60` DDL and `61` Diff, each offline + `-live`; Bind follows), `65` the masking of values in the engine's error text (`DBIO::ClickHouse::Util`), `66`-`67` the same through the storage hook `_mask_error_values` (`66` live, with the text a server writes; `67` offline, the way of every statement shape to the hook).
Live files are named `*-live.t` or sit at the
slot of the layer they exercise (`t/20`, `t/30`, `t/32`) and are **DSN-gated**: they
`plan skip_all` without `DBIO_TEST_CLICKHOUSE_DSN`.

`t/51-native-encoder.t` is the one file gated on something other than a DSN: it
`skip_all`s without the optional `ClickHouse::Encoder`. `t/50-native.t` is
offline, never skips, and asserts the non-dependency structurally via `%INC`.

Run recursively: `../dbio/maint/capped-test prove -lr t/` or
`../dbio/maint/capped-test dzil test`. ClickHouse has **no embedded /
in-memory mode**, so any *live* test needs a real server;
`DBIO::ClickHouse::Test->init_schema` is gated on `DBIO_TEST_CLICKHOUSE_DSN`
(+ `_DBUSER` / `_DBPASS`) and dies cleanly when unset. A resource-limited
single-pod server manifest lives in `maint/k8s/clickhouse.yaml` — do not run it
without following the "Live testing" discipline in `.claude/rules/.local.dbio-rules.md`.

The live fixture is `DBIO::ClickHouse::Test::Schema`, **not** the family's
`DBIO::Test::Schema` — that one cannot deploy here (it never loads the
ClickHouse component) and its auto-increment integer keys are exactly the
identity model this driver refuses. Each live process takes its own database
(`dbio_ch_test_<pid>`) and drops it on exit. The live-run procedure is in the
`dbio-clickhouse-database` skill.
