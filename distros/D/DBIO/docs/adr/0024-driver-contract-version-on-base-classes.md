# ADR 0024 — Per-base-class `$CONTRACT_VERSION` on driver base classes

- Status: accepted
- Date: 2026-06-25
- Tags: public-api, contract, cross-repo, versioning, drivers

## Context

Out-of-tree DBIO drivers subclass five core base classes to inherit the canonical
behaviour they are expected to honour:

- `DBIO::Introspect::Base`
- `DBIO::Diff::Base`
- `DBIO::Deploy::Base`
- `DBIO::SQLMaker`
- `DBIO::Storage::DBI::Capabilities`

Until now, the canonical-model shape these drivers depend on was specified in
prose POD on each base class, and the only machine-readable version signal was
the dist-wide `$VERSION` (build-injected by Dist::Zilla's
`VersionFromMainModule` into every module). Dist `$VERSION` is a *release* signal
— it advances every CPAN release and tells consumers what they have installed —
not a contract signal. A driver that subclasses `DBIO::Deploy::Base` has no
way to programmatically ask "what shape of `_execute_ddl` am I inheriting?" and
no way to warn at load time when that shape drifts from what the driver was
written against.

The convention-only contract has already fractured once. ADR 0021 records that
the `constraint_name` canonical key has visibly drifted spelling across
out-of-tree drivers — the kind of drift a machine-readable version stamp would
have caught at the moment a driver's `cpanfile` was bumped, not after the fact
in a cross-repo audit. Drivers cannot currently even notice.

## Decision

Add a per-base-class `$CONTRACT_VERSION` and a `contract_version()` accessor to
all five base classes listed above. Drivers record the contract version they
were last tested against and warn / strict-fail at load time when it drifts.

1. **Each base class carries its own `our $CONTRACT_VERSION = '1.x';`** plus a
   `sub contract_version { $CONTRACT_VERSION }` accessor. The accessor shape
   matches the rest of the per-base-class style (`simple_model`,
   `has_changes`, etc.) so it is idiomatic to read and easy to override in
   tests.
2. **`$CONTRACT_VERSION` is independent of the dist `$VERSION`.** The dist
   `$VERSION` continues to advance every release. The contract version advances
   only when the shape of the public surface (method signatures, capability
   names, return types) changes in a way drivers can observe. A code-only
   refactor that preserves shape is not a contract bump.
3. **The contract version starts at `'1.0'`** — "the contract is now defined."
   `1.1` records the F02 / F10 / F12 additions (`transactional_ddl`,
   `supports_if_exists` capabilities on `DBIO::Storage::DBI::Capabilities`;
   `should_emit_if_exists` helper on `DBIO::Diff::Op`; `_execute_ddl` txn-do
   wrap probe on `DBIO::Deploy::Base`).
4. **Drivers record what they were tested against and warn on drift.**
   Recommended idiom (per the per-base-class POD):
   ```perl
   package DBIO::Storage::MyDriver;
   use DBIO::Storage::DBI::Capabilities;
   our $TESTED_AGAINST_CONTRACT = '1.1';
   if (DBIO::Storage::DBI::Capabilities->contract_version ne $TESTED_AGAINST_CONTRACT) {
       warnings::warn "DBIO contract drift: wrote against 1.1, "
                    . "core now ships " . DBIO::Storage::DBI::Capabilities->contract_version;
   }
   ```
   The exact policy (warn, carp, croak) is per-driver. Core's job is to make the
   signal machine-readable.
5. **A mock-only regression test (`t/test/12_contract_version.t`) locks the
   accessor shape and asserts `contract_version ne $VERSION`** so a future
   edit cannot silently merge the two.

## Rationale

A version signal is the cheapest way to make an implicit contract explicit. The
core/base side carries a one-line accessor and a `POD` paragraph; the driver
side carries a one-line declaration and a load-time check. That is a smaller
surface area than continuing to rely on prose POD that drifts unnoticed.

Bumping `$CONTRACT_VERSION` decoupled from dist `$VERSION` matches the actual
axes drivers care about: a CPAN release that ships only a bugfix does not
change what drivers need to honour, so it should not force every driver to
re-test. Decoupling the two signals keeps the per-driver check signal-to-noise
ratio high — when the contract number moves, drivers *should* re-test.

Centralising the version on the base classes (rather than on a separate
`DBIO::Contract` module drivers must `use` explicitly) follows the
"bless-it-on-the-method's-own-class" pattern of ADR 0023 — the contract lives
next to the code that defines the shape, and a driver's natural subclass
relationship is enough to inherit the signal.

## Consequences

- Every out-of-tree driver is invited to record `$TESTED_AGAINST_CONTRACT` and
  warn on drift. Core does not enforce a specific policy; that is a per-driver
  decision (and a good karr cross-repo item to propose).
- Future contract-shape changes (new capability names, new required method
  signatures, new return types on existing methods) become conscious, versioned
  events. The regression test forces the bump to be deliberate: editing
  `$CONTRACT_VERSION` without updating the test's expected literal will fail CI.
- Drivers that do nothing still work — the contract version is opt-in to read,
  not required at load time. The cost of being conservative is zero for
  in-tree code and a small POD nudge for out-of-tree drivers.
- The five base classes share a version number. This is intentional: the
  contract is one family-wide model, and the bumps tend to come together (F02
  / F10 / F12 touched three of the five). A driver that subclasses more than
  one base class sees one signal, not five. If the bases ever diverge, the
  accessor shape is already in place to give each its own number without
  breaking readers.
- `t/test/12_contract_version.t` is the regression guard. It also documents
  the bump history inline, so a future reader sees why the number is what it
  is.

Relates to ADR 0021 (the spelling drift that motivated the version), ADR 0023
(same ownership principle — bless-the-method's-own-class), and ADR 0026 (the
1.0 → 1.1 bump recorded there).
