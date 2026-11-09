# ADR 0039 — The `… ALL` set operators on Oracle: refuse by default, lift with a class-level opt-in

- Status: accepted
- Date: 2026-08-04
- Tags: sql, resultset, set-operations, capability, adr-0039, oracle

## Context

Core ADR 0039 replaced ADR 0037's single-operation `_except_operator` with one
hook for all six set operations, `_set_operation_keyword($op)`, whose two jobs
are to **spell** an operation for this engine or to **refuse** one the engine
does not have. This driver is the only one in the family that had overridden
the old name, so the rename was an active defect here before it was work: the
override was not called any more, silently, and `$rs->except` went back to
emitting the ANSI `EXCEPT` on an engine that wants `MINUS`.

The spelling half is unchanged and needed no decision. The refusal half did,
and core ADR 0039 §7 handed the decision to this board rather than making it,
because the constraint it lives under is sharp:

- The hook is resolved by `DBIO::ResultSet::_set_operation` **while the query
  is being built**, and the keyword is baked into a literal `from` clause at
  construction time. It must therefore be a **static class fact** — no `$dbh`,
  no version probe. Probing here is what made `$rs->except($other)->as_query`
  open a connection before ADR 0037, and for a refusal it would mean
  connecting *in order to throw*.
- Every gap is version-**bounded**. Verified against the SQL Language
  Reference, section *The Set Operators*: **19c** enumerates exactly `UNION`,
  `UNION ALL`, `INTERSECT`, `MINUS`; **21c** enumerates `UNION`, `UNION ALL`,
  `INTERSECT`, `INTERSECT ALL`, `EXCEPT`, `EXCEPT ALL`, `MINUS`, `MINUS ALL`.
  So `except_all` and `intersect_all` are absent below 21c and present from
  21c on — and the hook cannot ask which of the two it is talking to.

Today's behaviour on every version is the same: `$rs->except_all` emits
`EXCEPT ALL`, `$rs->intersect_all` emits `INTERSECT ALL`. Below 21c that is a
syntax error raised by the server several layers below the method the caller
called. From 21c on, both are **correct and work**.

## Decision

**Refuse both operations by default, and lift the refusal with a class-level
opt-in** — core ADR 0039 §7 option (b), not option (a).

```perl
__PACKAGE__->mk_group_accessors( dbms_capability     => '_supports_set_operator_all_family' );
__PACKAGE__->mk_group_accessors( use_dbms_capability => '_use_set_operator_all_family' );
__PACKAGE__->_use_set_operator_all_family (0);
sub _determine_supports_set_operator_all_family { 0 }
```

`_set_operation_keyword` answers `MINUS` for `except` unconditionally, throws
for `except_all` / `intersect_all` unless the switch is set, and hands
everything else to `$self->next::method($op)`. With the switch set,
`except_all` renders `MINUS ALL` — the same dialect as `except`, and equivalent
to the `EXCEPT ALL` 21c also accepts — and `intersect_all` inherits core's
`INTERSECT ALL`, which is Oracle's own spelling.

Three details are load-bearing rather than incidental:

1. **The default is `0`, declared outright.** The `use_dbms_capability`
   accessor falls through to `_supports_*` → `_determine_supports_*` only when
   its value is *undef*, and the only honest determination for this fact would
   read the server version. Declaring `0` means that path is never taken; the
   `_determine_supports_*` stub is pinned to a static `0` as well, so the tier
   that exists to probe cannot probe here either. Both tiers are nailed shut
   at the exact spot where a future author would add the version check.
2. **It uses the family's capability accessors, not a private flag.** The fact
   is capability-shaped ("does this server have these operators"), and the
   house rule is one capability mechanism, not a parallel one. What is
   Oracle-specific is only that the answer comes from the deployment instead
   of from a probe.
3. **The switch is readable on the class and on one storage.** The class-level
   form is the primary one, because it holds from load time. The per-storage
   form works once core has reblessed that storage onto this class — which is
   the state of any storage that has already raised the refusal, so the message
   can name it as a usable next step.

## Rationale

Option (a), an unconditional refusal, is simpler and correct on every version,
and core ADR 0039 §7 lists it first. It was rejected on the balance of costs:

- **It would remove working functionality.** On 21c and 23ai both operations
  work *today*, through the hard-coded ANSI keywords. An unconditional refusal
  turns a working call into a thrown exception on the current long-term
  release — the same trade core ADR 0039 §3 refused when it declined a
  capability gate defaulting to `0` ("a gate would regress every working
  engine"), here applied across versions of one engine instead of across
  engines.
- **The cost of (b) is small and lands in the right place.** A deployment
  knows its server version; the driver does not and may not ask. Moving one
  boolean to the party that has the information is the whole of the design.
- **The default still protects the majority.** 11.2 and 19c are the long-term
  releases this driver mostly meets, and neither has the family at all. A
  deployment that does nothing gets the correct answer for them, with a
  message that explains itself; only a 21c+ deployment has to act, and it is
  the one that can.

Probing the server version inside the hook was never an option, and is
recorded here as refused rather than unconsidered: it would open a connection
during query build, on the one path whose entire point is that it does not.

## Consequences

- `$rs->except_all` and `$rs->intersect_all` **throw by default on Oracle**,
  where they previously emitted SQL the server rejected below 21c and accepted
  from 21c on. For a pre-21c deployment this converts a remote syntax error
  into a local exception naming the boundary; for a 21c+ deployment it is a
  removal, undone by one line.
- The exception is raised **at query-build time**, before a single operand is
  rendered, so a refused operation never produces a fragment that could be
  embedded in a larger query, and never issues SQL.
- `_use_set_operator_all_family` is public surface for deployments from now on.
  It is the only supported way to enable the family, and its meaning is "this
  server is 21c or newer", not "please try".
- The old `_except_operator` override is gone. A core older than ADR 0039
  would call neither name and `$rs->except` would silently emit `EXCEPT` — the
  same silent failure that made this port urgent. The cpanfile pin is a
  release-time question, deliberately not moved here.
- Oracle's ban on set operators over `BLOB` / `CLOB` / `BFILE` / `VARRAY` /
  nested-table columns stays out of scope, as core ADR 0039 records: it is a
  per-query fact about column types, not decidable from an operation name, and
  it announces itself as a diagnosable engine error rather than a generic
  syntax failure.

## Related

- Core ADR 0039 — the one-hook seam, and §7, whose two options this ADR
  chooses between.
- Core ADR 0037 — the `_except_operator` this replaces, and §5, the
  no-connection-at-query-build-time constraint both inherit.
- ADR 0036 (this repo) — the other place where an Oracle-version boundary
  (23ai for `RETURNING` on `MERGE`) decides what the driver may promise.
