# ADR 0005 — Hierarchical queries (CONNECT BY / PRIOR) exposed as resultset attributes

- Status: accepted
- Date: 2026-06-22
- Tags: sqlmaker, hierarchical, connect-by, prior, oracle, dialect

## Context

Oracle's signature non-portable SQL feature is the hierarchical query:
`START WITH ... CONNECT BY [NOCYCLE] ... ORDER SIBLINGS BY ...`, with the `PRIOR`
operator inside the CONNECT BY condition to reference the parent row. There is no
ANSI equivalent that DBIO's portable resultset surface already models, and these
clauses sit in non-standard positions in the SELECT (CONNECT BY comes after
WHERE, before GROUP BY). DBIO needs a way to let users build these queries
through the normal `$rs->search({}, \%attrs)` API without dropping to literal
SQL, and the SQLMaker needs to splice the clauses into the right place in the
generated statement and collect their binds in the right order.

## Decision

Expose hierarchical queries as four resultset attributes —
`start_with`, `connect_by`, `connect_by_nocycle`, `order_siblings_by` — handled
by `DBIO::Oracle::SQLMaker`, and make `PRIOR` an operator usable inside those
conditions:

- **Clause assembly** — `_parse_rs_attrs` is overridden to build the CONNECT BY
  block via `_connect_by` and prepend it to the base-rendered tail
  (`SQLMaker.pm:73-83`). `_connect_by` renders `START WITH` / `CONNECT BY` /
  `CONNECT BY NOCYCLE` / `ORDER SIBLINGS BY` from the attrs, reusing
  `_recurse_where` for the conditions and `_order_by_chunks` for the siblings
  ordering (`SQLMaker.pm:85-134`).
- **Bind ordering** — a dedicated `oracle_connect_by` bind bucket is threaded
  into `_assemble_binds` between `from` and `group`/`having`
  (`SQLMaker.pm:68-71`, `78`) so CONNECT BY placeholders bind in statement order.
- **PRIOR operator** — registered as an old-style `special_op`
  (`regex => qr/^prior$/i`, handler `_where_field_PRIOR`, `SQLMaker.pm:47-50`,
  `136-147`). It is *deliberately* kept old-style because it is consumed inside
  CONNECT BY / START WITH via `_recurse_where` (the SQL::Abstract v1 engine),
  which does not route through the new `expand_op` mechanism — and the base's
  `disable_old_special_ops` does not reach that path either, so it keeps working
  (`SQLMaker.pm:40-46`).

The user-facing attribute contract and worked examples are documented in
`DBIO::Oracle::Storage` POD (`Storage.pm:186-265`).

## Rationale

Modelling the clauses as resultset attributes keeps Oracle hierarchical queries
inside the chainable DBIO API — the user writes `connect_by => { parentid =>
{ -prior => { -ident => 'personid' } } }` rather than a literal SQL blob, so the
result set stays composable (further `search`, ordering, column selection). The
SQLMaker owning the splice-point and the dedicated bind bucket is what makes the
non-standard clause position and bind order correct regardless of what else the
resultset carries.

Keeping `PRIOR` as an old-style `special_op` is a conscious exception to the
post-rename `expand_op` migration, not legacy debt: the CONNECT BY conditions are
rendered through the v1 `_recurse_where` path on purpose, and that path is
exactly where the old-style special-op mechanism still fires. Migrating `PRIOR`
to `expand_op` would route it through a path that the CONNECT BY renderer does
not use, breaking it. The in-code comment (`SQLMaker.pm:40-46`) records this so a
future "modernise all special_ops" pass does not regress it.

## Consequences

- The four attributes are Oracle-only; using them through a non-Oracle storage is
  a user error (they are simply not interpreted elsewhere).
- The CONNECT BY renderer depends on the SQL::Abstract v1 `_recurse_where` /
  `_order_by_chunks` internals and on the `oracle_connect_by` bind bucket
  threading through `_assemble_binds`. Changes to the base bind-assembly order or
  to the v1 where-engine must keep this bucket and the PRIOR old-style path
  intact.
- The canonical parenthesised WHERE renderer is now provided centrally by
  `DBIO::SQLMaker` (core ADR 0004), so the previous local `render_clause`
  override was removed (`SQLMaker.pm:43-46`) — the paren behaviour CONNECT BY
  queries rely on comes from core, not from this class.

## Related

- core ADR 0004 (SQLMaker select.where paren-restore + expand_op — provides the
  central paren renderer this class no longer overrides)
- core ADR 0003 (`apply_limit` replaces `limit_dialect` — the mechanism Oracle's
  ROWNUM dialect plugs into; `apply_limit` → `_RowNum`, `SQLMaker.pm:63-66`)
- ADR 0003 (identifier shortening — the arrayref `_quote` path,
  `SQLMaker.pm:149-170`, that had to be taught to shorten WHERE/HAVING
  qualifiers in these queries)
