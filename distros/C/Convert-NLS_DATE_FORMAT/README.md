# NAME

Convert::NLS\_DATE\_FORMAT - Convert Oracle NLS\_DATE\_FORMAT <-> strftime Format Strings

# SYNOPSIS

    use Convert::NLS_DATE_FORMAT qw(oracle2posix posix2oracle);
    my $strptime = oracle2posix($NLS_DATE_FORMAT);
    $NLS_DATE_FORMAT = posix2oracle($strftime);

# DESCRIPTION

Convert Oracle's NLS\_DATE\_FORMAT string into a strptime format string, or
the reverse.

## Functions

- oracle2posix

    Takes an Oracle NLS\_DATE\_FORMAT string and converts it into formatting
    string compatible with `strftime` or `strptime`.

        my $format = oracle2posix('YYYY-MM-DD HH24:MI:SS'); # '%Y-%m-%d %H:%M:%S'

    Character sequences that should not be translated may be enclosed within
    double quotes, as specified in the Oracle documentation.

        my $format = oracle2posix('YYYY-MM-DD"T"HH24:MI:SS'); # '%Y-%m-%dT%H:%M:%S'

- posix2oracle

    Takes a `strftime` or `strptime` formatting string and converts it
    into an Oracle NLS\_DATE\_FORMAT string. _It is possible to create strings
    which Oracle will not accept as valid NLS\_DATE\_FORMAT strings._

        my $format = posix2oracle('%Y-%m-%d %H:%M:%S'); # 'YYYY-MM-DD HH24:MI:SS'

## EXPORT

None by default. `oracle2posix` and `posix2oracle` when asked.

# SEE ALSO

[DateTime::Format::Oracle](https://metacpan.org/pod/DateTime::Format::Oracle).

# AUTHOR

Nathan Gray, &lt;kolibrie@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2005, 2006, 2011, 2012, 2016 Nathan Gray

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.
