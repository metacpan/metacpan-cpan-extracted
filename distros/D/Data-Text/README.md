# NAME

Data::Text - Class to handle text in an OO way

# VERSION

Version 0.17

# DESCRIPTION

`Data::Text` provides an object-oriented interface for managing and manipulating text content in Perl.
It wraps string operations in a class-based structure,
enabling clean chaining of methods like appending, trimming, replacing words, and joining text with conjunctions.
It supports flexible input types,
including strings, arrays, and other `Data::Text` objects,
and overloads common operators to allow intuitive comparisons and stringification.

# SYNOPSIS

    use Data::Text;

    my $d = Data::Text->new("Hello, World!\n");

    print $d->as_string();

# SUBROUTINES/METHODS

## new

Creates a Data::Text object.

The optional parameter contains a string, or object, to initialise the object with.

## set

Sets the object to contain the given text.

The argument can be a reference to an array of strings, or an object.
If called with an object, the message as\_string() is sent to it for its contents.

    $d->set({ text => "Hello, World!\n" });
    $d->set(text => [ 'Hello, ', 'World!', "\n" ]);

## append

Adds data given in "text" to the end of the object.
Contains a simple sanity test for consecutive punctuation.
I expect I'll improve that.

Successive calls to append() can be daisy chained.

    $d->set('Hello ')->append("World!\n");

The argument can be a reference to an array of strings, or an object.
If called with an object, the message as\_string() is sent to it for its contents.

## uppercase

Converts the text to uppercase.

    $d->uppercase();

## lowercase

Converts the text to lowercase.

    $d->lowercase();

## clear

Clears the text and resets internal state.

    $d->clear();

## equal

Are two texts the same?

    my $t1 = Data::Text->new('word');
    my $t2 = Data::Text->new('word');
    print ($t1 == $t2), "\n";   # Prints 1

## not\_equal

Are two texts different?

    my $t1 = Data::Text->new('xyzzy');
    my $t2 = Data::Text->new('plugh');
    print ($t1 != $t2), "\n";   # Prints 1

## as\_string

Returns the text as a string.

## length

Returns the length of the text.

## trim

Removes leading and trailing spaces from the text.

## rtrim

Removes trailing spaces from the text.

## replace

Replaces multiple words in the text.

    $dt->append('Hello World');
    $dt->replace({ 'Hello' => 'Goodbye', 'World' => 'Universe' });
    print $dt->as_string(), "\n";       # Outputs "Goodbye Universe"

## appendconjunction

Add a list as a conjunction.  See [Lingua::Conjunction](https://metacpan.org/pod/Lingua%3A%3AConjunction)
Because of the way Data::Text works with quoting,
this code works

    my $d1 = Data::Text->new();
    my $d2 = Data::Text->new('a');
    my $d3 = Data::Text->new('b');

    # Prints "a and b\n"
    print $d1->appendconjunction($d2, $d3)->append("\n");

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

There is no Unicode or UTF-8 support.

# SEE ALSO

[String::Util](https://metacpan.org/pod/String%3A%3AUtil), [Lingua::String](https://metacpan.org/pod/Lingua%3A%3AString)

# SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc Data::Text

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Data-Text](https://metacpan.org/release/Data-Text)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Text](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Text)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Data-Text](http://matrix.cpantesters.org/?dist=Data-Text)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Data::Text](http://deps.cpantesters.org/?module=Data::Text)

# LICENSE AND COPYRIGHT

Copyright 2021-2025 Nigel Horne.

This program is released under the following licence: GPL2
