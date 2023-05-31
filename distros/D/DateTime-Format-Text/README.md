# NAME

DateTime::Format::Text - Find a Date in Text

# VERSION

Version 0.04

# SYNOPSIS

Find a date in any text.

    use DateTime::Format::Text;
    my $dft = DateTime::Format::Text->new();
    # ...

# SUBROUTINES/METHODS

## new

Creates a DateTime::Format::Text object.
Takes no arguments

## parse\_datetime

Synonym for parse().

## parse

Returns a [DateTime](https://metacpan.org/pod/DateTime) object constructed from a date/time string embedded in
arbitrary text.

Can be called as a class or object method.

When called in an array context, returns an array containing all of the matches

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

Based on [https://github.com/etiennetremel/PHP-Find-Date-in-String](https://github.com/etiennetremel/PHP-Find-Date-in-String).
Here's the author information from that:

    author   Etienne Tremel
    license  L<https://creativecommons.org/licenses/by/3.0/> CC by 3.0
    link     L<http://www.etiennetremel.net>
    version  0.2.0

# BUGS

# SEE ALSO

[DateTime::Format::Natural](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ANatural)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::Text

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Text](http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Text)

- Search CPAN

    [http://search.cpan.org/dist/DateTime-Format-Text/](http://search.cpan.org/dist/DateTime-Format-Text/)

# LICENSE AND COPYRIGHT

Copyright 2019-2023 Nigel Horne.

This program is released under the following licence: GPL2
