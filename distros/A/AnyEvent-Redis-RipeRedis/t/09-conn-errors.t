use 5.008000;
use strict;
use warnings;

use Test::More tests => 31;
use AnyEvent::Redis::RipeRedis qw( :err_codes );
use Net::EmptyPort qw( empty_port );
use Scalar::Util qw( weaken );
require 't/test_helper.pl';

t_cant_connect_mth1();
t_cant_connect_mth2();

t_no_connection();
t_reconnection();
t_read_timeout();

t_premature_conn_close_mth1();
t_premature_conn_close_mth2();

t_subscription_lost();


sub t_cant_connect_mth1 {
  my $redis;
  my $port = empty_port();

  my $t_cli_err_msg;
  my $t_cmd_err_msg;
  my $t_cmd_err_code;

  AE::now_update();
  ev_loop(
    sub {
      my $cv = shift;

      $redis = AnyEvent::Redis::RipeRedis->new(
        port               => $port,
        connection_timeout => 3,
        reconnect          => 0,

        on_connect_error => sub {
          $t_cli_err_msg = shift;
        },
      );

      $redis->ping(
        { on_error => sub {
            $t_cmd_err_msg  = shift;
            $t_cmd_err_code = shift;

            $cv->send();
          },
        }
      );
    },
    0
  );

  my $t_npref = "can't connect; 'on_connect_error' used";
  like( $t_cli_err_msg, qr/^Can't connect to localhost:$port:/,
      "$t_npref; client error message" );
  like( $t_cmd_err_msg,
      qr/^Operation "ping" aborted: Can't connect to localhost:$port:/,
      "$t_npref; command error message" );
  is( $t_cmd_err_code, E_CANT_CONN, "$t_npref; command error code" );

  return;
}

sub t_cant_connect_mth2 {
  my $redis;
  my $port = empty_port();

  my $t_cli_err_msg;
  my $t_cli_err_code;
  my $t_cmd_err_msg;
  my $t_cmd_err_code;

  AE::now_update();
  ev_loop(
    sub {
      my $cv = shift;

      $redis = AnyEvent::Redis::RipeRedis->new(
        port               => $port,
        connection_timeout => 3,
        reconnect          => 0,

        on_error => sub {
          $t_cli_err_msg  = shift;
          $t_cli_err_code = shift;
        },
      );

      $redis->ping(
        { on_error => sub {
            $t_cmd_err_msg  = shift;
            $t_cmd_err_code = shift;

            $cv->send();
          },
        }
      );
    },
    0
  );

  my $t_npref = "can't connect; 'on_error' used";
  like( $t_cli_err_msg, qr/^Can't connect to localhost:$port:/,
      "$t_npref; client error message" );
  is( $t_cli_err_code, E_CANT_CONN, "$t_npref; client error code" );
  like( $t_cmd_err_msg,
      qr/^Operation "ping" aborted: Can't connect to localhost:$port:/,
      "$t_npref; command error message" );
  is( $t_cmd_err_code, E_CANT_CONN, "$t_npref; command error code" );

  return;
}

sub t_no_connection {
  my $redis;
  my $port = empty_port();

  my $t_cli_err_msg;
  my $t_cmd_err_msg_0;
  my $t_cmd_err_code_0;

  AE::now_update();
  ev_loop(
    sub {
      my $cv = shift;

      $redis = AnyEvent::Redis::RipeRedis->new(
        port               => $port,
        connection_timeout => 3,
        reconnect          => 0,

        on_connect_error => sub {
          $t_cli_err_msg = shift;
        },
      );

      $redis->ping(
        { on_error => sub {
            $t_cmd_err_msg_0  = shift;
            $t_cmd_err_code_0 = shift;

            $cv->send();
          },
        }
      );
    },
    0
  );

  my $t_npref = 'no connection';
  like( $t_cli_err_msg, qr/^Can't connect to localhost:$port:/,
      "$t_npref; client error message" );
  like( $t_cmd_err_msg_0,
      qr/^Operation "ping" aborted: Can't connect to localhost:$port:/,
      "$t_npref; first command error message" );
  is( $t_cmd_err_code_0, E_CANT_CONN, "$t_npref; first command error code" );

  my $t_cmd_err_msg_1;
  my $t_cmd_err_code_1;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->ping(
        { on_error => sub {
            $t_cmd_err_msg_1 = shift;
            $t_cmd_err_code_1 = shift;

            $cv->send();
          },
        }
      );
    }
  );

  is( $t_cmd_err_msg_1,
      "Operation \"ping\" aborted: No connection to the server.",
      "$t_npref; second command error message" );
  is( $t_cmd_err_code_1, E_NO_CONN, "$t_npref; second command error code" );

  return;
}

sub t_reconnection {
  my $port = empty_port();
  my $server_info = run_redis_instance(
    port => $port,
  );

  SKIP: {
    if ( !defined $server_info ) {
      skip 'redis-server is required for this test', 5;
    }

    my $t_conn_cnt = 0;
    my $t_disconn_cnt = 0;
    my $t_cli_err_msg;
    my $t_cli_err_code;
    my $redis;

    AE::now_update();
    ev_loop(
      sub {
        my $cv = shift;

        $redis = AnyEvent::Redis::RipeRedis->new(
          host => $server_info->{host},
          port => $server_info->{port},

          on_connect => sub {
            $t_conn_cnt++;
          },
          on_disconnect => sub {
            $t_disconn_cnt++;
            $cv->send();
          },
          on_error => sub {
            $t_cli_err_msg  = shift;
            $t_cli_err_code = shift;
          },
        );

        $redis->ping(
          { on_done => sub {
              my $timer;
              $timer = AE::postpone(
                sub {
                  undef $timer;
                  $server_info->{server}->stop();
                }
              );
            },
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
          {
            on_done => sub {
              $t_pong = shift;
              $cv->send();
            },
          }
        );
      }
    );

    my $t_npref = 'reconnection';
    is( $t_conn_cnt, 2, "$t_npref; connections" );
    is( $t_disconn_cnt, 1, "$t_npref; disconnections" );
    is( $t_cli_err_msg, 'Connection closed by remote host.',
        "$t_npref; error message" );
    is( $t_cli_err_code, E_CONN_CLOSED_BY_REMOTE_HOST, "$t_npref; error code" );
    is( $t_pong, 'PONG', "$t_npref; success PING" );

    $redis->disconnect();
  }

  return;
}

sub t_read_timeout {
  my $server_info = run_redis_instance();

  SKIP: {
    if ( !defined $server_info ) {
      skip 'redis-server is required for this test', 4;
    }

    my $redis;

    my $t_cli_err_msg;
    my $t_cli_err_code;
    my $t_cmd_err_msg;
    my $t_cmd_err_code;

    ev_loop(
      sub {
        my $cv = shift;

        $redis = AnyEvent::Redis::RipeRedis->new(
          host         => $server_info->{host},
          port         => $server_info->{port},
          reconnect    => 0,
          read_timeout => 1,

          on_error => sub {
            $t_cli_err_msg  = shift;
            $t_cli_err_code = shift;
          },
        );

        $redis->brpop( 'non_existent', '3',
          { on_error => sub {
              $t_cmd_err_msg  = shift;
              $t_cmd_err_code = shift;

              $cv->send();
            },
          }
        );
      }
    );

    $redis->disconnect();

    my $t_npref = 'read timeout';
    is( $t_cli_err_msg, 'Read timed out.', "$t_npref; client error message" );
    is( $t_cli_err_code, E_READ_TIMEDOUT, "$t_npref; client error code" );
    is( $t_cmd_err_msg, "Operation \"brpop\" aborted: Read timed out.",
        "$t_npref; command error message" );
    is( $t_cmd_err_code, E_READ_TIMEDOUT, "$t_npref; command error code" );
  }

  return;
}

sub t_premature_conn_close_mth1 {
  my $t_cli_err_msg;
  my $t_cli_err_code;
  my $t_cmd_err_msg;
  my $t_cmd_err_code;

  my $redis = AnyEvent::Redis::RipeRedis->new(
    on_error => sub {
      $t_cli_err_msg = shift;
      $t_cli_err_code = shift;
    },
  );

  $redis->ping(
    { on_error => sub {
        $t_cmd_err_msg = shift;
        $t_cmd_err_code = shift;
      },
    }
  );

  $redis->disconnect();

  my $t_npref = 'premature connection close; disconnect() used';
  is( $t_cli_err_msg, 'Connection closed by client prematurely.',
      "$t_npref; client error message" );
  is( $t_cli_err_code, E_CONN_CLOSED_BY_CLIENT, "$t_npref; client error message" );
  is( $t_cmd_err_msg,
      "Operation \"ping\" aborted: Connection closed by client prematurely.",
      "$t_npref; command error message" );
  is( $t_cmd_err_code, E_CONN_CLOSED_BY_CLIENT, "$t_npref; command error message" );

  return;
}

sub t_premature_conn_close_mth2 {
  my $on_error_was_called = 0;
  my $t_cmd_err_msg;

  local $SIG{__WARN__} = sub {
    $t_cmd_err_msg = shift;

    chomp( $t_cmd_err_msg );
  };

  my $redis = AnyEvent::Redis::RipeRedis->new();

  $redis->ping(
    { on_error => sub {
        $on_error_was_called = 1;
      },
    }
  );

  undef $redis;

  my $t_npref = 'premature connection close; undef() used';
  ok( !$on_error_was_called, "$t_npref; 'on_error' callback ignored" );
  is( $t_cmd_err_msg,
      "Operation \"ping\" aborted: Client object destroyed prematurely.",
      "$t_npref; command error message" );

  return;
}

sub t_subscription_lost {
  my $server_info = run_redis_instance();

  SKIP: {
    if ( !defined $server_info ) {
      skip 'redis-server is required for this test', 4;
    }

    my $redis;

    my $t_cli_err_msg;
    my $t_cli_err_code;
    my $t_cmd_err_msg;
    my $t_cmd_err_code;

    ev_loop(
      sub {
        my $cv = shift;

        $redis = AnyEvent::Redis::RipeRedis->new(
          host => $server_info->{host},
          port => $server_info->{port},

          on_error => sub {
            $t_cli_err_msg  = shift;
            $t_cli_err_code = shift;
          },
        );

        $redis->subscribe( 'ch_foo',
          { on_done => sub {
              $server_info->{server}->stop();
            },

            on_error => sub {
              $t_cmd_err_msg  = shift;
              $t_cmd_err_code = shift;

              $cv->send();
            },

            on_message => sub {},
          },
        );
      }
    );

    my $t_npref = 'subscription lost';
    is( $t_cli_err_msg, 'Connection closed by remote host.',
        "$t_npref; client error message" );
    is( $t_cli_err_code, E_CONN_CLOSED_BY_REMOTE_HOST,
        "$t_npref; client error code" );
    is( $t_cmd_err_msg,
        "Subscription \"ch_foo\" lost: Connection closed by remote host.",
        "$t_npref; command error message" );
    is( $t_cmd_err_code, E_CONN_CLOSED_BY_REMOTE_HOST,
        "$t_npref; command error code" );
  }

  return;
}
