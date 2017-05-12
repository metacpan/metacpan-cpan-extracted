package ArangoDB2::Replication;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;

my $JSON = JSON::XS->new->utf8;



###############
# API METHODS #
###############

# applierConfig
#
# GET /_api/replication/applier-config
# PUT /_api/replication/applier-config
sub applierConfig
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['configuration']);
    # build path
    my $path = $self->api_path('replication', 'applier-config');
    # make request
    return $args->{configuration}
        ? $self->arango->http->put($path, $args)
        : $self->arango->http->get($path);
}

# applierStart
#
# PUT /_api/replication/applier-start
sub applierStart
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['from']);
    # make request
    return $self->arango->http->put(
        $self->api_path('replication', 'applier-start'),
        $args,
    );
}

# applierState
#
# GET /_api/replication/applier-state
sub applierState
{
    my($self) = @_;
    # make request
    return $self->arango->http->get(
        $self->api_path('replication', 'applier-state'),
    );
}

# applierStop
#
# PUT /_api/replication/applier-stop
sub applierStop
{
    my($self) = @_;
    # make request
    return $self->arango->http->get(
        $self->api_path('replication', 'applier-stop'),
    );
}

# clusterInventory
#
# GET /_api/replication/clusterInventory
sub clusterInventory
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['includeSystem']);
    # make request
    return $self->arango->http->get(
        $self->api_path('replication', 'clusterInventory'),
        $args,
    );
}

# dump
#
# GET /_api/replication/dump
sub dump
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['chunkSize', 'collection', 'from', 'ticks', 'to']);
    # make request
    return $self->arango->http->get(
        $self->api_path('replication', 'dump'),
        $args,
    );
}

# inventory
#
# GET /_api/replication/inventory
sub inventory
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['includeSystem']);
    # make request
    return $self->arango->http->get(
        $self->api_path('replication', 'inventory'),
        $args,
    );
}

# loggerFollow
#
# GET /_api/replication/loggerFollow
sub loggerFollow
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['chunkSize', 'from', 'to']);
    # make request
    my $res = $self->arango->http->get(
        $self->api_path('replication', 'logger-follow'),
        $args,
        1, # get raw response
    ) or return;
    # build our own response
    my $ret = {};
    # response is newline separated JSON log entries
    $ret->{log} = [ map { $JSON->decode($_) } split(/\n/, $res->content) ];

    # get response header values
    $ret->{replication}->{active} = $res->header('x-arango-replication-active');
    $ret->{replication}->{checkmore} = $res->header('x-arango-replication-checkmore');
    $ret->{replication}->{lastincluded} = $res->header('x-arango-replication-lastincluded');
    $ret->{replication}->{lasttick} = $res->header('x-arango-replication-lasttick');

    return $ret;
}

# loggerState
#
# GET /_api/replication/loggerState
sub loggerState
{
    my($self) = @_;
    # make request
    return $self->arango->http->get(
        $self->api_path('replication', 'logger-state'),
    );
}

# serverId
#
# GET /_api/replication/server-id
sub serverId
{
    my($self) = @_;
    # make request
    return $self->arango->http->get(
        $self->api_path('replication', 'server-id'),
    );
}

# sync
#
# PUT /_api/replication/sync
sub sync
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['configuration']);
    # make request
    return $self->arango->http->put(
        $self->api_path('replication', 'sync'),
        $args,
    );
}


####################
# PROPERTY METHODS #
####################

# chunkSize
#
# get/set chunkSize
sub chunkSize { shift->_get_set('chunkSize', @_) }

# collection
#
# get/set collection
sub collection { shift->_get_set_name('collection', @_) }

# configuration
#
# get/set configuration
sub configuration { shift->_get_set('configuration', @_) }

# from
#
# get/set from
sub from { shift->_get_set('from', @_) }

# includeSystem
#
# get/set includeSystem
sub includeSystem { shift->_get_set('includeSystem', @_) }

# ticks
#
# get/set ticks
sub ticks { shift->_get_set_bool('ticks', @_) }

#
#
# get/set
sub to { shift->_get_set('', @_) }


1;

__END__

=head1 NAME

ArangoDB2::Replication - ArangoDB replication API methods

=head1 DESCRIPTION

=head1 API METHODS

=over 4

=item applierConfig

GET /_api/replication/applier-config
PUT /_api/replication/applier-config

Returns the configuration of the replication applier or sets the configuration of the replication applier.

Parameters:

    configuration

=item applierStart

PUT /_api/replication/applier-start

Starts the replication applier.

Parameters:

    from

=item applierState

GET /_api/replication/applier-state

Returns the state of the replication applier, regardless of whether the applier is currently running or not.

=item applierStop

PUT /_api/replication/applier-stop

Stops the replication applier.



=item clusterInventory

GET /_api/replication/clusterInventory

Returns the list of collections and indexes available on the cluster.

Parameters:

    includeSystem

=item dump

GET /_api/replication/dump

Returns the data from the collection for the requested range.

Parameters:

    chunkSize
    collection
    from
    ticks
    to

=item inventory

GET /_api/replication/inventory

Returns the list of collections and indexes available on the server. This list can be used by replication clients to initiate an initial sync with the server.

Parameters:

    includeSystem

=item loggerFollow

GET /_api/replication/logger-follow

Parameters:

    chunkSize
    from
    to

=item loggerState

GET /_api/replication/logger-state

Returns the current state of the server's replication logger.

=item serverId

GET /_api/replication/server-id

Returns the servers id. The id is also returned by other replication API methods, and this method is an easy means of determining a server's id.

=item sync

PUT /_api/replication/sync

Starts a full data synchronization from a remote endpoint into the local ArangoDB database.

Parameters:

    configuration

=back

=head1 PROPERTY METHODS

=over 4

=item chunkSize

Approximate maximum size of the returned result.

=item collection

The name or id of the collection to dump.  Accepts string or L<ArangoDB2::COllection> object.

=item configuration

JSON representation of the configuration

=item from

Lower bound tick value for results.

=item includeSystem

Include system collections in the result. The default value is false.

=item ticks

Whether or not to include tick values in the dump. Default value is true.

=item to

Upper bound tick value for results.

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
