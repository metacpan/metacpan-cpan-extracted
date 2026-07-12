# ADR 0025 — `redact_bind_value()` trace hook for sensitive bind values

- Status: accepted
- Date: 2026-06-25
- Tags: public-api, security, tracing, observability, bind-values

## Context

DBIO's tracing surface — `DBIO::Storage::DBI::_format_for_trace` and the
`trace`/`debug` callbacks it routes through — captures every executed SQL
statement together with its bind values, for live debugging and for the
post-mortem query log drivers and ops teams keep. Bind values are the
authoritative data plane of a request: column values, primary keys, search
predicates, foreign-key targets. They are also where sensitive data lives —
passwords hashed into `WHERE password = ?` predicates, session tokens carried
in `WHERE api_token = ?`, PII in `WHERE ssn = ?`, vault paths in
`WHERE credential_path = ?`.

Until now there was no DBIO-level way to redact a bind value before it lands in
the trace stream. Drivers and consumers could install their own trace callback
and post-process the formatted string, but that worked at the wrong layer: by
the time the bind value is already concatenated into the trace string, every
consumer that ever touches trace output (log shippers, error reporters, the
debug REPL, the `DBIC_TRACE` env var, the `connect_info.trace` callback chain)
must re-implement redaction in their own callback. The DDL of "what was
redacted" is duplicated across every consumer and drifts; one forgotten
consumer and the secret lands in the log.

The constraint is real: a trace hook that interferes with the bind value going
to the database is broken. The trace hook must read, transform, and return a
display-only string for the trace stream, leaving the bind value going to
`$dbh` `execute()` untouched. That is the seam this ADR blesses.

## Decision

Add a class-level `redact_bind_value` hook to `DBIO::Storage::DBI` that the
trace formatter consults for every bind value, before the value lands in the
trace stream. The hook is **display-only** — it never affects the value
passed to the database.

1. **Hook API**: a single coderef that takes the bind value and returns the
   redaction-safe display string.
   ```perl
   __PACKAGE__->redact_bind_value(sub {
       my ($value) = @_;
       return '[REDACTED]' if defined $value && $value =~ /secret/i;
       return $value;
   });
   ```
2. **Default identity**: out of the box, `redact_bind_value` is the identity
   function (`sub { return $_[1] }`) — no behaviour change for users who do
   not configure it. Traces today are byte-identical to traces tomorrow
   unless the hook is set.
3. **Layer**: the hook lives on `DBIO::Storage::DBI` (the base class), via
   `mk_classdata` (the established per-class hook shape in this codebase).
   Inherited by every storage subclass, including `Replicated::Storage` and
   every driver storage.
4. **Call site**: `_format_for_trace` calls the hook *once per bind value*,
   outside the `qq{}` interpolation that builds the trace string, so the
   hook's return value is rendered as a literal and cannot be parsed back
   into the original. The return value is `defined` or `undef` exactly as
   the hook returns it; the hook is responsible for the display shape.
5. **The bind value going to `$dbh->execute(@bind)` is untouched.** This is
   documented in the hook POD and in the `execute` call site comment.
6. **A mock-only regression test (`t/storage/trace_redact.t`) locks** that
   (a) the default hook is identity, (b) a custom hook is invoked once per
   bind value, (c) the bind value going to `execute` is byte-identical with
   and without the hook installed, (d) the rendered trace string shows the
   redaction rather than the original.

## Rationale

The hook lives on the storage class because that is the only place that has
both halves of the seam: it sees the bind value (via `_format_for_trace`)
*and* owns the class-level configuration consumers would otherwise need to
register globally. A global hook (e.g. on `DBIO::Trace` or via a process-wide
`%DBIO_TRACE_REDACT` registry) would not compose with the existing
`mk_classdata` style and would force every consumer to import a registry
module they do not otherwise need.

The identity default is conservative: existing users see no change, and the
hook is *opt-in* for the security-relevant case rather than *opt-out*. The
audit cost of an opt-in security hook is paid once, by the operator who
chooses to install it — not once per consumer who touches trace output.

Display-only is the right contract because the trace stream is observability,
not execution. Touching the bind value going to `$dbh->execute()` would
silently change query semantics — the canonical bug class of "the trace hook
broke the query." Encoding the seam at the *render* layer, not the
*execute* layer, is what makes the hook safe to use widely without
coordinated review.

`mk_classdata` matches the existing pattern (`redact_bind_value` is the same
shape as the per-class hooks already in `DBIO::Storage::DBI::Capabilities`),
so the hook is idiomatic and discoverable.

## Consequences

- **Operators can install a single hook and have redaction apply uniformly**
  across the trace stream: `DBIC_TRACE=1` env var output, the
  `connect_info.trace` callback chain, the debug REPL, error reporters.
  Per-consumer redaction is no longer required.
- **The hook is invoked per bind value, not per query.** A consumer that
  wants context-aware redaction (e.g. "redact column N in table T" rather
  than "redact any value matching pattern P") needs to read more context
  than the current one-arg signature provides. That is a deliberate scope
  cut — the v1 hook is "value in, string out," and a future ADR can widen
  the signature if the use case is reported.
- **The hook is a class-level setting, not per-instance.** Two storages in
  the same process share the hook unless the subclass overrides. This is
  intentional — the security-relevant setting is process-wide, and
  per-instance hooks would invite footguns where one storage is redacted
  and a sibling storage is not.
- **Future DBI drivers inherit the hook for free.** No per-driver plumbing
  is required; subclassing `DBIO::Storage::DBI` is enough.
- **A misconfigured hook (returns undef when the original was defined, or
  returns a value with newlines that breaks the trace line shape) is the
  hook author's bug, not DBIO's.** DBIO renders whatever the hook returns;
  it does not validate. The POD warns about this explicitly.
- `t/storage/trace_redact.t` is the regression guard.

Relates to ADR 0017 (native escape hatch methods on storage — same family of
"small, focused, opt-in surface on the base class"), and to ADR 0026
(same release's contract bump rationale — capabilities that affect driver
shape are versioned, and the trace hook does not change the bind values
going to `$dbh`, so it does not require a contract bump).
