# CommonMark::Massage

Manipulate CommonMark AST.

## Synopsis

    use CommonMark qw(:node :event);
    use CommonMark::Massage;

    my $parser = CommonMark::Parser->new;
    $parser->feed("Hello world");
    my $doc = $parser->finish;

    # Apply function to text nodes.
    my $doc->massage ( { NODE_TEXT => sub { ... } } );
    $doc->render_html;

## Description

The massage function can be used to manipulate the AST as produced by
the CommonMark parsers.

## Installation

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

## Support and Documentation

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-CommonMark-Massage.

You can find documentation for this module with the perldoc command.

    perldoc CommonMark::Massage

Please report any bugs or feature requests using the issue tracker on
GitHub.

## Copyright and Licence

Copyright (C) 2020 Johan Vromans

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

