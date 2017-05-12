package AnyEvent::Pg;

our $VERSION = 0.15;

use 5.010;
use strict;
use warnings;
use Carp;

use AnyEvent;
use Method::WeakCallback qw(weak_method_callback_cached weak_method_callback);
use Pg::PQ qw(:pgres_polling);

our $debug;
$debug ||= 0;

sub _debug {
    my $self = shift;
    local ($!, $@, $ENV{__DIE__});
    my $state = $self->{state} // '<undef>';
    my $dbc = $self->{dbc} // '<undef>';
    my $fd = $self->{fd} // '<undef>';
    my $dbc_status = eval { $dbc->status } // '<undef>';
    my ($pkg, $file, $line, $method) = (caller 0);
    $method =~ s/.*:://;
    my $error = eval { $self->{dbc}->errorMessage } // '<undef>';
    $error =~ s/\n\s*/|/msg;
    my $r = defined $self->{read_watcher};
    my $w = defined $self->{write_watcher};
    warn "[$self seq: $self->{seq}, state: $state, dbc: $dbc, fd: $fd, error: $error, dbc_status: $dbc_status (r:$r/w:$w)]\@${pkg}::$method> @_ at $file line $line\n";
}

sub _check_state {
    my $self = shift;
    my $state = $self->{state};
    for (@_) {
        return if $_ eq $state;
    }
    my $upsub = (caller 1)[3];
    croak "$upsub can not be called in state $state";
}

sub _ensure_list { ref $_[0] ? @{$_[0]} : $_[0]  }

my $next_seq = 1;

sub new {
    my ($class, $conninfo, %opts) = @_;
    my $on_connect = delete $opts{on_connect};
    my $on_connect_error = delete $opts{on_connect_error};
    my $on_empty_queue = delete $opts{on_empty_queue};
    my $on_notify = delete $opts{on_notify};
    my $on_error = delete $opts{on_error};
    my $timeout = delete $opts{timeout};
    my $seq = delete($opts{seq}) // ($next_seq++);

    %opts and croak "unknown option(s) ".join(", ", keys %opts)." found";

    my $dbc = Pg::PQ::Conn->start($conninfo);
    # $dbc->trace(\*STDERR);
    # FIXME: $dbc may be undef
    my $self = { state => 'connecting',
                 dbc => $dbc,
                 on_connect => $on_connect,
                 on_connect_error => $on_connect_error,
                 on_error => $on_error,
                 on_empty_queue => $on_empty_queue,
                 on_notify => $on_notify,
                 queries => [],
                 timeout => $timeout,
                 seq => $seq,
                 call_on_empty_queue => 1,
               };
    bless $self, $class;
    &AE::postpone(weak_method_callback($self, '_connectPoll'));
    $self;
}

sub dbc { shift->{dbc} }

sub _connectPoll {
    my $self = shift;
    my $dbc = $self->{dbc};
    my $fd = $self->{fd};

    $debug and $debug & 1 and $self->_debug("enter");

    my ($r, $goto, $rw, $ww);
    if (defined $fd) {
        $r = $dbc->connectPoll;
    }
    else {
        $fd = $self->{fd} = $dbc->socket;
        if ($fd < 0) {
            $debug and $debug & 1 and $self->_debug("error");
            $self->_on_connect_error;
            return;
        }
        $r = PGRES_POLLING_WRITING;
    }

    $debug and $debug & 1 and $self->_debug("wants to: $r");
    if    ($r == PGRES_POLLING_READING) {
        $rw = $self->{read_watcher} // AE::io $fd, 0, weak_method_callback_cached($self, '_connectPoll');
        # say "fd: $fd, read_watcher: $rw";
    }
    elsif ($r == PGRES_POLLING_WRITING) {
        $ww = $self->{write_watcher} // AE::io $fd, 1, weak_method_callback_cached($self, '_connectPoll');
        # say "fd: $fd, write_watcher: $ww";
    }
    elsif ($r == PGRES_POLLING_FAILED) {
        $goto = '_on_connect_error';
    }
    elsif ($r == PGRES_POLLING_OK or
           $r == PGRES_POLLING_ACTIVE) {
        $goto = '_on_connect';
    }
    $self->{read_watcher} = $rw;
    $self->{write_watcher} = $ww;
    # warn "read_watcher: $rw, write_watcher: $ww";

    if ($goto) {
        delete $self->{timeout_watcher};
        $debug and $debug & 1 and $self->_debug("goto $goto");
        $self->$goto;
    }
    elsif ($self->{timeout}) {
        $self->{timeout_watcher} = AE::timer $self->{timeout}, 0, weak_method_callback_cached($self, '_connectPollTimeout');
    }
}

sub _connectPollTimeout {
    my $self = shift;
    $debug and $debug & 2 and $self->_debug("_connectPoll timed out");
    delete @{$self}{qw(timeout_watcher read_watcher write_watcher)};
    $self->{timedout} = 1;
    $self->_on_connect_error;
}

sub _maybe_callback {
    my $self = shift;
    my $obj = (ref $_[0] ? shift : $self);
    my $cb = shift;
    my $sub = $obj->{$cb};
    if (defined $sub and not $obj->{canceled}) {
        if ($debug & 2) {
            local ($@, $ENV{__DIE__});
            my $name = eval {
                require Devel::Peek;
                Devel::Peek::CvGV($sub)
                } // 'unknown';
            $self->_debug("calling $cb as $sub ($name)");
        }
        $sub->($self, @_);
    }
    else {
        $debug and $debug & 1 and $self->_debug("no callback for $cb");
    }
}

sub _on_connect {
    my $self = shift;
    my $dbc = $self->{dbc};
    $dbc->nonBlocking(1);
    $self->{state} = 'connected';
    $debug and $debug & 2 and $self->_debug('connected to database');
    $self->{read_watcher} = AE::io $self->{fd}, 0, weak_method_callback_cached($self, '_on_consume_input');
    $self->_maybe_callback('on_connect');
    delete @{$self}{qw(on_connect on_connect_error)};
    $self->_on_push_query;
}

sub _on_connect_error {
    my $self = shift;
    $debug and $debug & 2 and $self->_debug("connection failed");
    $self->_maybe_callback('on_connect_error');
    delete @{$self}{qw(on_connect on_connect_error)};
    $self->_on_fatal_error;
}

sub abort_all { shift->_on_fatal_error }

sub finish {
    my $self = shift;
    $self->_on_fatal_error;
}

sub _on_fatal_error {
    my $self = shift;
    $self->{state} = 'failed';
    delete @{$self}{qw(write_watcher read_watcher timeout_watcher
                       on_connect on_connect_error on_empty_query)};

    my $cq = delete $self->{current_query};
    $cq and $self->_maybe_callback($cq, 'on_error');
    my $queries = $self->{queries};
    $self->_maybe_callback($_, 'on_error') for @$queries;
    @$queries = ();
    $self->_maybe_callback('on_error', 1);
    $self->{dbc}->finish;
    delete $self->{dbc};
}

sub _push_query {
    my ($self, %opts) = @_;
    my %query;

    my $unshift = delete $opts{_unshift};
    my $type = $query{type} = delete $opts{_type};
    $debug and $debug & 1 and $self->_debug("pushing query of type $type");
    $query{$_} = delete $opts{$_} for qw(on_result on_error on_done on_timeout);
    if    ($type eq 'query') {
        my $query = delete $opts{query};
        my $args = delete $opts{args};
        $query{args} = [_ensure_list($query), ($args ? @$args : ())];
    }
    elsif ($type eq 'query_prepared') {
        my $name = delete $opts{name} // croak "name argument missing";
        my $args = delete $opts{args};
        $query{args} = [_ensure_list($name), ($args ? @$args : ())];
    }
    elsif ($type eq 'prepare') {
        my $name = delete $opts{name} // croak "name argument missing";
        my $query = delete $opts{query} // croak "query argument missing";
        $query{args} = [$name, $query];
    }
    else {
        die "internal error: unknown push_query type $type";
    }
    %opts and croak "unsupported option(s) ".join(", ", keys %opts);

    my $query = \%query;
    if ($unshift) {
        unshift @{$self->{queries}}, $query;
    }
    else {
        push @{$self->{queries}}, $query;
    }

    $self->{call_on_empty_queue} = 1;

    $self->{current_query} or &AE::postpone(weak_method_callback_cached($self, '_on_postponed_push_query'));

    AnyEvent::Pg::Watcher->_new($query);
}

sub _on_postponed_push_query {
    my $self = shift;
    $debug and $debug & 4 and $self->_debug("postponed call to _on_push_query");
    $self->_on_push_query
}

sub queue_size {
    my $self = shift;
    my $size = @{$self->{queries}};
    $size++ if $self->{current_query};
    $size
}

sub push_query { shift->_push_query(_type => 'query', @_) }

sub push_query_prepared { shift->_push_query(_type => 'query_prepared', @_) }

sub push_prepare { shift->_push_query(_type => 'prepare', @_) }

sub unshift_query { shift->_push_query(_type => 'query', _unshift => 1, @_) }

sub unshift_query_prepared { shift->_push_query(_type => 'query_prepared', _unshift => 1, @_) }

sub last_query_start_time { shift->{query_start_time} }

sub _on_push_query {
    my $self = shift;
    $debug and $debug & 4 and $self->_debug("_on_push_query");
    if ($self->{current_query}) {
        $debug and $debug & 2 and $self->_debug("there is already a query being processed ($self->{current_query})");
    }
    else {
        my $queries = $self->{queries};
        if ($self->{state} eq 'connected') {
            while (@$queries) {
                if ($queries->[0]{canceled}) {
                    $debug and $debug & 2 and $self->_debug("the query at the head of the queue was canceled, looking again!");
                    shift @$queries;
                    next;
                }
                $debug and $debug & 1 and $self->_debug("want to write query");
                $self->{write_watcher} = AE::io $self->{fd}, 1, weak_method_callback_cached($self, '_on_push_query_writable');
                $self->{timeout_watcher} = AE::timer $self->{timeout}, 0, weak_method_callback_cached($self, '_on_timeout')
                    if $self->{timeout};
                return;
            }

            if (delete $self->{call_on_empty_queue}) {
                # This sub may be called repeatly from calls stacked by
                # AE::postponed, so we don't call the 'on_empty_queue'
                # callback unless this (ugly) flag is set
                $self->_maybe_callback('on_empty_queue');
            }
            else {
                $debug and $debug & 1 and $self->_debug("skipping on_empty_queue callback");
            }
        }
        elsif ($self->{state} eq 'failed') {
            $debug and $debug & 1 and $self->_debug("calling on_error queries because we are in state failed");
            $self->_maybe_callback($_, 'on_error') for @$queries;
            @$queries = ();
        }
        else {
            $debug and $debug & 1 and $self->_debug("not processing queued queries because we are in state $self->{state}");
            # else, do nothing
        }
    }
}

my %send_type2method = (query => 'sendQuery',
                        query_prepared => 'sendQueryPrepared',
                        prepare => 'sendPrepare' );

sub _on_push_query_writable {
    my $self = shift;
    $debug and $debug & 1 and $self->_debug("can write");
    # warn "_on_push_query_writable";
    undef $self->{write_watcher};
    undef $self->{timeout_watcher};
    $self->{current_query} and die "Internal error: _on_push_query_writable called when there is already a current query";
    my $dbc = $self->{dbc};
    my $query = shift @{$self->{queries}};
    # warn "sendQuery('" . join("', '", @query) . "')";
    my $method = $send_type2method{$query->{type}} //
        die "internal error: no method defined for push type $query->{type}";
    if ($debug and $debug & 1) {
        my $args = "'" . join("', '", @{$query->{args}}) . "'";
        $self->_debug("calling $method($args)");
    }
    $self->{query_start_time} = AE::now;
    if ($dbc->$method(@{$query->{args}})) {
        $self->{current_query} = $query;
        $self->_on_push_query_flushable;
    }
    else {
        $debug and $debug & 1 and $self->_debug("$method failed: ". $dbc->errorMessage);
        $self->_maybe_callback('on_error');
        # FIXME: this is broken in some way, sanitize it!
        # FIXME: check if the error is recoverable or fatal before continuing...
        $self->_on_push_query
    }
}

sub _on_push_query_flushable {
    my $self = shift;
    my $dbc = $self->{dbc};
    my $ww = delete $self->{write_watcher};
    undef $self->{timeout_watcher};

    $debug and $debug & 1 and $self->_debug("flushing");
    my $flush = $dbc->flush;
    if   ($flush == -1) {
        $self->_on_fatal_error;
    }
    elsif ($flush == 0) {
        $debug and $debug & 1 and $self->_debug("flushed");
        $self->_on_consume_input;
    }
    elsif ($flush == 1) {
        $debug and $debug & 1 and $self->_debug("wants to write");
        $self->{write_watcher} = $ww // AE::io $self->{fd}, 1, weak_method_callback_cached($self, '_on_push_query_flushable');
        $self->{timeout_watcher} = AE::timer $self->{timeout}, 0, weak_method_callback_cached($self, '_on_timeout')
            if $self->{timeout};
    }
    else {
        die "internal error: flush returned $flush";
    }
}

sub _on_consume_input {
    my $self = shift;
    my $dbc = $self->{dbc};

    undef $self->{timeout_watcher};

    $debug and $debug & 1 and $self->_debug("looking for data");
    unless ($dbc->consumeInput) {
        $debug and $debug & 1 and $self->_debug("consumeInput failed");
        return $self->_on_fatal_error;
    }

    $debug and $debug & 2 and $self->_debug("looking for notifications");
    while (my @notify = $dbc->notifies) {
        $debug and $debug & 2 and $self->_debug("notify recived: @notify");
        $self->_maybe_callback(on_notify => @notify);
    }

    if (defined (my $cq = $self->{current_query})) {
        while (1) {
            if ($self->{write_watcher} or $dbc->busy) {
                $debug and $debug & 1 and $self->_debug($self->{write_watcher}
                                                        ? "wants to write and read"
                                                        : "wants to read");
                $self->{timeout_watcher} = AE::timer $self->{timeout}, 0, weak_method_callback_cached($self, '_on_timeout')
                    if $self->{timeout};
                return;
            }
            else {
                $debug and $debug & 1 and $self->_debug("data available");

                my $result = $dbc->result;
                if ($result) {
                    if ($debug and $debug & 2) {
                        my $status = $result->status // '<undef>';
                        my $conn_status = $dbc->status // '<undef>';
                        my $cmdRows = $result->cmdRows // '<undef>';
                        my $rows = $result->rows // '<undef>';
                        my $cols = $result->columns // '<undef>';
                        my $sqlstate = $result->errorField('sqlstate') // '<undef>';
                        $self->_debug("calling on_result status: $status, sqlstate: $sqlstate, conn status: $conn_status, cmdRows: $cmdRows, columns: $cols, rows: $rows");
                    }
                    $self->_maybe_callback($cq, 'on_result', $result);
                }
                else {
                    $debug and $debug & 2 and $self->_debug("calling on_done");
                    $self->_maybe_callback($cq, 'on_done');
                    undef $self->{current_query};
                    $self->_on_push_query;
                    return;
                }
            }
        }
    }
}

sub _on_timeout {
    my $self = shift;
    $debug and $debug & 2 and $self->_debug("operation timed out");
    # _on_fatal_error already deletes watchers
    # delete @{$self}{qw(read_watcher write_watcher timeout_watcher)};
    $self->{timedout} = 1;
    $self->_on_fatal_error
}

sub destroy {
    my $self = shift;
    %$self = ();
}

package AnyEvent::Pg::Watcher;

sub _new {
    my ($class, $query) = @_;
    my $self = \$query;
    bless $self, $class;
}

sub DESTROY {
    # cancel query
    my $query = ${shift()};
    delete @{$query}{qw(on_error on_result on_done)};
    $query->{canceled} = 1;
}

1;
__END__

=head1 NAME

AnyEvent::Pg - Query a PostgreSQL database asynchronously

=head1 SYNOPSIS

  use AnyEvent::Pg;
  my $db = AnyEvent::Pg->new("dbname=foo",
                             on_connect => sub { ... });

  $db->push_query(query => 'insert into foo (id, name) values(7, \'seven\')',
                  on_result => sub { ... },
                  on_error => sub { ... } );

  # Note that $1, $2, etc. are Pg placeholders, nothing to do with
  # Perl regexp captures!

  $db->push_query(query => ['insert into foo (id, name) values($1, $2)', 7, 'seven']
                  on_result => sub { ... }, ...);

  $db->push_prepare(name => 'insert_into_foo',
                    query => 'insert into foo (id, name) values($1, $2)',
                    on_result => sub { ... }, ...);

  $db->push_query_prepared(name => 'insert_into_foo',
                           args => [7, 'seven'],
                           on_result => sub { ... }, ...);

=head1 DESCRIPTION

  *******************************************************************
  ***                                                             ***
  *** NOTE: This is a very early release that may contain lots of ***
  *** bugs. The API is not stable and may change between releases ***
  ***                                                             ***
  *******************************************************************

This library allows to query PostgreSQL databases asynchronously. It
is a thin layer on top of L<Pg::PQ> that integrates it inside the
L<AnyEvent> framework.

=head2 API

The following methods are available from the AnyEvent::Pg class:

=over 4

=item $adb = AnyEvent::Pg->new($conninfo, %opts)

Creates and starts the connection to the database. C<$conninfo>
contains the parameters defining how to connect to the database (see
libpq C<PQconnectdbParams> and C<PQconnectdb> documentation for the
details:
L<http://www.postgresql.org/docs/9.0/interactive/libpq-connect.html>).

The following options are accepted:

=over 4

=item on_connect => sub { ... }

The given callback is invoked after the connection has been
successfully established.

=item on_connect_error => sub { ... }

This callback is invoked if a fatal error happens when establishing
the connection to the database server.

=item on_empty_queue => sub { ... }

This callback is called every time the query queue becomes empty.

=item on_notify => sub { ... }

This callback is called when a notification is received.

=item on_error => sub { ... }

This callback is called when some error happens.

=item timeout => $seconds

Sets the default timeout for network activity. When nothing happens on
the network for the given seconds while processing some query, the
connection is marked as dead.

=back

=item $w = $adb->push_query(%opts)

Pushes a query into the object queue that will eventually be
dispatched to the database.

Returns a query watcher object. Destroying the watcher (usually when
it gets unreferenced) cancels the query.

The accepted options are:

=over

=item query => $sql_query

The SQL query to be passed to the database

=item query => [$sql_query, @args]

A SQL query with placeholders ($1, $2, $3, etc.) and the arguments.

=item args => \@args

An alternative way to pass the arguments to a SQL query with placeholders.

=item on_error => sub { ... }

The given callback will be called when the query processing fails for
any reason.

=item on_result => sub { ... }

The given callback will be called for every result returned for the
given query.

You should expect one result object for every SQL statement on the
query.

The callback will receive as its arguments the AnyEvent::Pg and the
L<Pg::PQ::Result> object.

=item on_done => sub { ... }

This callback will be run after the last result from the query is
processed. The AnyEvent::Pg object is passed as an argument.

=back

=item $w = $adb->push_prepare(%opts)

Queues a query prepare operation for execution.

The accepted options are:

=over

=item name => $name

Name of the prepared query.

=item query => $sql

SQL code for the prepared query.

=item on_error => sub { ... }

=item on_result => sub { ... }

=item on_done => sub { ... }

These callbacks perform in the same fashion as on the C<push_query>
method.

=back

=item $w = $adb->push_query_prepared(%opts)

Queues a prepared query for execution.

The accepted options are:

=over 4

=item name => $name

Name of the prepared query.

=item args => \@args

Arguments for the query.

=item on_result => sub { ... }

=item on_done => sub { ... }

=item on_error => sub { ... }

These callbacks work as on the C<push_query> method.

=back

=item $w = $adb->unshift_query(%opts)

=item $w = $adb->unshift_query_prepared(%opts)

These method work in the same way as its C<push> counterparts, but
instead of pushing the query at the end of the queue they push
(unshift) it at the beginning to be executed just after the current
one is done.

This methods can be used as a way to run transactions composed of
several queries.

=item $adb->abort_all

Marks the connection as dead and aborts any queued queries calling the
C<on_error> callbacks.

=item $adb->queue_size

Returns the number of queries queued for execution.

=item $adb->finish

Closes the connection to the database and frees the associated
resources.

=item $adb->last_query_start_time

Returns the time at which processing for the last query started.

=back

=head1 SEE ALSO

L<Pg::PQ>, L<AnyEvent>, L<AnyEvent::Pg::Pool>.

L<AnyEvent::DBD::Pg> provides non-blocking access to a PostgreSQL
through L<DBD::Pg>, but note that L<DBD::Pg> does not provides a
complete asynchronous interface (for instance, establishing new
connections is always a blocking operation).

L<Protocol::PostgreSQL>: pure Perl implementation of the PostgreSQL
client-server protocol that can be used in non-blocking mode.

=head1 BUGS AND SUPPORT

This is a very early release that may contain lots of bugs.

Send bug reports by email or using the CPAN bug tracker at
L<https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=AnyEvent-Pg>.

=head2 Commercial support

This module was implemented during the development of QVD
(L<http://theqvd.com>) the Linux VDI platform.

Commercial support, professional services and custom software
development services around this module are available from QindelGroup
(L<http://qindel.com>). Send us an email with a rough description of your
requirements and we will get back to you ASAP.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2014 by Qindel FormaciE<oacute>n y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
