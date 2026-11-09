# ADR 0042 — No wantarray-dependent return types; ResultSet chaining contract

- Status: accepted
- Date: 2026-08-15
- Tags: api, resultset, breaking, wantarray, chaining

> Accepted by maintainer decision in k103 (2026-07-25, implemented
> 2026-08-15). The ticket proposed ADR 0037, which was already taken by the
> exists-query ADR; this document is numbered 0042 per the monotonic,
> never-reuse rule. ADR 0011's addendum referenced "k103 / ADR 0037" and
> was corrected to point here.

## Context

DBIx::Class heritage made several DBIO methods context-sensitive: `search()`
returns a ResultSet in scalar context but executes the query and returns rows in
list context, and the `has_many`/`many_to_many` accessors, `slice()`,
`search_related()`, `search_literal()`, `search_like()` and
`ResultSetColumn::func()` propagated or reproduced the same split. `func()` went
further: its list-context return was a completely different shape (one value per
row).

This was a long-standing footgun. `my @cds = $rs->search(...)` looked like "one
result" to code that expected a single list, executed a query as a side effect
of assignment, and made the chaining helpers (`order_by`, `group_by`, …) — which
are implemented via `search` — context-sensitive too, so a chained call inside
an array assignment silently returned rows instead of a ResultSet.

DBIO's namespace fork (ADR 0001) is a clean break: divergence from DBIx::Class is
explicitly allowed, there is no compatibility shim. The `IgnoreWantarray`
component that upstream built to paper over this was deliberately not integrated
(see ADR 0011): it is opt-in per class, `search`-only, and silently skips any
component that overrides `search`.

## Decision

**"wantarray steuert in DBIO nirgends den Rueckgabetyp"** — no public DBIO
method changes its return type based on call context. A method that returns a
ResultSet returns it in every context; fetch rows explicitly (`->all`, `->next`,
`->single`, …).

**Amended 2026-10-12 (k285):** four sites keep a context-dependent return as
documented exceptions — `populate`, `DBIO::PK::id`, `DBIO::Storage::BlockRunner`
and the internal `_resolve_condition` of `DBIO::ResultSource`. See the addendum
of 2026-10-12.

### List context now throws

Calling the affected entry points in list context throws a typed
`DBIO::Exception` immediately — there is deliberately **no deprecation cycle**.
A silent later switch would be worse: `my @cds = $rs->search(...)` would then
silently become a one-element list holding the ResultSet, indistinguishable from
"one result". Precedent: void context on `search()` already threw before this
ADR.

Affected entry points (each guarded at the top by
`assert_no_list_context($what) if wantarray;`):

- `search` in `lib/DBIO/ResultSet.pm`
- `search_related`, `search_literal`, `search_like`, `slice` in
  `lib/DBIO/ResultSet.pm`
- the `multi` relationship accessor in `lib/DBIO/Relationship/Codegen.pm`
  (the `has_many` accessor)
- the `many_to_many` accessor in `lib/DBIO/Relationship/ManyToMany.pm`
- `func` in `lib/DBIO/ResultSetColumn.pm`

The `*_rs` accessors (`cds_rs`, …) remain as always-a-ResultSet aliases; the
`search_rs`-based helpers (`order_by`, `group_by`, `columns`, `rows`, …) are
context-free by construction.

`assert_no_list_context` lives in `lib/DBIO/Util.pm` and replaces the old
`fail_on_internal_wantarray` stack-walker, which existed only to catch the same
mistake when it originated inside DBIO itself. The call-site `if wantarray` is
the actual context check — the guard sub is always invoked in void context, so
it cannot re-check `wantarray` and exists solely to throw the ADR 0042
exception once list context has been established.

### New chaining helpers

`lib/DBIO/ResultSet.pm` gains condition/attr chaining shortcuts, all of them
thin wrappers over `search_rs` (always a new ResultSet, in every context):

- `where($cond)` — condition-only: a flat key/value list is collapsed into a
  condition hashref, a single ref (hashref / arrayref / literal) is passed
  through verbatim, no arguments return a clone without touching the condition,
  and a flat list with an odd number of elements throws. Attributes are
  deliberately not accepted — they belong to `order_by`/`group_by`/`columns`/
  `rows`/`offset`. Exactly the attribute ambiguity in the flat call that created
  the legacy `search(%cond)` trap is what this signature avoids. Repeated
  `where()` calls stack (AND semantics) through `search_rs`'s existing
  `_stack_cond`.
- `having($cond)` — same flat-list-or-single-ref signature as `where`, targeting
  the `having` search attribute; stacks like `where`.
- `offset($n)` — attr shortcut like the existing `rows`.
- `join($rel)` — attr shortcut; the join type comes from the relationship's
  `join_type` attribute exactly as for a plain `search(undef, { join => ... })`.
  There is **no `left_join` helper** (the ticket's stated reason: "`join`
  erzeugt ohnehin per Default einen LEFT JOIN"). That rationale is accurate for
  `has_many`-style relationships, but a plain `belongs_to` defaults to INNER —
  the decision still stands: the helper mirrors the attribute, and a
  `belongs_to` that must join left declares its own `join_type => 'left'`.
- `select($sel, [$as])` / `as($aliases)` — the `select`/`as` pair. Because
  `search_rs` normalizes selectors together (an `as`-only call throws), `as()`
  re-applies the current `select` alongside the new aliases; calling it without
  a preceding `select()` throws a clear error. `select(\@cols, \@as)` passes
  both at once.

The target chain:

    $rs->where(col1 => 'value')
       ->order_by(-desc => 'col1')
       ->group_by('col1')
       ->having(cnt => { '>' => 3 })
       ->join('artist')
       ->offset(20)
       ->rows(10);

### `func()` loses its list-context shape

`ResultSetColumn::func()` always returns the single scalar and refuses list
context. Per-row function values now come from `func_rs($fn)->all` /
`->all_async` (which inflate a Row per row); there is no list-context
`func_async` to build — the async twins were already scalar-only.

## Consequences

- **Breaking:** `my @cds = $artist->cds` and `my @cds = $rs->search(...)` now
  throw instead of returning rows. Covered by ADR 0001's clean-break mandate;
  documented in `lib/DBIO/Manual/Migration.pod` and README.
- The async immediate-mode fallbacks that run sync twins (`_rsc_run_async` in
  `lib/DBIO/ResultSetColumn.pm`, which evaluates its closure in list context)
  had to force scalar context on the `func`-family fallbacks so the immediate
  mode keeps working under the new guard.
- Defining a `sub join` in `lib/DBIO/ResultSet.pm` shadows the `CORE::join`
  builtin for bareword calls in that package; the internal call sites were
  qualified as `CORE::join(...)` to remove the ambiguity warning.
- Downstream driver dists use list-context `search` in a handful of places
  (6 files across dbio-graphql, dbio-oracle, dbio-postgresql, dbio-sqlite per
  the k103 survey); each is a separate cross-repo follow-up.

## Addendum 2026-10-12 — the documented exceptions (karr k285)

Maintainer decision of 2026-10-12. The rule of this ADR is about methods that
hand back a ResultSet or a row source: none of them answers differently by call
context. Four sites return by context and stay that way; they are the complete
list of exceptions, and a new one needs a decision of its own.

- **`populate` in `lib/DBIO/ResultSet.pm`.** Void context is the bulk insert,
  which creates no row objects; scalar context returns an array reference of the
  created rows, list context the rows themselves. The context selects the
  operation, not only the shape, so `my @rows = $rs->populate(...)` is a
  supported call.
- **`id` in `lib/DBIO/PK.pm`.** List context returns every primary-key value,
  scalar context the first. A row with a single-column key reads the same either
  way.
- **`_run` in `lib/DBIO/Storage/BlockRunner.pm`.** The runner executes the
  caller's code reference in the caller's context and returns what that code
  returned, as a list or as its first value. This is the contract of `txn_do`
  and `dbh_do`: the block decides what comes back.
- **`_resolve_condition` in `lib/DBIO/ResultSource.pm`.** Internal, with no
  public caller; it keeps its return for the relationship code that calls it.

None of the four returns a ResultSet, so none can be mistaken for the
"one element holding a ResultSet" case that the list-context guard exists for.
