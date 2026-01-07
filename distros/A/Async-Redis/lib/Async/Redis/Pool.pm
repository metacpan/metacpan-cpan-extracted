package Async::Redis::Pool;

use strict;
use warnings;
use 5.018;

use Future;
use Future::AsyncAwait;
use Future::IO;
use Async::Redis;
use Async::Redis::Error::Timeout;

our $VERSION = '0.001';

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        # Connection params (passed to Async::Redis->new)
        host     => $args{host} // 'localhost',
        port     => $args{port} // 6379,
        password => $args{password},
        database => $args{database},
        tls      => $args{tls},
        uri      => $args{uri},

        # Pool sizing
        min => $args{min} // 1,
        max => $args{max} // 10,

        # Timeouts
        acquire_timeout  => $args{acquire_timeout} // 5,
        idle_timeout     => $args{idle_timeout} // 60,
        connect_timeout  => $args{connect_timeout} // 10,
        cleanup_timeout  => $args{cleanup_timeout} // 5,

        # Dirty handling
        on_dirty => $args{on_dirty} // 'destroy',

        # Pool state
        _idle    => [],   # Available connections
        _active  => {},   # Connections in use (conn => 1)
        _waiters => [],   # Futures waiting for connection
        _pending => [],   # Background futures (creation, cleanup)
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

    # Clear pending futures
    $self->{_pending} = [];
}

# Acquire a connection from the pool
async sub acquire {
    my ($self) = @_;

    # Check for fork - clear pool if PID changed
    $self->_check_fork;

    # Try to get an idle connection
    while (@{$self->{_idle}}) {
        my $conn = shift @{$self->{_idle}};

        # Health check
        my $healthy = await $self->_health_check($conn);
        if ($healthy) {
            $self->{_active}{"$conn"} = $conn;
            return $conn;
        }

        # Unhealthy - destroy and try next
        $self->_destroy_connection($conn);
    }

    # No idle connections - can we create a new one?
    my $current_total = (scalar keys %{$self->{_active}}) + (scalar @{$self->{_idle}});

    if ($current_total < $self->{max}) {
        my $conn = await $self->_create_connection;
        $self->{_active}{"$conn"} = $conn;
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

    return unless $conn;

    # Check for fork - if forked, don't return to pool
    if ($self->_check_fork) {
        # Pool was cleared, just drop this connection
        return;
    }

    # Remove from active
    delete $self->{_active}{"$conn"};

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
        $self->{_active}{"$conn"} = $conn;
        $waiter->done($conn);
        return;
    }

    # Return to idle pool
    push @{$self->{_idle}}, $conn;
}

# Create a new connection
async sub _create_connection {
    my ($self) = @_;

    my %conn_args = (
        host            => $self->{host},
        port            => $self->{port},
        connect_timeout => $self->{connect_timeout},
    );

    $conn_args{password} = $self->{password} if defined $self->{password};
    $conn_args{database} = $self->{database} if defined $self->{database};
    $conn_args{tls}      = $self->{tls}      if $self->{tls};
    $conn_args{uri}      = $self->{uri}      if $self->{uri};

    my $conn = Async::Redis->new(%conn_args);
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

    my $current_total = (scalar keys %{$self->{_active}}) + (scalar @{$self->{_idle}});

    if ($current_total < $self->{min}) {
        # Create replacement asynchronously
        $self->_track_pending(
            $self->_create_connection->on_done(sub {
                my ($conn) = @_;
                $self->_return_to_pool($conn);
            })->on_fail(sub {
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

# Shutdown the pool
async sub shutdown {
    my ($self) = @_;

    # Cancel waiters
    for my $waiter (@{$self->{_waiters}}) {
        $waiter->fail("Pool shutting down") unless $waiter->is_ready;
    }
    $self->{_waiters} = [];

    # Close idle connections
    for my $conn (@{$self->{_idle}}) {
        $self->_destroy_connection($conn);
    }
    $self->{_idle} = [];

    # Active connections will be closed when released
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

Manages a pool of Redis connections with automatic dirty detection.

=head2 Connection Cleanliness

A connection is "dirty" if it has state that could affect the next user:

=over 4

=item * in_multi - In a MULTI transaction

=item * watching - Has WATCH keys

=item * in_pubsub - In subscription mode

=item * inflight - Has pending responses

=back

Dirty connections are destroyed by default. The cost of a new TCP handshake
is far less than the risk of data corruption.

=head2 The with() Pattern

Always prefer C<with()> over manual acquire/release:

    await $pool->with(async sub {
        my ($redis) = @_;
        # Use $redis here
        # Connection released automatically, even on exception
    });

=cut
