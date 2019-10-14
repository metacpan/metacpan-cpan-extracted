package Catmandu::PNX;

=encoding utf8

=head1 NAME

Catmandu::PNX - Modules for handling PNX data within the Catmandu framework

=head1 SYNOPSIS

Command line client C<catmandu>:

  catmandu convert PNX to JSON --fix myfixes.txt < data/pnx.xml > data/pnx.json

  catmandu convert JSON to PNX --fix myfixes.txt < data/pnx.json > data/pnx.xml

See documentation of modules for more examples.

=head1 DESCRIPTION

Catmandu::PNX contains modules to handle PNX an
XML Schema for Ex Libris' Primo search engine.

=head1 AVAILABLE MODULES

=over

=item L<Catmandu::Exporter::PNX>

Serialize PNX data

=item L<Catmandu::Importer::PNX>

Parse PNX data

=back

=head1 SEE ALSO

This module is based on the L<Catmandu> framework and L<XML::Compile>.
For more information on Catmandu visit: http://librecat.org/Catmandu/
or follow the blog posts at: https://librecatproject.wordpress.com/

=head1 DISCLAIMER

 * I'm not a PNX expert.
 * This project was created as part of the L<Catmandu> project as an example PNX files can be generated from MARC, EAD and others.
 * All the heavy work is done by the excellent L<XML::Compile> package.
 * I invite other developers to contribute to this code.

=head1 BUGS, QUESTIONS HELP

Use the github issue tracker for any bug reports or questions on this module:
https://github.com/LibreCat/Catmandu-PNX/issues

=head1 AUTHOR

Patrick Hochstenbach, C<< patrick.hochstenbach at ugent.be >>

=head1 CONTRIBUTOR

Johann Rolschewski, C<< jorol at cpan.org >>

=head1 COPYRIGHT AND LICENSE

Patrick Hochstenbach, 2016 -

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

use Moo;

use XML::Compile;
use XML::Compile::Schema;
use XML::Compile::Util 'pack_type';

our $VERSION = '0.04';

has '_reader'    => (is => 'ro');
has '_writer'    => (is => 'ro');

sub BUILD {
    my ($self) = @_;

    XML::Compile->addSchemaDirs(__FILE__);

    my $schema = XML::Compile::Schema->new();

    $schema->importDefinitions('pnx.pm');

    $self->{_reader} = $schema->compile(READER => '{}record' );

    $self->{_writer} = $schema->compile(WRITER => '{}record' );

    $schema = undef;
}

sub parse {
    my ($self,$input) = @_;
    $self->_reader->($input);
}

sub to_xml {
    my ($self,$data) = @_;
    my $doc    = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $xml    = $self->_writer->($doc, $data);
    $doc->setDocumentElement($xml);
    $xml = $doc->toString(1);
    utf8::decode($xml);
    $xml;
}

1;
