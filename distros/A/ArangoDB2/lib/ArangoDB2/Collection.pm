package ArangoDB2::Collection;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;

use ArangoDB2::Document;
use ArangoDB2::Edge;
use ArangoDB2::Index;

my $JSON = JSON::XS->new->utf8;

# params that can be set when creating collection
my @PARAMS = qw(
    doCompact isSystem isVolatile journalSize keyOptions name
    numberOfShards shardKeys type waitForSync
);



# checksum
#
# GET /_api/collection/{collection-name}/checksum
sub checksum
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['withData','withRevisions']);
    # make request
    return $self->arango->http->get(
        $self->api_path('collection', $self->name, 'checksum'),
        $args,
    );
}

# count
#
# get/set count
sub count { shift->_get_set_bool('count', @_) }

# create
#
# POST /_api/collection
#
# return self on success, undef on failure
sub create
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, \@PARAMS);
    # make request
    my $res = $self->arango->http->post(
        $self->api_path('collection'),
        undef,
        $JSON->encode($args),
    ) or return;
    # copy response data to instance
    $self->_build_self($res, [@PARAMS, 'id']);

    return $self;
}

# delete
#
# DELETE /_api/collection/{collection-name}
sub delete
{
    my($self) = @_;

    return $self->arango->http->delete(
        $self->api_path('collection', $self->name),
    );
}

# document
#
# get a specific ArangoDB2::Document by name (_key) or create a
# new blank ArangoDB2::Document
sub document
{
    my($self, $name) = @_;

    # if name (_key) is passed then instantiate a new
    # object with that name, which will retrieve the object
    if (defined $name) {
        return $self->documents->{$name} ||= ArangoDB2::Document->new(
            $self->arango,
            $self->database,
            $self,
            $name,
        );
    }
    # otherwise create a new empty document that can be used to
    # create a new document
    else {
        return ArangoDB2::Document->new(
            $self->arango,
            $self->database,
            $self,
        );
    }
}

# documents
#
# register of ArangoDB2::Document objects by name (_key)
sub documents { $_[0]->{documents} ||= {} }

# documentCount
#
# GET /_api/collection/{collection-name}/count
sub documentCount
{
    my($self) = @_;

    return $self->arango->http->get(
        $self->api_path('collection', $self->name, 'count'),
    );
}

# doCompact
#
# get/set doCompact
sub doCompact { shift->_get_set_bool('doCompact', @_) }

# edge
#
# get a specific ArangoDB2::Edge by name (_key) or create a
# new blank ArangoDB2::Edge
sub edge
{
    my($self, $name) = @_;

    # if name (_key) is passed then instantiate a new
    # object with that name, which will retrieve the object
    if (defined $name) {
        return $self->edges->{$name} ||= ArangoDB2::Edge->new(
            $self->arango,
            $self->database,
            $self,
            $name,
        );
    }
    # otherwise create a new empty document that can be used to
    # create a new document
    else {
        return ArangoDB2::Edge->new(
            $self->arango,
            $self->database,
            $self,
        );
    }
}

# edges
#
# register of ArangoDB2::Edge objects by name (_key)
sub edges { $_[0]->{edges} ||= {} }

# excludeSystem
#
# get/set excludeSystem
sub excludeSystem { shift->_get_set_bool('excludeSystem', @_) }

# figures
#
# GET /_api/collection/{collection-name}/figures
sub figures
{
    my($self) = @_;

    return $self->arango->http->get(
        $self->api_path('collection', $self->name, 'figures'),
    );
}

# index
#
# get an ArangoDB::Index by name or create new empty instance
sub index
{
    my($self, $name) = @_;

    # if name then create/retrieve named instance
    if (defined $name) {
        return $self->indexes->{$name} ||= ArangoDB2::Index->new(
            $self->arango,
            $self->database,
            $self,
            $name,
        );
    }
    # otherwise create a new empty instance
    else {
        return ArangoDB2::Index->new(
            $self->arango,
            $self->database,
            $self,
        );
    }
}

# indexes
#
# register of ArangoDB2::Index objects by name
sub indexes { $_[0]->{indexes} ||= {} }

# info
#
# GET /_api/collection/{collection-name}
sub info
{
    my($self) = @_;

    return $self->arango->http->get(
        $self->api_path('collection', $self->name),
    );
}

# isSystem
#
# get/set isSystem
sub isSystem { shift->_get_set_bool('isSystem', @_) }

# isVolatile
#
# get/set isVolatile
sub isVolatile { shift->_get_set_bool('isVolatile', @_) }

# journalSize
#
# get/set journalSize
sub journalSize { shift->_get_set('journalSize', @_) }

# keyOptions
#
# get/set keyOptions
sub keyOptions { shift->_get_set('keyOptions', @_) }

# list
#
# GET /_api/collection
sub list
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['excludeSystem']);
    # make request
    return $self->arango->http->get(
        $self->api_path('collection'),
        $args,
    );
}

# load
#
# PUT /_api/collection/{collection-name}/load
sub load
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['count']);
    # make request
    return $self->arango->http->put(
        $self->api_path('collection', $self->name, 'load'),
        $args,
    );
}

# numberOfShards
#
# get/set numberOfShards
sub numberOfShards { shift->_get_set('numberOfShards', @_) }

# properties
#
# GET /_api/collection/{collection-name}/properties
#
# or
#
# PUT /_api/collection/{collection-name}/properties
sub properties
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['journalSize', 'waitForSync']);
    # build path
    my $path = $self->api_path('collection', $self->name, 'properties');
    # make request
    my $res = %$args
        # if args are passed then set with PUT
        ? $self->arango->http->put($path, undef, $JSON->encode($args))
        # otherwise get properties
        : $self->arango->http->get($path);
    # copy response data to instance
    $self->_build_self($res, \@PARAMS);

    return $self;
}

# rename
#
# PUT /_api/collection/{collection-name}/rename
sub rename
{
    my($self, $args) = @_;
    # make a copy of current name
    my $old_name = $self->name;
    # process args
    $args = $self->_build_args($args, ['name']);

    my $res = $self->arango->http->put(
        $self->api_path('collection', $self->name, 'rename'),
        undef,
        $JSON->encode($args),
    );

    # if rename successful apply changes locally
    if ($res && $res->{name} eq $args->{name}) {
        # change internal name
        $self->name($res->{name});
        # unregister old name
        delete $self->database->collections->{$old_name};
        # register new name
        $self->database->collections->{ $res->{name} } = $self;
    }

    return $self;
}

# revision
#
# GET /_api/collection/{collection-name}/revision
sub revision
{
    my($self) = @_;

    return $self->arango->http->get(
        $self->api_path('collection', $self->name, 'revision'),
    );
}

# rotate
#
# PUT /_api/collection/{collection-name}/rotate
sub rotate
{
    my($self) = @_;

    return $self->arango->http->put(
        $self->api_path('collection', $self->name, 'rotate'),
    );
}

# shardKeys
#
# get/set shardKeys
sub shardKeys { shift->_get_set('shardKeys', @_) }

# truncate
#
# PUT /_api/collection/{collection-name}/truncate
sub truncate
{
    my($self) = @_;

    return $self->arango->http->put(
        $self->api_path('collection', $self->name, 'truncate'),
    );
}

# type
#
# get/set type
sub type { shift->_get_set('type', @_) }

# unload
#
# PUT /_api/collection/{collection-name}/unload
sub unload
{
    my($self) = @_;

    return $self->arango->http->put(
        $self->api_path('collection', $self->name, 'unload'),
    );
}

# waitForSync
#
# get/set waitForSync
sub waitForSync { shift->_get_set_bool('waitForSync', @_) }

# withData
#
# get/set withData
sub withData { shift->_get_set_bool('withData', @_) }

# withRevisions
#
# get/set withRevisions
sub withRevisions { shift->_get_set_bool('withRevisions', @_) }

# _class
#
# internal name for class
sub _class { 'collection' }

1;

__END__


=head1 NAME

ArangoDB2::Collection - ArangoDB collection API methods

=head1 METHODS

=over 4

=item new

=item checksum

=item count

=item create

=item delete

=item document

=item documents

=item documentCount

=item doCompact

=item edge

=item edges

=item excludeSystem

=item figures

=item index

=item indexes

=item info

=item isSystem

=item isVolatile

=item journalSize

=item keyOptions

=item list

=item load

=item numberOfShards

=item properties

=item rename

=item revision

=item rotate

=item shardKeys

=item truncate

=item type

=item unload

=item waitForSync

=item withData

=item withRevisions

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
