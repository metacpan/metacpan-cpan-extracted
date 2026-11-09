# ADR 0005 — COPY IN uses PostgreSQL text format (`\t` / `\N`)

- Status: accepted
- Date: 2026-06-21
- Tags: async, copy, bulk-load, ev-pg, drivers
- Amended: "all-or-nothing" holds for a row libpq did not take as well, and a
  COPY whose stream could not be ended costs its connection (see the Amendment
  of karr k65); the decision itself stands
- Amended: the writer applies the text-format escaping rules (see the
  Amendment of karr k98)

## Amendment (2026-10-30, karr k98) — the writer escapes values by the text-format rules

The writer serialises every value by PostgreSQL's COPY text-format rules, so a
value arrives in the table exactly as given. This replaces the "known
limitation" in the Consequences below.

- `\` becomes `\\`, TAB becomes `\t`, LF becomes `\n`, CR becomes `\r`. The
  field and row delimiters are therefore the only TAB and LF in the stream.
- `undef` stays `\N`, the NULL token. A literal `\N` in a value is written
  `\\N` (the backslash is doubled), which the server reads as the two
  characters, not as NULL.
- Text format stays the one format: no CSV mode, no `WITH` clause. The rule is
  stated in the POD of `copy_in` and in the SYNOPSIS of `DBIO::PostgreSQL::EV`.
- Callers pass raw values to the writer; escaping upstream is not needed and
  would be doubled.

## Amendment (2026-10-08, karr k65) — a row that was not written fails the COPY; a stream that could not be ended retires the connection

The Consequences below call the load all-or-nothing. That was true of a
callback that dies and of an error the server finds. It was not true of a row
the writer could not hand to libpq, and nothing said what becomes of a
connection whose COPY could not be ended. Both are decided here; what led to
them was read at Pg.xs (EV::Pg 0.02 and 0.07) and libpq's `fe-exec.c`, and
measured against PostgreSQL 18.6 with EV::Pg 0.07 on libpq 17.11.

- **The writer dies for a row `put_copy_data` did not take, and that fails the
  COPY.** `PQputCopyData` answers 0 on EV::Pg's non-blocking connection in one
  case only: libpq cannot enlarge its output buffer for the row
  (`pqCheckOutBufferSpace`) -- memory it does not get, or a buffer past
  `INT_MAX` bytes. It answers -1 on an error. The writer looked at neither, so
  the row was missing from a COPY that completed. Measured: a slow consumer and
  an address-space limit, 20000 rows put, 6600 answered 0, the COPY reported
  done with 13400 rows -- not the first 13400. Now the writer dies, for that
  row and every one after it, the COPY is aborted through `put_copy_end`, and
  the Future fails with the writer's error also when the callback catches the
  die.

  *Why not wait for room.* libpq's contract for 0 is "wait for write-ready and
  try again", and EV::Pg has `on_drain` for it. Waiting means running the EV
  loop, and the callback runs inside EV::Pg's delivery, where a nested loop
  hands the next result to the running callback (ADR 0001, amendment of karr
  k44). Keeping the row in Perl until `on_drain` would need the memory libpq
  just failed to get. A COPY that outgrows client memory needs a writer that
  yields to the loop -- another interface, not a handling of 0.

- **A COPY that ends with its stream open retires its connection.** That is a
  `put_copy_end` that answered -1, croaked, or answered 1 on a connection that
  is gone. Where libpq could not queue the end of the stream it is still in
  the COPY: the connection is open and refuses every statement, and nothing is
  left to end the COPY with. Handed back idle, it failed every later call it
  was given. The pool retires what it cannot use again (karr k49); closing the
  connection is also what makes the server throw the COPY away.

Consequence, recorded because it was not: the callback runs to its end before
the EV loop does anything else, so the part of the stream the server has not
read by then is held in libpq's output buffer, in the client. Measured with
1 kB rows: 15 MB held for a 200 MB COPY the server kept up with, 40 MB for a
40 MB COPY into a table with a slow row trigger. `copy_in` is not a streaming
interface.

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
- The writer closure handed to the user's callback joins a row's (escaped, see
  Amendment of karr k98) values with a literal TAB and terminates with a newline, mapping any `undef` to the text-format
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

- Values containing a literal TAB, newline, CR, backslash, or the exact bytes
  `\N` are escaped by the writer (Amendment of karr k98) and load unchanged.
- `undef` becomes SQL NULL via `\N`; the empty string remains the empty string —
  the two are correctly distinguished.
- A callback die aborts the whole COPY via `put_copy_end($@)`
  (`Storage.pm:631-634`); the load is all-or-nothing per the server's COPY
  semantics.
- This row serialiser is specific to PostgreSQL's text COPY format and has no
  analog in the generic base async storage; a driver author copying this driver
  must not assume the `\t`/`\N` writer transfers to another database's bulk-load
  protocol.
