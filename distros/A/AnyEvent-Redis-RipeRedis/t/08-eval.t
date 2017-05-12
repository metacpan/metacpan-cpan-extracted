use 5.008000;
use strict;
use warnings;

use Test::More;
use AnyEvent::Redis::RipeRedis qw( :err_codes );
use Digest::SHA qw( sha1_hex );
use Scalar::Util qw( weaken );
use version 0.77;
require 't/test_helper.pl';

my $SERVER_INFO = run_redis_instance();
if ( !defined $SERVER_INFO ) {
  plan skip_all => 'redis-server is required for this test';
}
my $REDIS = AnyEvent::Redis::RipeRedis->new(
  host => $SERVER_INFO->{host},
  port => $SERVER_INFO->{port},
);
my $ver = get_redis_version( $REDIS );
if ( $ver < version->parse( 'v2.6' ) ) {
  plan skip_all => 'redis-server 2.6 or higher is required for this test';
}
plan tests => 29;

can_ok( $REDIS, 'eval_cached' );

t_no_script( $REDIS );

t_eval_cached_mth1( $REDIS );
t_eval_cached_mth2( $REDIS );

t_eval_cached_mbulk_mth1( $REDIS );
t_eval_cached_mbulk_mth2( $REDIS );

t_error_reply_mth1( $REDIS );
t_error_reply_mth2( $REDIS );

t_errors_in_mbulk_reply_mth1( $REDIS );
t_errors_in_mbulk_reply_mth2( $REDIS );

$REDIS->disconnect();


sub t_no_script {
  my $redis = shift;

  my $t_err_msg;
  my $t_err_code;

  my $script = <<LUA
return redis.status_reply( 'OK' )
LUA
;
  my $script_sha1 = sha1_hex( $script );

  ev_loop(
    sub {
      my $cv = shift;

      $redis->evalsha( $script_sha1, 0,
        { on_error => sub {
            $t_err_msg  = shift;
            $t_err_code = shift;

            $cv->send();
          },
        }
      );
    }
  );

  my $t_npref = "no script; 'on_error' used";
  like( $t_err_msg, qr/^NOSCRIPT/, "$t_npref; error message" );
  is( $t_err_code, E_NO_SCRIPT, "$t_npref; error code" );

  return;
}

sub t_eval_cached_mth1 {
  my $redis = shift;

  my $script = <<LUA
return ARGV[1]
LUA
;
  my @t_replies;

  ev_loop(
    sub {
      my $cv = shift;

      my $redis = $redis;
      weaken( $redis );

      $redis->eval_cached( $script, 0, 42,
        { on_done => sub {
            my $reply = shift;

            push( @t_replies, $reply );

            $redis->eval_cached( $script, 0, 15 );

            $redis->eval_cached( $script, 0, 57,
              {
                on_done => sub {
                  my $reply = shift;
                  push( @t_replies, $reply );
                  $cv->send();
                },
              }
            );
          },
        }
      );
    }
  );

  is_deeply( \@t_replies, [ qw( 42 57 ) ], "eval_cached; 'on_done' used" );

  return;
}

sub t_eval_cached_mth2 {
  my $redis = shift;

  my $script = <<LUA
return ARGV[1]
LUA
;
  my @t_replies;

  ev_loop(
    sub {
      my $cv = shift;

      my $redis = $redis;
      weaken( $redis );

      $redis->eval_cached( $script, 0, 42,
        sub {
          my $reply = shift;

          if ( @_ ) {
            my $err_msg = shift;

            diag( $err_msg );

            return;
          }

          push( @t_replies, $reply );

          $redis->eval_cached( $script, 0, 15 );

          $redis->eval_cached( $script, 0, 57,
            sub {
              my $reply = shift;

              if ( @_ ) {
                my $err_msg = shift;

                diag( $err_msg );

                return;
              }

              push( @t_replies, $reply );

              $cv->send();
            }
          );
        }
      );
    }
  );

  is_deeply( \@t_replies, [ qw( 42 57 ) ], "eval_cached; 'on_reply' used" );

  return;
}

sub t_eval_cached_mbulk_mth1 {
  my $redis = shift;

  my $script = <<LUA
return
  { ARGV[1], ARGV[2],
    { ARGV[3],
      { ARGV[5], ARGV[6] },
      ARGV[4],
      { ARGV[7], ARGV[8] }
    }
  }
LUA
;
  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->eval_cached( $script, 0, qw( foo bar coo dar moo nar loo zar ),
        { on_done => sub {
            $t_reply = shift;

            $cv->send();
          },
        }
      );
    }
  );

  is_deeply( $t_reply,
    [ qw( foo bar ),
      [ 'coo',
        [ qw( moo nar ) ],
        'dar',
        [ qw( loo zar ) ]
      ]
    ], "eval_cached; multi-bulk; 'on_done' used" );

  return;
}

sub t_eval_cached_mbulk_mth2 {
  my $redis = shift;

  my $script = <<LUA
return
  { ARGV[1], ARGV[2],
    { ARGV[3],
      { ARGV[5], ARGV[6] },
      ARGV[4],
      { ARGV[7], ARGV[8] }
    }
  }
LUA
;
  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->eval_cached( $script, 0, qw( foo bar coo dar moo nar loo zar ),
        sub {
          $t_reply = shift;

          $cv->send();
        }
      );
    }
  );

  is_deeply( $t_reply,
    [ qw( foo bar ),
      [ 'coo',
        [ qw( moo nar ) ],
        'dar',
        [ qw( loo zar ) ]
      ]
    ], "eval_cached; multi-bulk; 'on_reply' used" );

  return;
}

sub t_error_reply_mth1 {
  my $redis = shift;

  my $script = <<LUA
return redis.error_reply( "ERR Something wrong." )
LUA
;
  my $t_err_msg;
  my $t_err_code;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->eval_cached( $script, 0,
        { on_error => sub {
            $t_err_msg  = shift;
            $t_err_code = shift;

            $cv->send();
          },
        }
      );
    }
  );

  my $t_npref = "eval_cached; error reply; 'on_error' used";
  is( $t_err_msg, 'ERR Something wrong.', "$t_npref; error message" );
  is( $t_err_code, E_OPRN_ERROR, "$t_npref; error code" );

  return;
}

sub t_error_reply_mth2 {
  my $redis = shift;

  my $script = <<LUA
return redis.error_reply( "ERR Something wrong." )
LUA
;
  my $t_err_msg;
  my $t_err_code;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->eval_cached( $script, 0,
        sub {
          my $reply = shift;

          if ( @_ ) {
            $t_err_msg  = shift;
            $t_err_code = shift;
          }

          $cv->send();
        }
      );
    }
  );

  my $t_npref = "eval_cached; error reply; 'on_reply' used";
  is( $t_err_msg, 'ERR Something wrong.', "$t_npref; error message" );
  is( $t_err_code, E_OPRN_ERROR, "$t_npref; error code" );

  return;
}

sub t_errors_in_mbulk_reply_mth1 {
  my $redis = shift;

  my $script = <<LUA
return { ARGV[1], redis.error_reply( "Something wrong." ),
    { redis.error_reply( "NOSCRIPT No matching script." ) } }
LUA
;
  my $t_err_msg;
  my $t_err_code;
  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->eval( $script, 0, 42,
        { on_error => sub {
            $t_err_msg  = shift;
            $t_err_code = shift;
            $t_reply    = shift;

            $cv->send();
          },
        }
      );
    }
  );

  my $t_npref = "errors in multi-bulk reply; 'on_error' used";
  is( $t_err_msg, "Operation \"eval\" completed with errors.",
      "$t_npref; error message" );
  is( $t_err_code, E_OPRN_ERROR, "$t_npref; error code" );

  is( $t_reply->[0], 42, "$t_npref; numeric reply" );

  isa_ok( $t_reply->[1], 'AnyEvent::Redis::RipeRedis::Error' );
  is( $t_reply->[1]->message(), 'Something wrong.',
      "$t_npref; level 0; error message" );
  is( $t_reply->[1]->code(), E_OPRN_ERROR, "$t_npref; level 0; error code" );

  isa_ok( $t_reply->[2][0], 'AnyEvent::Redis::RipeRedis::Error' );
  is( $t_reply->[2][0]->message(), 'NOSCRIPT No matching script.',
      "$t_npref; level 1; error message" );
  is( $t_reply->[2][0]->code(), E_NO_SCRIPT, "$t_npref; level 1; error code" );

  return;
}

sub t_errors_in_mbulk_reply_mth2 {
  my $redis = shift;

  my $script = <<LUA
return { ARGV[1], redis.error_reply( "Something wrong." ),
    { redis.error_reply( "NOSCRIPT No matching script." ) } }
LUA
;
  my $t_err_msg;
  my $t_err_code;
  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->eval( $script, 0, 42,
        sub {
          $t_reply = shift;

          if ( @_ ) {
            $t_err_msg  = shift;
            $t_err_code = shift;
          }

          $cv->send();
        }
      );
    }
  );

  my $t_npref = "errors in multi-bulk reply; 'on_reply' used";
  is( $t_err_msg, "Operation \"eval\" completed with errors.",
      "$t_npref; error message" );
  is( $t_err_code, E_OPRN_ERROR, "$t_npref; error code" );

  is( $t_reply->[0], 42, "$t_npref; numeric reply" );

  isa_ok( $t_reply->[1], 'AnyEvent::Redis::RipeRedis::Error' );
  is( $t_reply->[1]->message(), 'Something wrong.',
      "$t_npref; level 0; error message" );
  is( $t_reply->[1]->code(), E_OPRN_ERROR, "$t_npref; level 0; error code" );

  isa_ok( $t_reply->[2][0], 'AnyEvent::Redis::RipeRedis::Error' );
  is( $t_reply->[2][0]->message(), 'NOSCRIPT No matching script.',
      "$t_npref; level 1; error message" );
  is( $t_reply->[2][0]->code(), E_NO_SCRIPT, "$t_npref; level 1; error code" );

  return;
}
