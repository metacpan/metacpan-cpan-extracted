[![CPAN version](https://badge.fury.io/pl/Date-Age.svg)](https://metacpan.org/pod/Date::Age)

# NAME

Date::Age - Return an age or age range from date(s)

# VERSION

Version 0.07

# SYNOPSIS

    use Date::Age qw(describe details);

    print describe('1943', '2016-01-01'), "\n";   # '72-73'

    my $data = details('1943-05-01', '2016-01-01');
    # { min_age => 72, max_age => 72, range => '72', precise => 72 }

# DESCRIPTION

This module calculates the age or possible age range between a date of birth
and another date (typically now or a death date).
It works even with partial dates.

# METHODS

# FUNCTIONS

## describe

    my $range = describe($dob);
    my $range = describe($dob, $ref_date);

Returns a human-readable age or age range for the supplied date of birth.

`describe()` accepts a date of birth in any of the formats supported by
["details"](#details) (year only, year-month, or full year-month-day).  An optional
reference date may also be provided; if omitted, the current local date is
used.

Because partial dates imply uncertainty, the routine may return either a
single age (e.g. `"72"`) or an age range (e.g. `"72-73"`).  Year-only and
year-month dates can span a range of possible birthdays, and therefore a
range of possible ages.

Examples:

    describe('1943');     # e.g. '80-81'
    describe('1943-05', '2016');  # '72-73'
    describe('1943-05-01', '2016-01-01');  # '72'

This routine is a convenience wrapper around `details()` that returns only
the formatted range string.

## details

    my $info = details($dob);
    my $info = details($dob, $ref_date);

Returns a hashref describing the full computed age information.  This routine
performs the underlying date-range expansion and age calculation that
`describe()` relies on.

The returned hashref contains:

- `min_age`

    The minimum possible age based on the earliest possible birthday within the
    supplied date specification.

- `max_age`

    The maximum possible age based on the latest possible birthday.

- `range`

    A string representation of the age or age range, such as `"72"` or
    `"72-73"`.

- `precise`

    If the age is unambiguous (e.g. the date of birth and reference date are both
    fully specified), this is the exact age as an integer.  Otherwise it is
    `undef`.

Supported date formats for both `$dob` and `$ref_date` are:

- `YYYY` - year only (e.g. `1943`)
- `YYYY-MM` - year and month (e.g. `1943-05`)
- `YYYY-MM-DD` - full date (e.g. `1943-05-01`)

Invalid or unrecognised date strings will cause the routine to `croak()`.

Example:

    my $info = details('1943-05-01', '2016-01-01');

    # {
    #   min_age => 72,
    #   max_age => 72,
    #   range   => '72',
    #   precise => 72,
    # }

When the reference date is omitted, the current local date (YYYY-MM-DD) is
used.

# SEE ALSO

- Test coverage report: [https://nigelhorne.github.io/Date-Age/coverage/](https://nigelhorne.github.io/Date-Age/coverage/)

# REPOSITORY

[https://github.com/nigelhorne/Date-Age](https://github.com/nigelhorne/Date-Age)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-date-age at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Age](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Age).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Date::Age

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Date-Age](https://metacpan.org/dist/Date-Age)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Age](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Age)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Date-Age](http://matrix.cpantesters.org/?dist=Date-Age)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Date::Age](http://deps.cpantesters.org/?module=Date::Age)

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
