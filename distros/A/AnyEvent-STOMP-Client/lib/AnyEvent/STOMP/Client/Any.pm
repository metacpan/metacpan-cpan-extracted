package AnyEvent::STOMP::Client::Any;

use strict;
use warnings;

use parent 'Object::Event';

use AnyEvent::STOMP::Client;
use Log::Any '$log';
use Time::HiRes 'time';


our $VERSION = '0.40';


my $SEPARATOR_ID_ACK = '#';
my $SEPARATOR_BROKER_ID = ':';

sub new {
    my $class = shift;
    my $config = shift;

    my $self = $class->SUPER::new;
    bless $self, $class;

    $self->{config} = $config;
    $self->setup_stomp_clients();

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

        $self->{stomp_clients}{$id}->on_connected(
            sub {
                my (undef, $header) = @_;

                $log->debug("$id STOMP connection established.");

                $self->{current_stomp_client} = $self->{stomp_clients}{$id};
                $self->reset_backoff;
                delete $self->{connect_timeout_timer};

                $self->event('ANY_CONNECTED', $header, $id);
            }
        );

        $self->{stomp_clients}{$id}->on_transport_connected(
            sub {
                $log->debug("$id TCP/TLS connection established.");
            }
        );

        $self->{stomp_clients}{$id}->on_transport_disconnected(
            sub {
                $log->debug("$id TCP/TLS connection closed.");
            }
        );

        $self->{stomp_clients}{$id}->on_disconnected(
            sub {
                my (undef, $header) = @_;

                delete $self->{current_stomp_client};

                $self->event('ANY_DISCONNECTED', $header, $id);
            }
        );

        $self->{stomp_clients}{$id}->on_error(
            sub {
                my (undef, $header, undef) = @_;

                delete $self->{current_stomp_client};

                $log->debug("$id STOMP ERROR received: '$header->{message}'.");
                $self->event('ANY_ERROR', $header->{message}, $id);
            }
        );

        $self->{stomp_clients}{$id}->on_send(
            sub {

            }
        );

        $self->{stomp_clients}{$id}->on_connection_lost(
            sub {
                my (undef, undef, undef, $reason) = @_;

                delete $self->{current_stomp_client};

                $log->debug("$id Connection lost ($reason).");
                delete $self->{connect_timeout_timer};
                $self->set_client_unavailable($id);
                $self->event('ANY_CONNECTION_LOST', $id);
                $self->backoff;
            }
        );

        $self->{stomp_clients}{$id}->on_connect_error(
            sub {
                my (undef, undef, undef, $reason) = @_;
                $log->debug("$id Could not establish connection ($reason).");
                delete $self->{connect_timeout_timer};
                $self->set_client_unavailable($id);
                $self->backoff;
            }
        );

        $self->{stomp_clients}{$id}->on_receipt(
            sub {
                my (undef, $header) = @_;
                $self->event('ANY_RECEIPT', $header, $id);
            }
        );

        $self->{stomp_clients}{$id}->on_message(
            sub {
                my (undef, $header, $body) = @_;
                $self->event('ANY_MESSAGE', $header, $body, $id);
            }
        );

        $self->{stomp_clients}{$id}->on_subscribed(
            sub {
                my (undef, $destination) = @_;
                $self->event('ANY_SUBSCRIBED', $destination, $id);
            }
        );
    }

    $self->reset_clients_state;
    $log->debug("STOMP clients set up.");
}

sub connect {
    my $self = shift;
    my $id = $self->get_random_client_id;

    $log->debug("$id Establishing TCP/TLS connection.");
    $self->{stomp_clients}{$id}->connect;

    $self->{connect_timeout_timer} = AnyEvent->timer(
        after => 10,
        cb => sub {
            $log->debug("$id Timeout establishing STOMP connection.");
            $self->{stomp_clients}{$id}->disconnect;
            $self->set_client_unavailable($id);
            $self->backoff;
        }
    );
}

sub disconnect {
    my $self = shift;
    $self->get_instance->disconnect if $self->is_connected;
}

sub backoff {
    my $self = shift;

    if ($self->is_client_available) {
        $self->connect;
    }
    else {
        $self->increase_backoff;
        $self->reset_clients_state;

        $self->{reconnect_timer} = AnyEvent->timer(
            after => $self->get_backoff,
            cb => sub {
                $self->backoff;
            },
        );
    }
}

sub increase_backoff {
    my $self = shift;

    if (defined $self->{backoff}) {
        if ($self->{backoff} < $self->{config}{backoff}{maximum}) {
            my $old_backoff = $self->{backoff};
            my $randomness = rand($old_backoff)-$old_backoff/2;
            $self->{backoff} = $old_backoff*$self->{config}{backoff}{multiplier}+$randomness;
        }
        else {
            my $max = $self->{config}{backoff}{maximum};
            my $randomness = rand($max)-$max/2;
            $self->{backoff} = $max+$randomness;
        }
    }
    else {
        my $val = $self->{config}{backoff}{start_value};
        $self->{backoff} = rand($val)+$val/2;
    }

    $log->debug("Backing off ".$self->{backoff});
}

sub reset_backoff {
    my $self = shift;

    delete $self->{reconnect_timer};
    delete $self->{backoff};
    $self->reset_clients_state;
}

sub get_backoff {
    return shift->{backoff};
}

sub get_random_client_id {
    my $self = shift;
    my @available_clients;

    foreach my $id (keys %{$self->{stomp_clients}}) {
        if ($self->get_client_state($id)) {
            push @available_clients, $id;
        }
    }

    $log->debug('Available clients: '.join(', ', @available_clients));

    my $available_clients_count = scalar @available_clients;
    return @available_clients[int(rand($available_clients_count))];
}

sub is_client_available {
    my $self = shift;

    foreach my $id (keys %{$self->{stomp_clients}}) {
        if ($self->get_client_state($id)) {
            return 1;
        }
    }

    return 0;
}

sub set_client_unavailable {
    my ($self, $id) = @_;
    $self->{client_state}{$id} = 0;
}

sub set_client_available {
    my ($self, $id) = @_;
    $self->{client_state}{$id} = 1;
}

sub get_current_id {
    my $self = shift;

    return $self->{current_stomp_client}->{host}.$SEPARATOR_BROKER_ID.$self->{current_stomp_client}->{port};
}

sub get_client_state {
    my ($self, $id) = @_;
    return $self->{client_state}{$id};
}

sub reset_clients_state {
    my $self = shift;

    foreach my $id (keys %{$self->{stomp_clients}}) {
        $self->set_client_available($id);
    }
}

sub get_instance {
    my $self = shift;

    return $self->{current_stomp_client};
}

sub is_connected {
    my $self = shift;

    if (defined $self->get_instance) {
        return $self->get_instance->is_connected();
    }

    return 0;
}

sub get_uuid {
    return int(time*1000000);
}

sub send {
    shift->get_instance->send(@_);
}

sub subscribe {
    shift->get_instance->subscribe(@_);
}

sub on_connected {
    return shift->reg_cb('ANY_CONNECTED', shift);
}

sub on_disconnected {
    return shift->reg_cb('ANY_DISCONNECTED', shift);
}

sub on_connection_lost {
    return shift->reg_cb('ANY_CONNECTION_LOST', shift);
}

sub on_receipt {
    return shift->reg_cb('ANY_RECEIPT', shift);
}

sub on_message {
    return shift->reg_cb('ANY_MESSAGE', shift);
}

sub on_subscribed {
    return shift->reg_cb('ANY_SUBSCRIBED', shift);
}

sub on_error {
    return shift->reg_cb('ANY_ERROR', shift);
}

1;
