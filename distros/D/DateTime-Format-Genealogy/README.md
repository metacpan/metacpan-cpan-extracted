# NAME

DateTime::Format::Genealogy - Create a DateTime object from a Genealogy Date

# VERSION

Version 0.08

# SYNOPSIS

    use DateTime::Format::Genealogy;
    my $dtg = DateTime::Format::Genealogy->new();
    # ...

# SUBROUTINES/METHODS

## new

Creates a DateTime::Format::Genealogy object.

## parse\_datetime($string)

Given a date,
runs it through [Genealogy::Gedcom::Date](https://metacpan.org/pod/Genealogy%3A%3AGedcom%3A%3ADate) to create a [DateTime](https://metacpan.org/pod/DateTime) object.
If a date range is given, return a two element array in array context, or undef in scalar context

Returns undef if the date can't be parsed,
is before AD100,
is just a year or if it is an approximate date starting with "c", "ca" or "abt".
Can be called as a class or object method.

    my $dt = DateTime::Format::Genealogy->new()->parse_datetime('25 Dec 2022');

Optional arguments:
date: the date to be parsed
quiet: set to fail silently if there is an error with the date
strict: more strictly enforce the Gedcom standard, for example don't allow long month names

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

I can't get [DateTime::Format::Natural](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ANatural) to work on dates before AD100,
so this module rejects dates that old.

# SEE ALSO

[Genealogy::Gedcom::Date](https://metacpan.org/pod/Genealogy%3A%3AGedcom%3A%3ADate) and
[DateTime](https://metacpan.org/pod/DateTime)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::Genealogy

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Genealogy](http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Genealogy)

# LICENSE AND COPYRIGHT

Copyright 2018-2024 Nigel Horne.

This program is released under the following licence: GPL2
