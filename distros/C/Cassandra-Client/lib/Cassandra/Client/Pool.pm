package Cassandra::Client::Pool;
use 5.010;
use strict;
use warnings;

use Scalar::Util 'weaken';
use Cassandra::Client::Util;
use Cassandra::Client::Policy::LoadBalancing::Default;
use Cassandra::Client::NetworkStatus;

sub new {
    my ($class, %args)= @_;
    my $self= bless {
        client => $args{client},
        options => $args{options},
        metadata => $args{metadata},
        max_connections => $args{options}{max_connections},
        async_io => $args{async_io},
        policy => Cassandra::Client::Policy::LoadBalancing::Default->new(),

        shutdown => 0,
        pool => {},
        count => 0,
        list => [],

        last_id => 0,
        id2ip => {},

        i => 0,

        connecting => {},
        wait_connect => [],
    }, $class;
    weaken($self->{client});
    $self->{network_status}= Cassandra::Client::NetworkStatus->new(pool => $self, async_io => $args{async_io});
    return $self;
}

sub init {
    my ($self, $callback, $first_connection)= @_;

    # This code can be called twice.

    # If we didn't have a datacenter pinned before, now we do
    $self->{policy}{datacenter} ||= $first_connection->{datacenter};

    $self->add($first_connection);
    $self->{policy}->set_connected($first_connection->ip_address);

    # Master selection, warmup, etc
    series([
        sub {
            my ($next)= @_;
            $self->{network_status}->init($next);
        },
        sub {
            my ($next)= @_;

            if ($self->{config}{warmup}) {
                $self->connect_if_needed($next);
            } else {
                $self->connect_if_needed();
                return $next->();
            }
        },
    ], $callback);
}

sub get_one {
    my ($self)= @_;
    return undef unless $self->{count};

    # Round-robin: pick the next one
    return $self->{list}[$self->{i}= (($self->{i}+1) % $self->{count})];
}

sub get_one_cb {
    my ($self, $callback)= @_;

    return $callback->(undef, $self->get_one) if $self->{count};

    if (!%{$self->{connecting}}) {
        $self->connect_if_needed;
    }
    if (!%{$self->{connecting}}) {
        return $callback->("Disconnected: all servers unreachable");
    }

    push @{$self->{wait_connect} ||= []}, {
        callback => $callback,
        attempts => 0,
    };
}

sub remove {
    my ($self, $id)= @_;
    if (!$id) {
        # Probably never got added. Ignore.
        return;
    }

    my $ipaddress= delete $self->{id2ip}{$id};
    if (!$ipaddress) {
        warn 'BUG: Tried to remove an unregistered connection. Probably a bad idea.';
        return;
    }

    my $connection= delete $self->{pool}{$ipaddress};
    if (!$connection) {
        warn 'BUG: Found a registered but unknown connection. This should not happen.';
        return;
    }

    $self->rebuild;

    $self->{policy}->set_disconnected($ipaddress);
    $self->{network_status}->disconnected($connection->get_pool_id);
    $self->connect_if_needed;

    return;
}

sub add {
    my ($self, $connection)= @_;

    my $ipaddress= $connection->ip_address;

    if ($self->{pool}{$ipaddress}) {
        warn 'BUG: Duplicate connection for '.$ipaddress.'!';
    }

    my $id= (++($self->{last_id}));
    $connection->set_pool_id($id);
    $self->{pool}{$ipaddress}= $connection;
    $self->{id2ip}{$id}= $ipaddress;

    $self->rebuild;

    my $waiters= delete $self->{wait_connect};
    $_->{callback}->(undef, $connection) for @$waiters;

    $self->{network_status}->select_master(sub{});

    return;
}

sub rebuild {
    my ($self)= @_;

    $self->{list}= [ values %{$self->{pool}} ];
    $self->{count}= 0+ @{$self->{list}};

    return;
}

sub shutdown {
    my ($self)= @_;

    $self->{network_status}->shutdown;
    $self->{shutdown}= 1;

    my @pool= @{$self->{list}};
    $_->shutdown("Shutting down") for @pool;

    my @connecting= values %{$self->{connecting}};
    $_->shutdown("Shutting down") for @connecting;

    return;
}

sub connect_if_needed {
    my ($self, $callback)= @_;

    my $max_connect= $self->{max_connections} - $self->{count};
    return if $max_connect <= 0;

    $max_connect -= keys %{$self->{connecting}};
    return if $max_connect <= 0;

    return if $self->{shutdown};

    if ($self->{_in_connect}) {
        return;
    }
    local $self->{_in_connect}= 1;

    my $done= 0;
    my $expect= $max_connect;
    for (1..$max_connect) {
        $expect-- unless $self->spawn_new_connection(sub {
            $done++;

            if ($done == $expect) {
                $callback->() if $callback;
            }
        });
    }
    if ($callback && !$expect) {
        $callback->();
    }
}

sub spawn_new_connection {
    my ($self, $callback)= @_;

    my $host= $self->{policy}->get_next_candidate;
    return unless $host;

    my $connection= Cassandra::Client::Connection->new(
        client => $self->{client},
        options => $self->{options},
        host => $host,
        async_io => $self->{async_io},
        metadata => $self->{metadata},
    );

    $self->{connecting}{$host}= $connection;
    $self->{policy}->set_connected($host);

    $connection->connect(sub {
        my ($error)= @_;

        delete $self->{connecting}{$host};
        if ($error) {
            $self->{policy}->set_disconnected($host);

            if (my $waiters= delete $self->{wait_connect}) {
                if ($self->{count} && @$waiters) {
                    warn 'We have callbacks waiting for a connection while we\'re connected';
                }
                for my $waiter (@$waiters) {
                    if ($waiter->{attempts}++ || !%{$self->{connecting}}) {
                        $waiter->{callback}->("Failed to connect to server");
                    } else {
                        push @{$self->{wait_connect} ||= []}, $waiter;
                    }
                }
            }

            $self->connect_if_needed;
        } else {
            $self->add($connection);
        }

        $callback->($error);
    });

    return 1;
}

# Events coming from the network
sub event_added_node {
    my ($self, $ipaddress)= @_;
    $self->{network_status}->event_added_node($ipaddress);
}

sub event_removed_node {
    my ($self, $ipaddress)= @_;
    $self->{network_status}->event_removed_node($ipaddress);

    if (my $conn= $self->{pool}{$ipaddress}) {
        $conn->shutdown("Removed from pool");
    }
}

# Events coming from network_status
sub on_new_node {
    my ($self, $node)= @_;
    $self->{policy}->on_new_node($node);
}

sub on_removed_node {
    my ($self, $node)= @_;
    $self->{policy}->on_removed_node($node);
}

1;
