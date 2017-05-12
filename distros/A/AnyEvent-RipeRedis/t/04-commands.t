use 5.008000;
use strict;
use warnings;
use utf8;

use Test::More;
use AnyEvent::RipeRedis qw( :err_codes );
require 't/test_helper.pl';

my $server_info = run_redis_instance();
if ( !defined $server_info ) {
  plan skip_all => 'redis-server is required for this test';
}
plan tests => 33;

my $T_CONNECTED    = 0;
my $T_DISCONNECTED = 0;

my $redis;

ev_loop(
  sub {
    my $cv = shift;

    $redis = AnyEvent::RipeRedis->new(
      host               => $server_info->{host},
      port               => $server_info->{port},
      connection_timeout => 5,
      read_timeout       => 5,
      handle_params      => {
        autocork => 1,
      },

      on_connect => sub {
        $T_CONNECTED = 1;
        $cv->send;
      },
      on_disconnect => sub {
        $T_DISCONNECTED = 1;
      },
    );
  },
);

ok( $T_CONNECTED, 'on_connect' );

t_status_reply($redis);
t_numeric_reply($redis);
t_bulk_reply($redis);
t_set_undef($redis);
t_get_undef($redis);
t_set_utf8_string($redis);
t_get_utf8_string($redis);
t_get_non_existent($redis);
t_mbulk_reply($redis);
t_mbulk_reply_empty_list($redis);
t_mbulk_reply_undef($redis);
t_nested_mbulk_reply($redis);
t_multiword_command($redis);
t_error_reply($redis);
t_default_on_error($redis);
t_error_after_exec($redis);
t_discard_method($redis);
t_execute_method($redis);
t_quit($redis);


sub t_status_reply {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->set( 'foo', "some\r\nstring",
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );

      $redis->del( 'foo',
        sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_reply, 'OK', 'status reply; SET' );

  return;
}

sub t_numeric_reply {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->incr( 'bar',
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );

      $redis->del( 'bar',
        sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_reply, 1, 'numeric reply; INCR' );

  return;
}

sub t_bulk_reply {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->set( 'foo', "some\r\nstring" );

      $redis->get( 'foo',
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );

      $redis->del( 'foo',
        sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_reply, "some\r\nstring", 'bulk reply; GET' );

  return;
}

sub t_set_undef {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->set( 'empty', undef,
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_reply, 'OK', 'write undef; SET' );

  return;
}

sub t_get_undef {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->get( 'empty',
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_reply, '', 'read undef; GET' );

  return;
}

sub t_set_utf8_string {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->set( 'ключ', 'Значение',
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );

      $redis->del( 'ключ',
        sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_reply, 'OK', 'write UTF-8 string; SET' );

  return;
}

sub t_get_utf8_string {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->set( 'ключ', 'Значение' );

      $redis->get( 'ключ',
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );

      $redis->del( 'ключ',
        sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_reply, 'Значение', 'read UTF-8 string; GET' );

  return;
}

sub t_get_non_existent {
  my $redis = shift;

  my $t_reply = 'not_undef';
  my $t_err;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->get( 'non_existent',
        sub {
          $t_reply = shift;
          $t_err   = shift;

          if ( defined $t_err ) {
            diag( $t_err->message );
          }

          $cv->send;
        }
      );
    }
  );

  ok( !defined $t_reply && !defined $t_err, 'read non existent key; GET' );

  return;
}

sub t_mbulk_reply {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      for ( my $i = 1; $i <= 3; $i++ ) {
        $redis->rpush( 'list', "element_$i" );
      }

      $redis->lrange( 'list', 0, -1,
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( $err ) {
            diag( $err->message );
          }
        }
      );

      $redis->del( 'list',
        sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is_deeply( $t_reply,
    [ qw(
        element_1
        element_2
        element_3
      )
    ],
    'multi-bulk reply; LRANGE'
  );

  return;
}

sub t_mbulk_reply_empty_list {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->lrange( 'non_existent', 0, -1,
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is_deeply( $t_reply, [], 'read empty list; LRANGE' );

  return;
}

sub t_mbulk_reply_undef {
  my $redis = shift;

  my $t_reply = 'not_undef';
  my $t_err;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->brpop( 'non_existent', '1',
        sub {
          $t_reply = shift;
          $t_err   = shift;

          if ( defined $t_err ) {
            diag( $t_err->message );
          }

          $cv->send;
        }
      );
    }
  );

  ok( !defined $t_reply && !defined $t_err, 'read multi-bulk undef; BLPOP' );

  return;
}

sub t_nested_mbulk_reply {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      for ( my $i = 1; $i <= 3; $i++ ) {
        $redis->rpush( 'list', "element_$i" );
      }

      $redis->set( 'bar', "some\r\nstring" );

      $redis->multi;
      $redis->incr( 'foo' );
      $redis->lrange( 'list', 0, -1 );
      $redis->lrange( 'non_existent', 0, -1 );
      $redis->get( 'bar' );
      $redis->lrange( 'list', 0, -1 );
      $redis->exec(
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );

      $redis->del( qw( foo bar list ),
        sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is_deeply( $t_reply,
    [ 1,
      [ qw(
          element_1
          element_2
          element_3
        )
      ],
      [],
      "some\r\nstring",
      [ qw(
          element_1
          element_2
          element_3
        )
      ],
    ],
    'nested multi-bulk reply; MULTI/EXEC'
  );

  return;
}

sub t_multiword_command {
  my $redis = shift;

  my $ver = get_redis_version($redis);

  SKIP: {
    if ( $ver < version->parse( 'v2.6.9' ) ) {
      skip 'redis-server 2.6.9 or higher is required for this test', 2;
    }

    my $t_reply;

    ev_loop(
      sub {
        my $cv = shift;

        $redis->client_setname( 'test',
          sub {
            $t_reply = shift;
            my $err  = shift;

            if ( defined $err ) {
              diag( $err->message );
            }

            $cv->send;
          }
        );
      }
    );

    is_deeply( $t_reply, 'OK', 'multiword command; CLIENT SETNAME' );

    ev_loop(
      sub {
        my $cv = shift;

        $redis->client_getname(
          sub {
            $t_reply = shift;
            my $err  = shift;

            if ( defined $err ) {
              diag( $err->message );
            }

            $cv->send;
          }
        );
      }
    );

    is_deeply( $t_reply, 'test', 'multiword command; CLIENT GETNAME' );
  }

  return;
}

sub t_error_reply {
  my $redis = shift;

  my $t_err;

  ev_loop(
    sub {
      my $cv = shift;

      # missing argument
      $redis->set( 'foo',
        sub {
          my $reply = shift;
          $t_err    = shift;

          $cv->send;
        }
      );
    }
  );

  my $t_npref = 'error reply';
  isa_ok( $t_err, 'AnyEvent::RipeRedis::Error' );
  ok( defined $t_err->message, "$t_npref; error message" );
  is( $t_err->code, E_OPRN_ERROR, "$t_npref; error code" );

  return;
}

sub t_default_on_error {
  my $redis = shift;

  my $cv;
  my $t_err_msg;

  local $SIG{__WARN__} = sub {
    $t_err_msg = shift;

    chomp( $t_err_msg );

    $cv->send;
  };

  ev_loop(
    sub {
      $cv = shift;

      $redis->set; # missing argument
    }
  );

  ok( defined $t_err_msg, q{Default "on_error" callback} );

  return;
}

sub t_error_after_exec {
  my $redis = shift;

  my $t_reply;
  my $t_err;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->multi;
      $redis->set( 'foo', 'string' );
      $redis->incr( 'foo' );
      $redis->exec(
        sub {
          $t_reply = shift;
          $t_err   = shift;

          $cv->send;
        }
      );
    }
  );

  my $t_npref = 'error after EXEC';
  isa_ok( $t_err, 'AnyEvent::RipeRedis::Error' );
  is( $t_err->message, q{Operation "exec" completed with errors.},
      "$t_npref; error message" );
  is( $t_err->code, E_OPRN_ERROR, "$t_npref; error code" );
  is( $t_reply->[0], 'OK', "$t_npref; status reply" );

  isa_ok( $t_reply->[1], 'AnyEvent::RipeRedis::Error' );
  can_ok( $t_reply->[1], 'code' );
  can_ok( $t_reply->[1], 'message' );
  ok( defined $t_reply->[1]->message, "$t_npref; nested error message" );
  is( $t_reply->[1]->code, E_OPRN_ERROR, "$t_npref; nested error message" );

  return;
}

sub t_discard_method {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->set( 'foo', "some\r\nstring" );

      $redis->multi;
      $redis->get( 'foo' );
      $redis->incr( 'bar' );
      $redis->discard(
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );

      $redis->del( 'foo',
        sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_reply, 'OK', 'discard method' );

  return;
}

sub t_execute_method {
  my $redis = shift;

  can_ok( $redis, 'execute' );

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->execute( 'set', 'foo', "some\r\nstring",
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }
        }
      );

      $redis->execute( 'del', 'foo',
        sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_reply, 'OK', 'execute method' );

  return;
}

sub t_quit {
  my $redis = shift;

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->quit(
        sub {
          $t_reply = shift;
          my $err  = shift;

          if ( defined $err ) {
            diag( $err->message );
          }

          $cv->send;
        }
      );
    }
  );

  is( $t_reply, 'OK', 'disconnect; QUIT' );
  ok( $T_DISCONNECTED, 'on_disconnect' );

  return;
}
