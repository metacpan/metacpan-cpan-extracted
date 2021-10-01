# NAME

Data::Text - Class to handle text in an OO way

# VERSION

Version 0.05

# SYNOPSIS

Handle text in an OO way.

# SUBROUTINES/METHODS

## new

Creates a Data::Text object.

## append

Adds data to the end of the object.
Contains a simple sanity test for consecutive punctuation.
I expect I'll improve that.

Successful calls to append() can be daisy chained.

The argument can be a reference to an array of strings, or an object.
If called with an object, the message as\_string() is sent to it for its contents.

## as\_string

Returns the text as a string.

## length

Returns the length of the text.

## trim

Removes leading and trailing spaces from the string.

## rtrim

Removes trailing spaces from the string.

## replace

Replaces words.

    use Data::Text;

    my $dt = Data::Text->new();
    $dt->append('Hello World');
    $dt->replace({ 'Hello' => 'Goodbye dear' });
    print $dt->as_string(), "\n";       # Outputs "Goodbye dear world"

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

# SEE ALSO

[String::Clean](https://metacpan.org/pod/String%3A%3AClean), [String::Util](https://metacpan.org/pod/String%3A%3AUtil)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Text

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Data-Text](https://metacpan.org/release/Data-Text)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Text](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Text)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Data-Text](http://cpants.cpanauthors.org/dist/Data-Text)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Data-Text](http://matrix.cpantesters.org/?dist=Data-Text)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Data-Text](http://cpanratings.perl.org/d/Data-Text)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Data::Text](http://deps.cpantesters.org/?module=Data::Text)

# LICENSE AND COPYRIGHT

Copyright 2021 Nigel Horne.

This program is released under the following licence: GPL2
