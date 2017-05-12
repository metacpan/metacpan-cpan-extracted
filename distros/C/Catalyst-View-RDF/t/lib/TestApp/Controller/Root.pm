package TestApp::Controller::Root;

use strict;
use warnings;

use base 'Catalyst::Controller';
use RDF::Simple::Serialiser;

__PACKAGE__->config( namespace => '' );

sub foo : Global {
    my ( $self, $c ) = @_;

    my $ser = RDF::Simple::Serialiser->new;

    my $node1 = $ser->genid;
    my $node2 = $ser->genid;

    $c->component('View::RDF');
    my @triples = (
            [ 'http://example.com/url#', 'dc:creator', 'zool@example.com' ],
            [ 'http://example.com/url#', 'foaf:Topic', '_id:1234' ],
            [
                '_id:1234', 'http://www.w3.org/2003/01/geo/wgs84_pos#lat',
                '51.334422'
            ],
            [ $node1, 'foaf:name',  'Jo Walsh' ],
            [ $node1, 'foaf:knows', $node2 ],
            [ $node2, 'foaf:name',  'Robin Berjon' ],
            [ $node1, 'rdf:type',   'foaf:Person' ],
            [ $node2, 'rdf:type',   'http://xmlns.com/foaf/0.1/Person' ],
            [ $node2, 'foaf:url',   \'http://server.com/NOT/an/rdf/uri.html' ],

    );
    $c->stash->{triples} = \@triples;
    $c->forward('View::RDF');
}

1;
