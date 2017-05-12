use 5.008000;
use strict;
use warnings;

use Test::More;
use AnyEvent::RipeRedis qw( :err_codes );
use Scalar::Util qw( weaken );
use version 0.77;
require 't/test_helper.pl';

BEGIN {
  eval "use Test::LeakTrace 0.15";
  if ( $@ ) {
    plan skip_all => 'Test::LeakTrace 0.15 required for this test';
  }
}

my $server_info = run_redis_instance();
if ( !defined $server_info ) {
  plan skip_all => 'redis-server is required for this test';
}
plan tests => 6;

my $redis = AnyEvent::RipeRedis->new(
  host => $server_info->{host},
  port => $server_info->{port},
);

t_leaks_status_reply($redis);
t_leaks_bulk_reply($redis);
t_leaks_mbulk_reply($redis);
t_leaks_nested_mbulk_reply($redis);
t_leaks_subunsub($redis);

my $ver = get_redis_version($redis);

SKIP: {
  if ( $ver < version->parse( 'v2.6' ) ) {
    skip 'redis-server 2.6 or higher is required for this test', 1;
  }

  t_leaks_eval_cached($redis);
}

$redis->disconnect;


sub t_leaks_status_reply {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        $redis->set( 'foo', "some\r\nstring",
          sub {
            my $reply = shift;
            my $err   = shift;

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
  } 'leaks; status reply';

  return;
}

sub t_leaks_bulk_reply {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        $redis->set( 'foo', "some\r\nstring" );

        $redis->get( 'foo',
          sub {
            my $reply = shift;
            my $err   = shift;

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
  } 'leaks; bulk reply';

  return;
}

sub t_leaks_mbulk_reply {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        for ( my $i = 1; $i <= 3; $i++ ) {
          $redis->rpush( 'list', "element_$i" );
        }

        $redis->lrange( 'list', 0, -1,
          sub {
            my $reply = shift;
            my $err   = shift;

            if ( defined $err ) {
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
  } 'leaks; multi-bulk reply';

  return;
}

sub t_leaks_nested_mbulk_reply {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        for ( my $i = 1; $i <= 3; $i++ ) {
          $redis->rpush( 'list', "element_$i" );
        }

        $redis->set( 'foo', "some\r\nstring" );

        $redis->multi;
        $redis->incr( 'bar' );
        $redis->lrange( 'list', 0, -1 );
        $redis->lrange( 'non_existent', 0, -1 );
        $redis->get( 'foo' );
        $redis->lrange( 'list', 0, -1 );
        $redis->exec(
          sub {
            my $reply = shift;
            my $err   = shift;

            if ( defined $err ) {
              diag( $err->message );
            }
          },
        );

        $redis->del( qw( foo list bar ),
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
  } 'leaks; nested multi-bulk reply';

  return;
}

sub t_leaks_subunsub {
  my $redis = shift;

  no_leaks_ok {
    ev_loop(
      sub {
        my $cv = shift;

        $redis->subscribe( qw( ch_foo ch_bar ),
          { on_reply => sub {
              my $reply = shift;
              my $err   = shift;

              if ( defined $err ) {
                diag( $err->message );
              }
            },

            on_message => sub {
              my $ch_name = shift;
              my $msg     = shift;
            },
          }
        );

        $redis->unsubscribe( qw( ch_foo ch_bar ),
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
  } 'leaks; sub/unsub';

  return;
}

sub t_leaks_eval_cached {
  my $redis = shift;

  my $script = q{
    return ARGV[1]
  };

  no_leaks_ok {
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

            $redis->eval_cached( $script, 0, 57,
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
      }
    );
  } 'leaks; eval_cached';

  return;
}
