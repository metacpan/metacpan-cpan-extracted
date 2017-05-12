#!/usr/bin/perl

use strict;
use warnings;

use AnyEvent;
use AnyEvent::RipeRedis;

my $cv = AE::cv;

my $redis = AnyEvent::RipeRedis->new(
  host     => 'localhost',
  port     => 6379,
  password => 'redis_pass',

  on_connect => sub {
    print "Connected to Redis server\n";
  },

  on_disconnect => sub {
    print "Disconnected from Redis server\n";
  },
);

# Execute Lua script
$redis->eval_cached( 'return { KEYS[1], KEYS[2], ARGV[1], ARGV[2] }',
    2, 'key1', 'key2', 'first', 'second',
  sub {
    my $reply = shift;
    my $err   = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      return;
    };

    foreach my $val ( @{$reply}  ) {
      print "$val\n";
    }

    $cv->send;
  }
);

$cv->recv;

$redis->disconnect;
