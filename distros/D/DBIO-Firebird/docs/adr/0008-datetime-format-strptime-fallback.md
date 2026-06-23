# ADR 0008 — DateTime formatting via a strptime fallback subclass (no DateTime::Format::Firebird)

- Status: accepted
- Date: 2026-06-20
- Tags: datetime, inflation, storage

## Context

DBIO inflates/deflates datetime columns through a per-storage datetime parser
class. Most engines have a maintained `DateTime::Format::<Engine>` that the core
base `DBIO::Storage::DateTimeFormat` can use as its `preferred_format_class`.

Firebird has **no maintained `DateTime::Format::Firebird`** on CPAN. Firebird's
DBD layer is told to emit ISO date/timestamp strings at connect time
(`connect_call_datetime_setup` sets `ib_time_all = 'ISO'`,
`Storage/InterBase.pm:131-135`), and the `TIMESTAMP` type carries up to 4
fractional-second digits.

## Decision

`DBIO::Firebird::DateTime::Format` subclasses `DBIO::Storage::DateTimeFormat`
and sets **no** `preferred_format_class`, falling back to explicit
`DateTime::Format::Strptime` patterns sized for Firebird's ISO output
(`DateTime/Format.pm`):

- `datetime_parse_pattern` / `datetime_format_pattern` = `%Y-%m-%d %H:%M:%S.%4N`
  (the 4-digit fractional seconds Firebird's `TIMESTAMP` supports);
- `date_parse_pattern` / `date_format_pattern` = `%Y-%m-%d`.

The in-code comment records the reason: "No preferred_format_class: there is no
maintained DateTime::Format::Firebird." Both storage backends register this
class as their `datetime_parser_type` (`Storage.pm:11`,
`Storage/InterBase.pm:11`).

## Rationale

Without a maintained format module, the choice is to inflate by an explicit
pattern rather than depend on (or vendor) a `DateTime::Format::Firebird`. Using
the core `DBIO::Storage::DateTimeFormat` base — which already supports a
pattern-only mode — keeps Firebird's datetime handling on the same seam every
other driver uses (karr #8 migrated this from a bespoke formatter to the core
base), while pinning the patterns to Firebird's ISO + 4-fractional-digit
output. The patterns must match what `ib_time_all = 'ISO'` actually emits, which
is why the two decisions live together: the connect-call shapes the input, this
class parses it.

## Consequences

- Datetime inflation depends on Firebird emitting ISO strings, which requires
  the `datetime_setup` connect-call (`ib_time_all = 'ISO'`); without it the
  patterns will not match.
- The patterns are fixed at 4 fractional-second digits to match Firebird's
  `TIMESTAMP` precision; a server/locale that returns a different timestamp
  spelling will fail to inflate (the locale-format failure tracked in karr #7).
- If a maintained `DateTime::Format::Firebird` ever appears, this class can be
  reduced to a `preferred_format_class` setting; until then the strptime
  patterns are the contract.
