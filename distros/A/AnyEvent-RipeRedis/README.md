# NAME

AnyEvent::RipeRedis - Flexible non-blocking Redis client

# SYNOPSIS

    use AnyEvent;
    use AnyEvent::RipeRedis;

    my $redis = AnyEvent::RipeRedis->new(
      host     => 'localhost',
      port     => 6379,
      password => 'yourpass',
    );

    my $cv = AE::cv;

    $redis->set( 'foo', 'bar',
      sub {
        my $err = $_[1];

        if ( defined $err ) {
          warn $err->message . "\n";
          $cv->send;

          return;
        }

        $redis->get( 'foo',
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

AnyEvent::RipeRedis is flexible non-blocking Redis client. Supports
subscriptions, transactions and can automaticaly restore connection after
failure.

Requires Redis 1.2 or higher, and any supported event loop.

# CONSTRUCTOR

## new( %params )

    my $redis = AnyEvent::RipeRedis->new(
      host               => 'localhost',
      port               => 6379,
      password           => 'yourpass',
      database           => 7,
      connection_timeout => 5,
      read_timeout       => 5,
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

    Server hostname (default: 127.0.0.1)

- port => $port

    Server port (default: 6379)

- password => $password

    If the password is specified, the `AUTH` command is sent to the server
    after connection.

- database => $index

    Database index. If the index is specified, the client switches to the specified
    database after connection. You can also switch to another database after
    connection by using `SELECT` command. The client remembers last selected
    database after reconnection and switches to it automaticaly.

    The default database index is `0`.

- utf8 => $boolean

    If enabled, all strings will be converted to UTF-8 before sending to
    the server, and all results will be decoded from UTF-8.

    Enabled by default.

- connection\_timeout => $fractional\_seconds

    Specifies connection timeout. If the client could not connect to the server
    after specified timeout, the `on_error` callback is called with the
    `E_CANT_CONN` error. The timeout specifies in seconds and can contain a
    fractional part.

        connection_timeout => 10.5,

    By default the client use kernel's connection timeout.

- read\_timeout => $fractional\_seconds

    Specifies read timeout. If the client could not receive a reply from the server
    after specified timeout, the client close connection and call the `on_error`
    callback with the `E_READ_TIMEDOUT` error. The timeout is specifies in seconds
    and can contain a fractional part.

        read_timeout => 3.5,

    Not set by default.

- lazy => $boolean

    If enabled, the connection establishes at time when you will send the first
    command to the server. By default the connection establishes after calling of
    the `new` method.

    Disabled by default.

- reconnect => $boolean

    If the connection to the server was lost and the parameter `reconnect` is
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

- handle\_params => \\%params

    Specifies [AnyEvent::Handle](https://metacpan.org/pod/AnyEvent::Handle) parameters.

        handle_params => {
          autocork => 1,
          linger   => 60,
        }

    Enabling of the `autocork` parameter can improve performance. See
    documentation on [AnyEvent::Handle](https://metacpan.org/pod/AnyEvent::Handle) for more information.

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

# COMMAND EXECUTION

## &lt;command>( \[ @args \] \[, $cb->( $reply, $err ) \] )

To execute the command you must call specific method with corresponding name.
The reply to the command is passed to the callback in first argument. If any
error occurred during the command execution, the error object is passed to the
callback in second argument. Error object is the instance of the class
[AnyEvent::RipeRedis::Error](https://metacpan.org/pod/AnyEvent::RipeRedis::Error).

The command callback is optional. If it is not specified and any error
occurred, the `on_error` callback of the client is called.

The full list of the Redis commands can be found here: [http://redis.io/commands](http://redis.io/commands).

    $redis->get( 'foo',
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

    $redis->lrange( 'list', 0, -1,
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

    $redis->incr( 'counter' );

You can execute multi-word commands like this:

    $redis->client_getname(
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

## execute( $command, \[ @args \] \[, $cb->( $reply, $err ) \] )

An alternative method to execute commands. In some cases it can be more
convenient.

    $redis->execute( 'get', 'foo',
      sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          my $err_msg  = $err->message;
          my $err_code = $err->code;

          return;
        }

        print "$reply\n";
      }
    );

# TRANSACTIONS

The detailed information about the Redis transactions can be found here:
[http://redis.io/topics/transactions](http://redis.io/topics/transactions).

## multi( \[ $cb->( $reply, $err ) \] )

Marks the start of a transaction block. Subsequent commands will be queued for
atomic execution using `EXEC`.

## exec( \[ $cb->( $reply, $err ) \] )

Executes all previously queued commands in a transaction and restores the
connection state to normal. When using `WATCH`, `EXEC` will execute commands
only if the watched keys were not modified.

If during a transaction at least one command fails, to the callback will be
passed error object, and the reply will be contain nested error objects for
every failed command.

    $redis->multi();
    $redis->set( 'foo', 'string' );
    $redis->incr('foo');    # causes an error
    $redis->exec(
      sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          my $err_msg  = $err->message();
          my $err_code = $err->code();

          if ( defined $reply ) {
            foreach my $nested_reply ( @{$reply} ) {
              if ( ref($nested_reply) eq 'AnyEvent::RipeRedis::Error' ) {
                my $nested_err_msg  = $nested_reply->message();
                my $nested_err_code = $nested_reply->code();

                # error handling...
              }
            }

            return;
          }

          # error handling...

          return;
        }

        # reply handling...
      },
    );

## discard( \[ $cb->( $reply, $err ) \] )

Flushes all previously queued commands in a transaction and restores the
connection state to normal.

If `WATCH` was used, `DISCARD` unwatches all keys.

## watch( @keys \[, $cb->( $reply, $err ) \] )

Marks the given keys to be watched for conditional execution of a transaction.

## unwatch( \[ $cb->( $reply, $err ) \] )

Forget about all watched keys.

# SUBSCRIPTIONS

Once the client enters the subscribed state it is not supposed to issue any
other commands, except for additional `SUBSCRIBE`, `PSUBSCRIBE`,
`UNSUBSCRIBE`, `PUNSUBSCRIBE` and `QUIT` commands.

The detailed information about Redis Pub/Sub can be found here:
[http://redis.io/topics/pubsub](http://redis.io/topics/pubsub)

## subscribe( @channels, ( $cb->( $msg, $channel ) | \\%cbs ) )

Subscribes the client to the specified channels.

Method can accept two callbacks: `on_reply` and `on_message`. The `on_reply`
callback is called when subscription to all specified channels will be
activated. In first argument to the callback is passed the number of channels
we are currently subscribed. If subscription to specified channels was lost,
the `on_reply` callback is called with the error object in the second argument.

The `on_message` callback is called on every published message. If the
`subscribe` method is called with one callback, this callback will be act as
`on_message` callback.

    $redis->subscribe( qw( foo bar ),
      { on_reply => sub {
          my $channels_num = shift;
          my $err          = shift;

          if ( defined $err ) {
            # error handling...

            return;
          }

          # reply handling...
        },

        on_message => sub {
          my $msg     = shift;
          my $channel = shift;

          # message handling...
        },
      }
    );

    $redis->subscribe( qw( foo bar ),
      sub {
        my $msg     = shift;
        my $channel = shift;

        # message handling...
      }
    );

## psubscribe( @patterns, ( $cb->( $msg, $pattern, $channel ) | \\%cbs ) )

Subscribes the client to the given patterns. See `subscribe()` method for
details.

    $redis->psubscribe( qw( foo_* bar_* ),
      { on_reply => sub {
          my $channels_num = shift;
          my $err          = shift;

          if ( defined $err ) {
            # error handling...

            return;
          }

          # reply handling...
        },

        on_message => sub {
          my $msg     = shift;
          my $pattern = shift;
          my $channel = shift;

          # message handling...
        },
      }
    );

    $redis->psubscribe( qw( foo_* bar_* ),
      sub {
        my $msg     = shift;
        my $pattern = shift;
        my $channel = shift;

        # message handling...
      }
    );

## publish( $channel, $message \[, $cb->( $reply, $err ) \] )

Posts a message to the given channel.

## unsubscribe( \[ @channels \] \[, $cb->( $reply, $err ) \] )

Unsubscribes the client from the given channels, or from all of them if none
is given. In first argument to the callback is passed the number of channels we
are currently subscribed or zero if we were unsubscribed from all channels.

    $redis->unsubscribe( qw( foo bar ),
      sub {
        my $channels_num = shift;
        my $err          = shift;

        if ( defined $err ) {
          # error handling...

          return;
        }

        # reply handling...
      }
    );

## punsubscribe( \[ @patterns \] \[, $cb->( $reply, $err ) \] )

Unsubscribes the client from the given patterns, or from all of them if none
is given. See `unsubscribe()` method for details.

    $redis->punsubscribe( qw( foo_* bar_* ),
      sub {
        my $channels_num = shift;
        my $err          = shift;

        if ( defined $err ) {
          # error handling...

          return;
        }

        # reply handling...
      }
    );

# CONNECTION VIA UNIX-SOCKET

Redis 2.2 and higher support connection via UNIX domain socket. To connect via
a UNIX-socket in the parameter `host` you have to specify `unix/`, and in
the parameter `port` you have to specify the path to the socket.

    my $redis = AnyEvent::RipeRedis->new(
      host => 'unix/',
      port => '/tmp/redis.sock',
    );

# LUA SCRIPTS EXECUTION

Redis 2.6 and higher support execution of Lua scripts on the server side.
To execute a Lua script you can send one of the commands `EVAL` or `EVALSHA`,
or use the special method `eval_cached()`.

## eval\_cached( $script, $keys\_num \[, @keys \] \[, @args \] \[, $cb->( $reply, $err ) \] \] );

When you call the `eval_cached()` method, the client first generate a SHA1
hash for a Lua script and cache it in memory. Then the client optimistically
send the `EVALSHA` command under the hood. If the `E_NO_SCRIPT` error will be
returned, the client send the `EVAL` command.

If you call the `eval_cached()` method with the same Lua script, client don not
generate a SHA1 hash for this script repeatedly, it gets a hash from the cache
instead.

    $redis->eval_cached( 'return { KEYS[1], KEYS[2], ARGV[1], ARGV[2] }',
        2, 'key1', 'key2', 'first', 'second',
      sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          # error handling...

          return;
        }

        foreach my $value ( @{$reply}  ) {
          print "$value\n";
        }
      }
    );

Be care, passing a different Lua scripts to `eval_cached()` method every time
cause memory leaks.

If Lua script returns multi-bulk reply with at least one error reply, to the
callback will be passed error object, and the reply will be contain nested
error objects.

    $redis->eval_cached( "return { 'foo', redis.error_reply( 'Error.' ) }", 0,
      sub {
        my $reply = shift;
        my $err   = shift;

        if ( defined $err ) {
          my $err_msg  = $err->message;
          my $err_code = $err->code;

          if ( defined $reply ) {
            foreach my $nested_reply ( @{$reply} ) {
              if ( ref($nested_reply) eq 'AnyEvent::RipeRedis::Error' ) {
                my $nested_err_msg  = $nested_reply->message();
                my $nested_err_code = $nested_reply->code();

                # error handling...
              }
            }
          }

          # error handling...

          return;
        }

        # reply handling...
      }
    );

# ERROR CODES

Every error object, passed to callback, contain error code, which can be used
for programmatic handling of errors. AnyEvent::RipeRedis provides constants for
error codes. They can be imported and used in expressions.

    use AnyEvent::RipeRedis qw( :err_codes );

- E\_CANT\_CONN

    Can't connect to the server. All operations were aborted.

- E\_LOADING\_DATASET

    Redis is loading the dataset in memory.

- E\_IO

    Input/Output operation error. The connection to the Redis server was closed and
    all operations were aborted.

- E\_CONN\_CLOSED\_BY\_REMOTE\_HOST

    The connection closed by remote host. All operations were aborted.

- E\_CONN\_CLOSED\_BY\_CLIENT

    Connection closed by client prematurely. Uncompleted operations were aborted.

- E\_NO\_CONN

    No connection to the Redis server. Connection was lost by any reason on previous
    operation.

- E\_OPRN\_ERROR

    Operation error. For example, wrong number of arguments for a command.

- E\_UNEXPECTED\_DATA

    The client received unexpected reply from the server. The connection to the Redis
    server was closed and all operations were aborted.

- E\_READ\_TIMEDOUT

    Read timed out. The connection to the Redis server was closed and all operations
    were aborted.

Error codes available since Redis 2.6.

- E\_NO\_SCRIPT

    No matching script. Use the `EVAL` command.

- E\_BUSY

    Redis is busy running a script. You can only call `SCRIPT KILL`
    or `SHUTDOWN NOSAVE`.

- E\_NOT\_BUSY

    No scripts in execution right now.

- E\_MASTER\_DOWN

    Link with MASTER is down and slave-serve-stale-data is set to 'no'.

- E\_MISCONF

    Redis is configured to save RDB snapshots, but is currently not able to persist
    on disk. Commands that may modify the data set are disabled. Please check Redis
    logs for details about the error.

- E\_READONLY

    You can't write against a read only slave.

- E\_OOM

    Command not allowed when used memory > 'maxmemory'.

- E\_EXEC\_ABORT

    Transaction discarded because of previous errors.

Error codes available since Redis 2.8.

- E\_NO\_AUTH

    Authentication required.

- E\_WRONG\_TYPE

    Operation against a key holding the wrong kind of value.

- E\_NO\_REPLICAS

    Not enough good slaves to write.

- E\_BUSY\_KEY

    Target key name already exists.

Error codes available since Redis 3.0.

- E\_CROSS\_SLOT

    Keys in request don't hash to the same slot.

- E\_TRY\_AGAIN

    Multiple keys request during rehashing of slot.

- E\_ASK

    Redirection required. For more information see:
    [http://redis.io/topics/cluster-spec](http://redis.io/topics/cluster-spec)

- E\_MOVED

    Redirection required. For more information see:
    [http://redis.io/topics/cluster-spec](http://redis.io/topics/cluster-spec)

- E\_CLUSTER\_DOWN

    The cluster is down or hash slot not served.

# DISCONNECTION

When the connection to the server is no longer needed you can close it in three
ways: call the method `disconnect()`, send the `QUIT` command or you can just
"forget" any references to an AnyEvent::RipeRedis object, but in this
case the client object is destroyed without calling any callbacks, including
the `on_disconnect` callback, to avoid an unexpected behavior.

## disconnect()

The method for synchronous disconnection. All uncompleted operations will be
aborted.

## quit( \[ $cb->( $reply, $err ) \] )

The method for asynchronous disconnection.

# OTHER METHODS

## info( \[ $section \] \[, $cb->( $reply, $err ) \] )

Gets and parses information and statistics about the server. The result
is passed to callback as a hash reference.

More information about `INFO` command can be found here:
[http://redis.io/commands/info](http://redis.io/commands/info)

## host()

Gets current host of the client.

## port()

Gets current port of the client.

## select( $index, \[, $cb->( $reply, $err ) \] )

Selects the database by numeric index.

## database()

Gets selected database index.

## utf8( \[ $boolean \] )

Enables or disables UTF-8 mode.

## connection\_timeout( \[ $fractional\_seconds \] )

Gets or sets the `connection_timeout` of the client. The `undef` value resets
the `connection_timeout` to default value.

## read\_timeout( \[ $fractional\_seconds \] )

Gets or sets the `read_timeout` of the client.

## reconnect( \[ $boolean \] )

Enables or disables reconnection mode of the client.

## reconnect\_interval( \[ $fractional\_seconds \] )

Gets or sets `reconnect_interval` of the client.

## on\_connect( \[ $callback \] )

Gets or sets the `on_connect` callback.

## on\_disconnect( \[ $callback \] )

Gets or sets the `on_disconnect` callback.

## on\_error( \[ $callback \] )

Gets or sets the `on_error` callback.

# SEE ALSO

[AnyEvent::RipeRedis::Cluster](https://metacpan.org/pod/AnyEvent::RipeRedis::Cluster), [AnyEvent](https://metacpan.org/pod/AnyEvent), [Redis::hiredis](https://metacpan.org/pod/Redis::hiredis), [Redis](https://metacpan.org/pod/Redis),
[RedisDB](https://metacpan.org/pod/RedisDB)

# AUTHOR

Eugene Ponizovsky, <ponizovsky@gmail.com>

Sponsored by SMS Online, <dev.opensource@sms-online.com>

## Special thanks

- Alexey Shrub
- Vadim Vlasov
- Konstantin Uvarin
- Ivan Kruglov

# COPYRIGHT AND LICENSE

Copyright (c) 2012-2017, Eugene Ponizovsky, SMS Online. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
