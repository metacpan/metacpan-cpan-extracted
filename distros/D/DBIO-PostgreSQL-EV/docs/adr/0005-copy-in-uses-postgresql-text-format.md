# ADR 0005 — COPY IN uses PostgreSQL text format (`\t` / `\N`)

- Status: accepted
- Date: 2026-06-21
- Tags: async, copy, bulk-load, ev-pg, drivers

## Context

Bulk loading is the one place where row-at-a-time `INSERT` is the wrong tool:
each insert is a statement with its own parse/plan/execute, and even pipelined
that is far slower than PostgreSQL's `COPY ... FROM STDIN`, which streams rows
into the server in one operation. EV::Pg exposes the libpq COPY primitives
(`put_copy_data`, `put_copy_end`), but they push *bytes* — the driver has to
serialise each row into PostgreSQL's COPY wire format. COPY supports several
formats (text, CSV, binary); a format and its escaping rules must be chosen.

## Decision

`copy_in` issues `COPY <table> (<cols>) FROM STDIN` (the default, i.e.
PostgreSQL **text** format) and serialises each row into that format itself
(`Storage.pm:606-643`).

- The statement is built with quoted identifiers and no `WITH` clause
  (`Storage.pm:609-611`), so the server uses text format by default.
- The writer closure handed to the user's callback joins a row's values with a
  literal TAB and terminates with a newline, mapping any `undef` to the text-format
  NULL token `\N` (`Storage.pm:624-628`):

      my $line = join("\t", map { defined $_ ? $_ : '\N' } @$row) . "\n";
      $pg->put_copy_data($line);

- On success the stream is closed with `put_copy_end` and the connection released
  (`Storage.pm:636-638`); if the user callback dies, `put_copy_end($@)` aborts the
  COPY with the error and the Future fails (`Storage.pm:631-634`).

## Rationale

Text format with TAB delimiter and `\N` for NULL is PostgreSQL's documented COPY
default, so emitting it needs no `WITH (FORMAT ...)` clause and matches what the
server expects with zero configuration. It is also the simplest correct
serialisation to produce in pure Perl: a `join("\t", ...)` with a NULL sentinel,
versus CSV (quoting/escaping rules) or binary (length-prefixed typed encoding,
which would need per-column type knowledge the driver does not have at this seam).
Mapping `undef → \N` is mandatory, not cosmetic: in text format an empty field is
the empty string, not NULL, so without the sentinel every Perl `undef` would load
as `''` instead of SQL NULL. Aborting the COPY via `put_copy_end($@)` on a callback
die is what keeps a half-streamed load from being committed.

This is shipped, hence **accepted**, not proposed.

## Consequences

- Values containing a literal TAB, newline, backslash, or the exact bytes `\N`
  are **not** escaped by the writer and will corrupt the COPY stream or be
  misread. This is the known limitation of the minimal text-format serialiser:
  it assumes tab/newline/backslash-free field values. Data that can contain those
  bytes must not be loaded through `copy_in` as-is (escape upstream, or a future
  revision must add text-format escaping or switch to CSV/binary).
- `undef` becomes SQL NULL via `\N`; the empty string remains the empty string —
  the two are correctly distinguished.
- A callback die aborts the whole COPY via `put_copy_end($@)`
  (`Storage.pm:631-634`); the load is all-or-nothing per the server's COPY
  semantics.
- This row serialiser is specific to PostgreSQL's text COPY format and has no
  analog in the generic base async storage; a driver author copying this driver
  must not assume the `\t`/`\N` writer transfers to another database's bulk-load
  protocol.
