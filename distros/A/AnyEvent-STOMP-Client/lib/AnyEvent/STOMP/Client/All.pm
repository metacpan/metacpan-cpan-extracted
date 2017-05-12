package AnyEvent::STOMP::Client::All;

use strict;
use warnings;

use parent 'Object::Event';

use Carp;
use Log::Any qw($log);
use AnyEvent::STOMP::Client;


our $VERSION = '0.39';


my $SEPARATOR_ID_ACK = '#';
my $SEPARATOR_BROKER_ID = ':';

sub new {
    my $class = shift;
    my $config = shift;

    my $destination;

    my $self = {
        config => $config,
        condvar => AnyEvent->condvar,
    };
    bless $self, $class;

    $self->setup_stomp_clients;

    return $self;
}

sub setup_stomp_clients {
    my $self = shift;

    if (ref($self->{config}{broker}) ne 'ARRAY') {
        $self->{config}{broker} = [$self->{config}{broker}];
    }

    foreach (@{$self->{config}{broker}}) {
        my $host = $_->{host};
        my $port = $_->{port};
        my $id = "$host$SEPARATOR_BROKER_ID$port";

        my $config = {
            connect_headers => {},
            tls_context => {
                %{$self->{config}{tls_context}},
            },
        };

        if (defined $self->{config}{connect_headers}) {
            $config->{connect_headers} = $self->{config}{connect_headers};
        }

        if (defined $_->{connect_headers}) {
            $config->{connect_headers}{keys %{$_->{connect_headers}}} = values %{$_->{connect_headers}};
        }

        $self->{stomp_clients}{$id} = new AnyEvent::STOMP::Client(
            $host, $port,
            $config->{connect_headers},
            $config->{tls_context}
        );

        $self->{stomp_clients}{$id}->on_error(
            sub {
                my (undef, $header, undef) = @_;
                $log->warn("$id STOMP ERROR $header->{message}.");
            }
        );

        $self->{stomp_clients}{$id}->on_connected(
            sub {
                $self->reset_backoff($id);
            }
        );

        $self->{stomp_clients}{$id}->on_connection_lost(
            sub {
                my (undef, undef, undef, $reason) = @_;
                $log->debug("$id Connection lost ($reason).");
                $self->backoff($id);
            }
        );

        $self->{stomp_clients}{$id}->on_connect_error(
            sub {
                my (undef, undef, undef, $reason) = @_;
                $log->debug("$id Could not establish connection ($reason).");
                $self->backoff($id);
            }
        );
    }
}

sub connect {
    my $self = shift;
    
    foreach my $id (keys %{$self->{stomp_clients}}) {
        $log->debug("$id trying to connect.");
        $self->{stomp_clients}{$id}->connect();
    }
}

sub disconnect {
    my $self = shift;

    foreach my $id (keys %{$self->{stomp_clients}}) {
        $log->debug("$id disconnecting.");
        $self->{stomp_clients}{$id}->disconnect();
    }
}

sub subscribe {
    my ($self, $destination, $ack_mode, $additional_headers) = @_;

    foreach my $id (keys %{$self->{stomp_clients}}) {
        $log->debug("$id subscribing to $destination.");
        $self->{stomp_clients}{$id}->subscribe(
            $destination, $ack_mode, $additional_headers
        );
    }
}

sub send {
    my $self = shift;

    foreach my $id (keys %{$self->{stomp_clients}}) {
        $self->{stomp_clients}{$id}->send(@_);
    }
}

sub on_connected {
    my ($self, $callback) = @_;

    foreach my $id (keys %{$self->{stomp_clients}}) {
        $self->{stomp_clients}{$id}->on_connected($callback);
        $self->{stomp_clients}{$id}->on_connected(
            sub {
                $log->debug("$id connected.");
            }
        );
    }
}

sub on_disconnected {
    my ($self, $callback) = @_;

    foreach my $id (keys %{$self->{stomp_clients}}) {
        $self->{stomp_clients}{$id}->on_disconnected($callback);
        $self->{stomp_clients}{$id}->on_disconnected(
            sub {
                $log->debug("$id disconnected.");
            }
        );
    }
}

sub on_error {
    my ($self, $callback) = @_;

    foreach my $id (keys %{$self->{stomp_clients}}) {
        $self->{stomp_clients}{$id}->on_error($callback);
    }
}

sub on_message {
    my ($self, $callback) = @_;

    foreach my $id (keys %{$self->{stomp_clients}}) {
        $self->{stomp_clients}{$id}->on_message(
            sub {
                my ($self, $header, $body) = @_;

                delete $header->{'subscription'};
                delete $header->{'message-id'};
                delete $header->{'receipt'};

                if (defined $header->{'ack'}) {
                    $log->debug("$id message $header->{'ack'} received.");
                    $header->{'ack'} = $id.$SEPARATOR_ID_ACK.$header->{'ack'} if defined $header->{'ack'};
                }
                else {
                    $log->debug("$id message received.");
                }

                &$callback($self, $header, $body);
            }
        );
    }
}

sub ack {
    my ($self, $id_ack) = @_;
    my ($id, $ack) = split $SEPARATOR_ID_ACK, $id_ack;

    $log->debug("$id sending ack $ack.");

    $self->{stomp_clients}{$id}->ack($ack);
}

sub nack {
    my ($self, $id_ack) = @_;
    my ($id, $ack) = split $SEPARATOR_ID_ACK, $id_ack;

    $log->debug("$id sending nack $ack.");

    $self->{stomp_clients}{$id}->nack($ack);
}

sub backoff {
    my ($self, $id) = @_;

    if (defined $self->{backoff}{$id}{current}) {
        $self->increase_backoff($id);
    }
    else {
        $self->{backoff}{$id}{current} = $self->{config}{backoff}{start_value};
    }

    $log->debug("$id backoff: ".$self->{backoff}{$id}{current});

    $self->{reconnect_timers}{$id} = AnyEvent->timer (
        after => $self->get_backoff($id),
        cb => sub {
            $log->debug("$id trying to connect.");
            $self->{stomp_clients}{$id}->connect;
        },
    );
}

sub increase_backoff {
    my ($self, $id) = @_;

    if ($self->{backoff}{$id}{current} < $self->{config}{backoff}{maximum}) {
        $self->{backoff}{$id}{current} *= $self->{config}{backoff}{multiplier};
    }
}

sub reset_backoff {
    my ($self, $id) = @_;

    delete $self->{reconnect_timer}{$id};
    delete $self->{backoff}{$id}{current};
}

sub get_backoff {
    my ($self, $id) = @_;

    return $self->{backoff}{$id}{current};
}

1;
