package Cassandra::Client::NetworkStatus;
use 5.010;
use strict;
use warnings;

use Scalar::Util qw/weaken/;
use Cassandra::Client::Util;

sub new {
    my ($class, %args)= @_;

    my $self= bless {
        pool => $args{pool},
        async_io => $args{async_io},

        waiting_for_cb => [],
        master_id => undef,

        shutdown => undef,
    }, $class;
    weaken($self->{pool});
    return $self;
}

sub init {
    my ($self, $callback)= @_;
    $self->select_master($callback);
}

sub select_master {
    my ($self, $callback)= @_;

    return $callback->() if $self->{master_id};
    if (@{$self->{waiting_for_cb}}) {
        push @{$self->{waiting_for_cb}}, $callback;
        return;
    }
    push @{$self->{waiting_for_cb}}, $callback;

    my $attempts= 0;
    whilst(
        sub { # condition
            !$self->{shutdown} && !$self->{master_id}
        },
        sub { # while
            my ($wnext)= @_;
            series([
                sub {
                    my ($next)= @_;
                    if ($attempts++) {
                        # Don't retry immediately
                        $self->{async_io}->timer($next, 1);
                    } else {
                        $next->();
                    }
                },
                sub {
                    my ($next)= @_;
                    $self->{pool}->get_one_cb($next);
                },
                sub {
                    my ($next, $connection)= @_;
                    parallel([
                        sub {
                            my ($pnext)= @_;
                            $connection->register_events($pnext);
                        },
                        sub {
                            my ($pnext)= @_;
                            $connection->get_network_status($pnext);
                        },
                        sub {
                            $_[0]->(undef, $connection);
                        },
                    ], $next);
                }, sub {
                    my ($next, undef, $networkstatus, $connection)= @_;
                    $self->{master_id}= $connection->get_pool_id;
                    $self->load_status($networkstatus);
                    $next->();
                },
            ], sub {
                $wnext->();
            });
        },
        sub { # finish
            my ($error)= @_;
            my @cb= @{$self->{waiting_for_cb}};
            $self->{waiting_for_cb}= [];
            $error= $error || ($self->{master_id} ? undef : "Master selection aborted");
            $_->($error) for @cb;
        }
    );
}

sub shutdown {
    my ($self)= @_;
    $self->{shutdown}= 1;
}

sub load_status {
    my ($self, $new_status)= @_;
    my $old_status= $self->{status};
    $self->{status}= $new_status;

    my @old_hosts= grep {!$new_status->{$_}} keys %$old_status;
    my @new_hosts= grep {!$old_status->{$_}} keys %$new_status;

    $self->{pool}->on_removed_node($old_status->{$_}) for @old_hosts;
    $self->{pool}->on_new_node($new_status->{$_}) for @new_hosts;
}

sub event_added_node {
    my ($self, $ipaddress)= @_;
    $self->refresh_network_status unless $self->{status}{$ipaddress};
}

sub event_removed_node {
    my ($self, $ipaddress)= @_;
    my $old_node= delete $self->{status}{$ipaddress};
    if ($old_node) {
        $self->{pool}->on_removed_node($old_node);
    }
}

sub disconnected {
    my ($self, $id)= @_;
    if ($self->{master_id} && $self->{master_id} == $id) {
        $self->{master_id}= undef;
        $self->select_master(sub{});
    }
}

sub refresh_network_status {
    my ($self)= @_;

    series([
        sub {
            my ($next)= @_;
            $self->{pool}->get_one_cb($next);
        }, sub {
            my ($next, $connection)= @_;
            $connection->get_network_status($next);
        }, sub {
            my ($next, $status)= @_;
            $self->load_status($status);
            return $next->();
        }
    ], sub {
        my ($error)= @_;
        # XXX And now?
    });
}

1;
