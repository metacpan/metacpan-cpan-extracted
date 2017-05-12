
package Catalyst::Model::RDF;

use Moose;
extends 'Catalyst::Model';

use Moose::Util::TypeConstraints;
use RDF::Trine::Model;

# ABSTRACT: RDF model class for Catalyst based on RDF::Trine::Model.
our $VERSION = '0.03'; # VERSION


class_type NamespaceMap => { class => 'RDF::Trine::NamespaceMap' };
coerce 'NamespaceMap', from 'HashRef',
    via { RDF::Trine::NamespaceMap->new(shift) };

has ns => (
    is       => 'ro',
    isa      => 'NamespaceMap',
    coerce   => 1,
    init_arg => 'namespaces',
    default  => sub { RDF::Trine::NamespaceMap->new },
);


subtype 'SerializerFormat', as 'Str',
    where { grep { lc $_ } RDF::Trine::Serializer->serializer_names };

has format => (
    is      => 'rw',
    isa     => 'SerializerFormat',
    lazy    => 1,
    default => 'rdfxml',
);


class_type TrineStore => { class => 'RDF::Trine::Store' };
coerce 'TrineStore', from 'HashRef',
    via { RDF::Trine::Store->new_with_config(shift) };

has store => (
    is     => 'ro',
    isa    => 'TrineStore',
    coerce => 1,
);

has _class => (
    is      => 'ro',
    isa     => 'RDF::Trine::Model',
    lazy    => 1, # hack to ensure store is created first
    default => sub {
        my $self = shift;
        return $self->store ? RDF::Trine::Model->new($self->store) :
            RDF::Trine::Model->temporary_model;
    },
    handles => qr/.*/
);

sub serializer {
    my ($self, $format) = @_;

    $format ||= $self->format;

    my $serializer = RDF::Trine::Serializer->new($format);

    $serializer->serialize_model_to_string($self->_class);
}

1;

__END__

=pod

=head1 NAME

Catalyst::Model::RDF - RDF model class for Catalyst based on RDF::Trine::Model.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    # on the shell
    $ myapp_create.pl model RDF

    # in myapp.conf
    <Model::RDF>
        format turtle

        <namespaces>
            rdf  http://www.w3.org/1999/02/22-rdf-syntax-ns\#
            dct  http://purl.org/dc/terms/
        </namespaces>

        # see documentation for RDF::Trine::Store, this structure
        # gets passed verbatim to `new_with_config'.
        <store>
            storetype DBI
            name      myapp
            dsn       dbi:Pg:dbname=rdf
            user      rdfuser
            password  suparsekrit
        </store>
    </Model::RDF>

=head1 DESCRIPTION

L<Catalyst::Model::RDF> is a thin proxy around L<RDF::Trine::Model>.
It can be initialized using the L<Catalyst> configuration file or
method. The following parameters are currently recognized:

=over 4

=item namespaces

=item format

Any name found in L<RDF::Trine::Serializer/serializer_names> (as of
this writing, this consists of C<ntriples>, C<nquads>, C<rdfxml>,
C<rdfjson>, C<turtle> and C<ntriples-canonical>).

=item store

A hash reference (or configuration file equivalent) that will be passed
directly to L<RDF::Trine::Store/new_with_config>.

=back

=head1 METHODS

In addition to proxying L<RDF::Trine::Model>, this module implements
the following accessors:

=head2 format

Get or set the default format (see L<RDF::Trine::Serializer>).

=head2 store

Retrieve the L<RDF::Trine::Store> object underpinning the model.

=head2 serializer

Serialize the C<$model> to RDF/C<$format>, returning the result as a string.

=head1 AUTHORS

=over 4

=item *

Thiago Rondon <thiago@aware.com.br>

=item *

Dorian Taylor <dorian@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Thiago Rondon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
