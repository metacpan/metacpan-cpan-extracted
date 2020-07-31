# NAME

Acme::Unicodify - Convert ASCII text into look-somewhat-alike unicode

# VERSION

version 0.008

# SYNOPSIS

    my $translate = Acme::Unicodify->new();

    $foo = $translate->to_unicode('Hello, World');
    $bar = $translate->back_to_ascii($unified_string);

    file_to_unicode('/tmp/infile', '/tmp/outfile');
    file_back_to_ascii('/tmp/infile', '/tmp/outfile');

# DESCRIPTION

This is intended to translate basic 7 bit ASCII into characters
that use several Unicode features, such as accent marks and
non-Latin characters.  While this can be used just for fun, a
better use perhaps is to use it as part of a test suite, to
allow you to easily pass in Unicode and determine if your system
handles Unicode without corrupting the text.

# METHODS

## new

Create a new instance of the Unicodify object.

## to\_unicode($str)

Takes an input string and translates it into look-alike Unicode
characters.  Input is any string.

Basic ASCII leters are translated into Unicode "look alikes", while
any character (Unicode or not) is passed through unchanged.

## back\_to\_ascii($str)

Takes an input string that has perhaps previously been produced
by `to_unicode` and translates the look-alike characters back
into 7 bit ASCII.  Any other characters (Unicode or ASCII) are
passed through unchanged.

## file\_to\_unicode($infile, $outfile)

This method reads the file with the named passed as the first
argument, and produces a new output file with the name passed
as the second argument.

The routine will call `to_unicode` on the contents of the file.

Note this will overwrite existing files and it assumes the input
and output files are in UTF-8 encoding (or plain ASCII in the
case that no codepoints >127 are used).

This also assumes that there is sufficient memory to slurp the
entire contents of the file into memory.

## file\_back\_to\_ascii($infile, $outfile)

This method reads the file with the named passed as the first
argument, and produces a new output file with the name passed
as the second argument.

The routine will call `back_to_ascii` on the contents of the file.

Note this will overwrite existing files and it assumes the input
and output files are in UTF-8 encoding (or plain ASCII in the
case that no codepoints >127 are used).

# AUTHOR

Joelle Maslak <jmaslak@antelope.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015,2016,2017 by Joelle Maslak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
