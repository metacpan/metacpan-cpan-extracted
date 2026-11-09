# ADR 0008 — The text of the engine is masked before it is thrown

- Status: accepted
- Date: 2026-11-02

## Context

The family rule (core ADR 0075) is that a message names keys, columns and
options, never values. Core carries it out for the values bound to a statement:
the error text of the engine passes through the storage hook
`_mask_error_values` before it becomes part of an exception, and the base of the
hook replaces each bound value of at least four characters.

ClickHouse breaks the premise that this is enough. Over the MySQL wire
protocol `DBD::mysql` puts the bind values into the statement on the client,
so the engine never sees a placeholder; it quotes what it received, in
sentences of its own and in several places of one message:

- the sentence of the error (`Cannot parse string 'x' as Int32`, `Cannot parse
  date here: x`, `Unknown element 'x' for enum`, `found 'x'`), also an excerpt
  the engine cuts off (`31337-99-9` of `31337-99-99`) and the part it parsed
  (`parsed just '7'`);
- the statement it received (`In scope ...`, `While processing ...`, the rest
  of a `Syntax error: failed at position`);
- the row that broke a constraint (`Column values: s = 'x'`);
- the plan of a failed function (`while executing 'FUNCTION ...'`), which holds
  the constants of the statement.

A bound value shorter than four characters is not touched by the base of the
hook, and an excerpt is not the value. Measured against a 25.3 server, the
sentences above leaked values of two and three characters, truncated dates and
the first character of an array element.

## Decision

**1. The storage overrides `_mask_error_values`.** It first applies
`DBIO::ClickHouse::Util::mask_error_details`, then hands the result to
`next::method`, so the sentences of the engine are masked by their form and the
bound values by core wherever else they stand. The hook never throws and leaves
a text without a value, an `undef` and a reference as they are.

**2. The sentences are masked by form, one rule each.** A rule keeps the words
around the value -- the code, the type, the column, the constraint, the table,
the position -- and replaces the value, however the engine quotes it. The
quotes stay where the engine quotes (`'***'`), so a sentence reads as the
engine wrote it. A statement the engine quotes keeps its identifiers, keywords
and function names; every literal in it is replaced by `***` without quotes.
`Column values:` is read as `name = value` pairs and falls back to masking all
of it where it is not readable one way only.

**3. A plan is replaced as a whole.** `while executing '...'` carries the
constants of the statement and names no cause the caller can use; it becomes
`while executing '***'`.

**4. Every statement shape runs through the hook.** Select, insert, the
multi-row insert of a void `populate`, `update` and `delete` all execute through
core's `_dbh_execute`, which names the statement and its values for the error
handler; the statements that run on the handle of the storage without that
bookkeeping (introspection, the scratch-database deploy, the diff's DDL) reach
the hook through the same error handler of the handle. `$dbh->errstr` and
`$sth->errstr` keep the raw text, as core's ADR 0075 states.

## Known limits

- A value the engine writes without quotes ends where the next sentence of the
  engine begins; a value that contains such a delimiter is masked up to it and
  its rest stays.
- A bare word in a quoted statement is kept: it cannot be told from the name of
  a column. A value written there without quotes and without the form of a
  literal is not recognised.
- A value that is short, unquoted and in a form no rule knows stays. Values of
  at least four characters are covered by core wherever they stand, which
  closes both limits for them.

A new sentence of the engine that quotes a value is a new rule in
`mask_error_details` with a case in t/65 and, where a server is at hand, in t/66.

## Consequences

- The message of a failed statement is shorter in its quoted parts and
  otherwise unchanged: code, type, column, constraint and the number of binds
  are what a caller debugs from.
- A caller that read a value out of an error text of the engine does not get it
  any more; the values are in the caller's hands.
- The rules are tied to the sentences of the server versions measured (25.3). A
  server that words an error differently is not covered by a rule until one is
  written; the value-agnostic parts (core's masking, the plan, the statement
  literals) hold regardless.
