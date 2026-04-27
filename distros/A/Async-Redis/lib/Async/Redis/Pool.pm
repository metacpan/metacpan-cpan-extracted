package Async::Redis::Pool;

use strict;
use warnings;
use 5.018;

use Future;
use Future::AsyncAwait;
use Future::IO;
use Scalar::Util qw(refaddr);
use Async::Redis;
use Async::Redis::Error::Disconnected;
use Async::Redis::Error::Timeout;

sub new {
    my ($class, %args) = @_;

    # Separate pool-specific args from connection args.
    # Everything not pool-specific is passed through to Async::Redis->new().
    my %pool_args;
    for my $key (qw(min max acquire_timeout idle_timeout cleanup_timeout on_dirty)) {
        $pool_args{$key} = delete $args{$key} if exists $args{$key};
    }

    my $self = bless {
        # Connection params (passed through to Async::Redis->new)
        _conn_args => \%args,

        # Pool sizing
        min => $pool_args{min} // 1,
        max => $pool_args{max} // 10,

        # Timeouts
        acquire_timeout  => $pool_args{acquire_timeout} // 5,
        idle_timeout     => $pool_args{idle_timeout} // 60,
        cleanup_timeout  => $pool_args{cleanup_timeout} // 5,

        # Dirty handling
        on_dirty => $pool_args{on_dirty} // 'destroy',

        # Pool state
        _idle     => [],   # Available connections
        _active   => {},   # Connections in use (refaddr => conn)
        _waiters  => [],   # Futures waiting for connection
        _shutdown => 0,    # Set by shutdown(); blocks new acquires
        _pending         => [],   # Background futures (creation, cleanup)
        _creating        => 0,    # Connections currently being created
        _total_created   => 0,
        _total_destroyed => 0,

        # Fork safety
        _pid => $$,
    }, $class;

    return $self;
}

# Accessors
sub min { shift->{min} }
sub max { shift->{max} }

# Statistics
sub stats {
    my ($self) = @_;

    return {
        active    => scalar keys %{$self->{_active}},
        idle      => scalar @{$self->{_idle}},
        waiting   => scalar @{$self->{_waiters}},
        total     => (scalar keys %{$self->{_active}}) + (scalar @{$self->{_idle}}),
        destroyed => $self->{_total_destroyed},
    };
}

# Check if fork occurred and clear pool
sub _check_fork {
    my ($self) = @_;

    if ($self->{_pid} && $self->{_pid} != $$) {
        # Fork detected - invalidate all connections
        $self->_clear_all_connections;
        $self->{_pid} = $$;
        return 1;
    }

    return 0;
}

# Clear all connections (called after fork)
sub _clear_all_connections {
    my ($self) = @_;

    # Clear idle connections without closing (parent owns the sockets)
    $self->{_idle} = [];

    # Clear active connection tracking (caller still has reference)
    $self->{_active} = {};

    # Cancel waiters
    for my $waiter (@{$self->{_waiters}}) {
        $waiter->fail("Pool invalidated after fork") unless $waiter->is_ready;
    }
    $self->{_waiters} = [];

    # Clear pending futures and creation counter
    $self->{_pending} = [];
    $self->{_creating} = 0;
}

# Acquire a connection from the pool
async sub acquire {
    my ($self) = @_;

    if ($self->{_shutdown}) {
        die Async::Redis::Error::Disconnected->new(
            message => "Pool is shut down",
        );
    }

    # Check for fork - clear pool if PID changed
    $self->_check_fork;

    # Try to get an idle connection
    while (@{$self->{_idle}}) {
        my $conn = shift @{$self->{_idle}};

        # Health check
        my $healthy = await $self->_health_check($conn);
        if ($healthy) {
            $self->{_active}{refaddr($conn)} = $conn;
            return $conn;
        }

        # Unhealthy - destroy and try next
        $self->_destroy_connection($conn);
    }

    # No idle connections - can we create a new one?
    # Include _creating count to prevent concurrent acquires from exceeding max
    my $current_total = (scalar keys %{$self->{_active}})
                      + (scalar @{$self->{_idle}})
                      + $self->{_creating};

    if ($current_total < $self->{max}) {
        $self->{_creating}++;
        my $conn;
        eval {
            $conn = await $self->_create_connection;
        };
        my $error = $@;
        $self->{_creating}--;

        if ($error) {
            die $error;
        }

        $self->{_active}{refaddr($conn)} = $conn;
        return $conn;
    }

    # At max capacity - wait for release
    my $waiter = Future->new;
    push @{$self->{_waiters}}, $waiter;

    my $timeout_future = Future::IO->sleep($self->{acquire_timeout})->then(sub {
        Future->fail(Async::Redis::Error::Timeout->new(
            message => "Acquire timed out after $self->{acquire_timeout}s",
            timeout => $self->{acquire_timeout},
        ));
    });

    my $wait_f = Future->wait_any($waiter, $timeout_future);

    my $result;
    eval {
        $result = await $wait_f;
    };
    my $error = $@;

    # If waiter was cancelled by timeout, remove from queue
    if (!$waiter->is_done) {
        @{$self->{_waiters}} = grep { $_ != $waiter } @{$self->{_waiters}};
    }

    die $error if $error;
    return $result;
}

# Release a connection back to the pool
sub release {
    my ($self, $conn) = @_;

    return unless defined $conn;

    # Check for fork - if forked, don't return to pool
    if ($self->_check_fork) {
        # Pool was cleared, just drop this connection
        return;
    }

    my $id = refaddr($conn);
    unless (exists $self->{_active}{$id}) {
        warn "Pool: release called on unknown or already-released connection";
        return;
    }
    delete $self->{_active}{$id};

    # After shutdown, destroy instead of pooling
    if ($self->{_shutdown}) {
        $self->_destroy_connection($conn);
        return;
    }

    # Check if connection is dirty
    if ($conn->is_dirty) {
        if ($self->{on_dirty} eq 'cleanup' && $self->_can_attempt_cleanup($conn)) {
            # Attempt cleanup asynchronously
            $self->_track_pending(
                $self->_cleanup_connection($conn)->on_done(sub {
                    $self->_return_to_pool($conn);
                })->on_fail(sub {
                    $self->_destroy_connection($conn);
                    $self->_maybe_create_replacement;
                })
            );
        }
        else {
            # Default: destroy and potentially replace
            $self->_destroy_connection($conn);
            $self->_maybe_create_replacement;
        }
        return;
    }

    # Clean connection - return to pool or give to waiter
    $self->_return_to_pool($conn);
}

sub _return_to_pool {
    my ($self, $conn) = @_;

    # Give to waiting acquirer if any
    if (@{$self->{_waiters}}) {
        my $waiter = shift @{$self->{_waiters}};
        $self->{_active}{refaddr($conn)} = $conn;
        $waiter->done($conn);
        return;
    }

    # Return to idle pool
    push @{$self->{_idle}}, $conn;
}

# Create a new connection
async sub _create_connection {
    my ($self) = @_;

    my $conn = Async::Redis->new(%{$self->{_conn_args}});
    await $conn->connect;

    $self->{_total_created}++;

    return $conn;
}

# Destroy a connection
sub _destroy_connection {
    my ($self, $conn) = @_;

    eval { $conn->disconnect };
    $self->{_total_destroyed}++;
}

# Maybe create a replacement connection to maintain min
sub _maybe_create_replacement {
    my ($self) = @_;

    my $current_total = (scalar keys %{$self->{_active}})
                      + (scalar @{$self->{_idle}})
                      + $self->{_creating};

    if ($current_total < $self->{min}) {
        # Create replacement asynchronously
        $self->{_creating}++;
        $self->_track_pending(
            $self->_create_connection->on_done(sub {
                my ($conn) = @_;
                $self->{_creating}--;
                $self->_return_to_pool($conn);
            })->on_fail(sub {
                $self->{_creating}--;
                # Failed to create replacement - log and continue
                warn "Failed to create replacement connection: @_";
            })
        );
    }
}

# Track a pending background future
sub _track_pending {
    my ($self, $f) = @_;

    push @{$self->{_pending}}, $f;

    # Clean up completed futures
    $f->on_ready(sub {
        @{$self->{_pending}} = grep { !$_->is_ready } @{$self->{_pending}};
    });

    return $f;
}

# Health check
async sub _health_check {
    my ($self, $conn) = @_;

    # Can't PING a pubsub connection
    if ($conn->in_pubsub) {
        return 0;
    }

    # Quick PING with 1 second timeout
    my $ok = 0;
    eval {
        my $ping_f = $conn->ping;
        my $timeout_f = Future::IO->sleep(1)->then(sub { Future->fail('health_timeout') });
        my $result = await Future->wait_any($ping_f, $timeout_f);
        $ok = 1 if defined $result && $result eq 'PONG';
    };

    return $ok;
}

# Check if cleanup can be attempted
sub _can_attempt_cleanup {
    my ($self, $conn) = @_;

    # NEVER attempt cleanup for these states:

    # PubSub mode - UNSUBSCRIBE returns confirmation frames that
    # must be correctly drained in modal pubsub mode. Too risky.
    return 0 if $conn->in_pubsub;

    # Inflight requests - after timeout/reset we've already
    # declared the stream desynced.
    return 0 if $conn->inflight_count > 0;

    # Cleanup MAY be attempted for these (still risky, but bounded):
    # - in_multi: DISCARD is safe if we're actually in MULTI
    # - watching: UNWATCH is always safe
    return 1 if $conn->in_multi || $conn->watching;

    # Unknown dirty state - don't risk it
    return 0;
}

# Attempt to cleanup a dirty connection
async sub _cleanup_connection {
    my ($self, $conn) = @_;

    # Note: Only called for in_multi or watching states
    # PubSub and inflight connections are always destroyed

    eval {
        # Reset transaction state
        if ($conn->in_multi) {
            my $discard_f = $conn->command('DISCARD');
            my $timeout_f = Future::IO->sleep($self->{cleanup_timeout})->then(sub {
                Future->fail('cleanup_timeout');
            });
            await Future->wait_any($discard_f, $timeout_f);
            $conn->{in_multi} = 0;
        }

        if ($conn->watching) {
            my $unwatch_f = $conn->command('UNWATCH');
            my $timeout_f = Future::IO->sleep($self->{cleanup_timeout})->then(sub {
                Future->fail('cleanup_timeout');
            });
            await Future->wait_any($unwatch_f, $timeout_f);
            $conn->{watching} = 0;
        }
    };

    if ($@) {
        die "Cleanup failed: $@";
    }

    # Verify connection is now clean
    if ($conn->is_dirty) {
        die "Connection still dirty after cleanup";
    }

    return $conn;
}

# The recommended pattern
async sub with {
    my ($self, $code) = @_;

    my $conn = await $self->acquire;
    my $result;
    my $error;

    eval {
        $result = await $code->($conn);
    };
    $error = $@;

    # Always release, even on exception
    # release() handles dirty detection
    $self->release($conn);

    die $error if $error;
    return $result;
}

# Shutdown the pool — synchronous. Blocks new acquires, fails waiters,
# closes idle connections. Active connections are destroyed when released.
sub shutdown {
    my ($self) = @_;
    return if $self->{_shutdown};
    $self->{_shutdown} = 1;

    # Close idle connections
    for my $conn (@{$self->{_idle}}) {
        $self->_destroy_connection($conn);
    }
    $self->{_idle} = [];

    # Fail all pending acquire waiters
    for my $waiter (@{$self->{_waiters}}) {
        $waiter->fail(Async::Redis::Error::Disconnected->new(
            message => "Pool is shutting down",
        )) unless $waiter->is_ready;
    }
    $self->{_waiters} = [];
}

1;

__END__

=head1 NAME

Async::Redis::Pool - Connection pool for Async::Redis

=head1 SYNOPSIS

    my $pool = Async::Redis::Pool->new(
        host => 'localhost',
        min  => 2,
        max  => 10,
    );

    # Recommended: scoped pattern
    my $result = await $pool->with(async sub {
        my ($redis) = @_;
        await $redis->incr('counter');
    });

    # Manual acquire/release (be careful!)
    my $redis = await $pool->acquire;
    await $redis->set('key', 'value');
    $pool->release($redis);

=head1 DESCRIPTION

Manages a pool of Redis connections with automatic dirty detection. Pool-specific
options are consumed by C<Async::Redis::Pool>; all other constructor arguments
are passed through to C<< Async::Redis->new >>.

=head1 CONSTRUCTOR

=head2 new

    my $pool = Async::Redis::Pool->new(
        host            => 'localhost',
        min             => 2,
        max             => 10,
        acquire_timeout => 5,
        cleanup_timeout => 5,
        on_dirty        => 'destroy',
    );

Options:

=over 4

=item min

Minimum desired pool size. Default: 1. The pool creates replacement
connections after dirty connections are destroyed if the total drops below
this value.

=item max

Maximum number of active, idle, and currently-creating connections. Default: 10.

=item acquire_timeout

Seconds to wait for a connection when the pool is at capacity. Default: 5.
Timeouts throw L<Async::Redis::Error::Timeout>.

=item cleanup_timeout

Seconds to allow a best-effort cleanup command such as C<DISCARD> or
C<UNWATCH>. Default: 5.

=item on_dirty

Dirty connection policy. Default: C<destroy>.

C<destroy> closes dirty connections instead of returning them to the pool.

C<cleanup> attempts bounded cleanup only for transaction/watch state. PubSub
connections and connections with pending responses are still destroyed.

=item idle_timeout

Accepted as a pool option but not currently enforced.

=back

=head1 METHODS

=head2 acquire

    my $redis = await $pool->acquire;

Return a healthy L<Async::Redis> connection from the pool, creating one if the
pool is below C<max>. The caller must later call C<release>.

=head2 release

    $pool->release($redis);

Return a connection to the pool. Dirty connections are either destroyed or
cleaned according to C<on_dirty>.

=head2 with

    my $result = await $pool->with(async sub {
        my ($redis) = @_;
        return await $redis->get('key');
    });

Acquire a connection, run the callback, and release the connection even if the
callback dies. This is the recommended public API.

=head2 stats

    my $stats = $pool->stats;

Returns a hashref with C<active>, C<idle>, C<waiting>, C<total>, and
C<destroyed> counts.

=head2 shutdown

    $pool->shutdown;

Stop new acquires, fail pending waiters, and close idle connections. Active
connections are destroyed when they are released.

=head2 min / max

Return the configured pool size limits.

=head1 CONNECTION CLEANLINESS

A connection is "dirty" if it has state that could affect the next user:

=over 4

=item * in_multi - In a MULTI transaction

=item * watching - Has WATCH keys

=item * in_pubsub - In subscription mode

=item * inflight - Has pending responses

=back

Dirty connections are destroyed by default. The cost of a new TCP handshake
is far less than the risk of data corruption. With C<< on_dirty => 'cleanup' >>,
the pool attempts C<DISCARD> and/or C<UNWATCH> only when it can prove those are
the only dirty states present.

=head1 RECOMMENDED USAGE

Always prefer C<with()> over manual acquire/release:

    await $pool->with(async sub {
        my ($redis) = @_;
        # Use $redis here
        # Connection released automatically, even on exception
    });

=cut
