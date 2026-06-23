# ADR 0005 — Own DateTime format classes; no DateTime::Format::MSSQL; smalldatetime channel

- Status: accepted
- Date: 2026-06-20
- Tags: datetime, types, format

## Context

The DBIO driver-development default for datetime parsing is: if a maintained
`DateTime::Format::<DB>` exists on CPAN, name it directly via
`datetime_parser_type` (or set it as `preferred_format_class` on a
`DBIO::Storage::DateTimeFormat` subclass and let it be used when installed).

A `DateTime::Format::MSSQL` exists on CPAN, but it is **mdy-based** and does
not round-trip identically with the patterns this driver uses (`%3N`
millisecond fractions; the Sybase `syb_date_fmt('ISO_strict')` ISO output).
MSSQL also has a datetime *channel* the core base does not model:
`smalldatetime` (minute precision, no fractional seconds).

## Decision

Both format classes subclass `DBIO::Storage::DateTimeFormat` and deliberately
set **no** `preferred_format_class`:

1. `DBIO::MSSQL::Storage::DateTime::Format`
   (`lib/DBIO/MSSQL/Storage/DateTime/Format.pm`) declares
   `datetime_*_pattern = '%Y-%m-%d %H:%M:%S.%3N'` and adds a third channel —
   `smalldatetime_parse_pattern` / `smalldatetime_format_pattern`
   (`%Y-%m-%d %H:%M:%S`, minute/second precision, no fraction) — exposed via
   `parse_smalldatetime` / `format_smalldatetime`. Core's
   `InflateColumn::DateTime` routes `smalldatetime` columns to these methods
   when the parser `->can()` them, else falls back to the datetime channel.
2. `DBIO::MSSQL::Storage::Sybase::DateTime::Format`
   (`lib/DBIO/MSSQL/Storage/Sybase/DateTime/Format.pm`) is **asymmetric**:
   `datetime_parse_pattern = '%Y-%m-%dT%H:%M:%S.%3NZ'` (reads the ISO_strict
   form DBD::Sybase emits) but `datetime_format_pattern =
   '%Y-%m-%d %H:%M:%S.%3N'` (writes a plain datetime literal MSSQL accepts).

## Rationale

`DateTime::Format::MSSQL` is mdy-oriented and would not round-trip with our
`%3N`/ISO patterns, so preferring it would break the fallback contract that
the preferred class and the hand-declared patterns must be interchangeable.
Subclassing `DBIO::Storage::DateTimeFormat` keeps the strptime patterns
declared as class data (no hand-rolled private Strptime wrapper inside the
Storage files) while letting MSSQL add the `smalldatetime` channel the base
does not have. The Sybase variant is asymmetric because the read path
(`syb_date_fmt('ISO_strict')`) and the write path (plain datetime literal)
genuinely use different formats — the connect-time
`connect_call_datetime_setup` sets ISO_strict output, but MSSQL wants a plain
literal on write. (Migration to these base-class subclasses tracked as karr
`dbio-mssql` #5, resolved.)

## Consequences

- This is a deliberate divergence from the "prefer the CPAN module" default;
  reviewers should not re-add `preferred_format_class('DateTime::Format::MSSQL')`.
- `cpanfile` declares no direct `DateTime::Format::Strptime` requires — the
  fallback engine is a hard requires of core.
- Both paths (with and without any preferred class) must round-trip
  identically; the offline format contract test covers this.
- `smalldatetime` round-trips at minute precision through its own channel;
  drivers without that channel would lose the column-type distinction.
