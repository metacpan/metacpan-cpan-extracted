# ADR 0034 — Guard non-concrete relation conditions at the resolver boundary, not split them into a ResultSet-layer nested upsert

- Status: accepted
- Date: 2026-07-13
- Tags: resultset, relationships, find, update_or_create, set_from_related, guard, supersedes-0033

## Context

[ADR 0033](0033-update-or-create-dwim-splits-unresolvable-relation-subhash.md)
gave `update_or_create()` a DWIM: when a passed condition mixed plain columns
with a relation-valued key that did not reduce to a concrete foreign-key
condition on the main table, the key was peeled out of the `find()` lookup and
applied afterwards as a second, transactional `update_or_create` on the
related resultset. The stated problem was real — `find()`'s existing
crosstable guard threw a safe but unhelpful exception, and the DWIM the caller
actually wanted (find/create the main row, then apply the relation to the
related row) had to be hand-rolled.

Implementing the split surfaced two problems 0033 did not anticipate:

1. **It consumed relation-valued keys that belong to the row layer.** A
   `has_many` / `has_one` / `might_have` sub-hash on `update_or_create`'s
   condition is exactly the shape a row-layer component (nested-write support)
   would want to interpret — insert-or-update the related rows as part of the
   same operation the main row participates in. Peeling it into an
   independent second upsert on the related resultset, wrapped in its own
   `txn_scope_guard`, took that key away from the row layer before any
   row-layer nested-write design existed, and hard-coded one specific
   interpretation (a bare related upsert) as the only one stock DBIO could
   ever give it.
2. **It was under-specified for `has_many`.** The split classifier peeled a
   `has_many` searched by non-key columns the same way as a `might_have` /
   `has_one`, but a `has_many` sub-hash more naturally describes a *set* of
   related rows, not a single upsert target — the one-upsert shape 0033
   shipped does not fit it.

0033's diagnosis of the underlying corruption risk was correct and is not
revisited here: a relation resolution that is non-concrete — crosstable, or
join-free but resolving to `undef` / `UNRESOLVABLE_CONDITION` on this table's
own columns (e.g. a `might_have` searched by a non-key column resolves to
`{ self_pk => undef }`) — silently clobbers a real key column with an undef
foreign key if folded into a lookup or a write without checking. That risk is
real and, per the `Changes` entry for this release, was reproducible against
every caller of `set_from_related`/`set_inflated_columns`, not only
`update_or_create`. What is revisited is the *remedy*: 0033 routed around the
risk by rewriting `update_or_create` into a two-write DWIM; this ADR instead
closes the risk at its source, at the resolver boundary itself, and gives
`update_or_create` back its original one-`find()`, one-write shape.

## Decision

**Guard non-concrete relation conditions where they are resolved, on both the
read and write path; do not split them into a second, ResultSet-layer write.**

1. **`find()` treats a non-concrete relation resolution as a miss instead of
   folding it in.** In `lib/DBIO/ResultSet.pm`, `find` and `find_async` both
   resolve their arguments through the shared `_resolve_find_query`, so the
   guard lives there once and the sync and async paths cannot drift. It already
   threw `Complex condition via relationship '$key' is unsupported in find()`
   for a genuinely crosstable relation sub-hash; that throw is unchanged and
   fires first. A relation that is *not* crosstable but resolves to an undefined
   or `UNRESOLVABLE_CONDITION` value slips past it (it reduces join-free to a
   hashref) and previously corrupted the lookup silently. `_resolve_find_query`
   now runs the resolved condition through `_related_cond_is_concrete` — a
   predicate over `_resolve_related_cond`'s result (unchanged: not crosstable, a
   non-empty `HASH`, every value defined and not the sentinel) — and, when it is
   not concrete, signals a *miss* out-of-band via an `$is_miss` flag rather than
   merging the condition. `find` returns `undef` on that flag and `find_async`
   resolves its future with `undef`. No row can match a condition that does not
   reduce to concrete columns, so this is the historically observable outcome of
   the find-then-write idioms (`find_or_create` / `update_or_new` fall through
   to their write branch) — now reached by a clean miss instead of a corrupt
   `WHERE key IS NULL` merge. (The miss must be signalled out-of-band because a
   bare `undef` resolved condition is *also* produced legitimately by the
   `'single'`-accessor path, which is not a miss, so definedness alone cannot
   distinguish the two.)

2. **`set_from_related` refuses a non-concrete relation resolution on the
   write path.** `DBIO::Relationship::Base::set_from_related`
   resolves a plain (unblessed) hashref
   argument via `_resolve_relationship_condition` and, before applying the
   result with `set_columns`, throws when any inferred value is undefined or
   the `UNRESOLVABLE_CONDITION` sentinel. This is the same corruption
   `find()` guards against, reached through the row layer instead of the
   resultset layer — `Row::update` → `set_inflated_columns`
   (in `lib/DBIO/Row.pm`) hands a raw hashref straight to
   `set_from_related` for a `'single'`-accessor relationship, so this is the
   one place that write-path corruption can occur, for every caller
   (`update_or_create` included, but not exclusively). A blessed related
   object and an explicit `undef` (belongs_to disassociation) are left
   untouched — the guard fires only on a plain hashref that resolves
   non-concretely.

3. **`update_or_create()` no longer splits, and opens no transaction for this
   case.** `_split_related_update_conds` is renamed and repurposed to
   `_find_lookup_cond`: it returns a single
   lookup condition — the passed condition with every relation-valued key
   that does not reduce to a concrete condition removed — instead of
   `(\%main, \%related)`. `update_or_create`
   passes that lookup to `find()`, and passes
   the **full, original, unsplit condition** — relation keys included — to
   `$row->update` / `new_result->insert`. The row layer, not
   `update_or_create`, decides what a nested relation sub-hash means; stock
   DBIO's row layer does not currently accept one (see Consequences), so it
   throws, exactly as it did before the 0.900001 DWIM existed. Because there
   is no second write to protect, the `txn_scope_guard` the split opened is
   gone; the common case opens no transaction, same as before 0.900001.

4. **The `key` attribute is untouched by this ADR.** It was, and remains,
   scoped to the main-table `find()` lookup only ( `_find_lookup_cond`
   doesn't touch it); 0033's reasoning for that scoping stands independent of
   the split it originally described.

## Rationale

A resolver-boundary guard is strictly more general than a
`update_or_create`-specific split: it closes the corruption for every path
that resolves a relation value down to columns on this table — `find()`,
`set_from_related`, and therefore `update_or_create`, `update_or_new`, and any
future caller — with one predicate (`_related_cond_is_concrete`) and one
guard each on the read and write side, rather than one bespoke rewrite of a
single method. It also stops pre-deciding, in the ResultSet layer, what a
nested relation sub-hash on `update_or_create` *means*. That question belongs
to the row layer, which is where DBIO's other nested-write behaviour
(multi-create, `DBIO::Row::insert`) already lives; a ResultSet-layer split
answered it once, narrowly, and by removal, before a general row-layer answer
existed.

Restoring `update_or_create`'s single-`find()`, single-write shape (no second
resultset, no extra transaction) also matches its documented contract: one
row is found-or-created. The DWIM's insert-then-upsert-relation behaviour was
a second operation wearing a one-operation method's name.

## Consequences

- **Stock nested-write via `update_or_create` is removed, pending a row-layer
  design.** A `has_many` / `has_one` / `might_have` sub-hash on
  `update_or_create`'s condition once again throws at the row layer (the
  pre-0.900001 behaviour) instead of being peeled off and upserted separately.
  This is a real capability the 0.900001 DWIM gave stock callers and this ADR
  removes it; nested update belongs at the row layer instead, and an RFC for
  that seam is expected to follow. A result class that composes its own
  nested-relation semantics into the row layer may still accept such a
  sub-hash — `update_or_create` no longer forecloses that by peeling the key
  away first.
- **`update_or_new` is covered without a code change.** It delegates its lookup
  to `find()` with the full condition; `find()`'s
  guard (Decision §1) turns the previously-corrupt merge into a clean miss, and
  the fall-through `new_result($cond)` is governed by the row layer exactly as
  `update_or_create`'s write path is — a non-concrete `belongs_to` sub-hash hits
  the write-path guard (Decision §2), while a nested `has_many` / `might_have`
  follows the row layer's create-vs-update rules (documented in the
  `update_or_create` POD). So `update_or_new` no longer corrupts the key, again
  with no `update_or_new` change. Aligning it to `_find_lookup_cond`'s
  drop-and-defer-to-full-condition behaviour instead would be a small, separate
  follow-up — out of scope here, as it was under 0033.
- **Renamed/removed methods**: `_split_related_update_conds` →
  `_find_lookup_cond` (single lookup cond, not a `(\%main, \%related)` pair);
  no method now peels a relation out of `update_or_create`'s condition or
  opens a `txn_scope_guard` for it.
- **New shared predicate**: `_related_cond_is_concrete`,
  used by both `find()`'s guard and
  `_find_lookup_cond`, so the two agree on what "usable in a lookup" means —
  the same one-seam discipline 0033 established for resolution, kept here for
  concreteness-testing.
- **Test coverage**: `t/resultset/update_or_create_related.t` drops the
  peel-and-apply / txn / key-not-leaked blocks (the behaviour they tested is
  gone) and gains coverage for the restored plain found→update /
  absent→insert path (no transaction) and for composition-via-recording-
  subclass (find gets the lookup with the non-concrete relation dropped, the
  row layer gets the full condition). New `t/relationship/set_from_related_guard.t`
  covers the write-path guard directly: clobber refused via `set_from_related`
  and via the `set_inflated_columns` update trace, key column preserved; a
  concrete `belongs_to` hashref and an explicit `undef` disassociation still
  apply.
- No public API signature changes; the base-class contract version is
  untouched (ADR 0024 is unaffected — this is `ResultSet`/`Relationship::Base`
  behaviour, not a driver-facing base class).

## Relationship to other ADRs

- **0033 — split design superseded; corruption diagnosis kept.** 0033's
  Decision (peel a non-concrete relation sub-hash out of `update_or_create`'s
  `find()` condition and apply it as a second, transactional upsert on the
  related resultset) is fully superseded: `update_or_create` no longer splits
  or opens a transaction for this case. 0033's Context — that a non-concrete
  relation resolution folded into a lookup silently clobbers the main row's
  key — was correct and is exactly what this ADR's guards fix at the
  resolver boundary instead of routing around. 0033's Status is updated to
  "superseded by 0034"; its text is otherwise left intact as the historical
  record of the split design, why it was tried, and why it did not hold up
  (the row-layer ownership and has_many under-specification problems in
  Context above).
