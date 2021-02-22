# NAME

AtteanX::Serializer::RDFa - RDFa Serializer for Attean

# SYNOPSIS

    use Attean;
    use Attean::RDF qw(iri);
    use URI::NamespaceMap;

    my $ser = Attean->get_serializer('RDFa')->new;
    my $string = $ser->serialize_iter_to_bytes($iter);

    my $ns = URI::NamespaceMap->new( { ex => iri('http://example.org/') });
    $ns->guess_and_add('foaf');
    my $note = RDF::RDFa::Generator::HTML::Pretty::Note->new(iri('http://example.org/foo'), 'This is a Note');
    my $ser = Attean->get_serializer('RDFa')->new(base => iri('http://example.org/'),
                                                                                                                             namespaces => $ns,
                                                                                                                             style => 'HTML::Pretty',
                                                                                                                             generator_options => { notes => [$note]});
    $ser->serialize_iter_to_io($fh, $iter);

# DESCRIPTION

This module can be used to serialize RDFa with several different
styles. It is implemented using [Attean](https://metacpan.org/pod/Attean) to wrap around
[RDF::RDFa::Generator](https://metacpan.org/pod/RDF::RDFa::Generator), which does the heavy lifting.  It composes
[Attean::API::TripleSerializer](https://metacpan.org/pod/Attean::API::TripleSerializer) and
[Attean::API::AbbreviatingSerializer](https://metacpan.org/pod/Attean::API::AbbreviatingSerializer).

# METHODS AND ATTRIBUTES

## Attributes

In addition to attributes required by [Attean::API::TripleSerializer](https://metacpan.org/pod/Attean::API::TripleSerializer)
that should not be a concern to users, the following attributes can be
set:

- `style`

    This attribute sets the serialization style used by
    [RDF::RDFa::Generator](https://metacpan.org/pod/RDF::RDFa::Generator), see its documentation for details.

- `namespaces`

    A HASH reference mapping prefix strings to [URI::NamespaceMap](https://metacpan.org/pod/URI::NamespaceMap)
    objects. [RDF::RDFa::Generator](https://metacpan.org/pod/RDF::RDFa::Generator) will help manage this map, see its
    documentation for details.

- `base`

    An [Attean::API::IRI](https://metacpan.org/pod/Attean::API::IRI) object representing the base against which
    relative IRIs in the serialized data should be resolved. There is some
    support in [RDF::RDFa::Generator](https://metacpan.org/pod/RDF::RDFa::Generator), but currently, it doesn't do much.

- `generator_options`

    A HASH reference that will be passed as options to
    [RDF::RDFa::Generator](https://metacpan.org/pod/RDF::RDFa::Generator)'s `create_document` method. This is typically
    options that are specific to different styles, see synopsis for
    example.

## Methods

This implements four required methods:

- `serialize_iter_to_io( $fh, $iterator )`

    Serializes the elements from the [Attean::API::Iterator](https://metacpan.org/pod/Attean::API::Iterator) `$iterator` to
    the [IO::Handle](https://metacpan.org/pod/IO::Handle) object `$fh`.

- `serialize_iter_to_bytes( $fh )`

    Serializes the elements from the [Attean::API::Iterator](https://metacpan.org/pod/Attean::API::Iterator) `$iterator`
    and returns the serialization as a UTF-8 encoded byte string.

- `media_types` and `file_extensions`

    Declares that HTML media types are used for the output of this module.

# BUGS

Please report any bugs to
[https://github.com/kjetilk/p5-atteanx-serializer-rdfa/issues](https://github.com/kjetilk/p5-atteanx-serializer-rdfa/issues).

# SEE ALSO

[RDF::RDFa::Generator](https://metacpan.org/pod/RDF::RDFa::Generator), [RDF::Trine::Serializer::RDFa](https://metacpan.org/pod/RDF::Trine::Serializer::RDFa).

# TODO

- The `style` attribute may be implemented with better constraints.
- Make the writers (i.e. the code actually writing the DOM) configurable.

# AUTHOR

Kjetil Kjernsmo <kjetilk@cpan.org>.

# COPYRIGHT AND LICENCE

This software is copyright (c) 2017, 2018, 2019, 2021 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
