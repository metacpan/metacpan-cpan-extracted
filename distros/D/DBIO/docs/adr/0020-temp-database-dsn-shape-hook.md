# ADR 0020 — Temp-database DSN form is the single overridable seam (`_temp_dsn`)

- Status: accepted
- Date: 2026-06-20
- Tags: deploy, drivers, cross-driver, dsn, temp-database, family-policy

## Context

`DBIO::Deploy::Base::TempDatabase`
(`lib/DBIO/Deploy/Base/TempDatabase.pm`) is core's shared base for drivers whose
diff builds the target model by deploying the desired schema into a freshly
created temporary *database* and introspecting it — PostgreSQL and MySQL (ADR
0006 / ADR 0007). To connect to that temp database it must derive a temp-db DSN
from the live storage's `connect_info`. That derivation, `_temp_connect_info`,
does four things: it normalises the two connect-info shapes (array
`($dsn, $user, $pass)` and single-hashref `{ dsn, user, password }`), extracts
user/password, guards against a coderef DSN (dying, since a coderef cannot be
rewritten), and finally produces the temp DSN string.

Only the *last* of those four — the **form** of the temp DSN — is genuinely
engine-specific. PostgreSQL and MySQL both name the database with a
`dbname=`/`database=` key, so the standard derivation rewrites that key. But a
driver whose DSN shape differs has no key to rewrite: Firebird's DSN is
`dbi:Firebird:localhost:$db`, the database is positional, not a `dbname=` field.

Before this decision, a driver with a divergent DSN shape had no narrow seam —
it had to override the *whole* `_temp_connect_info`. `dbio-firebird` did exactly
that: its `Deploy.pm` replaced `_temp_connect_info` outright to build the
`localhost:$db` form, and in doing so re-implemented the connect-info shape
handling and the user/password extraction by copy. Worse, the copy **silently
dropped the coderef-DSN guard** — a duplication regression: the engine-agnostic
safety check existed in core but was absent from the fork's hand-rolled copy, so
a coderef DSN would not have been caught there. (karr core#48.)

## Decision

`DBIO::Deploy::Base::TempDatabase` exposes `_temp_dsn($dsn, $temp_db)` as the
**single overridable seam** for the *form* of the temp-database DSN. A driver
whose DSN shape differs overrides only this narrow hook and inherits everything
else from `_temp_connect_info`.

- `_temp_connect_info` keeps the shared, engine-agnostic work: connect-info
  shape normalisation, user/password extraction, and the coderef-DSN guard. Its
  final step is `$self->_temp_dsn($dsn, $temp_db)` — the one call a subclass can
  redirect (`TempDatabase.pm:142-163`).
- `_temp_dsn` is the only overridable form-hook. The default is
  **behaviour-preserving**: it builds today's standard form bit-identically —
  rewrite the `database=`/`dbname=` component to `$temp_db` when present, else
  append `;dbname=$temp_db` (`TempDatabase.pm:182-193`). PostgreSQL and MySQL are
  unchanged.
- This is a **cross-driver convention**: override the narrow form-hook, never the
  whole `_temp_connect_info`. A driver that reaches for the whole method to
  change only the DSN form is re-introducing the duplication (and the
  guard-dropping regression class) this seam exists to prevent.

The contract is pinned by `t/deploy-base.t`: the default `_temp_dsn` is asserted
bit-identical to the previous inline rewrite (rewrite `dbname=`/`database=`,
append when absent), and a `Temp::FirebirdShape` subclass overrides *only*
`_temp_dsn` to return `dbi:Firebird:localhost:$temp_db` — proving the override
drives the final DSN while user/password extraction and the coderef-DSN guard
are still inherited from `_temp_connect_info`.

## Rationale

The Firebird divergence was not a defect in `_temp_connect_info` — it was the
absence of a seam at the right granularity. The only legitimate per-driver
variation in temp-db connection derivation is the DSN *form*; everything else
(shape handling, credential extraction, the coderef guard) is engine-agnostic
and must stay shared. Forcing a whole-method override to vary the one thing that
legitimately varies guarantees duplication, and duplication of a safety invariant
guarantees that some copy will eventually drop it — which is exactly how the
coderef-DSN guard went missing from the Firebird copy.

Giving the one legitimate variation its own narrow hook removes both the
duplication and that whole regression class at once: the shared invariants live
in exactly one place (`_temp_connect_info`), and the form is a three-line method
a driver can safely replace. The default staying bit-identical means the seam is
a pure refactor for the engines that already worked — no behavioural change for
PostgreSQL or MySQL — while opening the correct, minimal door for the engines
that did not fit.

## Consequences

- A driver whose temp-db DSN shape differs from the `dbname=` form overrides only
  `_temp_dsn` and inherits shape handling, user/password extraction, and the
  coderef-DSN guard from core. Overriding the whole `_temp_connect_info` to vary
  only the DSN form is now a smell, not the pattern.
- `dbio-firebird` can drop its full `_temp_connect_info` override and replace it
  with `sub _temp_dsn { "dbi:Firebird:localhost:$_[2]" }`, inheriting the shared
  shape/credential/coderef-guard handling from core. This is work in the
  `dbio-firebird` repo, tracked by a karr ticket on that repo's board — and it
  closes the dropped-coderef-guard regression as a side effect.
- PostgreSQL and MySQL are unaffected: the default `_temp_dsn` reproduces the
  prior inline rewrite bit-for-bit.
- Extends the native temp-database deploy path of ADR 0006 (which established
  `DBIO::Deploy::Base::TempDatabase` as core's shared base for the temp-db
  deploy) with the per-driver DSN-form seam. Sits alongside ADR 0019 as a
  cross-driver correctness convention owned by core rather than re-asserted in
  each driver.
