use 5.008000;
use strict;
use warnings;

use Test::More;
use AnyEvent::RipeRedis qw( :err_codes );
use Digest::SHA qw( sha1_hex );
use Scalar::Util qw( weaken );
use version 0.77;
require 't/test_helper.pl';

my $server_info = run_redis_instance();
if ( !defined $server_info ) {
  plan skip_all => 'redis-server is required for this test';
}
my $redis = AnyEvent::RipeRedis->new(
  host => $server_info->{host},
  port => $server_info->{port},
);
my $ver = get_redis_version($redis);
if ( $ver < version->parse( 'v2.6' ) ) {
  plan skip_all => 'redis-server 2.6 or higher is required for this test';
}
plan tests => 17;

t_no_script($redis);
t_eval_cached($redis);
t_eval_cached_mbulk($redis);
t_error_reply($redis);
t_errors_in_mbulk_reply($redis);

$redis->disconnect;


sub t_no_script {
  my $redis = shift;

  my $t_err;

  my $script = q{
    return redis.status_reply( 'OK' )
  };

  my $script_sha1 = sha1_hex($script);

  ev_loop(
    sub {
      my $cv = shift;

      $redis->evalsha( $script_sha1, 0,
        sub {
          my $reply = shift;
          $t_err    = shift;

          $cv->send;
        }
      );
    }
  );

  my $t_npref = 'no script';
  like( $t_err->message, qr/^NOSCRIPT/, "$t_npref; error message" );
  is( $t_err->code, E_NO_SCRIPT, "$t_npref; error code" );

  return;
}

sub t_eval_cached {
  my $redis = shift;

  my $script = q{
    return ARGV[1]
  };

  my @t_replies;

  ev_loop(
    sub {
      my $cv = shift;

      my $redis = $redis;
      weaken( $redis );

      $redis->eval_cached( $script, 0, 42,
        sub {
          my $reply = shift;
          my $err   = shift;

          if ( defined $err ) {
            diag( $err->message );
            $cv->send;

            return;
          }

          push( @t_replies, $reply );

          $redis->eval_cached( $script, 0, 15 );

          $redis->eval_cached( $script, 0, 57,
            sub {
              my $reply = shift;
              my $err   = shift;

              if ( defined $err ) {
                diag( $err->message );
                $cv->send;

                return;
              }

              push( @t_replies, $reply );

              $cv->send;
            }
          );
        }
      );
    }
  );

  is_deeply( \@t_replies, [ qw( 42 57 ) ], "eval_cached" );

  return;
}

sub t_eval_cached_mbulk {
  my $redis = shift;

  my $script = q{
    return
      { ARGV[1], ARGV[2],
        { ARGV[3],
          { ARGV[5], ARGV[6] },
          ARGV[4],
          { ARGV[7], ARGV[8] }
        }
      }
  };

  my $t_reply;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->eval_cached( $script, 0, qw( foo bar coo dar moo nar loo zar ),
        sub {
          $t_reply = shift;
          my $err  = shift;

          $cv->send;
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
    ], 'eval_cached; multi-bulk' );

  return;
}

sub t_error_reply {
  my $redis = shift;

  my $script = q{
    return redis.error_reply( "ERR Something wrong." )
  };

  my $t_err;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->eval_cached( $script, 0,
        sub {
          my $reply = shift;
          $t_err    = shift;

          $cv->send;
        }
      );
    }
  );

  my $t_npref = 'eval_cached; error reply';
  isa_ok( $t_err, 'AnyEvent::RipeRedis::Error' );
  is( $t_err->message, 'ERR Something wrong.', "$t_npref; error message" );
  is( $t_err->code, E_OPRN_ERROR, "$t_npref; error code" );

  return;
}

sub t_errors_in_mbulk_reply {
  my $redis = shift;

  my $script = q{
    return { ARGV[1], redis.error_reply( "Something wrong." ),
        { redis.error_reply( "NOSCRIPT No matching script." ) } }
  };

  my $t_reply;
  my $t_err;

  ev_loop(
    sub {
      my $cv = shift;

      $redis->eval_cached( $script, 0, 42,
        sub {
          $t_reply = shift;
          $t_err   = shift;

          $cv->send;
        }
      );
    }
  );

  my $t_npref = 'errors in multi-bulk reply';
  isa_ok( $t_err, 'AnyEvent::RipeRedis::Error' );
  is( $t_err->message, q{Operation "eval_cached" completed with errors.},
      "$t_npref; error message" );
  is( $t_err->code, E_OPRN_ERROR, "$t_npref; error code" );

  is( $t_reply->[0], 42, "$t_npref; numeric reply" );

  isa_ok( $t_reply->[1], 'AnyEvent::RipeRedis::Error' );
  is( $t_reply->[1]->message, 'Something wrong.',
      "$t_npref; level 0; error message" );
  is( $t_reply->[1]->code, E_OPRN_ERROR, "$t_npref; level 0; error code" );

  isa_ok( $t_reply->[2][0], 'AnyEvent::RipeRedis::Error' );
  is( $t_reply->[2][0]->message, 'NOSCRIPT No matching script.',
      "$t_npref; level 1; error message" );
  is( $t_reply->[2][0]->code, E_NO_SCRIPT, "$t_npref; level 1; error code" );

  return;
}
