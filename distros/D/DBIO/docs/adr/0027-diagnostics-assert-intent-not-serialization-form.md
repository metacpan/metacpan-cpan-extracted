# ADR 0027 — Diagnostics are asserted on intent, not on serialization form

- Status: accepted
- Date: 2026-06-25
- Tags: testing, test-infra, diagnostics, dump_value, upstream-parity

## Context

`DBIO::Util::dump_value` renders an arbitrary Perl structure to a string for
human-facing diagnostics — most visibly the `"... at populate slice:\n%s"`
exception thrown by `DBIO::Storage::DBI::_dbh_execute_for_fetch`, but also
scan-plan errors in `DBIO::Storage::QueryRewrite` and the connection dump in
`_describe_connection`. It is a *diagnostic serializer*: `Data::Dumper` with
`Indent=1`, `Terse=1`, `Sortkeys=1`.

A live-Oracle test run (23c) surfaced the problem. `dbio-oracle`
`t/10-oracle.t:428` and `t/20-oracle-core.t:428` ("Partially failed populate
throws") assert the thrown exception with:

```perl
qr/unique constraint.+populate slice.+name => "pop_art_1"/s
```

That regex pins the *exact serialization form* — bare key, double-quoted value
(`name => "pop_art_1"`). Current `dump_value` emits the single-quoted,
quote-keys-on form (`'name' => 'pop_art_1'`), so the regex never matches.
Upstream `DBIx::Class::_Util::dump_value` sets `Useqq(1)` and `Quotekeys(0)`,
which produces exactly the bare-key/double-quote form the verbatim-ported test
expects.

The naive fix is to add `Useqq(1)`+`Quotekeys(0)` to `dump_value` so the regex
passes. That fixes the symptom by handing the brittle assertion exactly the
bytes it demands. It leaves the deeper defect untouched: a test that fails when
a diagnostic's quoting flag changes, even though the behaviour it means to
verify — *the failing populate slice is named in the error message* — is
unchanged. `dump_value` with `Terse=1` emits a re-evaluatable bare Perl literal;
both quoting forms round-trip to the **identical** structure. The quoting style
carries no information the populate test cares about.

## Decision

1. **Diagnostics are asserted on intent — the data/structure surfaced — not on
   serialization form.** A consumer test that needs `dump_value`'s exact bytes
   to pass is asserting the serializer's config, not the diagnostic's purpose.
   Such an assertion is relaxed to structure (extract the dumped block,
   `eval` it back, `is_deeply`) or to a form-agnostic substring
   (`unique constraint` … `populate slice` … `name` … `pop_art_1`).

2. **The one legitimate place to pin `dump_value`'s exact byte form is the unit
   test of `dump_value` itself.** There the format *is* the contract. A core
   unit test (`t/util/dump_value.t`) locks the canonical output form. Every
   other consumer asserts structure/substring, never bytes.

3. **`dump_value` adopts the upstream `Useqq(1)`+`Quotekeys(0)` form as its own
   default** — on its own merit (diagnostic parity with `DBIx::Class`, the
   documented fork target), *not* as a crutch for any brittle assertion. The
   core unit test pins that form; consumers must stay green regardless of it.

## Rationale

House rule #7: tests verify intent, not just behaviour; a test that cannot fail
when business logic changes — but *does* fail when a cosmetic serializer flag
flips — is mis-targeted. Quoting style is not business logic.

Separation of concerns: one test owns "`dump_value`'s output form" (the
formatter contract); many tests own "this diagnostic surfaces the right data"
(behaviour). The two were conflated the moment a consumer assertion reached
*through* the formatter to pin its bytes. After this ADR a future
diagnostic-format change breaks exactly one test — `dump_value`'s own — updated
deliberately, instead of rippling into every driver that happened to quote a
diagnostic.

Verbatim upstream test ports remain the parity strategy, and most ports stay
verbatim. This is the **bounded exception**: when a verbatim port couples a
behavioural assertion to a diagnostic's serialization form, the assertion is
relaxed to intent, while the parity of the form itself is preserved *once*, in
the formatter's own unit test. We do not abandon verbatim porting — we carve out
diagnostic-form coupling specifically.

## Consequences

- **Core**: `dump_value` gains `Useqq(1)`+`Quotekeys(0)`; `t/util/dump_value.t`
  locks the canonical form. Diagnostic output bytes change (humans now see
  bare-key, double-quoted dumps). No machine contract depends on that output —
  it is observability, not an interface.
- **Drivers**: any test that pins a diagnostic's serialization form is relaxed
  to assert intent. Tracked per-driver via karr. First instance:
  `dbio-oracle` "Partially failed populate throws"
  (`t/10-oracle.t:428`, `t/20-oracle-core.t:428`).
- **Release ordering**: `dbio-oracle`'s `t/10` & `t/20` need the core release
  that ships the `dump_value` form *and* the relaxed assertion. Until both land,
  those two tests stay red on the form mismatch — the behaviour they verify
  already holds.
- A reviewer who later "simplifies" `dump_value` back to single quotes breaks
  `t/util/dump_value.t` (the deliberate guard), not a scatter of driver tests.

## Future architecture work (tracked cross-repo, not here)

- **dbio-oracle**: relax the "Partially failed populate throws" assertion
  (`t/10-oracle.t:428`, `t/20-oracle-core.t:428`) from the form-pinned regex to
  an intent assertion. karr ticket pushed to `dbio-oracle` from core #56.
