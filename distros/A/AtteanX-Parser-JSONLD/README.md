# AtteanX::Parser::JSONLD

## JSONLD RDF Parser

## VERSION

This document describes AtteanX::Parser::JSONLD version 0.001.

## SYNOPSIS

    use Attean;
    my $parser = Attean->get_parser('JSONLD')->new();
    $parser->parse_cb_from_io( $fh );

## DESCRIPTION

This module implements a JSON-LD 1.11 RDF parser for [Attean](https://metacpan.org/pod/Attean).

## ROLES

This class consumes the following roles:

* Attean::API::MixedStatementParser
* Attean::API::AbbreviatingParser
* Attean::API::PullParser

## METHODS

`canonical_media_type`

Returns the canonical media type for JSON-LD: `application/ld+json`.

`media_types`

Returns a list of media types that may be parsed with the JSON-LD
parser: `application/ld+json`.

`file_extensions`

Returns a list of file extensions that may be parsed with the
parser.

`parse_iter_from_io( $fh )`

Returns an iterator of Attean::API::Binding objects that result from
parsing the data read from the IO::Handle object `$fh`.

`parse_cb_from_bytes( $data )`

Calls the `$parser->handler` function once for each
Attean::API::Binding object that result from parsing the data read
from the UTF-8 encoded byte string $data.

## BUGS

Please report any bugs or feature requests to through the GitHub web
interface at <https://github.com/kasei/atteanx-parser-jsonld/issues>.

## SEE ALSO

* <irc://irc.perl.org/#perlrdf>
* [Attean](https://metacpan.org/pod/Attean)
* [JSONLD](https://metacpan.org/pod/JSONLD)

## AUTHOR

Gregory Todd Williams <gwilliams@cpan.org>

## COPYRIGHT

Copyright (c) 2020--2020 Gregory Todd Williams. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.
