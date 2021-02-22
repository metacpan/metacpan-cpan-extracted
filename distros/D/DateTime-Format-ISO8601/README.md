# NAME

DateTime::Format::ISO8601 - Parses ISO8601 formats

# VERSION

version 0.16

# SYNOPSIS

    use DateTime::Format::ISO8601;

    my $datetime_str = '2020-07-25T11:32:31';
    my $dt = DateTime::Format::ISO8601->parse_datetime($datetime_str);
    say $dt;

    # This format is ambiguous and could be either a date or time, so use the
    # parse_time method.
    my $time_str = '113231';
    $dt = DateTime::Format::ISO8601->parse_time($time_str);
    say $dt;

    # or

    my $iso8601 = DateTime::Format::ISO8601->new;
    $dt = $iso8601->parse_datetime($datetime_str);
    say $dt;

    $dt = $iso8601->parse_time($time_str);
    say $dt;

    say DateTime::Format::ISO8601->format_datetime($dt);

# DESCRIPTION

Parses almost all ISO8601 date and time formats. ISO8601 time-intervals will be
supported in a later release.

# METHODS

This class provides the following methods:

## Constructors

### DateTime::Format::ISO8601->new( ... )

Accepts an optional hash.

    my $iso8601 = DateTime::Format::ISO8601->new(
        base_datetime => $dt,
        cut_off_year  => 42,
        legacy_year   => 1,
    );

- base\_datetime

    A `DateTime` object that will be used to fill in missing information from
    incomplete date/time formats.

    This key is optional.

- cut\_off\_year

    A integer representing the cut-off point between interpreting 2-digits years as
    19xx or 20xx.

        2-digit years <  cut_off_year will be interpreted as 20xx
        2-digit years >= cut_off_year will be untreated as 19xx

    This key defaults to the value of `DefaultCutOffYear`.

- legacy\_year

    A boolean value controlling if a 2-digit year is interpreted as being in the
    current century (unless a `base_datetime` is set) or if `cut_off_year` should
    be used to place the year in either 20xx or 19xx.

    If this is true, then the `cut_off_year` is used. If this is false, then the
    year is always interpreted as being in the current century.

    This key defaults to the value of `DefaultLegacyYear`.

### $iso8601->clone

Returns a replica of the given object.

## Object Methods

### $iso8601->base\_datetime

Returns a `DateTime` object if a `base_datetime` has been set.

### $iso8601->set\_base\_datetime( object => $object )

Accepts a `DateTime` object that will be used to fill in missing information
from incomplete date/time formats.

### $iso8601->cut\_off\_year

Returns a integer representing the cut-off point between interpreting 2-digits
years as 19xx or 20xx.

### $iso8601->set\_cut\_off\_year($int)

Accepts a integer representing the cut-off point between interpreting 2-digits
years as 19xx or 20xx.

    2-digit years <  legacy_year will be interpreted as 20xx
    2-digit years >= legacy_year will be interpreted as 19xx

### $iso8601->legacy\_year

Returns a boolean value indicating the 2-digit year handling behavior.

### $iso8601->set\_legacy\_year($bool)

Accepts a boolean value controlling if a 2-digit year is interpreted as being
in the current century (unless a `base_datetime` is set) or if `cut_off_year`
should be used to place the year in either 20xx or 19xx.

## Class Methods

### DateTime::Format::ISO8601->DefaultCutOffYear($int)

Accepts a integer representing the cut-off point for 2-digit years when calling
`parse_*` as class methods and the default value for `cut_off_year` when
creating objects. If called with no parameters this method will return the
default value for `cut_off_year`.

### DateTime::Format::ISO8601->DefaultLegacyYear($bool)

Accepts a boolean value controlling the legacy year behavior when calling
`parse_*` as class methods and the default value for `legacy_year` when
creating objects. If called with no parameters this method will return the
default value for `legacy_year`.

## Parser(s)

These methods may be called as either class or object methods.

### parse\_datetime

### parse\_time

Please see the ["FORMATS"](#formats) section.

## Formatter

This may be called as either class or object method.

### format\_datetime($dt)

Formats the datetime in an ISO8601-compatible format. This differs from
["iso8601" in DateTime](https://metacpan.org/pod/DateTime#iso8601) by including nanoseconds/milliseconds and the correct
timezone offset.

# FORMATS

There are 6 strings that can match against date only or time only formats. The
`parse_datetime` method will attempt to match these ambiguous strings against
date only formats. If you want to match against the time only formats use the
`parse_time` method.

## Conventions

- Expanded ISO8601

    These formats are supported with exactly 6 digits for the year. Support for a
    variable number of digits will be in a later release.

- Precision

    If a format doesn't include a year all larger time unit up to and including the
    year are filled in using the current date/time or \[if set\] the `base_datetime`
    object.

- Fractional time

    There is no limit on the expressed precision.

## Supported via parse\_datetime

The supported formats are listed by the section of ISO 8601:2000(E) in which
they appear.

### 5.2 Dates

- 5.2.1.1
    - YYYYMMDD
    - YYYY-MM-DD
- 5.2.1.2
    - YYYY-MM
    - YYYY
    - YY
- 5.2.1.3
    - YYMMDD
    - YY-MM-DD
    - -YYMM
    - -YY-MM
    - -YY
    - --MMDD
    - --MM-DD
    - --MM
    - ---DD
- 5.2.1.4
    - +\[YY\]YYYYMMDD
    - +\[YY\]YYYY-MM-DD
    - +\[YY\]YYYY-MM
    - +\[YY\]YYYY
    - +\[YY\]YY
- 5.2.2.1
    - YYYYDDD
    - YYYY-DDD
- 5.2.2.2
    - YYDDD
    - YY-DDD
    - -DDD
- 5.2.2.3
    - +\[YY\]YYYYDDD
    - +\[YY\]YYYY-DDD
- 5.2.3.1
    - YYYYWwwD
    - YYYY-Www-D
- 5.2.3.2
    - YYYYWww
    - YYYY-Www
    - YYWwwD
    - YY-Www-D
    - YYWww
    - YY-Www
    - -YWwwD
    - -Y-Www-D
    - -YWww
    - -Y-Www
    - -WwwD
    - -Www-D
    - -Www
    - -W-D
- 5.2.3.4
    - +\[YY\]YYYYWwwD
    - +\[YY\]YYYY-Www-D
    - +\[YY\]YYYYWww
    - +\[YY\]YYYY-Www

### 5.3 Time of Day

- 5.3.1.1 - 5.3.1.3

    Values can optionally be prefixed with 'T'.

- 5.3.1.1
    - hh:mm:ss
- 5.3.1.2
    - hh:mm
- 5.3.1.3 - 5.3.1.4

    fractional (decimal) separator maybe either ',' or '.'

- 5.3.1.3
    - hhmmss,ss
    - hh:mm:ss,ss
    - hhmm,mm
    - hh:mm,mm
    - hh,hh
- 5.3.1.4
    - -mm:ss
    - -mmss,s
    - -mm:ss,s
    - -mm,m
    - --ss,s
- 5.3.3 - 5.3.4.2

    Values can optionally be prefixed with 'T'.

- 5.3.3
    - hhmmssZ
    - hh:mm:ssZ
    - hhmmZ
    - hh:mmZ
    - hhZ
    - hhmmss.ssZ
    - hh:mm:ss.ssZ
- 5.3.4.2
    - hhmmss\[+-\]hhmm
    - hh:mm:ss\[+-\]hh:mm
    - hhmmss\[+-\]hh
    - hh:mm:ss\[+-\]hh
    - hhmmss.ss\[+-\]hhmm
    - hh:mm:ss.ss\[+-\]hh:mm

### 5.4 Combinations of date and time of day

- 5.4.1
    - YYYYMMDDThhmmss
    - YYYY-MM-DDThh:mm:ss
    - YYYYMMDDThhmmssZ
    - YYYY-MM-DDThh:mm:ssZ
    - YYYYMMDDThhmmss\[+-\]hhmm
    - YYYY-MM-DDThh:mm:ss\[+-\]hh:mm
    - YYYYMMDDThhmmss\[+-\]hh
    - YYYY-MM-DDThh:mm:ss\[+-\]hh
- 5.4.2
    - YYYYMMDDThhmmss.ss
    - YYYY-MM-DDThh:mm:ss.ss
    - YYYYMMDDThhmmss.ss\[+-\]hh
    - YYYY-MM-DDThh:mm:ss.ss\[+-\]hh
    - YYYYMMDDThhmmss.ss\[+-\]hhmm
    - YYYY-MM-DDThh:mm:ss.ss\[+-\]hh:mm
- 5.4.3

    Support for this section is not complete.

    - YYYYMMDDThhmm
    - YYYY-MM-DDThh:mm
    - YYYYMMDDThhmmZ
    - YYYY-MM-DDThh:mmZ
    - YYYYDDDThhmm
    - YYYY-DDDThh:mm
    - YYYYDDDThhmmZ
    - YYYY-DDDThh:mmZ
    - YYYYWwwDThhmm\[+-\]hhmm
    - YYYY-Www-DThh:mm\[+-\]hh

### 5.5 Time-Intervals

These are not currently supported

## Supported via parse\_time

### 5.3.1.1 - 5.3.1.3

Values can optionally be prefixed with 'T'.

- 5.3.1.1
    - hhmmss
- 5.3.1.2
    - hhmm
    - hh
- 5.3.1.4
    - -mmss
    - -mm
    - --ss

# STANDARDS DOCUMENT

## Title

    ISO8601:2000(E)
    Data elements and interchange formats - information exchange -
    Representation of dates and times
    Second edition 2000-12-15

## Reference Number

    ISO/TC 154 N 362

# CREDITS

Iain 'Spoon' Truskett (SPOON) who wrote [DateTime::Format::Builder](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ABuilder). That has
grown into _The Vacuum Energy Powered `Swiss Army` Katana_ of date and time
parsing. This module was inspired by and conceived in honor of Iain's work.

Tom Phoenix (PHOENIX) and PDX.pm for helping me solve the ISO week conversion
bug. Not by fixing the code but motivation me to fix it so I could participate
in a game of `Zendo`.

Jonathan Leffler (JOHNL) for reporting a test bug.

Kelly McCauley for a patch to add 8 missing formats.

Alasdair Allan (AALLAN) for complaining about excessive test execution time.

Everyone at the DateTime `Asylum`.

# SEE ALSO

- [DateTime](https://metacpan.org/pod/DateTime)
- [DateTime::Format::Builder](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ABuilder)

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/DateTime-Format-ISO8601/issues](https://github.com/houseabsolute/DateTime-Format-ISO8601/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for DateTime-Format-ISO8601 can be found at [https://github.com/houseabsolute/DateTime-Format-ISO8601](https://github.com/houseabsolute/DateTime-Format-ISO8601).

# AUTHORS

- Joshua Hoblitt <josh@hoblitt.com>
- Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Doug Bell <doug@preaction.me>
- joe <draxil@gmail.com>
- Liam Widdowson <lbw@telstra.com>
- Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Joshua Hoblitt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
`LICENSE` file included with this distribution.
