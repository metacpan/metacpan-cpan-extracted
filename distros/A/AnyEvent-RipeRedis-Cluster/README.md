# NAME

AnyEvent::RipeRedis::Cluster - Non-blocking Redis Cluster client

# SYNOPSIS

    use AnyEvent;
    use AnyEvent::RipeRedis::Cluster;

    my $cluster = AnyEvent::RipeRedis::Cluster->new(
      startup_nodes => [
        { host => 'localhost', port => 7000 },
        { host => 'localhost', port => 7001 },
        { host => 'localhost', port => 7002 },
      ],
    );

    my $cv = AE::cv;

    $cluster->set( 'foo', 'bar',
      sub {
        my $err = $_[1];

        if ( defined $err ) {
          warn $err->message . "\n";
          $cv->send;

          return;
        }

        $cluster->get( 'foo',
          sub {
            my $reply = shift;
            my $err   = shift;

            if ( defined $err ) {
              warn $err->message . "\n";
              $cv->send;

              return;
            }

            print "$reply\n";
            $cv->send;
          }
        );
      }
    );

    $cv->recv;

# DESCRIPTION

AnyEvent::RipeRedis::Cluster is non-blocking Redis Cluster client built on top
of the [AnyEvent::RipeRedis](https://metacpan.org/pod/AnyEvent::RipeRedis).

Requires Redis 3.0 or higher, and any supported event loop.

For more information about Redis Cluster see here:

- [http://redis.io/topics/cluster-tutorial](http://redis.io/topics/cluster-tutorial)
- [http://redis.io/topics/cluster-spec](http://redis.io/topics/cluster-spec)

# CONSTRUCTOR

## new( %params )

    my $cluster = AnyEvent::RipeRedis::Cluster->new(
      startup_nodes => [
        { host => 'localhost', port => 7000 },
        { host => 'localhost', port => 7001 },
        { host => 'localhost', port => 7002 },
      ],
      connection_timeout => 5,
      read_timeout       => 5,
      refresh_interval   => 5,
      lazy               => 1,
      reconnect_interval => 5,

      on_node_connect => sub {
        my $host = shift;
        my $port = shift;

        # handling...
      },

      on_node_disconnect => sub {
        my $host = shift;
        my $port = shift;

        # handling...
      },

      on_node_error => sub {
        my $err = shift;
        my $host = shift;
        my $port = shift;

        # error handling...
      },

      on_error => sub {
        my $err = shift;

        # error handling...
      },
    );

- startup\_nodes => \\@nodes

    Specifies the list of startup nodes. Parameter should contain the array of
    hashes that contains addresses of some nodes in the cluster. Each hash should
    contain `host` and `port` elements. The client will try to connect to random
    node from the list to retrieve information about all cluster nodes and slots
    mapping. If the client could not connect to first selected node, it will try
    to connect to another random node from the list.

- password => $password

    If the password is specified, the `AUTH` command is sent to all nodes
    of the cluster after connection.

- allow\_slaves => $boolean

    If enabled, the client will try to send read-only commands to slave nodes.

    Disabled by default.

- utf8 => $boolean

    If enabled, all strings will be converted to UTF-8 before sending to nodes,
    and all results will be decoded from UTF-8.

    Enabled by default.

- connection\_timeout => $fractional\_seconds

    Specifies connection timeout. If the client could not connect to the node
    after specified timeout, the `on_node_error` callback is called with the
    `E_CANT_CONN` error. The timeout specifies in seconds and can contain a
    fractional part.

        connection_timeout => 10.5,

    By default the client use kernel's connection timeout.

- read\_timeout => $fractional\_seconds

    Specifies read timeout. If the client could not receive a reply from the node
    after specified timeout, the client close connection and call the
    `on_node_error` callback with the `E_READ_TIMEDOUT` error. The timeout is
    specifies in seconds and can contain a fractional part.

        read_timeout => 3.5,

    Not set by default.

- lazy => $boolean

    If enabled, the initial connection to the startup node establishes at time when
    you will send the first command to the cluster. By default the initial
    connection establishes after calling of the `new` method.

    Disabled by default.

- reconnect => $boolean

    If the connection to the node was lost and the parameter `reconnect` is
    TRUE (default), the client will try to restore the connection when you execute
    next command. The client will try to reconnect only once and, if attempt fails,
    the error object is passed to command callback. If you need several attempts of
    the reconnection, you must retry a command from the callback as many times, as
    you need. Such behavior allows to control reconnection procedure.

    Enabled by default.

- reconnect\_interval => $fractional\_seconds

    If the parameter is specified, the client will try to reconnect only after
    this interval. Commands executed between reconnections will be queued.

        reconnect_interval => 5,

    Not set by default.

- refresh\_interval => $fractional\_seconds

    Cluster state refresh interval. If set to zero, cluster state will be updated
    only on MOVED redirect.

    By default is 15 seconds.

- handle\_params => \\%params

    Specifies [AnyEvent::Handle](https://metacpan.org/pod/AnyEvent::Handle) parameters.

        handle_params => {
          autocork => 1,
          linger   => 60,
        }

    Enabling of the `autocork` parameter can improve performance. See
    documentation on [AnyEvent::Handle](https://metacpan.org/pod/AnyEvent::Handle) for more information.

- on\_node\_connect => $cb->( $host, $port )

    The `on_node_connect` callback is called when the connection to particular
    node is successfully established. To callback are passed two arguments: host
    and port of the node to which the client was connected.

    Not set by default.

- on\_node\_disconnect => $cb->( $host, $port )

    The `on_node_disconnect` callback is called when the connection to particular
    node is closed by any reason. To callback are passed two arguments: host and
    port of the node from which the client was disconnected.

    Not set by default.

- on\_node\_error => $cb->( $err, $host, $port )

    The `on_node_error` callback is called when occurred an error, which was
    affected on entire node (e. g. connection error or authentication error). Also
    the `on_node_error` callback can be called on command errors if the command
    callback is not specified. To callback are passed three arguments: error object,
    and host and port of the node on which an error occurred.

    Not set by default.

- on\_error => $cb->( $err )

    The `on_error` callback is called when occurred an error, which was affected
    on entire client (e. g. nodes discovery error). Also the `on_error` callback is
    called on command errors if the command callback is not specified. If the
    `on_error` callback is not specified, the client just print an error messages
    to `STDERR`.

# COMMAND EXECUTION

## &lt;command>( \[ @args \] \[, ( $cb->( $reply, $err ) | \\%cbs ) \] )

To execute the command you must call particular method with corresponding name.
The reply to the command is passed to the callback in first argument. If any
error occurred during the command execution, the error object is passed to the
callback in second argument. The error object is the instance of the class
[AnyEvent::RipeRedis::Error](https://metacpan.org/pod/AnyEvent::RipeRedis::Error).

Before the command execution, the client determines the pool of nodes, on which
the command can be executed. The pool can contain the one or more nodes
depending on the cluster and the client configurations, and command type. The
client will try to execute the command on random node from the pool and, if the
command failed on selected node, the client will try to execute it on another
random node.

The command callback is optional. If it is not specified and any error
occurred, the `on_error` callback of the client is called.

The full list of the Redis commands can be found here: [http://redis.io/commands](http://redis.io/commands).

    $cluster->get( 'foo',
      sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          my $err_msg  = $err->message;
          my $err_code = $err->code;

          # error handling...

          return;
        }

        print "$reply\n";
      }
    );

    $cluster->lrange( 'list', 0, -1,
      sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          my $err_msg  = $err->message;
          my $err_code = $err->code;

          # error handling...

          return;
        }

        foreach my $value ( @{$reply}  ) {
          print "$value\n";
        }
      }
    );

    $cluster->incr( 'counter' );

If you want to track errors on particular nodes, you must specify `on_node_error`
callback in command method.

    $cluster->get( 'foo',
      { on_reply => sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            my $err_msg  = $err->message;
            my $err_code = $err->code;

            # error handling...

            return;
          }

          print "$reply\n";
        },

        on_node_error => sub {
          my $err  = shift;
          my $host = shift;
          my $port = shift;

          # error handling...
        }
      }
    );

## execute( $command \[, @args \] \[, ( $cb->( $reply, $err ) | \\%cbs ) \] )

An alternative method to execute commands. In some cases it can be more
convenient.

    $cluster->execute( 'get', 'foo',
      sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          my $err_msg  = $err->message;
          my $err_code = $err->code;

          # error handling...

          return;
        }

        print "$reply\n";
      }
    );

# TRANSACTIONS

To perform the transaction you must get the master node by the key using
`nodes` method and then execute all commands on this node. Nodes must be
discovered first.

    $node = $cluster->nodes('foo');

    $node->multi;
    $node->set( '{foo}bar', "some\r\nstring" );
    $node->set( '{foo}car', 42 );
    $node->exec(
      sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          # error handling...

          return;
        }

        # reply handling...
      }
    );

The detailed information about the Redis transactions can be found in
documentation on [AnyEvent::RipeRedis](https://metacpan.org/pod/AnyEvent::RipeRedis) and here:
[http://redis.io/topics/transactions](http://redis.io/topics/transactions).

# ERROR CODES

Every error object, passed to callback, contain error code, which can be used
for programmatic handling of errors. AnyEvent::RipeRedis::Cluster provides
constants for error codes. They can be imported and used in expressions.

    use AnyEvent::RipeRedis::Cluster qw( :err_codes );

Full list of error codes see in documentation on [AnyEvent::RipeRedis](https://metacpan.org/pod/AnyEvent::RipeRedis).

# DISCONNECTION

When the connection to the cluster is no longer needed you can close it in two
ways: call the method `disconnect()` or just "forget" any references to an
AnyEvent::RipeRedis::Cluster object, but in this case the client object is
destroyed without calling any callbacks, including the `on_disconnect`
callback, to avoid an unexpected behavior.

## disconnect()

The method for disconnection. All uncompleted operations will be
aborted.

# OTHER METHODS

## nodes( \[ $key \] \[, $allow\_slaves \] )

Gets particular nodes of the cluster. Nodes must be discovered first. In scalar
context method returns the first node from the list.

Getting all master nodes of the cluster:

    my @master_nodes = $cluster->nodes;

Getting all nodes of the cluster, including slave nodes:

    my @nodes = $cluster->nodes( undef, 1 );

Getting master node by the key:

    my $master_node = $cluster->nodes('foo');

Getting nodes by the key, including slave nodes:

    my @nodes = $cluster->nodes( 'foo', 1 );

## refresh\_interval( \[ $fractional\_seconds \] )

Gets or sets the `refresh_interval` of the client. The `undef` value resets
the `refresh_interval` to default value.

## on\_error( \[ $callback \] )

Gets or sets the `on_error` callback.

# SERVICE FUNCTIONS

Service functions provided by AnyEvent::RipeRedis::Cluster can be imported.

    use AnyEvent::RipeRedis::Cluster qw( crc16 hash_slot );

## crc16( $data )

Compute CRC16 for the specified data as defined in Redis Cluster specification.

## hash\_slot( $key );

Returns slot number by the key.

# SEE ALSO

[AnyEvent::RipeRedis](https://metacpan.org/pod/AnyEvent::RipeRedis)

# AUTHOR

Eugene Ponizovsky, <ponizovsky@gmail.com>

Sponsored by SMS Online, <dev.opensource@sms-online.com>

# COPYRIGHT AND LICENSE

Copyright (c) 2016-2017, Eugene Ponizovsky, SMS Online. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
