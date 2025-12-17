#!/usr/bin/perl

package BACnet::Device;

use v5.16;

use warnings;
use strict;

use Data::Dumper;

use BACnet::Subscription;
use BACnet::Socket;
use BACnet::APDU;
use BACnet::ServiceRequestSequences::SubscribeCOV;
use BACnet::PDUTypes::Error;
use BACnet::PDUTypes::SimpleACK;
use BACnet::ServiceRequestSequences::COVConfirmedNotification;
use BACnet::ServiceRequestSequences::Utils;

use IO::Async::Loop;

sub new {
    my ( $class, %args ) = @_;

    my @subscriptions = ();

    my $io_loop = IO::Async::Loop->new;

    my %args_socket = (
        retries => 3,
        timeout => 3,
        io_loop => $io_loop,
        debug   => 0,
        addr    => $args{addr},
        sport   => $args{sport}
    );

    my $self = {
        socket    => undef,
        id        => $args{id},
        subs_ptr  => \@subscriptions,
        invoke_id => 0,
    };

    my $socket = BACnet::Socket->new( $self, %args_socket );

    $self->{socket} = $socket;

    bless $self, $class;
    return $self;
}

sub _react {
    my ( $self, $message, $source_port, $source_ip ) = @_;

    if (   !defined $message->{payload}
        || !defined $message->{payload}->{service_request}
        || !defined $message->{payload}->{service_request}->{val}
        || !
        defined $message->{payload}->{service_request}->{val}
        ->{monitored_object_identifier}
        || defined $message->{payload}->{service_request}->{val}
        ->{monitored_object_identifier}->{error} )
    {
        return;
    }

    my $monitored_object_identifier =
      $message->{payload}->{service_request}->{val}
      ->{monitored_object_identifier};

    for my $subscription ( @{ $self->{subs_ptr} } ) {
        my @octets           = map { ord($_) } split //, $source_ip;
        my $source_ip_string = join( '.', @octets );

        if (   $source_ip_string eq $subscription->{host_ip}
            && $monitored_object_identifier->{object_type} ==
            $subscription->{obj_type}
            && $monitored_object_identifier->{object_instance} ==
            $subscription->{obj_inst} )
        {
            $subscription->{on_COV}
              ->( $self, $message->{payload}, $source_port, $source_ip );

            if ( !defined $message->{error}
                && $message->{payload}
                ->isa('BACnet::PDUTypes::ConfirmedRequest') )
            {
                $self->send_approve(
                    service_choice => 'ConfirmedCOVNotification',
                    host_ip        => $source_ip_string,
                    peer_port      => $source_port,
                    invoke_id      => $message->{payload}->{invoke_id}
                );
            }

            last;
        }
    }
}

sub _invoke_id {
    my ($self) = @_;

    my $result = $self->{invoke_id};
    $self->{invoke_id} = ( $self->{invoke_id}  + 1) % 256;

    return $result;
}

sub _clean_subs {
    my ($self) = @_;
    my $current_time = time();
    @{ $self->{subs_ptr} } = grep {
             ( $_->{lifetime} >= $current_time - 60 )
          || ( $_->{lifetime} == 0 )
    } @{ $self->{subs_ptr} };

    #-60 means that device let sub in list subscription time + 1 min, it
    #helps system to stand out bursts of messages when some messages
    #can leas in socket que some time. If the delay is longer than 1 min
    #the system is already messed up (in most cases).
}

sub _remove_sub {
    my ( $self, $subscription ) = @_;
    @{ $self->{subs_ptr} } = grep {
        !(     $_->{host_ip} eq $subscription->{host_ip}
            && $_->{obj_type} eq $subscription->{obj_type}
            && $_->{obj_inst} == $subscription->{obj_inst} )
    } @{ $self->{subs_ptr} };
}

sub _add_sub {
    my ( $self, $subscription ) = @_;
    push @{ $self->{subs_ptr} }, $subscription;
}

sub subscribe {
    my ( $self, @rest ) = @_;

    my %args = (
        obj_type                      => undef,
        obj_inst                      => undef,
        issue_confirmed_notifications => undef,
        lifetime_in                   => undef,
        host_ip                       => undef,
        peer_port                     => undef,
        on_COV                        => undef,
        on_response                   => undef,
        @rest,
    );

    $self->_clean_subs();

    my $subscription = BACnet::Subscription->new(%args);

    my $sub_time;

    if ( $subscription->{lifetime} == 0 ) {
        $sub_time = 0;
    }
    else {
        $sub_time = $subscription->{lifetime} - time();
    }

    my $invoke_id = $self->_invoke_id();

    my $packet = BACnet::APDU->construct(
        BACnet::PDUTypes::ConfirmedRequest->construct(
            invoke_id       => $invoke_id,
            service_choice  => 'SubscribeCOV',
            service_request =>
              BACnet::ServiceRequestSequences::SubscribeCOV::request(
                subscriber_process_identifier    => $self->{id},
                monitored_object_identifier_type => $subscription->{obj_type},
                monitored_object_identifier_instance =>
                  $subscription->{obj_inst},
                issue_confirmed_notifications =>
                  $subscription->{issue_confirmed_notifications},
                lifetime => $sub_time,
              ),
            flags => 0x00,
        )
    );

    $self->_add_sub($subscription);

    my $sub_res =
      $self->{socket}->_send_recv( $packet, $args{host_ip}, $args{peer_port},
        ( on_response => $args{on_response}, invoke_id => $invoke_id ) );

    if ( !defined $sub_res->result ) {
        _remove_sub( $self, $subscription );
        return ( undef, "subscription failed\n" );
    }

    return ( $subscription, undef );
}

sub send_approve {
    my ( $self, @rest ) = @_;

    my %args = (
        service_choice => undef,
        host_ip        => undef,
        peer_port      => undef,
        invoke_id      => undef,
        @rest,
    );

    my $packet = BACnet::APDU->construct(
        BACnet::PDUTypes::SimpleACK->construct(
            invoke_id      => $args{invoke_id},
            service_choice => $args{service_choice},
        )
    );

    $self->{socket}->_send( $packet, $args{host_ip}, $args{peer_port} );
}

sub send_error {
    my ( $self, @rest ) = @_;

    my %args = (
        service_choice => undef,
        invoke_id      => undef,
        error_class    => undef,
        error_code     => undef,
        host_ip        => undef,
        peer_port      => undef,
        @rest,
    );

    my $error = BACnet::ServiceRequestSequences::Utils::_error_type(
        error_class => $args{error_class},
        error_code  => $args{error_code},
    );

    my $packet = BACnet::APDU->construct(
        BACnet::PDUTypes::Error->construct(
            invoke_id       => $args{invoke_id},
            service_choice  => $args{service_choice},
            service_request => $error,
        )
    );

    $self->{socket}->_send( $packet, $args{host_ip}, $args{peer_port} );
}

sub read_property {
    my ( $self, @rest ) = @_;

    my %args = (
        obj_type             => undef,
        obj_instance         => undef,
        property_identifier  => undef,
        property_array_index => undef,
        host_ip              => undef,
        peer_port            => undef,
        on_response          => undef,
        @rest,
    );

    my $invoke_id = $self->_invoke_id();

    my $packet = BACnet::APDU->construct(
        BACnet::PDUTypes::ConfirmedRequest->construct(
            invoke_id       => $invoke_id,
            service_choice  => 'ReadProperty',
            service_request =>
              BACnet::ServiceRequestSequences::ReadProperty::request(
                object_identifier_type     => $args{obj_type},
                object_identifier_instance => $args{obj_instance},
                property_identifier        => $args{property_identifier},
                property_array_index       => $args{property_array_index},
              ),
            flags => 0x00,
        )
    );

    my $read_res =
      $self->{socket}->_send_recv( $packet, $args{host_ip}, $args{peer_port},
        ( on_response => $args{on_response}, invoke_id => $invoke_id ) );

    if ( !defined $read_res->result ) {
        return ( undef, "read property failed\n" );
    }

    return;
}

sub unsubscribe {
    my ( $self, $subscription, $on_response ) = @_;

    $self->_clean_subs();

    my $invoke_id = $self->_invoke_id();

    my $packet = BACnet::APDU->construct(
        BACnet::PDUTypes::ConfirmedRequest->construct(
            invoke_id       => $invoke_id,
            service_choice  => 'SubscribeCOV',
            service_request =>
              BACnet::ServiceRequestSequences::SubscribeCOV::request(
                subscriber_process_identifier    => $self->{id},
                monitored_object_identifier_type => $subscription->{obj_type},
                monitored_object_identifier_instance =>
                  $subscription->{obj_inst},
              ),
            flags => 0x00,
        )
    );

    my $sub_res = $self->{socket}->_send_recv(
        $packet,
        $subscription->{host_ip},
        $subscription->{peer_port},
        ( on_response => $on_response, invoke_id => $invoke_id )
    );

    $sub_res->get;

    if ( !defined $sub_res->result ) {
        return ("unsubscription failed\n");
    }

    _remove_sub( $self, $subscription );
    return undef;
}

sub run {
    my ($self) = @_;
    $self->{socket}->{loop}->loop_forever;
}

sub stop {
    my ($self) = @_;
    $self->{socket}->_stop();
}

sub subscriptions {
    my ($self) = @_;

    $self->_clean_subs();
    return @{ $self->{subs_ptr} };
}

sub DESTROY {
    my ($self) = @_;
}

1;

=encoding UTF-8
=head1 NAME

C<BACnet::Device> - High-level interface for BACnet device communication and COV subscriptions

=head1 SYNOPSIS

    use BACnet::Device;

    my $dev = BACnet::Device->new(
        id    => 100,
        addr  => '192.168.1.10',
        sport => 47808,
    );

    my ($sub, $err) = $dev->subscribe(
        obj_type  => 1,
        obj_inst  => 5,
        host_ip   => '192.168.1.20',
        peer_port => 47808,
        on_COV    => sub {
            my ($dev, $payload, $port, $ip) = @_;
            print "COV update received\n";
        },
    );

    $dev->run;

=head1 DESCRIPTION

C<BACnet::Device> provides a higher-level abstraction for communicating with
BACnet devices using BACnet/IP.  
It includes:

=over 4

=item * Management of BACnet sockets and IO::Async event loop

=item * Subscribing to another BACnet device and receiving COV (Change of Value) notifications

=item * Reading property of BACnet object of another BACnet device

=item * Automatic SimpleACK (approve) responses for confirmed notifications

=item * Automatic cleanup and lifetime handling of subscriptions

=back

=head1 METHODS


=head2 new


Example:


    my $dev = BACnet::Device->new(
        id => 100,
        addr => '192.168.1.10',
        sport => 47808,
    );



Creates a new C<BACnet::Device> instance.


Parameters (C<%args>):

=over 4

=item * C<id> (Int) – Identifier of the local BACnet device.

=item * C<addr> (Str) – Local IP address in dotted-decimal form.

=item * C<sport> (Int) – Local UDP source port.

=back


Returns a new object instance.

=head2 read_property


Example:


    $dev->read_property(
        obj_type => 0,
        obj_instance => 1,
        property_identifier => 85,
        host_ip => '192.168.1.20',
        peer_port => 47808,
        on_response => sub {
                print "Property value received";
            },
    );



Sends a BACnet ReadProperty request.


Parameters (C<%args>):


=over 4

=item * C<obj_type> (Int) – BACnet object type.

=item * C<obj_instance> (Int) – Object instance.

=item * C<property_identifier> (Int) – Property identifier.

=item * C<property_array_index> (Int|undef) – Optional array index.

=item * C<host_ip> (Str) – Target device IP.

=item * C<peer_port> (Int) – Target device port.

=item * C<on_response> (CodeRef) – Callback executed after response.

=back


=head2 subscribe

Example:

    my ($sub, $err) = $dev->subscribe(
        obj_type  => 1,
        obj_inst  => 5,
        host_ip   => '192.168.1.20',
        peer_port => 47808,
        issue_confirmed_notifications => 1,
        lifetime_in => 300,
        on_COV    => sub {
            my ($dev, $payload, $port, $ip) = @_;
            print "COV update received\n";
        },
        on_response => sub {
            print "Subscription response received\n";
        },
    );


Subscribes to a BACnet object to receive COV (Change Of Value) notifications.

Parameters (C<%args>):

=over 4

=item * C<obj_type> (Int) – BACnet object type to monitor.

=item * C<obj_inst> (Int) – Object instance to monitor.

=item * C<host_ip> (Str) – Target device IP.

=item * C<peer_port> (Int) – Target device port.

=item * C<issue_confirmed_notifications> (Bool|undef) – Request confirmed notifications (1 for yes).

=item * C<lifetime_in> (Int|undef) – Subscription lifetime in seconds (0 for indefinite).

=item * C<on_COV> (CodeRef) – Callback executed on COV notification.

=item * C<on_response> (CodeRef|undef) – Callback executed after subscription response.

=back

Returns:

=over 4

=item * (Subscription object, undef) on success.

=item * (undef error message) on failure.

=back


=head2 unsubscribe

Example:

    my $err = $dev->unsubscribe(
        $sub,
        sub {
            my ($res) = @_;
            print "Unsubscription response received\n";
        },
    );

Cancels an existing subscription on a remote BACnet device.

Parameters:

=over 4

=item * C<$sub> (Subscription) – Subscription object returned by C<subscribe>.

=item * C<on_response> (CodeRef|undef) – Callback executed after unsubscription response.

=back

Returns:

=over 4

=item * undef on success.

=item * Error message on failure.

=back

=head2 send_error

Example:

    $dev->send_error(
        service_choice => 'ReadProperty',
        invoke_id      => 42,
        error_class    => 1,
        error_code     => 32,    
        host_ip        => '192.168.1.20',
        peer_port      => 47808,
    );

Sends a BACnet Error APDU.

Parameters (C<%args>):

=over 4

=item * C<service_choice> (Str) – BACnet service identifier associated with the original request.

=item * C<invoke_id> (Int) – Invoke ID of the request being answered.

=item * C<error_class> (Int) – BACnet error class.

=item * C<error_code> (Int) – BACnet error code.

=item * C<host_ip> (Str) – Target device IP.

=item * C<peer_port> (Int) – Target device port.

=back

Returns:

=over 4

=item * undef

=back


=head2 send_approve


Example:


    $dev->send_approve(
        service_choice => 'ConfirmedCOVNotification',
        host_ip => '192.168.1.20',
        peer_port => 47808,
        invoke_id => 5,
    );


Sends a SimpleACK.


Parameters (C<%args>):


=over 4

=item * C<service_choice> (Str) – BACnet service name.

=item * C<host_ip> (Str) – Target IP.

=item * C<peer_port> (Int) – Target port.

=item * C<invoke_id> (Int) – Invocation identifier to acknowledge.

=back

Returns:

=over 4

=item * undef

=back


=head2 run()

Starts the event loop.

Example:

    $dev->run();


=head2 stop()

Stops the event loop.

Example:

    $dev->stop();


=head2 subscriptions()

Returns list of active and less than 60 seconds expired subscriptions.

=head2 DESTROY()

=head1 DATA UNITS

=head2 callback functions

Example:

    sub callback {
        my ( $device, $message, $port, $ip ) = @_;
    }

Callback function are called with parameters:

=over 4

=item * C<$device> (Device) – current Device object.

=item * C<$message> (PDU) – Object of type PDU. PDU classes are implemented in files in BACnet/PDUTypes folder.

=item * C<$port> (Int) – Port used by sending device.

=item * C<$ip> (Str) – Ip address used by sending device.

=back


=head2  Service choices


In file C</BACnet/PDUTypes/Utils.pm> in variables:

=over 4

=item * C<$confirmed_service> - BACnet confirmed services

=item * C<$unconfirmed_service> - BACnet unconfirmed services


=back


=head1 INTERNAL METHODS

The following methods are internal and not intended for external use:

=over 4

=item * C<_react>

=item * C<_clean_subs>

=item * C<_remove_sub>

=item * C<_add_sub>

=item * C<_invoke_id>

=back

=head1 AUTHOR

Vojtěch Křenek <vojtechkrenek@email.cz>
Tomas Szaniszlo - <xszanisz@fi.muni.cz>

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut
