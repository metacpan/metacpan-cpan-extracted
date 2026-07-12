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
