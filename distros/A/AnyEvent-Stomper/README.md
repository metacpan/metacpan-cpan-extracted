# NAME

AnyEvent::Stomper - Flexible non-blocking STOMP client

# SYNOPSIS

    use AnyEvent;
    use AnyEvent::Stomper;

    my $stomper = AnyEvent::Stomper->new(
      host       => 'localhost',
      prot       => '61613',
      login      => 'guest',
      passcode   => 'guest',
    );

    my $cv = AE::cv;

    $stomper->subscribe(
      id          => 'foo',
      destination => '/queue/foo',

      on_receipt => sub {
        my $err = $_[1];

        if ( defined $err ) {
          warn $err->message . "\n";
          $cv->send;

          return;
        }

        $stomper->send(
          destination => '/queue/foo',
          body        => 'Hello, world!',
        );
      },

      on_message => sub {
        my $msg = shift;

        my $body = $msg->body;
        print "Consumed: $body\n";

        $cv->send;
      },
    );

    $cv->recv;

# DESCRIPTION

AnyEvent::Stomper is flexible non-blocking STOMP client. Supports following
STOMP versions: 1.0, 1.1, 1.2.

Is recommended to read STOMP protocol specification before using the client:
[https://stomp.github.io/index.html](https://stomp.github.io/index.html)

# CONSTRUCTOR

## new( %params )

    my $stomper = AnyEvent::Stomper->new(
      host               => 'localhost',
      port               => '61613',
      login              => 'guest',
      passcode           => 'guest',
      vhost              => '/',
      heartbeat          => [ 5000, 5000 ],
      connection_timeout => 5,
      lazy               => 1,
      reconnect_interval => 5,

      on_connect => sub {
        # handling...
      },

      on_disconnect => sub {
        # handling...
      },

      on_error => sub {
        my $err = shift;

        # error handling...
      },
    );

- host => $host

    Server hostname (default: localhost)

- port => $port

    Server port (default: 61613)

- login => $login

    The user identifier used to authenticate against a secured STOMP server.

- passcode => $passcode

    The password used to authenticate against a secured STOMP server.

- vhost => $vhost

    The name of a virtual host that the client wishes to connect to.

- heartbeat => \\@heartbeat

    Heart-beating can optionally be used to test the healthiness of the underlying
    TCP connection and to make sure that the remote end is alive and kicking. The
    first number sets interval in milliseconds between outgoing heart-beats to the
    STOMP server. `0` means, that the client will not send heart-beats. The second
    number sets interval in milliseconds between incoming heart-beats from the
    STOMP server. `0` means, that the client does not want to receive heart-beats.

        heartbeat => [ 5000, 5000 ],

    Not set by default.

- connection\_timeout => $connection\_timeout

    Specifies connection timeout. If the client could not connect to the server
    after specified timeout, the `on_error` callback is called with the
    `E_CANT_CONN` error. The timeout specifies in seconds and can contain a
    fractional part.

        connection_timeout => 10.5,

    By default the client use kernel's connection timeout.

- lazy => $boolean

    If enabled, the connection establishes at time when you will send the first
    command to the server. By default the connection establishes after calling of
    the `new` method.

    Disabled by default.

- reconnect\_interval => $reconnect\_interval

    If the connection to the server was lost, the client will try to restore the
    connection when you execute next command. By default reconnection is performed
    immediately, on next command execution. If the `reconnect_interval` parameter
    is specified, the client will try to reconnect only after this interval and
    commands executed between reconnections will be queued.

    The client will try to reconnect only once and, if attempt fails, the error
    object is passed to command callback. If you need several attempts of the
    reconnection, you must retry a command from the callback as many times, as you
    need.

        reconnect_interval => 5,

    Not set by default.

- handle\_params => \\%params

    Specifies [AnyEvent::Handle](https://metacpan.org/pod/AnyEvent::Handle) parameters.

        handle_params => {
          autocork => 1,
          linger   => 60,
        }

    Enabling of the `autocork` parameter can improve performance. See
    documentation on [AnyEvent::Handle](https://metacpan.org/pod/AnyEvent::Handle) for more information.

- default\_headers => \\%headers

    Specifies default headers for all outgoing frames.

        default_headers => {
          'x-foo' => 'foo_value',
          'x-bar' => 'bar_value',
        }

- command\_headers

    Specifies default headers for particular commands.

        command_headers => {
          SEND => {
            receipt => 'auto',
          },

          SUBSCRIBE => {
            durable => 'true',
            ack     => 'client',
          },
        }

- on\_connect => $cb->()

    The `on_connect` callback is called when the connection is successfully
    established.

    Not set by default.

- on\_disconnect => $cb->()

    The `on_disconnect` callback is called when the connection is closed by any
    reason.

    Not set by default.

- on\_error => $cb->( $err )

    The `on_error` callback is called when occurred an error, which was affected
    on entire client (e. g. connection error or authentication error). Also the
    `on_error` callback is called on command errors if the command callback is not
    specified. If the `on_error` callback is not specified, the client just print
    an error messages to `STDERR`.

# COMMAND METHODS

To execute the STOMP command you must call appropriate method. STOMP headers
can be specified as command parameters. The client automatically adds
`content-length` header to all outgoing frames. Every command method can also
accept two additional parameters: the `body` parameter where you can specify
the body of the frame, and the `on_receipt` parameter that is the alternative
way to specify the command callback.

If you want to receive `RECEIPT` frame, you must specify `receipt` header.
The `receipt` header can take the special value `auto`. If it set, the
receipt identifier will be generated automatically by the client. The
`RECEIPT` frame is passed to the command callback in first argument as the
object of the class [AnyEvent::Stomper::Frame](https://metacpan.org/pod/AnyEvent::Stomper::Frame). If the `receipt` header is
not specified the first argument of the command callback will be `undef`.

For commands `SUBSCRIBE`, `UNSUBSCRIBE`, `DISCONNECT` the client
automatically adds `receipt` header for internal usage.

The command callback is called in one of two cases depending on the presence of
the `receipt` header. First case, when the command was successfully written to
the socket. Second case, when the `RECEIPT` frame will be received. In first
case `on_receipt` callback can be called synchronously. If any error occurred
during the command execution, the error object is passed to the callback in
second argument. Error object is the instance of the class
[AnyEvent::Stomper::Error](https://metacpan.org/pod/AnyEvent::Stomper::Error).

The command callback is optional. If it is not specified and any error
occurred, the `on_error` callback of the client is called.

The full list of all available headers for every command you can find in STOMP
protocol specification and in documentation on your STOMP server. For various
versions of STOMP protocol and various STOMP servers they can be differ.

## send( \[ %params \] \[, $cb->( $receipt, $err ) \] )

Sends a message to a destination in the messaging system.

    $stomper->send(
      destination => '/queue/foo',
      body        => 'Hello, world!',
    );

    $stomper->send(
      destination => '/queue/foo',
      body        => 'Hello, world!',

      sub {
        my $err = $_[1];

        if ( defined $err ) {
          my $err_msg   = $err->message;
          my $err_code  = $err->code;
          my $err_frame = $err->frame;

          # error handling...

          return;
        }
      }
    );

    $stomper->send(
      destination => '/queue/foo',
      receipt     => 'auto',
      body        => 'Hello, world!',

      on_receipt => sub {
        my $receipt = shift;
        my $err     = shift;

        if ( defined $err ) {
          my $err_msg   = $err->message;
          my $err_code  = $err->code;
          my $err_frame = $err->frame;

          # error handling...

          return;
        }

        # receipt handling...
      }
    );

## subscribe( \[ %params \] \[, $cb->( $msg ) \] )

The method is used to register to listen to a given destination. The
`subscribe` method require the `on_message` callback, which is called on
every received `MESSAGE` frame from the server. The `MESSAGE` frame is passed
to the `on_message` callback in first argument as the object of the class
[AnyEvent::Stomper::Frame](https://metacpan.org/pod/AnyEvent::Stomper::Frame). If the `subscribe` method is called with one
callback, this callback will be act as `on_message` callback.

    $stomper->subscribe(
      id          => 'foo',
      destination => '/queue/foo',

      sub {
        my $msg = shift;

        my $headers = $msg->headers;
        my $body    = $msg->body;

        # message handling...
      },
    );

    $stomper->subscribe(
      id          => 'foo',
      destination => '/queue/foo',
      ack         => 'client',

      on_receipt => sub {
        my $receipt = shift;
        my $err     = shift;

        if ( defined $err ) {
          my $err_msg   = $err->message;
          my $err_code  = $err->code;
          my $err_frame = $err->frame;

          return;
        }

        # receipt handling...
      },

      on_message => sub {
        my $msg = shift;

        my $headers = $msg->headers;
        my $body    = $msg->body;

        # message handling...
      },
    );

## unsubscribe( \[ %params \] \[, $cb->( $receipt, $err ) \] )

The method is used to remove an existing subscription.

    $stomper->unsubscribe(
      id          => 'foo',
      destination => '/queue/foo',

      sub {
        my $receipt = shift;
        my $err     = shift;

        if ( defined $err ) {
          my $err_msg   = $err->message;
          my $err_code  = $err->code;
          my $err_frame = $err->frame;

          return;
        }

        # receipt handling...
      }
    );

## ack( \[ %params \] \[, $cb->( $receipt, $err ) \] )

The method is used to acknowledge consumption of a message from a subscription
using `client` or `client-individual` acknowledgment. Any messages received
from such a subscription will not be considered to have been consumed until the
message has been acknowledged via an `ack()` method. Method `ack()` must be
called with required parameter `message` in which must be specified the
`MESSAGE` frame.

    $stomper->ack( message => $msg );

    $stomper->ack(
      message => $msg,
      receipt => 'auto',

      sub {
        my $receipt = shift;
        my $err     = shift;

        if ( defined $err ) {
          my $err_msg   = $err->message;
          my $err_code  = $err->code;
          my $err_frame = $err->frame;

          # error handling...
        }

        # receipt handling...
      }
    );

## nack( \[ %params \] \[, $cb->( $receipt, $err ) \] )

The `nack` method is the opposite of `ack` method. It is used to tell the
server that the client did not consume the message. Method `nack()` must be
called with required parameter `message` in which must be specified the
`MESSAGE` frame.

    $stomper->nack( message => $msg );

    $stomper->nack(
      message => $msg,
      receipt => 'auto',

      sub {
        my $receipt = shift;
        my $err     = shift;

        if ( defined $err ) {
          my $err_msg   = $err->message;
          my $err_code  = $err->code;
          my $err_frame = $err->frame;

          # error handling...
        }

        # receipt handling...
      }
    );

## begin( \[ %params \] \[, $cb->( $receipt, $err ) \] )

The method `begin` is used to start a transaction.

## commit( \[ %params \] \[, $cb->( $receipt, $err ) \] )

The method `commit` is used to commit a transaction.

## abort( \[ %params \] \[, $cb->( $receipt, $err ) \] )

The method `abort` is used to roll back a transaction.

## disconnect( \[ %params \] \[, $cb->( $receipt, $err ) \] )

A client can disconnect from the server at anytime by closing the socket but
there is no guarantee that the previously sent frames have been received by
the server. To do a graceful shutdown, where the client is assured that all
previous frames have been received by the server, you must call `disconnect`
method and wait for the `RECEIPT` frame.

## execute( $command, \[ %params \] \[, $cb->( $receipt, $err ) \] )

An alternative method to execute commands. In some cases it can be more
convenient.

    $stomper->execute( 'SEND',
      destination => '/queue/foo',
      receipt     => 'auto',
      body        => 'Hello, world!',

      sub {
        my $receipt = shift;
        my $err     = shift;

        if ( defined $err ) {
          my $err_msg   = $err->message;
          my $err_code  = $err->code;
          my $err_frame = $err->frame;

          # error handling...

          return;
        }

        # receipt handling...
      }
    );

# ERROR CODES

Every error object, passed to callback, contain error code, which can be used
for programmatic handling of errors. AnyEvent::Stomper provides constants for
error codes. They can be imported and used in expressions.

    use AnyEvent::Stomper qw( :err_codes );

- E\_CANT\_CONN

    Can't connect to the server. All operations were aborted.

- E\_IO

    Input/Output operation error. The connection to the STOMP server was closed and
    all operations were aborted.

- E\_CONN\_CLOSED\_BY\_REMOTE\_HOST

    The connection closed by remote host. All operations were aborted.

- E\_CONN\_CLOSED\_BY\_CLIENT

    Connection closed by client prematurely. Uncompleted operations were aborted

- E\_OPRN\_ERROR

    Operation error. For example, missing required header.

- E\_UNEXPECTED\_DATA

    The client received unexpected data from the server. The connection to the
    STOMP server was closed and all operations were aborted.

- E\_READ\_TIMEDOUT

    Read timed out. The connection to the STOMP server was closed and all operations
    were aborted.

# OTHER METHODS

## host()

Gets current host of the client.

## port()

Gets current port of the client.

## connection\_timeout( \[ $fractional\_seconds \] )

Gets or sets the `connection_timeout` of the client. The `undef` value resets
the `connection_timeout` to default value.

## reconnect\_interval( \[ $fractional\_seconds \] )

Gets or sets `reconnect_interval` of the client.

## on\_connect( \[ $callback \] )

Gets or sets the `on_connect` callback.

## on\_disconnect( \[ $callback \] )

Gets or sets the `on_disconnect` callback.

## on\_error( \[ $callback \] )

Gets or sets the `on_error` callback.

## force\_disconnect()

The method for forced disconnection. All uncompleted operations will be
aborted.

# WORKING WITH CLUSTER

If you have the cluster of STOMP servers, you can use
[AnyEvent::Stomper::Cluster](https://metacpan.org/pod/AnyEvent::Stomper::Cluster) to work with it.

# SEE ALSO

[AnyEvent::Stomper::Cluster](https://metacpan.org/pod/AnyEvent::Stomper::Cluster)

# AUTHOR

Eugene Ponizovsky, <ponizovsky@gmail.com>

Sponsored by SMS Online, <dev.opensource@sms-online.com>

# COPYRIGHT AND LICENSE

Copyright (c) 2016-2017, Eugene Ponizovsky, SMS Online. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
