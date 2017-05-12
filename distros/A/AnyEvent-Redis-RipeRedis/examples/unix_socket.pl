#!/usr/bin/perl

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Redis::RipeRedis;

my $cv = AE::cv();

my $redis;
$redis = AnyEvent::Redis::RipeRedis->new(
  host                   => 'unix/',
  port                   => '/var/run/redis/redis.sock',
  password               => 'redis_pass',
  connection_timeout     => 5,
  read_timeout           => 5,
  min_reconnect_interval => 5,

  on_connect => sub {
    print "Connected to Redis server\n";
  },

  on_disconnect => sub {
    print "Disconnected from Redis server\n";
  },
);

my $timer;
$timer = AE::timer( 0, 1,
  sub {
    $redis->incr( 'foo',
      sub {
        my $data = shift;

        if ( @_ ) {
          my $err_msg = shift;

          warn $err_msg;

          return;
        }

        print "$data\n";
      },
    );
  },
);

my $on_signal = sub {
  print "Stopped\n";
  $cv->send();
};

my $int_w  = AE::signal( INT  => $on_signal );
my $term_w = AE::signal( TERM => $on_signal );

$cv->recv();

$redis->disconnect();
