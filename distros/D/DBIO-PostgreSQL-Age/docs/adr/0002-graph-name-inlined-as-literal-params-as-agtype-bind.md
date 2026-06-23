# ADR 0002 — Graph name validated and inlined as a SQL literal; params as one JSON `agtype` bind

- Status: accepted
- Date: 2026-06-21
- Tags: drivers, storage, security, sql-injection, age, agtype, bind

## Context

Core ADR 0017 point 3 makes validate-or-escape at the method boundary a
load-bearing security obligation for any native escape-hatch method that builds
a SQL string from caller input: a method that bypasses DBI placeholder binding
also bypasses DBI placeholder quoting, and that boundary is its only line of
defence. `cypher()` (ADR 0001) is exactly such a method. Two of its arguments
cannot be handled the way ordinary DBI binds are:

1. **The graph name.** Apache AGE's `cypher()` function requires its first
   argument to be a *name constant* — a string literal in the SQL text. It
   cannot be passed as a placeholder; `cypher($1, ...)` is rejected by AGE. So
   the graph name has to be interpolated into the SQL string, which is precisely
   the case ADR 0017 point 3 is about.
2. **Cypher parameters.** AGE takes query parameters as a single JSON object in
   the `cypher()` third argument, not as positional typed placeholders matching
   `$name` references inside the Cypher text.

## Decision

**Graph name — validate then inline.** Before any SQL is built, the graph name
is matched against the plain-identifier pattern
`\A[A-Za-z_][A-Za-z0-9_]*\z` and `throw_exception("Invalid AGE graph name
'$graph'")` on failure (`Storage.pm:116-117`). Only a value that has passed that
gate is interpolated into the SQL literal `cypher('$graph', ...)`
(`Storage.pm:126`). The pattern admits exactly the unquoted PostgreSQL/AGE
identifiers AGE will accept and rejects everything else — spaces,
schema-qualification (`public.social`), quotes, and injection-shaped input
(`g'); DROP TABLE x; --`). The validation *is* the security boundary that
ADR 0017 point 3 requires for the one value this method must interpolate.

**Cypher params — one JSON-encoded `agtype` bind.** When a non-empty `\%params`
is given, it is encoded with a module-level canonical, utf8 `JSON::MaybeXS`
instance (`Storage.pm:9-11`) and pushed as a single bind value
(`Storage.pm:122-124`); the SQL gets one `?` placeholder in the `cypher()`
third-argument slot (`Storage.pm:125-126`). An absent or empty params hashref
adds neither placeholder nor bind. Caller-supplied *values* therefore never
touch the SQL string — they ride DBI's real placeholder, exactly as AGE's
parameter contract wants.

These rules live entirely inside the pure `_cypher_sql_bind` helper, so both the
literal-inlining gate and the bind behaviour are pinned offline in
`t/20-cypher.t` (rejection of space/leading-digit/injection names, acceptance of
`_My_graph2`, the param-slot `?` and the JSON-encoded bind, the empty-hashref
no-op).

## Rationale

The asymmetry is forced by AGE, not chosen: the graph name *must* be inlined
because AGE rejects a placeholder there, and the parameters *must* be a single
JSON argument because that is AGE's parameter-passing shape. Given the name has
to be inlined, the only safe move is the one ADR 0017 mandates — validate at the
boundary against a strict allowlist of acceptable identifiers — rather than
attempt to quote-escape an arbitrary string into a context (`cypher()`'s name
constant) where quoting rules are AGE-specific and brittle. Allowlisting plain
identifiers is both sufficient (AGE accepts nothing broader without explicit
quoting that the driver does not offer) and auditable: the regex is the whole
policy. Routing every caller *value* through a real bind keeps the injection
surface down to exactly one interpolated token — the validated name — and that
token is checked before any string is built.

Shipped and test-pinned in `t/20-cypher.t`, hence **accepted**.

## Consequences

- Only plain-identifier graph names are usable. Quoted or schema-qualified graph
  names are deliberately unsupported; a caller needing one gets a thrown
  exception, not a silently mangled query. Widening the allowlist is a
  security-relevant change that must update `t/20-cypher.t` and be reviewed
  against ADR 0017 point 3.
- The graph-name regex is the security boundary for this driver. It is the
  reviewable artifact for ADR 0017 compliance; an injection-shaped name is
  rejected by test, not by luck.
- Cypher parameters are values only — they cannot inject identifiers, labels or
  query structure, because they arrive as one JSON `agtype` bind. Callers who
  need a dynamic label/relationship type must build that into the (trusted)
  query text, knowingly, not via `\%params`.
- `JSON::MaybeXS` is pinned (`cpanfile`, `1.004008`) and used canonical+utf8 so
  the encoded bind is stable and round-trips through AGE's `agtype` parser.
