# ADR 0005 — Native JSONB operators and the jsonb() path DSL

- Status: accepted
- Date: 2026-06-20
- Tags: sqlmaker, jsonb, expand-op, dsl, drivers

## Context

Core ADR 0002 put the DBIO SQLMaker hierarchy on canonical `SQL::Abstract` (the
expand/render engine), and core ADR 0004 set `disable_old_special_ops => 1` so
every DBIO driver expresses its operators through `SQL::Abstract`'s newer
`expand_op` mechanism rather than the legacy special-op path. That is the
substrate this ADR builds on; it does not restate it.

PostgreSQL's JSONB operators are exactly the kind of engine-specific operator
that substrate is for. But two of them collide with the surrounding machinery:
the key-existence operators `?`, `?|`, `?&` use `?`, which is also DBI's bind
placeholder — passing a literal `?` operator through to DBI would be parsed as a
placeholder and corrupt the statement.

## Decision

Register PostgreSQL's JSONB operators through core's `expand_op` mechanism, and
rewrite the `?`-family to functions to dodge the placeholder clash. Separately,
ship a public path-extraction DSL for comparing fields inside a JSONB value.

- **Operator registration via `expand_op`.** `DBIO::PostgreSQL::SQLMaker`
  declares the JSONB operator set `@>` `<@` `@?` `@@` `?` `?|` `?&`
  (`SQLMaker.pm:13-21`) and, in its constructor, wires each one into
  `$opts{expand_op}{$op}` wrapping the handler's output in a `-literal` node
  (`SQLMaker.pm:31-37`). This is precisely the `expand_op` path core ADR 0004
  mandates — the base `DBIO::SQLMaker` having disabled the old special-ops
  system.
- **`?`/`?|`/`?&` rewritten to functions.** Because a literal `?` would be eaten
  by DBI's placeholder parser, `_where_op_jsonb_exists` emits
  `jsonb_exists(col, ?)`, `jsonb_exists_any(col, ARRAY[...])`, and
  `jsonb_exists_all(col, ARRAY[...])` instead of the raw operators
  (`SQLMaker.pm:122-140`). The remaining operators (`@>`, `<@`, `@?`, `@@`) are
  emitted as-is with `::jsonb` / `::jsonpath` casts.
- **Public `jsonb()` path DSL.** `DBIO::PostgreSQL::JSONB` exports a `jsonb`
  function (`JSONB.pm:10-15`) returning an operator object;
  `jsonb($col, @path)->eq(...)` (and `ne`/`gt`/`like`/`is_null`/`as_order`/…)
  builds a text-extraction path expression (`->>` single-level, `#>>`
  multi-level) suitable for `search()`. This covers per-field comparison, which
  the containment/existence operators above do not.

## Rationale

JSONB querying is a headline PostgreSQL capability; expressing it through
`expand_op` (rather than reviving the legacy special-op API) is exactly what
core ADR 0004 asks every driver to do, so the PostgreSQL operators slot into the
same predictable operator model as the rest of the family. The `?`-to-function
rewrite is not cosmetic: it is the only way to use the key-existence operators at
all through a DBI placeholder-based layer — `jsonb_exists*()` are PostgreSQL's
own functional equivalents, so the rewrite is faithful, not a hack around
semantics. The `jsonb()` DSL is split out from the operator handlers because
path extraction returns a *value* to compare with standard operators, whereas
`@>` / `?` are whole-value predicates; keeping them in separate modules
(`SQLMaker` transparent in `search`, `JSONB` an explicit import) matches how a
user reaches for each.

## Consequences

- Containment, jsonpath and key-existence operators work transparently in
  `search({ 'me.data' => { '@>' => {...} } })` with no import, because they are
  registered on the SQLMaker the storage instantiates.
- Field comparison requires `use DBIO::PostgreSQL::JSONB qw(jsonb)` — a
  deliberate, explicit dependency for the DSL, distinct from the
  always-available operators.
- The operator set is coupled to `SQL::Abstract`'s `expand_op` contract (core
  ADR 0002 / 0004); an engine-internal change to how `expand_op` handlers are
  invoked would land here and must be regression-tested against the JSONB
  operators.
- The `?`-family will always render as `jsonb_exists*()` functions, never as the
  raw `?` operators, in generated SQL — expected and required, not a limitation.
