package Beekeeper::Service::Router::Worker;

use strict;
use warnings;

our $VERSION = '0.07';

use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';

use Beekeeper::Worker::Util 'shared_cache';
use Scalar::Util 'weaken';

use constant FRONTEND_ROLE   =>'frontend';
use constant SESSION_TIMEOUT => 1800;
use constant SHUTDOWN_WAIT   => 2;
use constant QUEUE_LANES     => 2;
use constant DEBUG           => 0;

$Beekeeper::Worker::LogLevel = 9 if DEBUG;


sub authorize_request {
    my ($self, $req) = @_;

    return unless $self->__has_authorization_token('BKPR_ROUTER');

    return BKPR_REQUEST_AUTHORIZED;
}

sub on_startup {
    my $self = shift;

    my $worker_config = $self->{_WORKER}->{config};
    my $bus_config    = $self->{_WORKER}->{bus_config};

    $self->{sess_timeout}  = $worker_config->{'session_timeout'} || SESSION_TIMEOUT;
    $self->{shutdown_wait} = $worker_config->{'shutdown_wait'}   || SHUTDOWN_WAIT;
    $self->{frontend_role} = $worker_config->{'frontend_role'}   || FRONTEND_ROLE;

    $self->_init_routing_table;

    my $frontend_role = $self->{frontend_role};
    my $frontends_config = Beekeeper::Config->get_bus_group_config( bus_role => $frontend_role );

    unless (@$frontends_config) {
        die "No bus with role '$frontend_role' was found into config file bus.config.json\n";
    }

    $self->{wait_frontends_up} = AnyEvent->condvar;

    # Create a connection to every frontend
    foreach my $config (@$frontends_config) {

        $self->init_frontend_connection( $config );
    }
}

sub init_frontend_connection {
    my ($self, $config) = @_;

    my $bus_id  = $config->{'bus_id'};
    my $back_id = $self->{_BUS}->bus_id;

    $self->{wait_frontends_up}->begin;

    my $bus; $bus = Beekeeper::MQTT->new( 
        %$config,
        bus_id   => $bus_id,
        timeout  => 60,
        on_error => sub {
            # Reconnect
            my $errmsg = $_[0] || ""; $errmsg =~ s/\s+/ /sg;
            log_alert "Connection to $bus_id failed: $errmsg";
            delete $self->{FRONTEND}->{$bus_id};
            $self->{wait_frontends_up}->end;
            my $delay = $self->{connect_err}->{$bus_id}++;
            $self->{reconnect_tmr}->{$bus_id} = AnyEvent->timer(
                after => ($delay < 10 ? $delay * 3 : 30),
                cb    => sub { $bus->connect },
            );
        },
    );

    $bus->connect(
        on_connack => sub {
            # Setup routing
            log_info "Routing: $back_id <--> $bus_id";
            $self->{FRONTEND}->{$bus_id} = $bus;
            $self->{wait_frontends_up}->end;
            $self->pull_frontend_requests( frontend => $bus );
            $self->pull_backend_responses( frontend => $bus );
            $self->pull_backend_notifications( frontend => $bus );
        },
    );
}

sub on_shutdown {
    my ($self, %args) = @_;

    log_info "Shutting down";

    my $frontend_role = $self->{frontend_role};

    my $backend_bus  = $self->{_BUS};
    my $backend_role = $self->{_BUS}->{bus_role};

    my $cv = AnyEvent->condvar;

    # 1. Do not pull frontend requests anymore
    foreach my $frontend_bus (values %{$self->{FRONTEND}}) {

        foreach my $lane (1..QUEUE_LANES) {

            my $topic = "\$share/BKPR/req/$backend_role-$lane";
            $cv->begin;
            $frontend_bus->unsubscribe(
                topic       => $topic,
                on_unsuback => sub {
                    my ($success, $prop) = @_;
                    log_error "Could not unsubscribe from $topic" unless $success;
                    $cv->end;
                }
            );
        }
    }

    # 2. Stop forwarding notifications to frontend
    foreach my $lane (1..QUEUE_LANES) {

        my $topic = "\$share/BKPR/msg/$frontend_role-$lane";
        $cv->begin;
        $backend_bus->unsubscribe(
            topic       => $topic,
            on_unsuback => sub {
                my ($success, $prop) = @_;
                log_error "Could not unsubscribe from $topic" unless $success;
                $cv->end;
            }
        );
    }

    # 3. Wait for unsubacks, assuring that no more requests or messages are buffered 
    my $tmr = AnyEvent->timer( after => 30, cb => sub { $cv->send });
    $cv->recv;

    # 4. Just in case of pool full stop, wait for workers to finish their current tasks
    my $wait = AnyEvent->condvar;
    $tmr = AnyEvent->timer( after => $self->{shutdown_wait}, cb => sub { $wait->send });
    $wait->recv;

    $cv = AnyEvent->condvar;

    # 5. Stop forwarding responses to frontend
    foreach my $frontend_bus (values %{$self->{FRONTEND}}) {

        my $frontend_id = $frontend_bus->bus_id;

        foreach my $lane (1..QUEUE_LANES) {

            my $topic = "\$share/BKPR/res/$frontend_id-$lane";
            $cv->begin;
            $backend_bus->unsubscribe(
                topic       => $topic,
                on_unsuback => sub {
                    my ($success, $prop) = @_;
                    log_error "Could not unsubscribe from $topic" unless $success;
                    $cv->end;
                }
            );
        }
    }

    # 6. Wait for unsubacks, assuring that no more responses are buffered 
    $tmr = AnyEvent->timer( after => 30, cb => sub { $cv->send });
    $cv->recv;

    # Disconnect from all frontends
    my @frontends = values %{$self->{FRONTEND}};
    foreach my $frontend_bus (@frontends) {

        next unless ($frontend_bus->{is_connected});
        $frontend_bus->disconnect;
    }

    # Disconnect from backend bus group
    $self->{MqttSessions}->disconnect;
}

sub pull_frontend_requests {
    my ($self, %args) = @_;
    weaken($self);

    # Get requests from frontend bus and forward them to backend bus
    #
    # from:  req/backend-n                @frontend
    # to:    req/backend/{app}/{service}  @backend

    my $frontend_bus = $args{frontend};
    my $frontend_id  = $frontend_bus->bus_id;

    my $backend_bus  = $self->{_BUS};
    my $backend_id   = $backend_bus->bus_id;
    my $backend_role = $backend_bus->bus_role;

    foreach my $lane (1..QUEUE_LANES) {

        my $src_queue = "\$share/BKPR/req/$backend_role-$lane";

        my ($payload_ref, $mqtt_properties);
        my ($dest_queue, $reply_to, $caller_id, $mqtt_session);
        my %pub_args;

        $frontend_bus->subscribe(
            topic       => $src_queue,
            maximum_qos => 0,
            on_publish  => sub {
                ($payload_ref, $mqtt_properties) = @_;

                # (!) UNTRUSTED REQUEST

                # eg: req/backend/myapp/service
                $dest_queue = $mqtt_properties->{'fwd_to'} || '';
                return unless $dest_queue =~ m|^req(/(?!_)[\w-]+)+$|;

                # eg: priv/7nXDsxMDwgLUSedX
                $reply_to = $mqtt_properties->{'response_topic'} || '';
                return unless $reply_to =~ m|^priv/(\w{16,23})$|;
                $caller_id = $1;

                #TODO: Extra sanity checks could be done here before forwarding to backend

                %pub_args = (
                    topic          => $dest_queue,
                    clid           => $caller_id,
                    response_topic => "res/$frontend_id-$lane",
                    addr           => "$reply_to\@$frontend_id",
                    payload        => $payload_ref,
                    qos            => 1, # because workers consume using QoS 1
                );

                $mqtt_session = $self->{MqttSessions}->get( $caller_id );

                if (defined $mqtt_session) {
                    $self->{MqttSessions}->touch( $caller_id );
                    $pub_args{'auth'} = $mqtt_session->[2];
                }

                $backend_bus->publish( %pub_args );

                DEBUG && log_trace "Forwarded request:  $src_queue \@$frontend_id --> $dest_queue \@$backend_id";

                $self->{_WORKER}->{call_count}++;
            },
            on_suback => sub {
                log_debug "Forwarding $src_queue \@$frontend_id --> req/$backend_role/{app}/{service} \@$backend_id";
            }
        );
    }
}

sub pull_backend_responses {
    my ($self, %args) = @_;

    # Get responses from backend bus and forward them to frontend bus
    #
    # from:  res/frontend-n     @backend
    # to:    priv/{session_id}  @frontend

    my $frontend_bus = $args{frontend};
    my $frontend_id  = $frontend_bus->bus_id;

    my $backend_bus  = $self->{_BUS};
    my $backend_id   = $backend_bus->bus_id;

    foreach my $lane (1..QUEUE_LANES) {

        my $src_queue = "\$share/BKPR/res/$frontend_id-$lane";

        my ($payload_ref, $mqtt_properties, $dest_queue);

        $backend_bus->subscribe(
            topic       => $src_queue,
            maximum_qos => 0,
            on_publish  => sub {
                ($payload_ref, $mqtt_properties) = @_;

                ($dest_queue) = split('@', $mqtt_properties->{'addr'}, 2);

                $frontend_bus->publish(
                    topic   => $dest_queue,
                    payload => $payload_ref,
                );

                DEBUG && log_trace "Forwarded response: $src_queue \@$backend_id --> $dest_queue \@$frontend_id";
            },
            on_suback => sub {
                log_debug "Forwarding $src_queue \@$backend_id --> priv/{session_id} \@$frontend_id";
            }
        );
    }
}

sub pull_backend_notifications {
    my ($self, %args) = @_;
    weaken($self);

    # Get notifications from backend bus and broadcast them to all frontend buses
    #
    # from:  msg/frontend-n                         @backend
    # to:    msg/frontend/{app}/{service}/{method}  @frontend

    unless (keys %{$self->{FRONTEND}} && $self->{wait_frontends_up}->ready) {
        # Wait until connected to all (working) frontends before pulling 
        # notifications otherwise messages cannot be broadcasted properly
        #TODO: MQTT: broker will discard messages unless someone subscribes
        return;
    }

    my $frontend_bus = $args{frontend};
    my $frontend_id  = $frontend_bus->bus_id;

    my $backend_bus  = $self->{_BUS};
    my $backend_id   = $backend_bus->bus_id;

    my $frontend_role = $self->{frontend_role};

    foreach my $lane (1..QUEUE_LANES) {

        my $src_queue = "\$share/BKPR/msg/$frontend_role-$lane",

        my ($payload_ref, $mqtt_properties, $destination, $address);

        $backend_bus->subscribe(
            topic       => $src_queue,
            maximum_qos => 0,
            on_publish  => sub {
                ($payload_ref, $mqtt_properties) = @_;

                ($destination, $address) = split('@', $mqtt_properties->{'fwd_to'}, 2);

                if (defined $address) {

                    # Unicast
                    my $dest_queues = $self->{Addr_to_topics}->{$address} || return;

                    foreach my $queue (@$dest_queues) {

                        my ($destination, $bus_id) = split('@', $queue, 2);

                        my $frontend_bus = $self->{FRONTEND}->{$bus_id} || next;

                        $frontend_bus->publish(
                            topic   => $destination,
                            payload => $payload_ref,
                        );

                        DEBUG && log_trace "Forwarded notific:  $src_queue \@$backend_id --> $destination \@$frontend_id";
                    }
                }
                else {

                    # Broadcast
                    foreach my $frontend_bus (values %{$self->{FRONTEND}}) {

                        $frontend_bus->publish(
                            topic   => $destination,
                            payload => $payload_ref,
                        );

                        DEBUG && log_trace "Forwarded notific:  $src_queue \@$backend_id --> $destination \@$frontend_id";
                    }
                }

                $self->{_WORKER}->{notif_count}++;
            },
            on_suback => sub {
                log_debug "Forwarding $src_queue \@$backend_id --> msg/frontend/{app}/{service}/{method} \@$frontend_id";
            }
        );
    }
}

sub _init_routing_table {
    my $self = shift;

    $self->{Addr_to_topics}   = {};
    $self->{Addr_to_sessions} = {};

    $self->{MqttSessions} = $self->shared_cache( 
        id => "router",
        persist => 1,
        max_age => $self->{sess_timeout},
        on_update => sub {
            my ($caller_id, $value, $old_value) = @_;

            # Keep indexes:  address -> [ caller_addr, ... ]
            #                address -> [ caller_id,   ... ]

            if (defined $value) {
                # Bind
                my $addr  = $value->[0];
                my $topic = $value->[1];

                return unless defined $addr;

                my $relpy_topics = $self->{Addr_to_topics}->{$addr} ||= [];
                return if grep { $_ eq $topic } @$relpy_topics;
                push @$relpy_topics, $topic;

                my $caller_sessions = $self->{Addr_to_sessions}->{$addr} ||= [];
                push @$caller_sessions, $caller_id;
            }
            elsif (defined $old_value) {
                # Unbind
                my $addr  = $old_value->[0];
                my $topic = $old_value->[1];

                return unless defined $addr;

                my $relpy_topics = $self->{Addr_to_topics}->{$addr} || return;
                @$relpy_topics = grep { $_ ne $topic } @$relpy_topics;
                delete $self->{Addr_to_topics}->{$addr} unless @$relpy_topics;

                my $caller_sessions = $self->{Addr_to_sessions}->{$addr};
                @$caller_sessions = grep { $_ ne $caller_id } @$caller_sessions;
                delete $self->{Addr_to_sessions}->{$addr} unless @$caller_sessions;
            }
        },
    );

    $self->accept_remote_calls(
        '_bkpr.router.bind'   => 'bind_remote_session',
        '_bkpr.router.unbind' => 'unbind_remote_session',
    );
}

sub bind_remote_session {
    my ($self, $params) = @_;

    my $address     = $params->{address};
    my $caller_id   = $params->{caller_id};
    my $caller_addr = $params->{caller_addr};
    my $auth_data   = $params->{auth_data};

    unless (defined $caller_id && $caller_id =~ m/^\w{16,}$/) {
        # eg: 7nXDsxMDwgLUSedX
        die ( $caller_id ? "Invalid caller_id $caller_id" : "caller_id not specified");
    }

    unless (defined $caller_addr && $caller_addr =~ m!^priv/\w+\@[\w-]+$!) {
        # eg: priv/7nXDsxMDwgLUSedX@frontend-1
        die ( $caller_id ? "Invalid caller_addr $caller_addr" : "caller_addr not specified");
    }

    if (defined $address) {

        my $frontend_role = $self->{frontend_role};

        unless ($address =~ m/^[\w-]+\.[\w-]+$/) {
            # eg: frontend.user-1234
            die ( "Invalid address $address" );
        }

        unless ($address =~ m/^$frontend_role\./) {
            # eg: frontend.user-1234
            die ( "Invalid address $address: router can handle only $frontend_role.* namespace" );
        }

        $address =~ s/^$frontend_role\.//;
    }

    $self->{MqttSessions}->set( $caller_id => [ $address, $caller_addr, $auth_data ] );

    return 1;
}

sub unbind_remote_session {
    my ($self, $params) = @_;

    my $caller_id = $params->{caller_id};
    my $address   = $params->{address};

    my $frontend_role = $self->{frontend_role};

    if (defined $caller_id && $caller_id !~ m/^\w{16,}$/) {
        # eg: 7nXDsxMDwgLUSedX
        die "Invalid caller_id $caller_id";
    }

    if (defined $address && $address !~ m/^$frontend_role\.[\w-]+$/) {
        # eg: @frontend.user-1234
        die "Invalid address $address";
    }

    unless ($caller_id || $address) {
        die "No caller_id nor address were specified";
    }

    if ($caller_id) {
        # Remove single session
        $self->{MqttSessions}->delete( $caller_id );
    }

    if ($address) {

        $address =~ s/^$frontend_role\.//;

        my $sessions = $self->{Addr_to_sessions}->{$address};

        # Make a copy because @$sessions shortens on each delete
        my @sessions = $sessions ? @$sessions : ();

        # Remove all sessions binded to address
        foreach my $caller_id (@sessions) {
            $self->{MqttSessions}->delete( $caller_id );
        }
    }

    return 1;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper::Service::Router::Worker - Route messages between backend and frontend buses

=head1 VERSION
 
Version 0.07

=head1 SYNOPSIS

=head1 DESCRIPTION

Router workers pull requests from all frontend brokers and forward them to the single
backend broker it is connected to, and pull generated responses from the backend and
forward them to the aproppiate frontend broker which the client is connected to.

Additionally, routers include some primitives that can be used to implement session
management and push notifications. In order to push unicasted notifications, routers will
keep an in-memory shared table of client connections and server side assigned addresses.
Each entry consumes 1.5 KiB of memory, so a table of 100K sessions will consume around
150 MiB for each Router worker.

If the application does not bind client sessions the routers can scale horizontally 
really well, as you can have thousands of them connected to hundreds of brokers.

But please note that, when the application does use the session binding mechanism, all
routers will need the in-memory shared table, and this shared table will not scale to 
a great extent as the rest of the system. The limiting factor is the global rate of 
updates to the table, which will cap around 5000 bind operations (logins) per second.
This may be fixed on future releases by means of partitioning the table. Meanwhile, 
this session binding mechanism is not suitable for applications with a large number
of concurrent clients.

Router workers are not created automatically. In order to add Router workers to a pool
these must be declared into config file C<pool.config.json>:

  [
      {
          "pool_id" : "myapp",
          "bus_id"  : "backend",
          "workers" : {
              "Beekeeper::Service::Router::Worker" : { "worker_count": 4 },
               ...
          },
      },
  ]

=head1 METHODS

See L<Beekeeper::Service::Router> for a description of the methods exposed by this
worker class.

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
