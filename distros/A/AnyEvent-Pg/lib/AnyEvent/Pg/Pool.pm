package AnyEvent::Pg::Pool;

our $VERSION = '0.14';

use strict;
use warnings;
use 5.010;

use Carp qw(verbose croak);
use Data::Dumper;

use Method::WeakCallback qw(weak_method_callback);
use AnyEvent::Pg;
BEGIN {
    *debug = \$AnyEvent::Pg::debug;
    *_maybe_callback = \&AnyEvent::Pg::_maybe_callback;
};

our $debug;

sub _debug {
    my $pool = shift;
    my $connecting   = keys %{$pool->{connecting}};
    my $initializing = keys %{$pool->{initializing}};
    my $idle         = keys %{$pool->{idle}};
    my $busy         = keys %{$pool->{busy}};
    my $delayed      = ($pool->{delay_watcher} ? 1 : 0);
    my $total        = keys %{$pool->{conns}};
    local ($ENV{__DIE__}, $@);
    my ($pkg, $file, $line, $method) = (caller 0);
    $method =~ s/.*:://;
    warn "[$pool c:$connecting/i:$initializing/-:$idle/b:$busy|t:$total|d:$delayed]\@${pkg}::$method> @_ at $file line $line\n";
}

my %default = ( connection_retries => 3,
                connection_delay => 2,
                timeout => 30,
                size => 1 );

sub new {
    my ($class, $conninfo, %opts) = @_;
    $conninfo = { %$conninfo } if ref $conninfo;
    my $size = delete $opts{size} // $default{size};
    my $connection_retries = delete $opts{connection_retries} // $default{connection_retries};
    my $connection_delay = delete $opts{connection_delay} // $default{connection_delay};
    my $timeout = delete $opts{timeout} // $default{timeout};
    my $global_timeout = delete $opts{global_timeout};
    my $on_error = delete $opts{on_error} ;
    my $on_connect_error = delete $opts{on_connect_error};
    my $on_transient_error = delete $opts{on_transient_error};
    # my $on_empty_queue = delete $opts{on_empty_queue};
    my $pool = { conninfo => $conninfo,
                 size => $size,
                 on_error => $on_error,
                 on_connect_error => $on_connect_error,
                 on_transient_error => $on_transient_error,
                 # on_empty_queue => $on_empty_queue,
                 timeout => $timeout,
                 max_conn_retries => $connection_retries,
                 conn_retries => 0,
                 conn_delay => $connection_delay,
                 global_timeout => $global_timeout,
                 conns => {},
                 current => {},
                 busy => {},
                 idle => {},
                 connecting => {},
                 initializing => {},
                 init_queue_ix => {},
                 queue => [],
                 seq => 1,
                 query_seq => 1,
                 listener_by_channel => {},
                 listeners_by_conn => {},
               };
    bless $pool, $class;
    &AE::postpone(weak_method_callback($pool, '_on_start'));
    $pool;
}

sub is_dead { shift->{dead} }

sub set {
    my $pool = shift;
    while (@_) {
        my $k = shift;
        my $v = shift // $default{$k};
        if ($k eq 'global_timeout') {
            if (defined (my $gt = shift)) {
                $pool->{max_conn_time} += $gt - $pool->{global_timeout}
                    if defined $pool->{max_conn_time};
            }
            else {
                delete $pool->{max_conn_time};
            }
            $pool->{$k} = $v;
        }
    }
}

sub _on_start {}

sub push_query {
    my ($pool, %opts) = @_;
    my %query;
    my $retry_on_sqlstate = delete $opts{retry_on_sqlstate};
    $retry_on_sqlstate = { map { $_ => 1 } @$retry_on_sqlstate }
        if ref($retry_on_sqlstate) eq 'ARRAY';
    $query{retry_on_sqlstate} = $retry_on_sqlstate // {};
    $query{$_} = delete $opts{$_} for qw(on_result on_error on_done query args max_retries);
    $query{seq} = $pool->{query_seq}++;
    my $query = \%query;

    my $queue = ($opts{initialization} ? ($pool->{init_queue} //= []) : $pool->{queue});
    if (defined(my $priority = $opts{priority})) {
        $query{priority} = $priority;
        # FIXME: improve the search algorithm used here
        my $i;
        for ($i = 0; $i < @$queue; $i++) {
            my $p2 = $queue->[$i]{priority} // last;
            $p2 >= $priority or last;
        }
        splice @$queue, $i, 0, $query;
        $debug and $debug & 8 and $pool->_debug("query with priority $priority inserted into queue at position $i/$#$queue");
    }
    else {
        push @$queue, $query;
    }

    if ($opts{initialization}) {
        &AE::postpone(weak_method_callback($pool, '_check_init_queue_idle'));
        $debug and $debug & 8 and $pool->_debug('initialization query pushed into queue, queue size is now ' . scalar @$queue);
    }
    else {
        &AE::postpone(weak_method_callback($pool, '_check_queue'));
        $debug and $debug & 8 and $pool->_debug('query pushed into queue, raw queue size is now ' . scalar @$queue);
        return AnyEvent::Pg::Pool::QueryWatcher->_new($query)
            if defined wantarray;
    }
    ()
}

sub _postponed_on_listener_started_callback {
    my ($pool, $callback, $channel) = @_;
    # at this point, even if unlikey, the listener may be
    # not in state 'running' anymore, but we ignore that
    # possibility as the on_listener_started is just a
    # hint.
    $pool->_maybe_callback($callback, 'on_listener_started', $channel)
        unless $callback->{cancelled};
}

sub listen {
    my $pool = shift;
    my %opts = (@_ & 1 ? (channel => @_) : @_);
    my $channel = delete $opts{channel} // croak "channel tag missing";

    # As the channel goes passed unquoted into the SQL we ensure that
    # it is a valid identifier:
    $channel =~ /^[a-z]\w*$/i or croak "invalid listen channel";

    my $lbc = $pool->{listener_by_channel};

    my $callback = { on_notify           => delete $opts{on_notify},
                     on_listener_started => delete $opts{on_listener_started} };

    if (my $listener = $lbc->{$channel}) {
        push @{$listener->{callbacks}}, $callback;
        if ($listener->{state} eq 'running') {
            &AE::postpone(weak_method_callback($pool, '_postponed_on_listener_started_callback', $callback, $channel));
        }
    }
    else {
        $lbc->{$channel} = { seq       => $pool->{seq}++,
                             channel   => $channel,
                             callbacks => [$callback],
                             state     => 'new' };

        $pool->_start_listener($channel);
    }

    $debug and $debug & 8 and $pool->_debug("listener callback for channel $channel registered");
    return AnyEvent::Pg::Pool::ListenerWatcher->_new($callback)
        if defined wantarray;
}

sub _listener_check_callbacks {
    my ($pool, $channel) = @_;
    my $listener = $pool->{listener_by_channel}{$channel}
        or die "internal error: listener for channel $channel not found";
    my $callbacks = $listener->{callbacks};
    @$callbacks = grep !$_->{canceled}, @$callbacks;
    $debug and $debug & 8 and $pool->_debug("there are " . scalar(@$callbacks) . " watchers for listener $channel");
    scalar @$callbacks;
}

sub _start_listener {
    my ($pool, $channel) = @_;

    if ($pool->{dead}) {
        $debug and $debug & 4 and $pool->_debug("ignoring listeners, the pool is dead");
        return;
    }
    if ($pool->_listener_check_callbacks($channel)) {
        my $qw = $pool->push_query( query => "listen $channel", # the channel can not be passed in a placeholder!
                                    on_result => weak_method_callback($pool, '_on_listen_query_result', $channel),
                                    on_error  => weak_method_callback($pool, '_start_listener', $channel) );

        my $listener = $pool->{listener_by_channel}{$channel}
            or die "internal error: listener for channel $channel not found";
        $listener->{state} = 'starting';
        $listener->{listen_query_watcher} = $qw;
    }
    else {
        # Just forget about this listener:
        delete $pool->{listener_by_channel}{$channel};
    }
}

sub _on_listen_query_result {
    my ($pool, $channel, undef, $conn, $result) = @_;

    my $seq = $conn->{seq};
    $debug and $debug & 8 and $pool->_debug("result for listen query is here, served by conn $seq. Conn: " . Dumper($conn));

    my $listener = $pool->{listener_by_channel}{$channel}
        or die "internal error: listener for channel $channel not found";

    delete $listener->{listen_query_watcher};
    $pool->{listeners_by_conn}{$seq}{$channel} = 1;
    $listener->{conn} = $seq;
    $listener->{state} = 'running';

    $debug and $debug & 4 and $pool->_debug("listeners_by_conn is now: " . Dumper($pool->{listeners_by_conn}));

    $pool->_run_listener_callbacks($channel, 'on_listener_started');
}

sub _stop_listener {
    my ($pool, $channel) = @_;
    if (my $listener = $pool->{listener_by_channel}{$channel}) {
        # We have to push the unlisten through the same connection were we do
        # the listen so we push the query directly there.
        if (my $conn = $pool->{conn}{$listener->{conn}}) {
            $listener->{state} = 'stopping';
            my $qw = $conn->push_query(query   => "unlisten $channel",
                                       on_done => weak_method_callback($pool, '_on_unlisten_query_done', $channel));
            $listener->{unlisten_query_watcher} = $qw;
        }
    }
}

sub _on_unlisten_query_done {
    my ($pool, $channel) = @_;
    if (my $listener = $pool->{listener_by_channel}{$channel}) {
        delete $listener->{unlisten_query_watcher};
        delete $pool->{listeners_by_conn}{$listener->{conn}}{$channel};
        $pool->_start_listener($channel)
    }
}

sub _on_notify {
    my ($pool, $conn, $seq, $channel, @more) = @_;
    $debug and $debug & 4 and $pool->_debug("notification for channel $channel received");
    $pool->_run_listener_callbacks($channel, 'on_notify', @more);
}

sub _run_listener_callbacks {
    my ($pool, $channel, $cbname, @more) = @_;
    if (my $listener = $pool->{listener_by_channel}{$channel}) {
        if ($listener->{state} eq 'running') {
            my $clean;
            my $callbacks = $listener->{callbacks};
            for my $cb (@$callbacks) {
                if ($cb->{canceled}) {
                    $clean = 1;
                }
                else {
                    $pool->_maybe_callback($cb, $cbname, $channel, @more);
                }
            }
            if ($clean) {
                unless ($pool->_listener_check_callbacks($channel)) {
                    $pool->_stop_listener($channel);
                }
            }
        }
    }
}

sub _is_queue_empty {
    my $pool = shift;
    my $queue = $pool->{queue};
    $debug and $debug & 8 and $pool->_debug('raw queue size is ' . scalar @$queue);
    while (@$queue) {
        return unless $queue->[0]{canceled};
        shift @$queue;
    }
    $debug and $debug & 8 and $pool->_debug('queue is empty');
    return 1;
}

sub _start_query {
    my ($pool, $seq, $query) = @_;
    my $conn = $pool->{conns}{$seq}
        or die("internal error, pool is corrupted, seq: $seq:\n" . Dumper($pool));
    my $watcher = $conn->push_query(query     => $query->{query},
                                    args      => $query->{args},
                                    on_result => weak_method_callback($pool, '_on_query_result', $seq),
                                    on_done   => weak_method_callback($pool, '_on_query_done',   $seq) );
    $pool->{current}{$seq} = $query;
    $query->{watcher} = $watcher;
    $debug and $debug & 8 and $pool->_debug("query $query started on conn $conn, seq: $seq");
}

sub _check_queue {
    my $pool = shift;
    my $idle = $pool->{idle};
    while (1) {
        $debug and $debug & 8 and $pool->_debug('checking queue, there are '
                                                . (scalar keys %$idle)
                                                . ' idle connections, queue size is '
                                                . (scalar @{$pool->{queue}}));
        if ($pool->_is_queue_empty) {
            $debug and $debug & 8 and $pool->_debug('queue is now empty');
            last;
        }
        $debug and $debug & 8 and $pool->_debug('processing first query from the queue');
        unless (%$idle) {
            if ($pool->{dead}) {
                my $query = shift @{$pool->{queue}};
                $pool->_maybe_callback($query, 'on_error');
                $debug and $debug & 8 and $pool->_debug('on_error called for query $query');
                next;
            }
            $debug and $debug & 8 and $pool->_debug('starting new connection');
            $pool->_start_new_conn;
            return;
        }
        keys %$idle;
        my ($seq) = each %$idle;
        delete $idle->{$seq};
        $pool->{busy}{$seq} = 1;

        my $query = shift @{$pool->{queue}};
        $pool->_start_query($seq, $query);
    }
    $debug and $debug & 8 and $pool->_debug('queue is empty!');
}

my %error_severiry_fatal = map { $_ => 1 } qw(FATAL PANIC);

sub _on_query_result {
    my ($pool, $seq, $conn, $result) = @_;
    my $query = $pool->{current}{$seq};
    if ($debug and $debug & 8) {
        $pool->_debug("query result $result received for query $query on connection $conn, seq: $seq");
        $result->status == Pg::PQ::PGRES_FATAL_ERROR and
            $pool->_debug("errorDescription:\n" . Dumper [$result->errorDescription]);
    }
    if ($query->{retry}) {
        $debug and $debug & 8 and $pool->_debug("retry is set, ignoring later on_result");
    }
    else {
        if ($query->{max_retries} and $result->status == Pg::PQ::PGRES_FATAL_ERROR) {
            if ($query->{retry_on_sqlstate}{$result->errorField('sqlstate')}) {
                $pool->_debug("this is a retry-able error, skipping the on_result callback");
                $query->{retry} = 1;
                return;
            }
            if ($error_severiry_fatal{$result->errorField('severity')}) {
                $pool->_debug("this is a real FATAL error, skipping the on_result callback");
                $query->{retry} = 1;
                return;
            }
        }
        $query->{max_retries} = 0;
        $pool->_maybe_callback($query, 'on_result', $conn, $result);
    }
}

sub _requeue_query {
    my ($pool, $query) = @_;
    $query->{priority} = 0 + 'inf';
    unshift @{$pool->{queue}}, $query;
}

sub _on_query_done {
    my ($pool, $seq, $conn) = @_;
    my $query = delete $pool->{current}{$seq};
    if (delete $query->{retry}) {
        $debug and $debug & 8 and $pool->_debug("unshifting failed query into queue");
        $query->{max_retries}--;
        $pool->_requeue_query($query);
    }
    else {
        $pool->_maybe_callback($query, 'on_done', $conn);
    }
}

sub _start_new_conn {
    my $pool = shift;
    if (keys %{$pool->{conns}} < $pool->{size}             and
        !%{$pool->{connecting}}                            and
        $pool->{conn_retries} <= $pool->{max_conn_retries} and
        !$pool->{delay_watcher}) {
        my $seq = $pool->{seq}++;
        $debug and $debug & 8 and $pool->_debug("starting new connection, seq: $seq");
        my $conn = AnyEvent::Pg->new($pool->{conninfo},
                                     timeout => $pool->{timeout},
                                     on_connect => weak_method_callback($pool, '_on_conn_connect', $seq),
                                     on_connect_error => weak_method_callback($pool, '_on_conn_connect_error', $seq),
                                     on_empty_queue => weak_method_callback($pool, '_on_conn_empty_queue', $seq),
                                     on_error => weak_method_callback($pool, '_on_conn_error', $seq),
                                     on_notify => weak_method_callback($pool, '_on_notify', $seq),
                                     seq => $seq,
                                    );
        $debug and $debug & 8 and $pool->_debug("new connection started, seq: $seq, conn: $conn");
        $pool->{conns}{$seq} = $conn;
        $pool->{connecting}{$seq} = 1;
    }
    else {
        $debug and $debug & 8 and $pool->_debug('not starting new connection, conns: '
                                                . (scalar keys %{$pool->{conns}})
                                                . ", retries: $pool->{conn_retries}, connecting: "
                                                . (scalar keys %{$pool->{connecting}}));
    }
}

sub _on_conn_error {
    my ($pool, $seq, $conn) = @_;

    # note that failed initialization queries also come over here
    if (my $query = delete $pool->{current}{$seq}) {
        if ($query->{max_retries}-- > 0) {
            $pool->_requeue_query($query);
        }
        else {
            $pool->_maybe_callback($query, 'on_error', $conn);
        }
    }

    if ($debug and $debug & 8) {
        my @states = grep $pool->{$_}{$seq}, qw(busy idle connecting initializing);
        $pool->_debug("removing broken connection in state(s!) @states, "
                      . "\$conn: $conn, \$pool->{conns}{$seq}: "
                      . ($pool->{conns}{$seq} // '<undef>'));
    }
    delete $pool->{busy}{$seq}
        or delete $pool->{idle}{$seq}
            or delete $pool->{initializing}{$seq}
                or die "internal error, pool is corrupted, seq: $seq\n" . Dumper($pool);

    delete $pool->{init_queue_ix}{$seq};
    delete $pool->{conns}{$seq};

    my $listeners = delete $pool->{listeners_by_conn}{$seq};

    if ($pool->{dead}) {
        $pool->_maybe_callback('on_connect_error', $conn);
    }
    else {
        $pool->_maybe_callback('on_transient_error');

        if ($listeners) {
            $pool->_start_listener($_) for keys %$listeners;
        }
        else {
            $debug and $debug & 4 and $pool->_debug("connection $seq had no listeners attached: " .
                                                    Dumper($pool->{listeners_by_conn}));
        }
    }

    $pool->_check_queue;
}

sub _on_conn_connect {
    my ($pool, $seq, $conn) = @_;
    $debug and $debug & 8 and $pool->_debug("conn $conn is now connected, seq: $seq");
    $pool->{conn_retries} = 0;
    delete $pool->{max_conn_time};
    # _on_conn_empty_queue is called afterwards by the $conn object
}

sub _on_conn_connect_error {
    my ($pool, $seq, $conn) = @_;
    $debug and $debug & 8 and $pool->_debug("unable to connect to database");

    $pool->_maybe_callback('on_transient_error');

    # the connection object will be removed from the Pool on the
    # on_error callback that will be called just after this one
    # returns:
    delete $pool->{connecting}{$seq};
    $pool->{busy}{$seq} = 1;

    if ($pool->{delay_watcher}) {
        $debug and $debug & 8 and $pool->_debug("a delayed reconnection is already queued");
        return;
    }

    my $now = time;
    # This failed connection is not counted against the limit
    # unless it is the only connection remaining. Effectively the
    # module will keep going until all the connections become
    # broken and no more connections can be established.
    unless (keys(%{$pool->{conns}}) > 1) {
        $pool->{conn_retries}++;
        if ($pool->{global_timeout}) {
            $pool->{max_conn_time} ||= $now + $pool->{global_timeout} - $pool->{conn_delay};
        }
    }

    if ($pool->{conn_retries} <= $pool->{max_conn_retries}) {
        if (not $pool->{max_conn_time} or $pool->{max_conn_time} >= $now) {
            $debug and $debug & 8 and $pool->_debug("starting timer for delayed reconnection $pool->{conn_delay}s");
            $pool->{delay_watcher} = AE::timer $pool->{conn_delay}, 0, weak_method_callback($pool, '_on_delayed_reconnect');
            return
        }
        $debug and $debug & 8 and $pool->_debug("global_timeout expired");
    }

    # giving up!
    $debug and $debug & 8 and $pool->_debug("it has been impossible to connect to the database, giving up!!!");
    $pool->{dead} = 1;

    # processing continues on the on_conn_error callback
}

sub _on_fatal_connect_error {
    my ($pool, $conn) = @_;
    # This error is fatal. After it happens, everything is going to
    # fail.
    $pool->{dead} = 1;

}

sub _on_delayed_reconnect {
    my $pool = shift;
    $debug and $debug & 8 and $pool->_debug("_on_delayed_reconnect called");
    undef $pool->{delay_watcher};
    $pool->_start_new_conn;
}

sub _check_init_queue_idle {
    my $pool = shift;
    my $idle = $pool->{idle};
    for my $seq (keys %$idle) {
        delete $idle->{$seq};
        $pool->_check_init_queue($seq);
    }
}

sub _check_init_queue {
    my ($pool, $seq) = @_;
    my $init_queue = $pool->{init_queue};
    no warnings 'uninitialized';
    return if $pool->{init_queue_ix}{$seq} >= @$init_queue;
    my $ix = $pool->{init_queue_ix}{$seq}++;
    my $query = { %{$init_queue->[$ix]} }; # clone
    $pool->{initializing}{$seq} = 1;
    $pool->_start_query($seq, $query);
    1;
}

sub _on_conn_empty_queue {
    my ($pool, $seq, $conn) = @_;
    $debug and $debug & 8 and $pool->_debug("conn $conn queue is now empty, seq: $seq");

    unless (delete $pool->{busy}{$seq} or
            delete $pool->{connecting}{$seq} or
            delete $pool->{initializing}{$seq}) {
        if ($debug) {
            $pool->_debug("pool object: \n" . Dumper($pool));
            die "internal error: empty_queue callback invoked by object not in state busy, connecting or initializing, seq: $seq";
        }
    }

    if (defined ($pool->{init_queue})) {
        $pool->_check_init_queue($seq) and return;
    }

    $pool->{idle}{$seq} = 1;
    $pool->_check_queue;
}


package AnyEvent::Pg::Pool::Watcher;

sub _new {
    my ($class, $obj) = @_;
    my $watcher = \$obj;
    bless $watcher, $class;
}

sub DESTROY {
    my $watcher = shift;
    my $obj = $$watcher // {};
    $obj->{canceled} = 1;
}

package AnyEvent::Pg::Pool::QueryWatcher;
our @ISA = ('AnyEvent::Pg::Pool::Watcher');

sub DESTROY {
    my $watcher = shift;
    my $obj = $$watcher // {};
    $obj->{canceled} = 1;
    # delete also the watcher for the slave query sent to the conn
    # object:
    delete $obj->{watcher};
}

package AnyEvent::Pg::Pool::ListenerWatcher;
our @ISA = ('AnyEvent::Pg::Pool::Watcher');


1;

=head1 NAME

AnyEvent::Pg::Pool

=head1 SYNOPSIS

  my $pool = AnyEvent::Pg::Pool->new($conninfo,
                                     on_connect_error => \&on_db_is_dead);

  my $qw = $pool->push_query(query => 'select * from foo',
                             on_result => sub { ... });

  my $lw = $pool->listen('bar',
                         on_notify => sub { ... });

=head1 DESCRIPTION

  *******************************************************************
  ***                                                             ***
  *** NOTE: This is a very early release that may contain lots of ***
  *** bugs. The API is not stable and may change between releases ***
  ***                                                             ***
  *******************************************************************

This module handles a pool of databases connections, and transparently
handles reconnection and reposting queries when network and server
errors occur.

=head2 API

The following methods are provided:

=over 4

=item $pool = AnyEvent::Pg::Pool->new($conninfo, %opts)

Creates a new object.

Accepts the following options:

=over 4

=item size => $size

Maximum number of database connections that can be simultaneously
established with the server.

=item connection_retries => $n

Maximum number of attempts to establish a new database connection
before calling the C<on_connect_error> callback when there is no other
connection alive on the pool.

=item connection_delay => $seconds

When establishing a new connection fails, this setting allows to
configure the number of seconds to delay before trying to connect
again.

=item timeout => $seconds

When some active connection does not report activity for the given
number of seconds, it is considered dead and closed.

=item global_timeout => $seconds

When all the connections to the database become broken and it is not
possible to establish a new connection for the given time period the
pool is considered dead and the C<on_error> callback will be called.

Note that this timeout is approximate. It is checked every time a new
connection attempt fails but its expiration will not cause the
abortion of an in-progress connection.

=item on_error => $callback

When some error happens that can not be automatically handled by the
module (for instance, by requeuing the current query), this callback
is invoked.

=item on_connect_error => $callback

When the number of failed reconnection attempts goes over the limit,
this callback is called. The pool object and the L<AnyEvent::Pg>
object representing the last failed attempt are passed as arguments.

=item on_transient_error => $callback

The given callback is invoked every time an internal recoverable error
happens (for instance, on of the pool connections fails or times out).

There is no guarantee about when this callback will be called and how
many times. It should be considered just a hint.

=back

=item $w = $pool->push_query(%opts)

Pushes a database query on the pool queue. It will be sent to the
database once any of the database connections becomes idle.

A watcher object is returned. If that watcher goes out of scope, the
query is canceled.

This method accepts all the options supported by the method of the
same name on L<AnyEvent::Pg> plus the following ones:

=over 4

=item retry_on_sqlstate => \@states

=item retry_on_sqlstate => \%states

A hash of sqlstate values that are retryable. When some error happens,
and the value of sqlstate from the result object has a value on this
hash, the query is reset and reintroduced on the query.

=item max_retries => $n

Maximum number of times a query can be retried. When this limit is
reached, the on_error callback will be called.

Note that queries are not retried after partial success. For instance,
when a result object is returned, but then the server decides to abort
the transaction (this is rare, but can happen from time to time).

=item priority => $n

This option allows to prioritize queries. The pool dispatches first those
with the highest priority value.

The default priority is -inf.

Queries of equal priority are dispatched in FIFO order.

=item initialization => $bool

When this option is set, the query will be invoked for every database
connection (both currently existing or created on the future) before
any other query.

It can be used to set up session parameters. For instance:

  $pool->push_query(initialization => 1,
                    query => "set session time zone 'UTC'");

Pushing initialization queries does not return a watcher object. Also,
once pushed, the current API does not allow removing them.

=back

The callbacks for the C<push_query> method receive as arguments the
pool object, the underlying L<AnyEvent::Pg> object actually handling
the query and the result object when applicable. For instance:

    sub on_result_cb {
        my ($pool, $conn, $result) = @_;
        ...
    }

    sub on_done_cb {
        my ($pool, $conn) = @_;
    }

    my $watcher = $pool->push_query("select * from foo",
                                    on_result => \&on_result_cb,
                                    on_done   => \&on_done_cb);

=item $w = $pool->listen($channel, %opts)

This method allows to subscribe to the given notification channel and
receive an event every time another sends a notification (see
PostgreSQL NOTIFY/LISTEN documentation).

The module will take care of keeping an active L<AnyEvent::Pg> connection
subscribed to the channel, recovering from errors automatically.

Currently, due to some limitations on the way the C<LISTEN> SQL
command is parsed, the channel selector has to match C</^[a-z]\w*$/i>.

The options accepted by the method are as follow:

=over 4

=item on_notify => $callback

The given callback will be called every time some client sends a
notification for the selected channel.

The arguments to the callback are the pool object, the channel
selector and any possible data load passed by the client sending the
notification.

=item on_listener_started => $callback

When the connection is started the first time, or when recovering from
some connection error, there may be a lapse of time where no
connection is subscribed to the channel and notifications sent by
other clients lost.

This callback is called every time a connection is subscribed to the
channel. It is really a hint that allows to check in some application
specific way (i.e. performing a select) that no event has been lost.

The arguments passed to the callback are the pool object and the
channel selector.

=back

=item $bool = $pool->is_dead

Returns a true value if the pool object has been marked as dead.

=item $pool->set($param1 => $value1, $param2 => $value2, ...);

Changes the values of pool parameters.

See the constructor documentation for the list of parameters that can
be changed.

=back

=head1 SEE ALSO

L<AnyEvent::Pg>, L<Pg::PQ>, L<AnyEvent>.

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

Copyright (C) 2012-2014 by Qindel FormaciE<oacute>n y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
