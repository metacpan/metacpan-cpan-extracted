# ADR 0026 — DDL transactional safety + IF EXISTS capability flag

- Status: accepted
- Date: 2026-06-25
- Tags: contract, capability, deploy, cross-repo, drivers, transaction

## Context

`DBIO::Deploy` and `DBIO::DeploymentHandler` are the two surfaces that drive
schema changes — single-statement DDL during normal deploy, multi-statement
upgrade migrations during version bumps. Both shipped with an implicit
assumption: that every supported RDBMS honours transactional DDL, so wrapping
the DDL body in `$storage->txn_do` is safe and gives atomic rollback on
failure.

That assumption is false on at least five production engines:

| Engine | DDL transactional? | Why wrapping in `txn_do` is wrong |
|---|---|---|
| MySQL (< 8.0) | no | DDL implicitly commits; `txn_do` is a no-op |
| Oracle | no | DDL implicitly commits; rollback has no effect |
| DB2 | no | DDL implicitly commits |
| Sybase | no | DDL implicitly commits |
| Informix | no | DDL implicitly commits |
| SQLite | n/a | Rebuild path depends on `AutoCommit = on`; wrapping in `txn_do` forces it off and breaks rebuild |

Pre-fix, `DBIO::Deploy::Base::_execute_ddl` and
`DBIO::DeploymentHandler::upgrade` wrapped the DDL body in `$storage->txn_do`
unconditionally. On the six engines above, this is either a silent no-op (and
the operator never gets atomic rollback) or, on SQLite, a regression that
breaks the rebuild path outright.

A second related assumption lived in the diff renderer: when emitting a
`DROP TABLE foo` (or index, or column), the renderer asked
"$driver_name matches the engines-that-have-IF-EXISTS list?" by string
comparison. That string match drifted across drivers — the canonical
problem ADR 0021 records for `constraint_name` — and silently mis-emitted on
any driver whose name did not match the literal. The result was SQL that
crashed on engines that did not parse `DROP TABLE IF EXISTS`, or DDL that
crashed on engines that did parse it because the renderer emitted a hard
drop where the operator expected a conditional one.

## Decision

Replace the implicit DDL-transactional assumption with a per-engine
capability flag, and the IF-EXISTS string match with a per-engine capability
flag and a single emit-time helper.

1. **Two new capabilities** on `DBIO::Storage::DBI::Capabilities`, using the
   same `mk_group_accessors( use_dbms_capability => ... )` shape as the
   existing capability set:
   - `transactional_ddl` — opt in via
     `__PACKAGE__->_use_transactional_ddl(1)` in the driver's storage class,
     or override `_determine_supports_transactional_ddl`. Default 0
     (conservative: do not assume).
   - `supports_if_exists` — opt in via
     `__PACKAGE__->_use_supports_if_exists(1)`, or override
     `_determine_supports_supports_if_exists`. Default 0.
2. **Deploy::Base::_execute_ddl probes the capability** and only wraps the
   DDL body in `$storage->txn_do` when `transactional_ddl` is true.
   Otherwise it runs the DDL body statement-at-a-time and relies on the
   `__VERSION` row gate in `version_storage` as the forward-progress
   recovery story. Behaviour on PostgreSQL (where `transactional_ddl` is
   true) is unchanged. Behaviour on the six engines above is now correct.
3. **DeploymentHandler::upgrade does the same.** The body still runs in the
   same order — pre-hooks ascending, DDL, post-hooks ascending, version
   bump — only the wrapping `txn_do` is conditional.
4. **One-shot `carp_once` on first non-transactional upgrade**, naming the
   storage class. Operators see *once* that recovery on this engine depends
   on the `__VERSION` row gate rather than on rollback. After the first
   upgrade, no further warning — this is a feature, not nag.
5. **Diff::Op::should_emit_if_exists($storage) is the single emit-site the
   diff renderer asks.** Returns true when the storage declares
   `supports_if_exists`, false otherwise. No more guessing by driver name
   string match; the renderer asks the storage directly.
6. **Contract version bumps 1.0 → 1.1.** The new capabilities and the
   `should_emit_if_exists` helper are public-shape changes for drivers that
   adopt them. Per ADR 0024, contract version documents the bump.

## Rationale

The capability-flag pattern is the same one the existing
`DBIO::Storage::DBI::Capabilities` uses for `limit_dialect`, `multi_concat`,
and `join_optimizer` — it is the established way for a driver to declare an
engine fact and for the core to honour it. Reusing the shape keeps the
addition small (no new abstraction), consistent (drivers that already know
how to declare `limit_dialect` know how to declare `transactional_ddl`),
and discoverable (one POD section lists all the capabilities a driver can
opt into).

The conservative default (`0`) for both new capabilities matches the
existing default behaviour — until a driver opts in, the engine is assumed
not to honour the feature. That is the right default for a fallback when
the driver has not been updated: it preserves the *known-good*
pre-existing behaviour (single-statement DDL, hard drops) instead of
silently assuming the new behaviour. The driver is the place that has the
information; the driver must opt in.

`carp_once` for the non-transactional branch is a deliberate UX choice:
operators need to know that recovery on this engine does not include
rollback, but they do not need to be told on every upgrade. The one-shot
mechanism is reused from `DBIO::Carp` and follows the same shape as the
existing single-statement DDL announce.

`should_emit_if_exists` is a helper rather than a flag on the storage
itself because the question the diff renderer asks is
"should I emit IF EXISTS *for this op*?", not "does this engine parse
IF EXISTS?" — those are different questions when the renderer knows that a
particular op type (e.g. `DROP COLUMN` on a column the renderer itself
just added in this same upgrade) is safe to drop unconditionally. The
helper is the right shape because it can take the op context the renderer
has; the capability alone is not enough.

Bumping the contract version (per ADR 0024) makes this a deliberate,
versioned event. Drivers that subclass any of the five base classes can
record what they were tested against and warn on drift. Pre-bump, drivers
that subclass `DBIO::Storage::DBI::Capabilities` would silently inherit
the new capabilities and not know to test against them.

## Consequences

- **PostgreSQL behaviour is unchanged.** It already declares
  `transactional_ddl = 1` and `supports_if_exists = 1` (or has the engine
  facts to set them); the deploy path continues to wrap in `txn_do` and to
  emit `IF EXISTS`. The release is invisible on PG.
- **MySQL (pre- and post-8.0), Oracle, DB2, Sybase, Informix need driver
  updates.** Each driver declares its own value for `transactional_ddl`
  (typically 0) and `supports_if_exists` (typically 0 for the legacy
  engines, 1 for engines that have caught up). This is a per-driver
  follow-up — the right place for it is each driver's own karr board.
- **SQLite explicitly opts out of `transactional_ddl = 1`** so the rebuild
  path's `AutoCommit = on` invariant is preserved. This is the canonical
  case where blanket-wrapping would be a regression; the capability flag
  fixes it.
- **Diff renderer's IF-EXISTS question is now an engine-fact question, not
  a name-match question.** Driver audit drift of the kind ADR 0021 records
  for `constraint_name` cannot recur here, because the renderer no longer
  reads driver names to make the decision.
- **Operators on non-transactional engines get a one-shot carp at first
  upgrade.** This is the desired UX — visible but not nagging — and the
  `__VERSION` row gate remains the forward-progress recovery story on
  those engines.
- **Contract version 1.1** locks the bump, and `t/test/12_contract_version.t`
  is the tripwire that forces any future contract change to be deliberate.
- `t/test/13_deploy_capabilities.t` (15 assertions) is the regression
  guard for the capability plumbing: get/set, fallback, txn_do wrap
  conditional, upgrade branch, carp_once one-shot, IF-EXISTS helper.
  Mock-only — no real DB required.

Relates to ADR 0021 (the spelling drift that motivates
driver-name-string-matches being a wrong-shape contract), ADR 0024 (the
contract-version mechanism that records this bump), and the F02 / F10 / F12
flaws from the CurtisPoe review of DBIO core.

## Addendum 2026-07-29 — the capability is per connection, atomicity is per statement

Decision §2 makes `_execute_ddl` bracket the DDL body in `txn_do` exactly when
the storage reports `transactional_ddl`. That reads the engine as uniform: either
its DDL participates in transactions or it does not. PostgreSQL falsifies it, and
k132 (this addendum) records the correction rather than filing it as an
implementation detail, because it changes what the capability means.

### What the boolean cannot say

`ALTER TYPE ... ADD VALUE` on PostgreSQL is not transactional even though every
other statement the driver emits is. Before server 12 the engine rejects it
outright inside a transaction block; from 12 on it accepts it, but the new enum
value stays unusable until that transaction commits — so an upgrade that adds a
value and then references it (a column default, a data migration) fails either
way. `apply()` hands the **whole** diff to `_execute_ddl` as one batch, so a
driver facing this had exactly two options under §2, both wrong: declare the
capability and ship an upgrade path that breaks on enum changes, or refuse it and
give up atomicity for every deploy the engine could have run atomically. That is
what blocked dbio-postgresql k50.

Other engines have their own such statements (`CREATE INDEX CONCURRENTLY`,
`VACUUM`); which of them a driver actually emits is per-driver work.

### The rule

A second, finer question sits under the capability:
`_ddl_statement_is_transactional($stmt)` on
`DBIO::Storage::DBI::Capabilities`, **default true**. It is asked once per
statement, and only on a storage that already reports `transactional_ddl` — a
driver cannot switch the grouping on by defining the hook alone.

`_execute_ddl` groups consecutive statements by the answer, preserving order:
each run of transaction-safe statements gets one `txn_do`, a statement that
answered false runs on its own outside any transaction. A batch where everything
answers true produces a single run and is byte-identical to the §2 behaviour, so
a driver that never defines the hook sees no change whatsoever.

Three alternatives were weighed. **All-or-nothing per batch** — one disqualifying
statement drops the bracket for everything — is the cheapest and was rejected as
too blunt: a single enum value would cost an entire upgrade its atomicity.
**Op-driven marking**, where a diff op declares itself non-transactional, models
the problem most cleanly but only covers `apply`; `install` has a plain DDL string
with no ops behind it, so it would need one of the other two underneath anyway.
Grouping was chosen because it keeps atomicity everywhere it is still available
and needs no knowledge of ops.

### What it costs

A split batch is no longer one transaction. A failure in a later run leaves the
earlier ones applied — the same partial-application state §2 accepts on
non-transactional engines, and the `__VERSION` gate in `DBIO::DeploymentHandler`
is the same recovery story: a re-run recomputes the diff against live state and
picks up the remainder. Core announces a split once per deploy class, keyed on
the class rather than the message, since the statement counts in the text vary
from batch to batch and would otherwise re-arm the one-shot.

### Contract version

No bump; stays **1.2**. Per the in-cycle rule recorded in
`t/test/12_contract_version.t`, 1.2 has never been released — the last CPAN
release, 0.900002, carries 1.1 — so this hook joins the generation that has not
shipped yet rather than opening a 1.3 no consumer could distinguish. The hook is
additive with a default that reproduces existing behaviour exactly, and no driver
in the family declares `$TESTED_AGAINST_CONTRACT`, so nothing can compare against
a 1.2 that lacked it.

Relates to k131 (the ownership condition on the same bracket, a fix rather
than a decision) and to ADR 0024 (the contract-version mechanism).

### Async parity (k199)

`DBIO::Storage::Async::deploy_async` is the Future-side mirror of
`_execute_ddl`. It already probed the connection-level capability
(`_use_transactional_ddl`) but ignored the per-statement half above: on a
transactional engine it wrapped the **whole** batch in one `txn_do_async`, so a
statement the hook declares non-transactional (PostgreSQL `ALTER TYPE ... ADD
VALUE` under `dbio-postgresql-ev`) still ran between `BEGIN` and `COMMIT`.

The async path now asks the **same** `_ddl_statement_is_transactional` hook —
on the owning sync storage (`_owner_storage`), the storage
`_use_transactional_ddl` already delegates to and the one carrying the
capability — and reuses the **same** grouping (`_group_ddl_statements`) so the
runs come out in the same order and grouping as the sync deploy. Each
transaction-safe run is bracketed in one `txn_do_async` on a pinned connection;
a non-transactional run executes on its own pooled connection, outside any
transaction. A batch where everything is transaction-safe is one run, identical
to bracketing the whole loop, so nothing changes for a driver that never
defines the hook. A split is announced once per class, and the `__VERSION` gate
is the same recovery story. Each connection — pinned txn or pooled outlier — is
released exactly once on both the success and failure paths.

This is a parity fix, not a new decision: no capability, hook, or contract
change. `DBIO::Storage::Async` is not one of the contract-versioned base
classes, so the contract stays **1.2**. Regression coverage:
`t/test/19_async_deploy.t` (mock-only, fake async transport) pins the
`[txn] [outlier] [txn]` grouping, consecutive-outlier coalescing, the
hook-default single-run case, and exactly-once connection release on the error
paths, all by connection identity rather than counters alone.
