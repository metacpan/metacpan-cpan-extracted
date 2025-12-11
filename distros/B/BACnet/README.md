`BACnet::Device` - High-level interface for BACnet device communication and COV subscriptions

# SYNOPSIS

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

# DESCRIPTION

`BACnet::Device` provides a higher-level abstraction for communicating with
BACnet devices using BACnet/IP.  
It includes:

- Management of BACnet sockets and IO::Async event loop
- Subscribing to another BACnet device and receiving COV (Change of Value) notifications
- Reading property of BACnet object of another BACnet device
- Automatic SimpleACK (approve) responses for confirmed notifications
- Automatic cleanup and lifetime handling of subscriptions

# METHODS

## new

Example:

    my $dev = BACnet::Device->new(
        id => 100,
        addr => '192.168.1.10',
        sport => 47808,
    );

Creates a new `BACnet::Device` instance.

Parameters (`%args`):

- `id` (Int) – Identifier of the local BACnet device.
- `addr` (Str) – Local IP address in dotted-decimal form.
- `sport` (Int) – Local UDP source port.

Returns a new object instance.

## read\_property

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

Parameters (`%args`):

- `obj_type` (Int) – BACnet object type.
- `obj_instance` (Int) – Object instance.
- `property_identifier` (Int) – Property identifier.
- `property_array_index` (Int|undef) – Optional array index.
- `host_ip` (Str) – Target device IP.
- `peer_port` (Int) – Target device port.
- `on_response` (CodeRef) – Callback executed after response.

## subscribe

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

Parameters (`%args`):

- `obj_type` (Int) – BACnet object type to monitor.
- `obj_inst` (Int) – Object instance to monitor.
- `host_ip` (Str) – Target device IP.
- `peer_port` (Int) – Target device port.
- `issue_confirmed_notifications` (Bool|undef) – Request confirmed notifications (1 for yes).
- `lifetime_in` (Int|undef) – Subscription lifetime in seconds (0 for indefinite).
- `on_COV` (CodeRef) – Callback executed on COV notification.
- `on_response` (CodeRef|undef) – Callback executed after subscription response.

Returns:

- (Subscription object, undef) on success.
- (undef error message) on failure.

## unsubscribe

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

- `$sub` (Subscription) – Subscription object returned by `subscribe`.
- `on_response` (CodeRef|undef) – Callback executed after unsubscription response.

Returns:

- undef on success.
- Error message on failure.

## send\_error

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

Parameters (`%args`):

- `service_choice` (Str) – BACnet service identifier associated with the original request.
- `invoke_id` (Int) – Invoke ID of the request being answered.
- `error_class` (Int) – BACnet error class.
- `error_code` (Int) – BACnet error code.
- `host_ip` (Str) – Target device IP.
- `peer_port` (Int) – Target device port.

Returns:

- undef

## send\_approve

Example:

    $dev->send_approve(
        service_choice => 'ConfirmedCOVNotification',
        host_ip => '192.168.1.20',
        peer_port => 47808,
        invoke_id => 5,
    );

Sends a SimpleACK.

Parameters (`%args`):

- `service_choice` (Str) – BACnet service name.
- `host_ip` (Str) – Target IP.
- `peer_port` (Int) – Target port.
- `invoke_id` (Int) – Invocation identifier to acknowledge.

Returns:

- undef

## run()

Starts the event loop.

Example:

    $dev->run();

## stop()

Stops the event loop.

Example:

    $dev->stop();

## DESTROY()

Automatically unsubscribes from active subscriptions.

# Data Units

## CALLBACK FUNCTIONS

Example:

    sub callback {
        my ( $device, $message, $port, $ip ) = @_;
    }

Callback function are called with parameters:

- `$device` (Device) – current Device object.
- `$message` (PDU) – Object of type PDU. PDU classes are implemented in files in BACnet/PDUTypes folder.
- `$port` (Int) – Port used by sending device.
- `$ip` (Str) – Ip address used by sending device.

## Service choices

In file `/BACnet/PDUTypes/Utils.pm` in variables:

- `$confirmed_service` - BACnet confirmed services
- `$unconfirmed_service` - BACnet unconfirmed services

# INTERNAL METHODS

The following methods are internal and not intended for external use:

- `_react`
- `_clean_subs`
- `_remove_sub`
- `_add_sub`

# BUG REPORTS

https://github.com/VojtaKrenek/BACnet-Perl/issues

# AUTHOR

Vojtěch Křenek <vojtechkrenek@email.cz>
Tomas Szaniszlo - <xszanisz@fi.muni.cz>

# LICENSE

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
