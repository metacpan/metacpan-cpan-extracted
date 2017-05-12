package ArangoDB2::Admin;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use JSON::XS;

my $JSON = JSON::XS->new->utf8;



###############
# API METHODS #
###############

# echo
#
# GET /_admin/echo
sub echo
{
    my($self) = @_;
    # make request
    return $self->arango->http->get('/_admin/echo');
}

# execute
#
# POST /_admin/execute
sub execute
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['program','returnAsJSON']);
    my $program = delete $args->{program};
    # make request
    return $self->arango->http->post(
        '/_admin/execute',
        $args,
        $program,
    );
}

# log
#
# GET /_admin/log
sub log
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, [qw(
        upto level start size offset search sort
    )]);
    # make request
    return $self->arango->http->get('/_admin/log', $args);
}

# routingReload
#
# POST /_admin/routing/reload
sub routingReload
{
    my($self) = @_;
    # make request
    return $self->arango->http->post('/_admin/routing/reload');
}

# serverRole
#
# GET /_admin/server/role
sub serverRole
{
    my($self) = @_;
    # make request
    return $self->arango->http->get('/_admin/server/role');
}

# shutdown
#
# GET /_admin/shutdown
sub shutdown
{
    my($self) = @_;
    # make request
    return $self->arango->http->get('/_admin/shutdown');
}

# statistics
#
# GET /_admin/statistics
sub statistics
{
    my($self) = @_;
    # make request
    return $self->arango->http->get('/_admin/statistics');
}

# statisticsDescription
#
# GET /_admin/statistics-description
sub statisticsDescription
{
    my($self) = @_;
    # make request
    return $self->arango->http->get('/_admin/statistics-description');
}

# test
#
# POST /_admin/test
sub test
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['tests']);
    # make request
    return $self->arango->http->post('/_admin/test', $args->{tests});
}

# time
#
# GET /_admin/time
sub time
{
    my($self) = @_;
    # make request
    return $self->arango->http->get('/_admin/time');
}

# walFlush
#
# PUT /_admin/wal/flush
sub walFlush
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['waitForSync', 'waitForCollector']);
    # make request
    return $self->arango->http->put('/_admin/wal/flush', $args);
}

# walProperties
#
# GET /_admin/wal/properties
# PUT /_admin/wal/properties
sub walProperties
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, [qw(
        allowOversizeEntries logfileSize historicLogfiles
        reserveLogfiles throttleWait throttleWhenPending
    )]);
    # request path
    my $path = '/_admin/wal/properties';
    # make request
    return $args
        ? $self->arango->http->put($path, undef, $JSON->encode($args))
        : $self->arango->http->get($path);
}

####################
# PROPERTY METHODS #
####################

sub allowOversizeEntries { shift->_get_set_bool('allowOversizeEntries', @_) }
sub level { shift->_get_set('level', @_) }
sub logfileSize { shift->_get_set('logfileSize', @_) }
sub historicLogfiles { shift->_get_set('historicLogfiles', @_) }
sub offset { shift->_get_set('offset', @_) }
sub program { shift->_get_set('program', @_) }
sub reserveLogfiles { shift->_get_set('reserveLogfiles', @_) }
sub returnAsJSON { shift->_get_set_bool('returnAsJSON', @_) }
sub search { shift->_get_set('search', @_) }
sub size { shift->_get_set('size', @_) }
sub sort { shift->_get_set('sort', @_) }
sub start { shift->_get_set('start', @_) }
sub tests { shift->_get_set('tests', @_) }
sub throttleWait { shift->_get_set('throttleWait', @_) }
sub throttleWhenPending { shift->_get_set('throttleWhenPending', @_) }
sub upto { shift->_get_set('upto', @_) }
sub waitForCollector { shift->_get_set_bool('waitForCollector', @_) }
sub waitForSync { shift->_get_set_bool('waitForSync', @_) }

1;

__END__


=head1 NAME

ArangoDB2::Admin - ArangoDB admin API methods

=head1 API METHODS

=over 4

=item echo

GET /_admin/echo

Returns current request info.

=item execute

POST /_admin/execute

Executes the javascript code in the body on the server.

Parameters:

    program

=item log

GET /_admin/log

Returns the log files.

Parameters:

    upto
    level
    start
    size
    offset
    search
    sort

=item returnAsJSON

When executing program set to true to get a JSON object result.

=item routingReload

POST /_admin/routing/reload

Reloads the routing information from the collection routing.

=item statistics

GET /_admin/statistics

Returns the statistics information.

=item statisticsDescription

GET /_admin/statistics-description

Returns a description of the statistics returned by /_admin/statistics.

=item serverRole

GET /_admin/server/role

Returns the role of a server in a cluster.

=item shutdown

GET /_admin/shutdown

This call initiates a clean shutdown sequence.

=item test

POST /_admin/test

Executes the specified tests on the server and returns an object with the test results.

Parameters:

    tests

=item time

GET /_admin/time

The call returns an object with the attribute time.

=item walFlush

PUT /_admin/wal/flush

Flushes the write-ahead log.

Parameters:

    waitForSync
    waitForCollector

=item walProperties

GET /_admin/wal/properties
PUT /_admin/wal/properties

Configures the behavior of the write-ahead log.

Parameters:

    allowOversizeEntries
    logfileSize
    historicLogfiles
    reserveLogfiles
    throttleWait
    throttleWhenPending

=back

=head1 PROPERTY METHODS

=over 4

=item allowOversizeEntries

Whether or not operations that are bigger than a single logfile can be executed and stored.

=item level

Returns all log entries of log level level. Note that the URL parameters upto and level are mutually exclusive.

=item logfileSize

The size of each write-ahead logfile.

=item historicLogfiles

The maximum number of historic logfiles to keep.

=item offset

Starts to return log entries skipping the first offset log entries. offset and size can be used for pagination.

=item program

Code of javascript program to be executed.

=item reserveLogfiles

The maximum number of reserve logfiles that ArangoDB allocates in the background.

=item search

Only return the log entries containing the text specified in search.

=item size

Restricts the result to at most size log entries.

=item sort

Sort the log entries either ascending (if sort is asc) or descending (if sort is desc) according to their lid values. Note that the lid imposes a chronological order. The default value is asc.

=item start

Returns all log entries such that their log entry identifier (lid value) is greater or equal to start.

=item tests

A list of files containing the test suites to run.

=item throttleWait

The maximum wait time that operations will wait before they get aborted if case of write-throttling (in milliseconds).

=item throttleWhenPending

The number of unprocessed garbage-collection operations that, when reached, will activate write-throttling. A value of 0 means that write-throttling will not be triggered.

=item upto

Returns all log entries up to log level upto. Note that upto must be:

    fatal or 0
    error or 1
    warning or 2
    info or 3
    debug or 4

The default value is info.

=item waitForCollector

Whether or not the operation should block until the data in the flushed log has been collected.

=item waitForSync

Whether or not the operation should block until the not-yet synchronized data in the write-ahead log was synchronized to disk.

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


