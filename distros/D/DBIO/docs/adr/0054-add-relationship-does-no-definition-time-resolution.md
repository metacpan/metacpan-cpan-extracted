# ADR 0054 — add_relationship does no definition-time resolution of the related source

- Status: accepted
- Date: 2026-09-22
- Tags: resultsource, relationships, public-api, forward-references, dead-code

## Context

`add_relationship` on `DBIO::ResultSource` (`lib/DBIO/ResultSource.pm`) records a
relationship declaration: after two local, self-contained checks — a join condition
must be supplied, and (when the condition is a hashref) its keys must be prefixed
`foreign.` and its values `self.` — it stores `{ class, source, cond, attrs }` in
`_relationships` and returns.

The method carried a disabled block after its `return $self;`, headed
`# XXX disabled. doesn't work properly currently. skip in tests.`. The dead code
looked up the foreign source (`$self->schema->source($f_source_name)`, falling back to
`ensure_class_loaded` + the prototype `result_source`) and then ran
`_resolve_join($rel, 'me', {}, [])` inside a try/catch, backing the relationship out
and re-throwing on failure. It was **eager, definition-time validation** of the
relationship against the related source.

This block is a direct DBIx::Class fossil. It entered DBIO at the fork's birth commit
(`b65d776a`) already disabled — the `# XXX disabled` marker predates DBIO entirely — and
was only ever touched by the mechanical Try::Tiny conversion (`52b420dd`). It has never
run in this repo. The doc audit (karr k187) posed the choice: reactivate it (with a fix)
or bury it.

Eager resolution at `add_relationship` time is fundamentally incompatible with how
relationships are declared:

- **The prototype has no schema, no storage.** Result classes declare relationships at
  class-compile time via `has_many`/`belongs_to`/`has_one`/`might_have`, which reach
  `add_relationship` on the standalone `result_source_instance` prototype — not attached
  to any schema. `_resolve_join` needs both a schema (to resolve the related source by
  name) and `$self->storage` (`relname_to_table_alias`), neither of which exists yet.
- **Forward references are normal.** Result classes load in arbitrary order; A can
  legitimately declare a relationship to B before B is registered. The dead block's own
  fallback cannot save this: `_resolve_join` re-resolves through `related_source`, which —
  once the source *is* registered with a schema — asks `$schema->source($name)` and
  **throws** for any name not yet registered.
- **Circular references cannot resolve at either end's definition time.** A↔B can never
  both be resolvable when either one is declared.

The rest of the relationship layer already reflects this. `has_many`
(`lib/DBIO/Relationship/HasMany.pm`) carries a parallel disabled check with the note
`# FIXME - this check needs to be moved to schema-composition time...` and guards it with
"only perform checks if the far side appears already loaded". `belongs_to`
(`lib/DBIO/Relationship/BelongsTo.pm`) wraps its far-side `result_source_instance` lookup
in try/catch precisely for the case where the class "did not load entirely due to a
circular relation chain". The whole layer deliberately avoids resolving the far side at
declaration time.

## Decision

**`add_relationship` performs no definition-time resolution or validation of the related
source. The dead `_resolve_join` block is removed.**

`add_relationship` keeps exactly the validation it already ran: the local, forward-ref-
independent checks (missing condition; `foreign.`/`self.` prefixing of a hashref
condition). These are self-consistent — they inspect only the arguments to this call and
never touch the related source — so they are safe at definition time and stay. There was
no safe subset of the eager block to reactivate: the safe checks were already live above
the `return`, and everything below it needed the related source resolved.

Resolution of the related source stays **lazy**: it happens on first use, when
`related_source` / `_resolve_join` run against a fully-composed schema (join building,
prefetch, related-resultset construction). By then every source is registered and the
resolution either succeeds or throws a precise "No such relationship" / unregistered-source
error at the point of use.

This is a **deliberate keep of the existing runtime behaviour** — the fossil never ran, so
nothing observable changes — recorded so the `# XXX disabled` block is not mistaken for a
regression or "resurrected" by a future reader. `add_relationship` is public API; eager
validation would break legitimate forward- and circular-reference declarations that work
today.

## Consequences

- `add_relationship` continues to accept a relationship to a not-yet-registered (or
  entirely absent) foreign source without throwing — the documented, tested behaviour.
  `t/relationship/malformed_declaration.t` already relies on this implicitly (it names a
  `'nonexistent bars'` foreign source and only the malformed-condition check fires).
- A dedicated regression test pins the property directly: a source registered with a
  schema can `add_relationship` to a foreign source that is not yet registered, this does
  not throw, and the relationship is recorded. Re-introducing eager `_resolve_join`
  validation would turn this test red.
- The `# XXX disabled` / dead-code confusion in `add_relationship` is gone; the method's
  POD states that the related source is resolved lazily on first use, not here.
- Errors for a genuinely bad relationship (wrong source name, bad condition columns) still
  surface — later, at join-resolve time, against the fully-composed schema, where they can
  be resolved accurately. This ADR does not remove any error, only moves the fossilised,
  never-run one out of the declaration path.
