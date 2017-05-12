package ArangoDB2::Graph;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;

use ArangoDB2::Graph::EdgeDefinition;
use ArangoDB2::Graph::VertexCollection;
use ArangoDB2::Traversal;

my $JSON = JSON::XS->new->utf8;



# create
#
# POST /_api/gharial
sub create
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, ['edgeDefinitions', 'name', 'orphanCollections']);
    # make request
    my $res = $self->arango->http->post(
        $self->api_path('gharial'),
        undef,
        $JSON->encode($args),
    ) or return;
    # copy param data from res to self
    $self->_build_self($res, ['edgeDefinitions', 'name', 'orphanCollections']);
    # register instance
    $self->database->graphs->{$self->name} = $self;

    return $self;
}

# delete
#
# DELETE /_api/gharial/graph-name
sub delete
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, ['dropCollections', 'name']);
    # make request
    my $res = $self->arango->http->delete(
        $self->api_path('gharial', delete $args->{name}),
        $args,
    ) or return;

    # remove register instance
    delete $self->database->graphs->{$self->name};

    return $res;
}

# dropCollections
#
# get/set dropCollections
sub dropCollections { shift->_get_set('dropCollections', @_) }

# edgeDefinition
#
# return ArangoDB2::Graph::EdgeDefinition object
sub edgeDefinition
{
    my($self, $name) = @_;

    if (defined $name) {
        return $self->edgeDefinitionRegister->{name} ||= ArangoDB2::Graph::EdgeDefinition->new(
            $self->arango,
            $self->database,
            $self,
            $name,
        );
    }
    else {
        return ArangoDB2::Graph::EdgeDefinition->new(
            $self->arango,
            $self->database,
            $self,
        );
    }
}

# edgeDefinitionRegister
#
# index of ArangoDB2::Graph::EdgeDefinition objects by name
sub edgeDefinitionRegister { $_[0]->{edgeDefinitionRegister} ||= {} }

# edgeDefinitions
#
# get/set edgeDefinitions
sub edgeDefinitions { shift->_get_set('edgeDefinitions', @_) }

# get
#
# GET /_api/gharial/graph-name
sub get
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['name']);
    # make request
    my $res = $self->arango->http->get(
        $self->api_path('gharial', delete $args->{name})
    ) or return;
    # copy param data from res to self
    $self->_build_self($res, ['edgeDefinitions', 'name', 'orphanCollections']);
    # register instance
    $self->database->graphs->{$self->name} = $self;

    return $self;
}

# list
#
# GET /_api/gharial
sub list
{
    my($self) = @_;

    return $self->arango->http->get(
        $self->api_path('gharial')
    );
}

# orphanCollections
#
# get/set orphanCollections
sub orphanCollections { shift->_get_set('orphanCollections', @_) }

# traversal
#
# get a new ArangoDB2::Traversal object
sub traversal
{
    my($self) = @_;

    return ArangoDB2::Traversal->new(
        $self->arango,
        $self->database,
        $self,
    );
}

# vertexCollection
#
# return ArangoDB2::Graph::VertexCollection object
sub vertexCollection
{
    my($self, $name) = @_;

    if (defined $name) {
        return $self->vertexCollections->{name} ||= ArangoDB2::Graph::VertexCollection->new(
            $self->arango,
            $self->database,
            $self,
            $name,
        );
    }
    else {
        return ArangoDB2::Graph::VertexCollection->new(
            $self->arango,
            $self->database,
            $self,
        );
    }
}

# vertexCollections
#
# index of ArangoDB2::Graph::VertexCollection objects by name
sub vertexCollections { $_->{vertexCollections} ||= {} }

# _class
#
# internal name for class
sub _class { 'graph' }

1;

__END__

=head1 NAME

ArangoDB2::Graph - ArangoDB graph API methods

=head1 DESCRIPTION

ArangoDB2::Graph implements the "General Graph" API (/_api/gharial) and not
the deprecated "Graphs" API (/_api/graph).  In order to make things more
intuitive this is named "Graph" instead of "Gharial."

=head1 METHODS

=over 4

=item new

=item create

=item delete

=item dropCollections

=item edgeDefinition

=item edgeDefinitionRegister

=item edgeDefinitions

=item get

=item list

=item orphanCollections

=item traversal

=item vertex

=item vertexCollection

=item vertexCollections

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
