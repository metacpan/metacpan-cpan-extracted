# ADR 0009 — Loader folded into core as DBIO::Generate with style emitters

- Status: accepted
- Date: 2026-06-19
- Tags: generate, loader, introspect, styles, backfill

## Context

In DBIx::Class, generating Result/Schema classes from an existing database was
the job of `DBIx::Class::Schema::Loader` — a separate CPAN distribution that did
its own DBI introspection and emitted classes in one fixed style. DBIO already
has a native, normalised introspection layer in core (ADR 0007), so the
introspection half of that job is duplicated work; and DBIO now offers more than
one way to write a Result class (Vanilla, Candy, Cake, Moo, Moose), so a single
fixed output style no longer fits.

## Decision

Fold the Schema::Loader responsibility into core as `DBIO::Generate`
(`lib/DBIO/Generate.pm`), splitting it into two layers — reuse the native
Introspect contract for reading the database, and emit code through pluggable
**Style emitters** for writing it.

- `DBIO::Generate` (`lib/DBIO/Generate.pm`) ships in core. Its `dump($introspect)`
  method iterates `$introspect->table_keys`, builds monikers/class names, infers
  relationships via `DBIO::Generate::Relationships`, and writes one `.pm` per
  table through the configured Style emitter. `$introspect` must satisfy the
  normalised `DBIO::Introspect::Base` contract (ADR 0007) — Generate does **not**
  re-implement DBI introspection; it consumes the same layer the diff/deploy
  stack uses.
- Style emitters are pluggable and interchangeable, selected by a name →
  class map (`Generate.pm:51-57`): `vanilla`, `cake`, `candy`, `moose`, `moo`.
  Each is a `DBIO::Generate::Style::*` module exposing the same `emit($spec)`
  interface over an identical spec hashref, so they produce the same schema in
  different source styles:
  - `Vanilla` — classic `__PACKAGE__->add_columns(...)`.
  - `Candy` — the Candy DSL (ADR 0010).
  - `Cake` — the Cake DDL DSL (ADR 0010).
  - `Moo` / `Moose` — Moo/Moose-flavoured Result classes (the Moo/Moose bridges).

## Rationale

Schema::Loader as a separate dist meant a second introspection implementation to
maintain and keep in step with the database catalog. Folding it into core lets it
reuse the one normalised Introspect contract DBIO already trusts for migrations
(ADR 0007); the generator becomes a thin code-emitter over that contract rather
than a parallel introspection engine. Splitting code emission behind a Style
interface is what makes the multiple Result-class styles first-class: the same
introspected spec can be rendered as Vanilla, Candy, Cake, Moo or Moose without
the generator knowing anything about each style's syntax.

Heritage.pod frames the styles side directly (`lib/DBIO/Manual/Heritage.pod:128`
onward, "RESULT CLASS STYLES": Vanilla kept, Candy and Cake added). The
"folded into core" half rests on the code: `DBIO::Generate` lives in this
distribution, consumes `DBIO::Introspect::Base`, and is exercised end-to-end in
`t/generate/06-generate.t` against an introspection fixture.

## Consequences

- Result-class generation no longer needs the external Schema::Loader. It is a
  core capability (`DBIO::Generate`) built on the native Introspect contract.
- Adding a new output style is adding one `DBIO::Generate::Style::*` module that
  implements `emit($spec)` and one entry in the style map (`Generate.pm:51-57`);
  the generator and introspection layers are untouched.
- The Cake and Candy emitters tie this ADR to ADR 0010 (those DSLs are the
  *runtime* sugar; here they are *output* styles), and the Moo/Moose emitters tie
  it to the Moo/Moose bridges — Generate can *emit* code in a style whose runtime
  support is a separate decision.
- **Framing flag:** neither Heritage.pod nor Migration.pod literally say
  "Schema::Loader → DBIO::Generate." The substitution is real in the code
  (in-core generator, native introspection reuse, pluggable styles) but DBIO
  presents it as "Result-class generation with styles," not as a loader port.
  The ADR records the substitution; do not expect a one-line "Loader is now
  Generate" sentence upstream.
