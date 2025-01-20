# NAME

DateTime::Format::Text - Find a Date in Text

# VERSION

Version 0.10

# SYNOPSIS

Extract and parse date strings from arbitrary text.

    use DateTime::Format::Text;
    my $dft = DateTime::Format::Text->new();
    # ...

# SUBROUTINES/METHODS

## new

Creates a DateTime::Format::Text object.
Takes no arguments

## parse\_datetime

A synonym for parse().

## parse

Core function for extracting and parsing dates from text returning a [DateTime](https://metacpan.org/pod/DateTime) object.
It handles various date formats, such as:

- dd/mm/yyyy, dd-mm-yy, d m yyyy
- Sunday, 1 March 2015
- 1st March 2015

If direct parsing fails, attempt to use the [DateTime::Format::Flexible](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AFlexible) module as a last resort.

Can be called as a class or object method.

When called in an array context, returns an array containing all of the matches.

If the given test is an object, it's sent the message as\_string() and that is parsed

    use Class::Simple;
    my $foo = Class::Simple->new();
    $foo->as_string('25/12/2022');
    my $dt = $dft->parse($foo);

    # or

    print DateTime::Format::Text->parse('25 Dec 2021, 11:00 AM UTC')->epoch(), "\n";

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

Based on [https://github.com/etiennetremel/PHP-Find-Date-in-String](https://github.com/etiennetremel/PHP-Find-Date-in-String).
Here's the author information from that:

author   Etienne Tremel
license  [https://creativecommons.org/licenses/by/3.0/](https://creativecommons.org/licenses/by/3.0/) CC by 3.0
link     [http://www.etiennetremel.net](http://www.etiennetremel.net)
version  0.2.0

# BUGS

# SEE ALSO

[DateTime::Format::Flexible](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AFlexible),
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

Copyright 2019-2025 Nigel Horne.

This program is released under the following licence: GPL2
