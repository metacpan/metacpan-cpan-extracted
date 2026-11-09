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

1. **Hook API**: a single coderef, called as `$hook->($column_name, $value)`,
   that returns the redaction-safe display string. `$column_name` is the
   column the SQL generator attached to the bind slot, or `undef` for a bind
   that carries no column metadata (a positional placeholder in literal SQL).
   ```perl
   __PACKAGE__->redact_bind_value(sub {
       my ($column_name, $value) = @_;
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
4. **Call site**: `_format_for_trace` calls the hook *once per defined bind
   value* — an `undef` bind is rendered as `NULL` without asking the hook —
   outside the `qq{}` interpolation that builds the trace string, so the
   hook's return value is rendered as a literal and cannot be parsed back
   into the original. The return value is put between single quotes as the
   hook returns it; the hook is responsible for the display shape.
5. **The bind value going to `$dbh->execute(@bind)` is untouched.** This is
   documented in the hook POD and in the comment at the hook's declaration.
6. **A mock-only regression test (`t/storage/trace_redact.t`) locks** that
   (a) the default hook is identity, (b) a custom hook is invoked once per
   bind value, with the column name and the value, (c) a hook that masks one
   column leaves the other binds as they are, (d) the rendered trace string
   shows the redaction rather than the original. That the bind value going
   to `execute` is the same with and without the hook (item 5) is not
   asserted there.

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
- **The hook is invoked per bind value, not per query.** It gets the column
  name and the value, so "redact every `password` column" and "redact any
  value matching pattern P" both work. A consumer that wants more context
  (e.g. "redact column N in table T") needs to read more than the
  two-argument signature provides. That is a deliberate scope cut — the v1
  hook is "column name and value in, string out," and a future ADR can
  widen the signature if the use case is reported.
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

## Addendum 2026-10-09 — a message never quotes credentials (karr k297, k305)

The Decision is about bind values in the trace stream. The same concern
reaches connect info: a DSN, a password or a connection URI repeated in an
exception text, a warning or a debug line. The rule, in force since karr k297:

**A message never quotes credentials, and the one place that knows how to take
them out is `DBIO::Util::mask_connect_secrets`.** Every site that writes
connect info into a message asks it; none rolls its own pattern. The value is
replaced by `***`, the key, the user name and the rest of the text stay, so the
message stays usable.

Where the masking happens is core's job, not each transport's. The error a
transport raises while a pool connection is made passes through
`mask_connect_secrets` in `DBIO::Storage::PoolBase::_spawn_connection` (karr
k305) before it is rethrown or failed into a waiter's Future: libpq quotes a
connection URI whole, `user:password@` included, and a driver author cannot be
expected to know that. A transport may still mask at its source; the pool masks
again, and masking is idempotent.

Known limits: a secret under a key whose name is not one of those named in
the addendum of 2026-10-16 is not seen; the password argument is replaced verbatim,
so a trivial password makes the message hard to read.

Not decided here, and still open for the maintainer: the replicant key that
`DBIO::Replicated::Pool::connect_replicants` derives from the DSN rest (it is
the `force_pool` name) and the `PrintError` text of `bin/dbiogen`'s
`DBI->connect` (karr k305 (b), (c)).

## Addendum 2026-10-16 — statements of connect actions (karr k343)

The rule extends to the statements of connect actions (`on_connect_do`,
`on_connect_call`, `do_sql`, `ATTACH`, `PRAGMA key`) and to the errors that
quote them.

**An error about a statement never quotes what the statement carries as a
secret.** The value of a key ending in `password`, `passwd`, `pwd`, `pass`,
`passphrase`, `key`, `token` or `secret` is replaced by `***` by
`DBIO::Util::mask_connect_secrets`, in the statement forms `key = 'x'`,
`key='x'`, `?token=x` and `key('x')` as well.

`DBIO::Util::mask_statement_secrets($text, @statements)` is the entry for a
text about statements: it takes the secret values out of the statements and
masks them wherever the text repeats them, including the part a database
quotes of one (SQLite: `unrecognized token: "'...`). `DBIO::Storage::DBI`
applies it to every error of a statement run through `_do_query`, in
`_dbi_handle_error` before the `exception_action` sees the text, and on the
die of an async pool runner.

## Addendum 2026-10-30 — the async path (karr k402)

The async path carries the same rule as the sync path. `DBIO::Storage::Async`
holds it once, in `_debug_query($sql, $bind, $bind_attrs)`, for every
transport: the statement at level 1, the binds from level 2 through the
`redact_bind_value` of the owning storage as `($column_name, $value, $attrs)`,
cut to 32 characters, `undef` as `NULL`; `query_start` goes to the owner's
`debugobj` and the call returns a coderef for `query_end`.

The bind attributes of a statement core builds (select, select_single, insert,
update, delete) are resolved by the rule of the sync path (`_resolve_bindattrs`:
`dbic_colname`, `sqlt_datatype`, `redact` for an `encode_column` column) and
travel as a second list beside the binds, an arrayref parallel to them that
carries no value. The seam is `_query_async($sql, $bind, $bind_attrs)` and
`_query_async_pinned($conn, $sql, $bind, $bind_attrs)`; the binds on the wire
stay bare values. A raw statement has no attributes, and the hook is asked with
`undef` for name and attributes.

## Addendum 2026-10-30 — connect statements on a pool connection (karr k405)

The statements of the connect and disconnect actions (`on_connect_do`,
`on_connect_call`, `on_disconnect_do`, `on_disconnect_call`) that run on a pool
connection of an async transport are traced like those of the sync path
(`_do_query`). The runner `DBIO::Storage::Async` hands the owning storage
(`_setup_pool_connection`, `_teardown_pool_connection`) sends each statement
through `_debug_query` with the text in its fingerprint form
(`mask_statement_fingerprint`: a secret shows as `***[sha256:<8 hex>]`), and
calls `query_end` after the statement succeeded. Level 0 traces nothing. The
row queries of a `connect_call_*` (`dbio_rows`) are not traced and return their
rows as before. The trace line is in the runner of the core, so a transport
that overrides `_run_pool_connect_statement` gets it too.

Each rendering of an insert, update or delete in `_run_crud` and
`_crud_bind_attrs` receives a flat copy of the options hash of the call. A
driver SQL maker consumes keys of the options it is given (`on_conflict`,
`insert_or`); the statement on the wire and the rendering that resolves the
bind attributes therefore each see the complete options, the attribute list
lines up with the binds, and the options of the caller stay as given.
