package ArangoDB2::Graph::VertexCollection;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;

use ArangoDB2::Graph::Vertex;

my $JSON = JSON::XS->new->utf8;



# create
#
# POST /_api/gharial/graph-name/vertex
sub create
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, ['name']);
    # make request
    my $res = $self->arango->http->post(
        $self->api_path('gharial', $self->graph->name, 'vertex'),
        undef,
        $JSON->encode({collection => $args->{name}}),
    ) or return;
    # set name
    $self->name($args->{name});
    # update parent graph object with response data
    $self->graph->_build_self($res, ['edgeDefinitions', 'name', 'orphanCollections']);
    # register instance
    $self->graph->vertexCollections->{$self->name} = $self;

    return $self;
}

# delete
#
# DELETE /_api/gharial/graph-name/vertex/collection-name
sub delete
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, ['dropCollection', 'name']);
    # make request
    my $res = $self->arango->http->delete(
        $self->api_path('gharial', $self->graph->name, 'vertex', delete $args->{name}),
        $args,
    ) or return;
    # update parent graph object with response data
    $self->graph->_build_self($res, ['edgeDefinitions', 'name', 'orphanCollections']);
    # unregister instance
    delete $self->graph->vertexCollections->{$self->name};

    return $res;
}

# dropCollection
#
# get/set dropCollection
sub dropCollection { shift->_get_set_bool('dropCollection', @_) }

# list
#
# GET /_api/gharial/graph-name/vertex
sub list
{
    my($self) = @_;

    my $res = $self->arango->http->get(
        $self->api_path('gharial', $self->graph->name, 'vertex')
    ) or return;

    return $res->{collections};
}

# vertex
#
# return an ArangoDB2::Graph::Vertex object
sub vertex
{
    my($self, $name) = @_;

    if (defined $name) {
        return $self->vertices->{$name} ||= ArangoDB2::Graph::Vertex->new(
            $self->arango,
            $self->database,
            $self->graph,
            $self,
            $name,
        );
    }
    else {
        return ArangoDB2::Graph::Vertex->new(
            $self->arango,
            $self->database,
            $self->graph,
            $self,
        );
    }
}

# vertices
#
# index of ArangoDB2::Graph::Vertex objects by name
sub vertices { $_[0]->{vertices} ||= {} }

# _class
#
# internally treat this as a collection
sub _class { 'collection' }

1;

__END__

=head1 NAME

ArangoDB2::Graph::VertexCollection - ArangoDB vertex collection API methods

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item new

=item create

=item delete

=item dropCollection

=item list

=item vertex

=item vertices

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
