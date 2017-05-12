use 5.008000;
use strict;
use warnings;

use Test::More;
use AnyEvent::RipeRedis;
require 't/test_helper.pl';

my $SERVER_INFO = run_redis_instance();
if ( !defined $SERVER_INFO ) {
  plan skip_all => 'redis-server is required for this test';
}
plan tests => 2;

my $T_CONNECTED = 0;

my $redis;

ev_loop(
  sub {
    my $cv = shift;

    $redis = AnyEvent::RipeRedis->new(
      host       => $SERVER_INFO->{host},
      port       => $SERVER_INFO->{port},
      lazy       => 1,
      reconnect  => 0,

      on_connect => sub {
        $T_CONNECTED = 1;
      },
    );

    my $timer;
    $timer = AnyEvent->timer(
      after => 3,
      cb    => sub {
        undef $timer;

        ok( !$T_CONNECTED, 'lazy connection (no connected yet)' );

        $redis->ping(
          sub {
            my $reply = shift;
            my $err   = shift;

            if ( defined $err ) {
              diag( $err->message );
            }

            $cv->send;
          }
        );
      },
    );
  }
);

ok( $T_CONNECTED, 'lazy connection (connected)' );
