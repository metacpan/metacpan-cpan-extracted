# ADR 0052 — `index_type` is a bilateral attribute of the canonical index model

- Status: accepted
- Date: 2026-09-21
- Tags: diff, migration, introspect, canonical-model, drivers, cross-repo, contract

## Context

The native diff layer (ADR 0007) compares a live introspect model against a
desired model and emits migration operations for what differs. For indexes, the
canonical "did this index change?" question is answered by `changed_index_fields`
in `lib/DBIO/Diff/Compare.pm`, which until now compared exactly two attributes:
`is_unique` (a bool) and `columns` (an order-independent set).

That is blind to the index's **access method / class**. On MySQL a
`BTREE` index and a `FULLTEXT` index over the same column, with the same
uniqueness, compare **equal** — so a schema that changes a plain index to
`FULLTEXT` (or `SPATIAL`, or `HASH`) produces **no diff**, and the new index is
never created. The type is present in the engine and, for MySQL, already read
into the introspect model (`Index_type` from `SHOW INDEX` /
`information_schema.STATISTICS`), but the canonical comparison discards it. The
same blind spot applies to any engine with more than one index method:
PostgreSQL's `btree`/`hash`/`gin`/`gist`/`brin`/`spgist`, and so on.

The obvious fix — "compare `index_type` like any other scalar" — is **wrong**,
and ADR 0019 says why in as many words. The desired-state contract that ADR 0019
made always-on skips a `scalar`/`type`/`dim`/`array` field only when the
**target** side is `undef`, and deliberately treats "target set, live `undef`"
as a **real change** (its regression test `t/diff-desired-state-undef.t` case
(c) pins this). ADR 0019 explicitly rejects a symmetric either-side-`undef`
skip, because for a server-assigned column attribute an `undef` on the target
means "the schema did not prescribe it" while a value on the target that the
live DB lacks means "the schema prescribes something the DB must adopt."

Index type does not behave like that. A driver that does not introspect index
type has **no opinion at all** — it produces `undef` on *both* sides, or, in a
mixed/degenerate case, on one side. If `index_type` were a `scalar`, the
"target set, live `undef`" branch would fire and a typeless (or partially typed)
driver would emit a **phantom index migration**: an attempt to "change" an index
to a type when we do not actually know it is not already that type. That is the
exact class of bug ADR 0019 exists to prevent, arriving from the opposite
direction.

## Decision

`index_type` becomes a first-class, **optional** attribute of the canonical
index model, compared **bilaterally**.

1. **Canonical model.** The `indexes` section of the canonical model
   (`lib/DBIO/Introspect/Base.pm`, `CANONICAL MODEL`) gains an optional
   `index_type` key alongside `is_unique`, `columns` and `origin`. It holds the
   engine's index access method / class as an opaque token
   (`BTREE`/`FULLTEXT`/`SPATIAL`/`HASH`; PostgreSQL `gin`/`gist`/`brin`/...).
   **The default is `undef` — "this driver has no opinion about index type."**
   Core enumerates no closed vocabulary; a driver stores whatever it introspects.

2. **A new comparison group, `mutual`.** `changed_fields` in
   `lib/DBIO/Diff/Compare.pm` gains a `mutual` group. A `mutual` field is
   compared as a case/whitespace-insensitive token (via `norm_type`, so
   `btree` and `BTREE` are equal — PostgreSQL reports lowercase, MySQL
   uppercase), **but only when both sides carry a value**. `undef` on *either*
   side means that participant has no opinion, so the field is not compared and
   never contributes a diff. This is a distinct skip policy from the
   desired-state `scalar`/`type` groups, which skip only on target-`undef`.

3. **`changed_index_fields` adopts it.** `changed_index_fields` now passes
   `mutual => ['index_type']` in addition to `bool => ['is_unique']` and
   `array => ['columns']`. So a `BTREE` → `FULLTEXT` switch on otherwise
   identical columns is now a real change, while an index with no type on one or
   both sides is unchanged with respect to type.

4. **Contract surface — rides along in 1.2 (ADR 0024).** Adding an optional key
   to the canonical `indexes` shape is a contract-surface change on
   `DBIO::Introspect::Base`. Following the same in-cycle rule ADR 0037 / ADR
   0039 applied — the 1.2 generation has never been released (last CPAN release
   `0.900002`), so nothing added before its first release can be told apart from
   1.2 by any consumer — `$CONTRACT_VERSION` stays `1.2`. The change is recorded
   in the ledger comment of `t/test/12_contract_version.t` rather than by
   minting a `1.3`. It is purely additive (a new optional key, no signature or
   return-type change) and its `undef` default reproduces the previous index
   diff index-for-index, so there is nothing a driver could compare against
   `$TESTED_AGAINST_CONTRACT` and act on. `DBIO::Diff::Compare` carries no
   `$CONTRACT_VERSION` of its own; the `mutual` group rides with the
   `DBIO::Introspect::Base` canonical-model surface exactly as ADR 0037's storage
   hooks ride with `DBIO::Storage::DBI`.

## Rationale

The choice that matters is `mutual` versus `scalar`. ADR 0019 established that
the diff kernel encodes a specific meaning of `undef` per field group, and that
choosing the wrong group re-introduces phantom migrations. Its own last
consequence anticipated this case: *"any future field whose `undef` is a
meaningful value (rather than 'unspecified') must be declared `bool` (or a new
group with matching semantics), not `scalar`."* Index type is that field, and
`bool` does not fit (it is a token, not a flag), so it earns the new group.

The meaning of `undef` for `index_type` is "no opinion," and it is symmetric
because the reason for the `undef` is symmetric: it is a property of the
**driver**, not of the schema author's intent. A typeless driver omits the key
on both the introspected and the desired side, because both models come from
the same driver. When only one side carries a type, we still cannot honestly
diff — we would be asserting a change we cannot substantiate. Silence is the
only phantom-free answer, and it is also the safe one: the worst outcome of
staying silent is a missed type change on a half-instrumented driver, versus the
worst outcome of diffing, which is a destructive index rebuild on every upgrade
for a driver that never had type information to begin with.

Putting the mechanism in `changed_fields` (a `mutual` group) rather than
special-casing `index_type` inside `changed_index_fields` keeps the kernel the
one place that decides `undef` semantics — the same principle ADR 0019 used to
solve the desired-state bug once instead of per-caller. A second engine that
needs the same bilateral treatment (PostgreSQL index method, a storage
parameter) reuses the group instead of re-deriving the skip logic.

## Consequences

- A driver that does not introspect `index_type` is **unchanged**: `undef` on
  both sides means the index diff behaves exactly as before this ADR. No driver
  is required to adopt the field, and none regresses by ignoring it.
- A driver that carries `index_type` gets `BTREE` ↔ `FULLTEXT` ↔ `SPATIAL` ↔
  `HASH` (etc.) changes as real diffs — but only where the type is known on both
  sides. To *render* the resulting create/drop, the driver's own `Diff::Index`
  `as_sql` must emit the type keyword; that is driver-owned work (below).
- The `mutual` group is available to every caller of `changed_fields`. It is
  documented in `DBIO::Diff::Compare` POD next to `scalar`/`type`/`bool`/`dim`/
  `array`, with the explicit contrast to the desired-state rule so the next
  author does not reach for `scalar` and reopen the ADR 0019 hazard.
- The phantom-diff guarantee is pinned by tests: `t/diff-compare.t` (the
  `mutual` group's five undef directions, and `changed_index_fields`'s
  both-typed / identical-typed / all-three-undef-directions cases) and
  `t/diff-op.t` (a `BTREE` → `FULLTEXT` switch reaching `on_changed` through the
  real `diff_nested` walk while a typeless index does not).

## Future architecture work (tracked cross-repo, not here)

Core owns the canonical model and the comparison kernel; **rendering and
introspecting** the type is per-driver and is not done here.

- **dbio-mysql (karr k52, parts 1 + 2)** — the ticket this ADR unblocks. MySQL
  already reads `Index_type` into its introspect model; parts 1 + 2 must (a)
  populate the canonical `index_type` key from that read (mapping the engine
  token, e.g. `FULLTEXT`/`SPATIAL`/`BTREE`/`HASH`), (b) populate `index_type` on
  the **desired** model compiled from the schema's index declarations, so both
  sides carry it and the bilateral compare fires, and (c) render the keyword in
  its `Diff::Index` `as_sql` (`ADD FULLTEXT INDEX` / `ADD SPATIAL INDEX` /
  `USING HASH`, etc.). Parts 1 + 2 were blocked on this core card.
- **Other typed-index drivers** — the same adoption is *available* to any driver
  with multiple index methods: PostgreSQL (`gin`/`gist`/`brin`/`spgist`/`hash`
  vs `btree`, via `USING <method>`), and others. It is opt-in per driver and
  each is its own karr ticket on that driver's board; nothing breaks until a
  driver chooses to populate `index_type` on both sides. Core does not route or
  schedule that work.

Relates to ADR 0007 (native diff layer), ADR 0019 (desired-state skip, whose
group-semantics warning this ADR answers), ADR 0024 (contract-version policy),
and ADR 0037 / ADR 0039 (the in-cycle ride-along precedent).
