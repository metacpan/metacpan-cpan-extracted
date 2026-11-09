# ADR 0006 — View bodies in the compare deploy: move CURRENT SCHEMA, don't rewrite SQL

- Status: accepted
- Date: 2026-09-05
- Tags: deploy, views, temp-schema, db2

## Context

ADR 0001 established the compare deploy: the throwaway target is a *schema*
inside the live database, and `_split_qualify_ddl` in `lib/DBIO/DB2/Deploy.pm`
re-points the install DDL at it by rewriting the statement shapes
`DBIO::DB2::DDL` emits. That ADR is explicit that the regex pass is a
"self-flagged, deliberate fragility" whose licence is that it only ever sees SQL
this distribution wrote itself, and that it must grow in lock-step with what
`install_ddl` emits.

It did not. `install_ddl` also emits `CREATE VIEW` — the view branch in
`lib/DBIO/DB2/DDL.pm` renders `CREATE VIEW <quoted name> AS <view_definition>`
for every non-virtual `DBIO::ResultSource::View` after all tables — and
`_split_qualify_ddl` had no view substitution at all. A schema carrying a view
therefore created its *compare* view unqualified, i.e. against `CURRENT SCHEMA`,
i.e. in the **live** schema. This is the same fault class as karr k29 (where the
identifier-quoting change of karr k28 had silently disabled every substitution),
with a smaller blast radius: it bites only schemas that have views.

The consequences are not confined to a stray object. `DBIO::DB2::Introspect::Tables`
reads `syscat.tables.type` and puts views into the model's `tables` section with
`kind => 'view'`, so views are diff-relevant. With the view missing from the
compare schema, `DBIO::DB2::Diff::Table` sees it in the source and not in the
target and emits a `DROP TABLE` against a live view; with the view already
present live, the unqualified `CREATE VIEW` fails outright (SQL0601N).

A view is not one object position but two, and only the first is tractable here:

- the **name**, an ordinary object position like every other one this pass
  rewrites;
- the **body**, the user's own `view_definition` — arbitrary SQL with arbitrary
  unqualified table references in it.

Rewriting only the name is worse than doing nothing. A
`CREATE VIEW DBIO_TEST_<pid>."v" AS SELECT ... FROM "author"` resolves its
`FROM` against `CURRENT SCHEMA`, i.e. against the **live** `author`, so the
compare view would mean something different from the live view of the same
name and the diff would compare two unlike objects. Rewriting the body means
parsing arbitrary SQL in a pass whose entire justification is that it never has
to.

## Decision

The compare deploy carries the view *name* textually, as before, and makes the
view *body* mean the right thing by moving the connection's schema instead of
its text.

- **`_split_qualify_ddl` gains a sixth substitution, `CREATE VIEW`, in the NAME
  position only.** The body after `AS` is passed through byte for byte.
  `DROP VIEW` is deliberately not covered: neither `install_ddl` nor the diff
  path emits one, and this pass grows only with shapes that exist.
- **`_build_target_model` brackets the compare deploy in `CURRENT SCHEMA`.** It
  reads the register through `_current_schema`, points it at the throwaway
  schema through `_set_current_schema` for the duration of the deploy, and puts
  the saved value back on the way out. Db2 qualifies unqualified object
  references in a dynamically prepared statement with `CURRENT SCHEMA`, so the
  view body resolves against the compare tables without being touched.
- **The register is read before the first side effect, and a value that cannot
  be read refuses the run.** The compare deploy runs on the handle the live
  storage owns (ADR 0001), so a value that cannot be restored is a run that must
  not start; refusing after `CREATE SCHEMA` would leak a schema.
- **The restore runs on every path and a failed restore is fatal**, even when
  the model came back fine: the shared handle would otherwise be left pointing
  at a schema this method has just dropped.
- **`_set_current_schema` passes the schema as a string constant**, not as a
  bare identifier, so a saved lower/mixed-case schema is not folded to uppercase
  on the way back.
- **A body that qualifies its references explicitly is left pointing where it
  says.** So does the live view built from the same `view_definition`, so the
  two sides still agree.

Getting the error out of the build `eval` intact is part of this change rather
than a separate cleanup: the restore is an `eval` of its own and the teardown in
`_drop_test_schema` is a series of them, so `$@` has to be captured immediately
after the build. It previously was not, and the post-teardown `die $@ if $@ and
not $model` read a `$@` belonging to the last teardown `eval` — a build failure
came back as a silent `undef` model, or was masked by a teardown error. ADR 0001
already describes the behaviour this restores ("re-raises only when the build
itself failed").

## Rationale

The two halves answer two different questions and neither can answer both.

The textual pass is deterministic, testable without a server, and is what the
family's other drivers would recognise — but it can only rewrite shapes known in
advance, and a `view_definition` is by construction not one. `CURRENT SCHEMA` is
the mechanism Db2 itself offers for exactly this: telling a statement what its
unqualified names mean without editing the statement. It needs no parser and it
cannot mis-parse.

The textual `CREATE VIEW` rewrite is kept alongside the register rather than
dropped as redundant. It is the half that can be pinned offline, and it is what
keeps a compare view out of the live schema even if the register leg ever fails
— in which case the view sits in the compare schema with a live-resolving body,
which the diff does not notice (`DBIO::DB2::Diff::Table` compares presence by
name, not view text) and the teardown removes. That is strictly better than the
pollution it replaces.

The rejected alternative was to **refuse**: have the compare deploy die with
"views are not supported" rather than risk a wrong body. That would have been an
acceptable outcome — silently polluting the live schema is not — but it is not
necessary, because the register makes the body correct without anyone parsing
it. Refusal would also have made views unusable with `upgrade` on a driver whose
introspector already models them.

## Consequences

- The compare deploy now mutates a connection-level register on the shared live
  handle for the duration of the target build. Nothing else in the deploy path
  depends on it — the `SYSCAT` reads in `DBIO::DB2::Introspect` and
  `_drop_test_schema` are explicitly qualified, the introspector scopes on
  `tabschema` as a bind value, and the rewritten DDL names its schema outright —
  but any future deploy-path code that relies on unqualified resolution will now
  resolve against the compare schema while the build is running.
- `_build_target_model` can now fail in two new ways that it previously could
  not: an unreadable `CURRENT SCHEMA` refuses before creating anything, and a
  failed restore is raised. Both are deliberate; both name the register.
- A build failure now propagates instead of returning `undef`. Callers that
  relied on the silent `undef` (there are none in-tree) would see an exception.
- `CURRENT PATH` is not moved, so an unqualified function in a view body
  resolves identically in the live and the compare view. This is intentional:
  the two sides must agree, not be independently correct.
- The Db2 behaviour the body half rests on — a dynamically prepared
  `CREATE VIEW` qualifying its unqualified references with `CURRENT SCHEMA` — is
  documented Db2 LUW, but **no live server was available when this was written**
  and it has not been confirmed against one. The first live run of a schema
  carrying a view is the confirmation, and it is the one part of this ADR that a
  real instance can still overturn.
- `t/43-deploy-qualify-ddl.t` covers both halves offline: the name rewrite
  textually, and the register bracketing by driving the real
  `_build_target_model` over a recording handle that notes which schema was in
  effect for each statement. Removing either half turns it red.

## Related

- ADR 0001 (test-deploy-and-compare against a temp SCHEMA — establishes
  `_split_qualify_ddl` and states the lock-step obligation this ADR discharges)
- ADR 0005 (foreign keys in DDL and ALTER diff — the `REFERENCES` substitution,
  the other object position that is not a statement head)
- karr k29 (the same fault for tables and indexes), karr k35 (this one)
