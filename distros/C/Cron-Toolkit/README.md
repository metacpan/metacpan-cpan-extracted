# NAME

Cron::Toolkit - Quartz-compatible cron parser with unique extensions and over 400 tests

# SYNOPSIS

    use Cron::Toolkit;
    use feature qw(say);

    my $c = Cron::Toolkit->new(
        expression => "0 30 14 ? * 6-2 *",
        time_zone  => "Europe/London",
    );

    say $c->describe;
    # 2:30 PM every day from Saturday to Tuesday of every month

    # next occurence in epoch seconds
    say $c->next;

    # previous occurence in epoch seconds
    say $c->previous;

    # Question: when does February 29th next land on a Monday? 
    say Cron::Toolkit->new(expression => "0 0 0 29 2 1 *")->next;
    # Mon Feb 29 00:00:00 2044

    # See exactly what was parsed
    $c->dump_tree;
    # ┌─ second: 0
    # ├─ minute: 30
    # ├─ hour:   14
    # ├─ dom:    ?
    # ├─ month:  *
    # ├─ dow:    6-2 
    # └─ year:   *

# DESCRIPTION

`Cron::Toolkit` implements a complete, rigorously-tested cron expression parser that supports the full Quartz Scheduler syntax plus several useful extensions not found in other implementations.

Notable features include:

- Full 7-field Quartz syntax (seconds and year fields)
- Both day-of-month and day-of-week may be specified simultaneously (AND logic)
- Wrapped day-of-week ranges (e.g. `6-2` = Saturday through Tuesday)
- Proper Quartz-compatible DST handling
- Time-zone support via IANA names or fixed UTC offsets
- Natural-language English descriptions
- Complete crontab parsing with environment variable expansion
- Full abstract syntax tree and `dump_tree()` for debugging

# RELIABILITY

The distribution ships with over 400 data-driven tests covering every supported token, leap years, DST transitions, all time zones from UTC−12 to UTC+14, and every edge case discovered during development.

If it parses, the result is correct.

# UNIQUE EXTENSIONS

- DOM + DOW = AND logic

    Allows queries such as "next February 29 that falls on a Monday".

- Wrapped day-of-week ranges

    6-2 matches Saturday, Sunday, Monday, Tuesday

- Internal day-of-week: 1–7 = Monday–Sunday

    Matches [Time::Moment](https://metacpan.org/pod/Time%3A%3AMoment) and [DateTime](https://metacpan.org/pod/DateTime). `as_quartz_string()` converts back to Quartz's 1=Sunday convention.

# FIELD REFERENCE & ALLOWED VALUES

    Field            Allowed values         Allowed special characters 
    -------------------------------------------------------------------
    Second           0–59                   *,/,-                     
    Minute           0–59                   *,/,-,
    Hour             0–23                   *,/,-,
    Day of month     1–31                   *,/,-,?,L,LW,W
    Month            1–12 or JAN–DEC        *,/,-                          
    Day of week      1–7 or MON-SUN         *,/,-,?,L,#
    Year (optional)  1970–2099              *,/,-

    Legend:
      *    wildcard
      ,    list
      -    range
      /    step
      ?    no specific value (DOM or DOW only)
      L    last (day or day-of-week)
      L-n  n to last day of the month
      nL   last n-day of the month 
      LW   last weekday of month
      nW   nearest weekday to n
      #    nth day-of-week (e.g. 3#2 = 2nd Wednesday)

    @aliases: @yearly @annually @monthly @weekly @daily @hourly (Quartz standard)

# METHODS

- `Cron::Toolkit->new( expression => $expr, %options )`

    Main constructor; auto-detects Unix vs Quartz format.

- `Cron::Toolkit->new_from_unix( expression => $expr, %options )`

    Force traditional 5-field Unix interpretation.

- `Cron::Toolkit->new_from_quartz( expression => $expr, %options )`

    Force Quartz interpretation.

- `Cron::Toolkit->new_from_crontab( $string )`

    Parse a full crontab; returns a list of `Cron::Toolkit` objects.
    Supports `$VAR` expansion, user field, and comments.

- `$c->as_string`

    Normalized 7-field representation (DOW 1–7 = Mon–Sun).

- `$c->as_quartz_string`

    Quartz-compatible string (DOW 1=Sunday).

- `$c->describe`

    Human-readable English description.

- `$c->next( [$from_epoch] )`

    Next occurrence after `$from_epoch` or `time`.

- `$c->previous( [$from_epoch] )`

    Previous occurrence before `$from_epoch` or `time`.

- `$c->is_match( $epoch )`

    Returns true if `$epoch` matches the expression.

- `$c->dump_tree`

    Pretty-printed abstract syntax tree (invaluable for debugging).

- `$c->to_json`

    JSON representation of the object (expression, description, bounds, etc.).

- Accessors

        $c->time_zone("Europe/Berlin")
        $c->utc_offset(+180)          # minutes
        $c->begin_epoch($epoch)
        $c->end_epoch($epoch)         # undef = no limit

# TIME ZONES AND DST

All calculations are performed in the configured time zone.
DST transitions follow Quartz Scheduler rules exactly:

- Spring forward — times that do not exist are skipped
- Fall back — repeated local times fire twice

# BUGS AND CONTRIBUTIONS

This module is under active development and has not yet reached a 1.0 release.

The test suite currently contains over 400 data-driven tests covering every supported token, DST transitions, leap years, all time zones, and many edge cases — but real-world cron expressions can be surprisingly creative.

If you find:

- an expression that should be valid but dies or is rejected
- a next/previous occurrence that is wrong
- a description that is misleading or unclear
- any behaviour that differs from Quartz Scheduler (when using Quartz syntax)

...please file a bug report at
[https://github.com/nathanielgraham/cron-toolkit-perl/issues](https://github.com/nathanielgraham/cron-toolkit-perl/issues)

Pull requests with failing test cases are especially welcome — they are the fastest way to get a fix merged.

Feature requests (e.g. more natural-language locales, RRULE export, etc.) are also very much appreciated.

Thank you!

# AUTHOR

Nathaniel Graham

# COPYRIGHT AND LICENSE

Copyright 2025 Nathaniel Graham

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
