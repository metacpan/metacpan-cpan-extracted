use 5.008000;
use strict;
use warnings;

use Test::More tests => 40;
use AnyEvent::RipeRedis qw( :err_codes );
use Net::EmptyPort qw( empty_port );
use Scalar::Util qw( weaken );
require 't/test_helper.pl';

t_cant_connect();
t_no_connection();
t_reconnection();
t_read_timeout();
t_premature_disconnect();
t_premature_destroy();
t_subscription_lost();


sub t_cant_connect {
  my $redis;
  my $port = empty_port();

  my $t_cli_err;
  my $t_cmd_err;

  AE::now_update();

  ev_loop(
    sub {
      my $cv = shift;

      $redis = AnyEvent::RipeRedis->new(
        port               => $port,
        connection_timeout => 3,
        reconnect          => 0,

        on_error => sub {
          $t_cli_err = shift;
        },
      );

      $redis->ping(
        sub {
          my $reply  = shift;
          $t_cmd_err = shift;

          $cv->send;
        }
      );
    },
    0
  );

  my $t_npref = q{can't connect; 'on_error' used};
  isa_ok( $t_cli_err, 'AnyEvent::RipeRedis::Error' );
  like( $t_cli_err->message, qr/^Can't connect to localhost:$port:/,
      "$t_npref; client error message" );
  is( $t_cli_err->code, E_CANT_CONN, "$t_npref; client error code" );
  isa_ok( $t_cmd_err, 'AnyEvent::RipeRedis::Error' );
  like( $t_cmd_err->message,
      qr/^Operation "ping" aborted: Can't connect to localhost:$port:/,
      "$t_npref; command error message" );
  is( $t_cmd_err->code, E_CANT_CONN, "$t_npref; command error code" );

  return;
}

sub t_no_connection {
  my $redis;
  my $port = empty_port();

  my $t_cli_err;
  my $t_cmd_err_1;

  AE::now_update();

  ev_loop(
    sub {
      my $cv = shift;

      $redis = AnyEvent::RipeRedis->new(
        port               => $port,
        connection_timeout => 3,
        reconnect          => 0,

        on_error => sub {
          $t_cli_err = shift;
        },
      );

      $redis->ping(
        sub {
          my $reply    = shift;
          $t_cmd_err_1 = shift;

          $cv->send;
        }
      );
    },
    0
  );

  my $t_npref = 'no connection';
  isa_ok( $t_cli_err, 'AnyEvent::RipeRedis::Error' );
  like( $t_cli_err->message, qr/^Can't connect to localhost:$port:/,
      "$t_npref; client error message" );
  isa_ok( $t_cmd_err_1, 'AnyEvent::RipeRedis::Error' );
  like( $t_cmd_err_1->message,
      qr/^Operation "ping" aborted: Can't connect to localhost:$port:/,
      "$t_npref; first command error message" );
  is( $t_cmd_err_1->code, E_CANT_CONN, "$t_npref; first command error code" );

  my $t_cmd_err_2;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->ping(
        sub {
          my $reply    = shift;
          $t_cmd_err_2 = shift;

          $cv->send;
        }
      );
    }
  );

  isa_ok( $t_cmd_err_2, 'AnyEvent::RipeRedis::Error' );
  is( $t_cmd_err_2->message,
      q{Operation "ping" aborted: No connection to the server.},
      "$t_npref; second command error message" );
  is( $t_cmd_err_2->code, E_NO_CONN, "$t_npref; second command error code" );

  return;
}

sub t_reconnection {
  my $port = empty_port();
  my $server_info = run_redis_instance(
    port => $port,
  );

  SKIP: {
    if ( !defined $server_info ) {
      skip 'redis-server is required for this test', 6;
    }

    my $t_conn_cnt = 0;
    my $t_disconn_cnt = 0;
    my $t_cli_err;
    my $redis;

    AE::now_update();

    ev_loop(
      sub {
        my $cv = shift;

        $redis = AnyEvent::RipeRedis->new(
          host => $server_info->{host},
          port => $server_info->{port},

          on_connect => sub {
            $t_conn_cnt++;
          },
          on_disconnect => sub {
            $t_disconn_cnt++;
            $cv->send;
          },
          on_error => sub {
            $t_cli_err = shift;
          },
        );

        $redis->ping(
          sub {
            my $reply = shift;
            my $err   = shift;

            if ( defined $err ) {
              diag( $err->message );
              $cv->send;

              return;
            }

            my $timer;
            $timer = AE::postpone(
              sub {
                undef $timer;
                $server_info->{server}->stop;
              }
            );
          }
        );
      }
    );

    $server_info = run_redis_instance(
      port => $port,
    );

    my $t_pong;

    ev_loop(
      sub {
        my $cv = shift;

        $redis->ping(
          sub {
            $t_pong = shift;
            my $err = shift;

            if ( defined $err ) {
              diag( $err->message );
              $cv->send;

              return;
            }

            $cv->send;
          }
        );
      }
    );

    my $t_npref = 'reconnection';
    is( $t_conn_cnt, 2, "$t_npref; connections" );
    is( $t_disconn_cnt, 1, "$t_npref; disconnections" );
    isa_ok( $t_cli_err, 'AnyEvent::RipeRedis::Error' );
    is( $t_cli_err->message, 'Connection closed by remote host.',
        "$t_npref; error message" );
    is( $t_cli_err->code, E_CONN_CLOSED_BY_REMOTE_HOST, "$t_npref; error code" );
    is( $t_pong, 'PONG', "$t_npref; success PING" );

    $redis->disconnect;
  }

  return;
}

sub t_read_timeout {
  my $server_info = run_redis_instance();

  SKIP: {
    if ( !defined $server_info ) {
      skip 'redis-server is required for this test', 6;
    }

    my $redis;

    my $t_cli_err;
    my $t_cmd_err;

    AE::now_update();

    ev_loop(
      sub {
        my $cv = shift;

        $redis = AnyEvent::RipeRedis->new(
          host               => $server_info->{host},
          port               => $server_info->{port},
          reconnect          => 0,
          connection_timeout => 6,
          read_timeout       => 1,

          on_error => sub {
            $t_cli_err = shift;
          },
        );

        $redis->brpop( 'non_existent', '3',
          sub {
            my $reply  = shift;
            $t_cmd_err = shift;

            $cv->send;
          }
        );
      }
    );

    $redis->disconnect;

    my $t_npref = 'read timeout';
    isa_ok( $t_cli_err, 'AnyEvent::RipeRedis::Error' );
    is( $t_cli_err->message, 'Read timed out.', "$t_npref; client error message" );
    is( $t_cli_err->code, E_READ_TIMEDOUT, "$t_npref; client error code" );
    isa_ok( $t_cmd_err, 'AnyEvent::RipeRedis::Error' );
    is( $t_cmd_err->message, q{Operation "brpop" aborted: Read timed out.},
        "$t_npref; command error message" );
    is( $t_cmd_err->code, E_READ_TIMEDOUT, "$t_npref; command error code" );
  }

  return;
}

sub t_premature_disconnect {
  my $t_cli_err;
  my $t_cmd_err;

  my $redis = AnyEvent::RipeRedis->new(
    on_error => sub {
      $t_cli_err = shift;
    },
  );

  $redis->ping(
    sub {
      my $reply  = shift;
      $t_cmd_err = shift;
    }
  );

  $redis->disconnect;

  my $t_npref = 'premature disconnect';
  isa_ok( $t_cli_err, 'AnyEvent::RipeRedis::Error' );
  is( $t_cli_err->message, 'Connection closed by client prematurely.',
      "$t_npref; client error message" );
  is( $t_cli_err->code, E_CONN_CLOSED_BY_CLIENT, "$t_npref; client error message" );
  isa_ok( $t_cmd_err, 'AnyEvent::RipeRedis::Error' );
  is( $t_cmd_err->message,
      q{Operation "ping" aborted: Connection closed by client prematurely.},
      "$t_npref; command error message" );
  is( $t_cmd_err->code, E_CONN_CLOSED_BY_CLIENT, "$t_npref; command error message" );

  return;
}

sub t_premature_destroy {
  my $on_error_was_called = 0;
  my $t_cmd_err_msg;

  local $SIG{__WARN__} = sub {
    $t_cmd_err_msg = shift;
    chomp( $t_cmd_err_msg );
  };

  my $redis = AnyEvent::RipeRedis->new();

  $redis->ping(
    sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        $on_error_was_called = 1;
      }
    }
  );

  undef $redis;

  my $t_npref = 'premature destroy';
  ok( !$on_error_was_called, "$t_npref; 'on_error' callback ignored" );
  is( $t_cmd_err_msg,
      q{Operation "ping" aborted: Client object destroyed prematurely.},
      "$t_npref; command error message" );

  return;
}

sub t_subscription_lost {
  my $server_info = run_redis_instance();

  SKIP: {
    if ( !defined $server_info ) {
      skip 'redis-server is required for this test', 6;
    }

    my $redis;

    my $t_cli_err;
    my $t_cmd_err;

    ev_loop(
      sub {
        my $cv = shift;

        $redis = AnyEvent::RipeRedis->new(
          host => $server_info->{host},
          port => $server_info->{port},

          on_error => sub {
            $t_cli_err = shift;
          },
        );

        $redis->subscribe( 'foo',
          { on_reply => sub {
              my $reply  = shift;
              $t_cmd_err = shift;

              if ( defined $t_cmd_err ) {
                $cv->send;
                return;
              }

              $server_info->{server}->stop;
            },

            on_message => sub {},
          },
        );
      }
    );

    my $t_npref = 'subscription lost';
    isa_ok( $t_cli_err, 'AnyEvent::RipeRedis::Error' );
    is( $t_cli_err->message, 'Connection closed by remote host.',
        "$t_npref; client error message" );
    is( $t_cli_err->code, E_CONN_CLOSED_BY_REMOTE_HOST,
        "$t_npref; client error code" );
    isa_ok( $t_cmd_err, 'AnyEvent::RipeRedis::Error' );
    is( $t_cmd_err->message,
        q{Subscription to channel "foo" lost:}
            . ' Connection closed by remote host.',
        "$t_npref; command error message" );
    is( $t_cmd_err->code, E_CONN_CLOSED_BY_REMOTE_HOST,
        "$t_npref; command error code" );
  }

  return;
}
