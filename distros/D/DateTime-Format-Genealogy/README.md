# NAME

DateTime::Format::Genealogy - Create a DateTime object from a Genealogy Date

# VERSION

Version 0.01

# SYNOPSIS

# SUBROUTINES/METHODS

## new

Creates a DateTime::Format::Genealogy object.

## parse\_datetime($string)

Given a date, runs it through [Genealogy::Gedcom::Date](https://metacpan.org/pod/Genealogy::Gedcom::Date) to create a [DateTime](https://metacpan.org/pod/DateTime) object.
If a date range is given, return a two element array in array context, or undef in scalar context

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

# SEE ALSO

[Genealogy::Gedcom::Date](https://metacpan.org/pod/Genealogy::Gedcom::Date) and
[DateTime](https://metacpan.org/pod/DateTime)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::Gedcom

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Gedcom](http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Gedcom)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/DateTime-Format-Gedcom](http://annocpan.org/dist/DateTime-Format-Gedcom)

- CPAN Ratings

    [http://cpanratings.perl.org/d/DateTime-Format-Gedcom](http://cpanratings.perl.org/d/DateTime-Format-Gedcom)

- Search CPAN

    [http://search.cpan.org/dist/DateTime-Format-Gedcom/](http://search.cpan.org/dist/DateTime-Format-Gedcom/)

# LICENSE AND COPYRIGHT

Copyright 2018 Nigel Horne.

This program is released under the following licence: GPL
