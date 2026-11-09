# ADR 0009 — The trace runs through the debug object of the owner storage and the redact_bind_value hook

- Status: accepted
- Date: 2026-10-30
- Tags: async, trace, redaction, builds-on-core-0025
- Origin: karr k53. Maintainer decision 2026-10-30.

## Context

Core traces a statement through the debug object of its storage
(`debugobj->query_start`, written to its `debugfh`) and shows each bind value
through the class-level `redact_bind_value` hook (core ADR 0025). The
transport's `_debug_query` wrote `"$sql: 'bind', ..."` with `warn` to STDERR,
every value whole: it reached neither the operator's `debugfh` nor the hook.

## Decision

1. **The debug object is the owner storage's** (`_owner_storage->debugobj`),
   the backend's own (`debugobj`) when no owner is attached. The statement goes
   out through `query_start`; nothing is written with `warn`. Pooled and pinned
   statements alike (`_query_async`, `_query_async_pinned`).
2. **Level.** The flag `$self->{debug}` (set by core from `DBIO_TRACE`) gives
   the level: its leading digits, any other true value is 1. Level 1 traces the
   SQL with the single element `''` for binds, as core's `_query_start` does;
   from level 2 the binds follow.
3. **Redaction, then cut.** Each defined bind goes through the owner's
   `redact_bind_value` (the class-level hook of `DBIO::Storage::DBI` without an
   owner), called as `->(undef, $value, undef)` -- the transport's binds are
   plain values without column metadata. The result is cut to 32 characters
   plus `...`. `undef` is `NULL`, the hook not called. Format `'value'`.
4. **No `query_end`.** A debug object has one start time; statements overlap on
   several connections, so a shared timer would report wrong durations.

## Consequences

- The operator's `DBIO_TRACE=1=/path` log and the redactor installed for the
  sync path apply to the async path unchanged.
- A redactor hiding a value by column name sees no name here; one working on
  the value does.
- Bind values appear in no message of the transport.

## Addendum (2026-10-30, core k402 / k404) -- the rule is core's now

The trace rule moved into core (`DBIO::Storage::Async::_debug_query`, core ADR
0025, core k402): an async transport carries no trace of its own. It calls
`$self->_debug_query($sql, $bind, $bind_attrs)` and runs the coderef it gets
back when the statement has settled -- done, failed or cancelled.
`_query_async` and `_query_async_pinned` take the optional `$bind_attrs` for
that call; on the wire the binds stay bare values. Statements core did not
build (`BEGIN`, `COMMIT`, ping, reset, connect actions, `_notify_send`) have no
attributes.

Two points of the decision above are superseded:

- Point 3: the redactor is called as `->($column_name, $value, $attrs)`, not
  `->(undef, $value, undef)`; a raw statement still gives it `undef` for name
  and attributes. A hook hiding a value by column name now sees the name
  (and `encode_column` binds show as `***`).
- Point 4: `query_end` is called. The coderef of core carries the statement
  and the redacted binds, no timer of the transport, and holds no bind
  arrayref (ADR 0044).

Points 1 and 2 stand, with core as the one place that implements them. The
select with a `bind` attribute (core k404) traces and runs through the same
seam.
