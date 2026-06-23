# ADR 0004 — Ordered subselects are wrapped with SELECT TOP <maxint>, else rejected

- Status: accepted
- Date: 2026-06-20
- Tags: storage, sql, subselect, ordering

## Context

MSSQL forbids `ORDER BY` inside a subquery unless that subquery also carries a
`TOP`. The obvious workaround `TOP 100 PERCENT` does **not** work — the
optimiser discards the ordering. An ordered subselect emitted unchanged
therefore either errors or silently loses its order, depending on context.

No other DBIO driver has this restriction; `_select_args_to_query` is not
overridden elsewhere in the family.

## Decision

`DBIO::MSSQL::Storage` overrides `_select_args_to_query`
(`Storage.pm:183-204`). After delegating to `next::method`, it detects an
ordered subquery — one whose generated SQL does **not** already start with
`(SELECT TOP <n> ...` yet has order criteria
(`_extract_order_criteria($attrs->{order_by})`):

1. If `$attrs->{unsafe_subselect_ok}` is not set, `throw_exception` with a
   pointer to the *Ordered Subselects* documentation (`Storage.pm:196-198`).
2. Otherwise, rewrite the leading `(SELECT` to
   `(SELECT TOP <max_int> ...`, where `<max_int>` is
   `$self->sql_maker->__max_int` = `0x7FFFFFFF` (inherited from core
   `DBIO::SQLMaker::ClassicExtensions`) (`Storage.pm:200`).

## Rationale

Wrapping with `TOP 0x7FFFFFFF` (the maximum 32-bit signed int) satisfies the
MSSQL parser's "TOP required for ORDER BY in subquery" rule while imposing no
practical row cap. `TOP 100 PERCENT` is rejected because MSSQL drops the order
under it. Gating the rewrite behind `unsafe_subselect_ok` keeps the default
behaviour loud: an ordered subselect is genuinely unsafe (the wrap changes
semantics under some plans), so the caller must opt in explicitly rather than
have the driver quietly reshape every query.

## Consequences

- Ordered subselects against MSSQL either fail loudly or are explicitly opted
  into via `unsafe_subselect_ok`, never silently mis-ordered.
- This is a driver-specific divergence from every other DBIO driver; reviewers
  comparing storage classes across the family should not expect a
  `_select_args_to_query` override anywhere but here.
- The rewrite depends on the SQL beginning with `(SELECT`; a future
  SQLMaker change to that prefix shape would require updating the regexes at
  `Storage.pm:192,200`.
