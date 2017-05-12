package ArangoDB2::Graph::EdgeDefinition;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;

use ArangoDB2::Graph::Edge;

my $JSON = JSON::XS->new->utf8;



# create
#
# POST /_api/gharial/graph-name/edge
sub create
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, ['from', 'name', 'to']);
    # copy name to collection
    my $name = $args->{collection} = delete $args->{name};
    # make request
    my $res = $self->arango->http->post(
        $self->api_path('gharial', $self->graph->name, 'edge'),
        undef,
        $JSON->encode($args),
    ) or return;
    # set name
    $self->name($name);
    # update parent graph object with response data
    $self->graph->_build_self($res, ['edgeDefinitions', 'name', 'orphanCollections']);
    # register instance
    $self->graph->edgeDefinitionRegister->{$self->name} = $self;

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
        $self->api_path('gharial', $self->graph->name, 'edge', delete $args->{name}),
        $args,
    ) or return;
    # update parent graph object with response data
    $self->graph->_build_self($res, ['edgeDefinitions', 'name', 'orphanCollections']);
    # unregister instance
    delete $self->graph->edgeDefinitionRegister->{$self->name};

    return $res;
}

# dropCollection
#
# get/set dropCollection
sub dropCollection { shift->_get_set_bool('dropCollection', @_) }

# edge
#
# return an ArangoDB2::Graph::Edge object
sub edge
{
    my($self, $name) = @_;

    if (defined $name) {
        return $self->edges->{$name} ||= ArangoDB2::Graph::Edge->new(
            $self->arango,
            $self->database,
            $self->graph,
            $self,
            $name,
        );
    }
    else {
        return ArangoDB2::Graph::Edge->new(
            $self->arango,
            $self->database,
            $self->graph,
            $self,
        );
    }
}

# edges
#
# index of ArangoDB2::Graph::Edge objects by name
sub edges { $_[0]->{edges} ||= {} }

# from
#
# get/set from (collection/name)
sub from { shift->_get_set('from', @_) };

# list
#
# GET /_api/gharial/graph-name/edge
sub list
{
    my($self) = @_;

    my $res = $self->arango->http->get(
        $self->api_path('gharial', $self->graph->name, 'edge')
    ) or return;

    return $res->{collections};
}

# replace
#
# PUT /_api/gharial/graph-name/edge/definition-name
sub replace
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, ['from', 'name', 'to']);
    # copy name to collection
    my $name = $args->{collection} = delete $args->{name};
    # make request
    my $res = $self->arango->http->put(
        $self->api_path('gharial', $self->graph->name, 'edge', $self->name),
        undef,
        $JSON->encode($args),
    ) or return;
    # set name
    $self->name($name);
    # update parent graph object with response data
    $self->graph->_build_self($res, ['edgeDefinitions', 'name', 'orphanCollections']);
    # register instance
    $self->graph->edgeDefinitionRegister->{$self->name} = $self;

    return $self;
}

# to
#
# get/set from (collection/name)
sub to { shift->_get_set('to', @_) };

# _class
#
# internally we treat this as a collection
sub _class { 'collection' }

1;

__END__

=head1 NAME

ArangoDB2::Graph::EdgeDefinition - ArangoDB edge collection API methods

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item new

=item create

=item delete

=item dropCollection

=item edge

=item edges

=item from

=item list

=item replace

=item to

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
