# NAME

DateTime::Format::Text - Find a Date in Text

# VERSION

Version 0.01

# SYNOPSIS

Find a date in any text.

    use DateTime::Format::Text;
    my $dft = DateTime::Format::Text->new();
    # ...

# SUBROUTINES/METHODS

## new

Creates a DateTime::Format::Text object.
Takes no arguments

## parse

Creates a DateTime::Format::Text object.
Returns a [DateTime](https://metacpan.org/pod/DateTime) object constructed from a date/time string embedding in aribitrary text.

Can be called as a class or object method.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

Based on https://github.com/etiennetremel/PHP-Find-Date-in-String.
Here's the author information from that:

    author   Etienne Tremel
    license  https://creativecommons.org/licenses/by/3.0/ CC by 3.0
    link     http://www.etiennetremel.net
    version  0.2.0

# BUGS

# SEE ALSO

    L<DateTime::Format::Natural>

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::Text

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Text](http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Text)

- CPAN Ratings

    [http://cpanratings.perl.org/d/DateTime-Format-Text](http://cpanratings.perl.org/d/DateTime-Format-Text)

- Search CPAN

    [http://search.cpan.org/dist/DateTime-Format-Text/](http://search.cpan.org/dist/DateTime-Format-Text/)

# LICENSE AND COPYRIGHT

Copyright 2019 Nigel Horne.

This program is released under the following licence: GPL2
