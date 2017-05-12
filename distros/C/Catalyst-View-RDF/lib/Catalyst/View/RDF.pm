
package Catalyst::View::RDF;

use Moose;
extends 'Catalyst::View';

use RDF::Simple::Serialiser;

# ABSTRACT: RDF view for your data
our $VERSION = '0.01'; # VERSION

has stash_key => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => 'triples'
);

has nodeid_prefix => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => 'a:'
);

has nss => (
    is        => 'rw',
    isa       => 'HashRef',
    lazy      => '1',
    predicate => 'has_nss',
    default   => sub { {} }
);

has encoding => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => 'utf-8'
);

sub process {
    my ( $self, $c ) = @_;

    my $ser =
      RDF::Simple::Serialiser->new( nodeid_prefix => $self->nodeid_prefix );

    $ser->addns( $self->nss ) if $self->has_nss;

    my $triples  = $c->stash->{ $self->stash_key };
    my $rdf      = $ser->serialise(@$triples);
    my $encoding = $self->encoding;

    $c->res->content_type("application/rdf; charset=$encoding");
    $c->res->output($rdf);
}
1;


=pod

=head1 NAME

Catalyst::View::RDF - RDF view for your data

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # lib/MyApp/View/RDF.pm
    package lib::MyApp::View::RDF;
    use base qw( Catalyst::View::RDF );
    1;

    # configure in lib/MyApp.pm
    MyApp->config({
        ...
        'View::RDF' => {
            nodeid_prefix => 'a:',
            nss => { foaf => 'http://xmlns.com/foaf/0.1/' },
            enconding => 'utf-8',
        },

    });

    sub foaf : Local {
        my ( $self, $c ) = @_;
        my @triples = (
            ['http://example.com/url#', 'dc:creator', 'zool@example.com'],
            ['http://example.com/url#', 'foaf:Topic', '_id:1234'],
            ['_id:1234','http://www.w3.org/2003/01/geo/wgs84_pos#lat','51.334422'],
            [$node1, 'foaf:name', 'Jo Walsh'],
            [$node1, 'foaf:knows', $node2],
            [$node2, 'foaf:name', 'Robin Berjon'],
            [$node1, 'rdf:type', 'foaf:Person'],
            [$node2, 'rdf:type','http://xmlns.com/foaf/0.1/Person']
            [$node2, 'foaf:url', \'http://server.com/NOT/an/rdf/uri.html'],
        );
        $c->stash->{triples} = \@triples;
        $c->forward('View::RDF');
    }

=head1 DESCRIPTION

Catalyst::View::RDF is a Catalyst View handler that returns stash
data in RDF format, based on L<RDF::Simple::Serialiser>.

=head1 AUTHOR

Thiago Rondon <thiago@aware.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Thiago Rondon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


