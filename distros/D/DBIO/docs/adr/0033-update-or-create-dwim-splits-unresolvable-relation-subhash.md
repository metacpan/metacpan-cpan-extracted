# ADR 0033 — update_or_create DWIM-splits an unresolvable relation sub-hash from the main-row search

- Status: accepted
- Date: 2026-07-11
- Tags: resultset, update_or_create, find, relationships, dwim, ergonomics

## Context

`$rs->update_or_create(\%col_data, \%attrs)` historically handed `%col_data`
verbatim to `find()` to locate the row to update-or-insert. When `%col_data`
mixed plain columns of the target table with a nested related sub-hash keyed on
a relationship name —

```perl
$rs->update_or_create(
  { artistid => 1, name => 'x', cds => { title => 'y', year => 2020 } },
  { key => 'primary' },
);
```

— the nested `cds => { ... }` was carried into the main-table search. This is a
long-standing DBIx::Class ergonomics wart reported by a user: the caller
*expects* the relation to be applied to the related rows, not folded into the
search for the main row.

The status quo is already **safe**, not a silent-corruption bug. `find()`
(`ResultSet.pm`) folds a related sub-hash into the main search only when the
relationship reduces to a join-free condition on this table's own columns; when
it cannot, it throws `Complex condition via relationship '$key' is unsupported
in find()`. This guard has existed since the earliest DBIx::Class history and
was carried into DBIO. So the caller got a hard exception, never a spurious join
or a mangled PK. The gap is purely ergonomic: the DWIM the caller expected —
keep the relation *out* of the main-row search, find/create the main row, then
apply the relation to the related resultset — was never automated. It existed
only as a manually-documented workaround (find, then
`$row->relation->update_or_create({...})`).

`create()` / multi-create already does the automated form of exactly this
(`DBIO::Row::insert`): related values are searched/created on the related source
separately, not blended into the main row's own search.

## Decision

1. **`update_or_create()` splits a mixed condition before the main `find()`.**
   A single shared resolution seam, `_resolve_related_cond($rsrc, $rel_name,
   $val)`, resolves a related sub-hash down to a condition on *this* source's own
   columns — the same resolution `find()`'s complex-condition guard performs.
   `find()` was refactored to call this seam; it is the one place the resolution
   lives, so the split logic and the guard can never drift apart.

2. **A top-level key is peeled into the related-subconds bucket only when it is a
   relationship name whose value is a plain (unblessed) hashref that does NOT
   reduce to a *concrete* foreign-key condition on the main table.** "Concrete"
   means: not crosstable, resolves to a non-empty `HASH`, and every resolved
   value is defined (no `undef`, no `UNRESOLVABLE_CONDITION` sentinel).
   - A resolvable `belongs_to` (FK-bearing hashref, or a blessed related object)
     reduces join-free to `{ self_fk => <defined> }` and **stays** in the main
     condition — `find()`/`update()`/`insert()` handle it exactly as before.
   - A `has_many` / `has_one` / `might_have` searched by its own non-key columns
     is either crosstable or resolves join-free to `{ self_pk => undef }` (which
     would silently clobber the main key with an undef FK). These are **peeled
     out** and applied to their own related resultset after the main row exists.
   - `has_many` **arrayrefs** (multi) and blessed/other non-plain-hashref
     relation values are left untouched in the main condition; the existing
     create/multi-create or update path already handles or rejects them,
     unchanged.

3. **The main row is found-or-updated (or created) from the plain columns only;
   each peeled relation is then applied via its own `update_or_create` on the
   corresponding related resultset**, mirroring `DBIO::Row::insert`'s
   multi-create fan-out.

4. **The `key` attribute constrains only the main-table lookup and is NOT
   propagated to the related resultsets.** A unique constraint named for the
   main table (e.g. `artist_name`) does not exist on the related source; leaking
   it would make the related `find()` die on an unknown constraint. The related
   upsert runs on its own resultset with no `key`, resolving via its own
   FK-scoped heuristics.

5. **When any relation is split out, the whole operation runs inside a
   transaction** (`schema->txn_scope_guard`), so a partially-built graph never
   survives a failure — the same guarantee `DBIO::Row::insert` gives multi-create.
   The common no-relation case opens no transaction.

## Rationale

The safe-but-unhelpful exception is replaced by the behaviour the caller
actually meant, without weakening `find()`: the complex-condition guard still
fires for a *direct* `find()` with a genuinely crosstable relation sub-hash.
This is an **extension**, not a behaviour break — the exception only disappears
for the mixed-condition `update_or_create` shape, where it was never useful.
Callers relying on the exception from a direct `find()` are unaffected.

Sharing one resolution seam between the guard and the split is the load-bearing
design point: the question "does this relation reduce to plain FK columns on the
main table?" is asked in exactly one place, so `update_or_create`'s DWIM and
`find()`'s guard interpret the *same* resolution result. Each caller interprets
it for itself — the guard rejects, the split peels — but neither re-derives it.

Scoping `key` to the main table follows from what a unique constraint *is*: a
property of one table. Propagating it to a related source is meaningless and
would surface as an "unknown constraint" error rather than the intended upsert.

## Consequences

- **Core**: `update_or_create` gains `_split_related_update_conds`; `find()` now
  routes its relation resolution through the shared `_resolve_related_cond`
  helper. New coverage: `t/resultset/update_or_create_related.t` (mock storage)
  exercises main-exists-relation-differs, `key`-scoped-to-main, insert-then-upsert
  under a transaction, the still-firing `find()` guard, and the split classifier
  (belongs_to folds, has_many peels).
- The returned value is unchanged: the (now stored) main row.
- No public API signature changes; the base-class contract version is untouched
  (this is `ResultSet` behaviour, not a driver-facing base class per ADR 0024).
- A future refactor that re-blends the related sub-hash into the main search, or
  that duplicates the FK-resolution test instead of calling the shared seam,
  breaks `t/resultset/update_or_create_related.t` — the deliberate guard.
