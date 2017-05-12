use 5.008000;
use strict;
use warnings;

use Test::More;
use AnyEvent::Redis::RipeRedis;
require 't/test_helper.pl';

my $SERVER_INFO = run_redis_instance();
if ( !defined $SERVER_INFO ) {
  plan skip_all => 'redis-server is required for this test';
}
plan tests => 2;

my $REDIS;
my $T_IS_CONN = 0;

ev_loop(
  sub {
    my $cv = shift;

    $REDIS = AnyEvent::Redis::RipeRedis->new(
      host       => $SERVER_INFO->{host},
      port       => $SERVER_INFO->{port},
      lazy       => 1,
      reconnect  => 0,

      on_connect => sub {
        $T_IS_CONN = 1;
      },
    );

    my $timer;
    $timer = AnyEvent->timer(
      after => 3,
      cb => sub {
        undef $timer;

        ok( !$T_IS_CONN, 'lazy connection (no connected yet)' );

        $REDIS->ping(
          { on_done => sub {
              $cv->send();
            },
          }
        );
      },
    );
  }
);

ok( $T_IS_CONN, 'lazy connection (connected)' );
