# ADR 0022 — DBIO helper and builder classes use Class::Accessor::Grouped

- Status: accepted
- Date: 2026-06-22
- Tags: convention, class-pattern, family-policy, helper-classes, cross-repo

## Context

DBIO's class stack is built on Class::Accessor::Grouped (CAG). `DBIO::Base` and
the CAG accessor machinery — `mk_group_accessors` with the `simple`,
`inherited`, and `component_class` groups, plus domain-specific groups like
`column` — underpin the whole runtime: `DBIO::Storage::DBI`,
`DBIO::ResultSource`, `DBIO::Row`, and the rest. Classes construct with a plain
`bless {}` and pure-Perl constructors; accessors route through `get_*`/`set_*`
hooks. This is the established, pervasive pattern, encoded in the
`dbio-perl-class-patterns` skill.

The helper and builder classes that drivers and extensions add — for example the
GraphQL field/type builder classes in dbio-graphql — are part of this same
stack. That they use CAG like everything else in DBIO was, until now, only
encoded in the skill, with no family-level record. Per-repo ADR audits had
nowhere canonical to point, so each was tempted to mint its own local note for
what is in fact one family-wide convention.

## Decision

DBIO helper and builder classes use Class::Accessor::Grouped, the same accessor
machinery as the rest of the DBIO class stack: `mk_group_accessors` for
attributes and pure-Perl `bless {}` constructors, consistent with `DBIO::Base`.
This is the family-wide class pattern for the helper layer, owned by core so the
whole family shares one source for it.

The helper layer stays on the core CAG machinery and does not carry a separate
object framework. (The narrow, deliberate Moo/Moose *bridge* seams documented
separately in the class-pattern skill are interop at defined boundaries, not the
helper-class pattern, and are out of scope here.)

## Rationale

CAG is not a preference weighed against alternatives — it is the substrate the
entire DBIO runtime already stands on. Helper and builder classes live inside
that runtime, share its accessor groups (`inherited` for class-data defaults,
`component_class` for lazy class resolution) and integrate with `DBIO::Base`'s
machinery directly. Using the same pattern keeps the helper layer first-class
within the stack rather than bolting a second object system onto the edge, and
keeps that layer free of a runtime dependency the core does not otherwise carry.

Recording it in core, at family level, follows the ownership lesson of ADR 0018:
a convention that spans the whole family carries no authority when it lives in a
single driver's repo. Blessing it here gives every repo's audit one ADR to
reference instead of each minting its own.

## Consequences

- Per-repo ADR audits reference this ADR for the helper-class pattern instead of
  writing a local one; the dbio-graphql audit deliberately routed the decision
  here rather than forking it.
- New helper and builder classes in any DBIO repo start on CAG by default. The
  `dbio-perl-class-patterns` skill remains the how-to; this ADR is the why.
- A helper or builder class that has drifted onto another object system is a
  deviation from the family pattern and is brought back onto CAG. dbio-graphql
  commit d061dc2 is such a correction, returning its GraphQL helper classes to
  the CAG machinery.

Relates to ADR 0018 (family-policy ownership pattern). Source convention:
the `dbio-perl-class-patterns` skill.
