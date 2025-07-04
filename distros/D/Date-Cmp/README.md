# NAME

Date::Cmp - Compare two dates with approximate parsing support

# VERSION

Version 0.03

# SYNOPSIS

    use Date::Cmp qw(datecmp);

    my $date1 = '1914';
    my $date2 = '1918';
    my $cmp = datecmp($date1, $date2);

    # Optionally provide a complaint callback:
    $cmp = datecmp($date1, $date2, sub { warn @_ });

# DESCRIPTION

This module provides a single function, `datecmp`, which compares two date strings
or date-like objects, returning a numeric comparison similar to Perl's spaceship operator (`<=>`).

The comparison is tolerant of approximate dates (e.g. "Abt. 1902", "BET 1830 AND 1832", "Oct/Nov/Dec 1950"),
partial dates (years only), and strings with common genealogy-style formats. It attempts to normalize
and parse these into comparable values using [DateTime::Format::Genealogy](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AGenealogy).

# FUNCTIONS

## datecmp

    my $result = datecmp($left, $right);
    my $result = datecmp($left, $right, \&complain);

Compares two date strings or date-like objects and returns:

- -1 if `$left` is earlier than `$right`
- 0 if they are equivalent
- 1 if `$left` is later than `$right`

Parameters:

- `$left`, `$right`

    The values to compare. These may be strings in a variety of genealogical or ISO-style formats,
    or blessed objects that implement a `date()` method returning a date string.

- `$complain` (optional)

    A coderef that will be called with diagnostic messages when ambiguous or unexpected conditions are encountered,
    e.g. when comparing a range with equal endpoints.

# SUPPORTED FORMATS

The function supports a variety of partial or approximate formats including:

- Exact dates (e.g. `1941-08-02`, `5/27/1872`)
- Years only (e.g. `1828`)
- Approximate dates (e.g. `Abt. 1802`, `ca. 1802`, `1802 ?`)
- Date ranges (e.g. `1802-1803`, `BET 1830 AND 1832`)
- Month ranges (e.g. `Oct/Nov/Dec 1950`)
- Qualifiers like `BEF`, `AFT`

# ERROR HANDLING

In cases where a date cannot be parsed or compared meaningfully, diagnostic messages
will be printed to STDERR, and the function may die with an error. Callbacks and
stack traces are used to help identify parsing issues.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

[Sort::Key::DateTime](https://metacpan.org/pod/Sort%3A%3AKey%3A%3ADateTime)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-date-cmp at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Cmp](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Cmp).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Date::Cmp

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
