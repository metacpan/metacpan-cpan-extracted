#!/usr/bin/perl

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Redis::RipeRedis;

my $cv = AE::cv();

my $redis = AnyEvent::Redis::RipeRedis->new(
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

# Subscribe to channels by name
$redis->subscribe( qw( foo bar ),
  { on_done => sub {
      my $channel      = shift;
      my $channels_num = shift;

      print "Subscribed: $channel. Active: $channels_num\n";
    },

    on_message => sub {
      my $channel = shift;
      my $msg     = shift;

      print "$channel: $msg\n";
    },
  }
);

# Subscribe to channels by pattern
$redis->psubscribe( qw( info_* err_* ),
  { on_done => sub {
      my $pattern      = shift;
      my $channels_num = shift;

      print "Subscribed: $pattern. Active: $channels_num\n";
    },

    on_message => sub {
      my $channel    = shift;
      my $msg        = shift;
      my $pattern = shift;

      print "$channel ($pattern): $msg\n";
    },
  }
);

# Unsubscribe
my $on_signal = sub {
  print "Stopped\n";

  $redis->unsubscribe( qw( foo bar ),
    { on_done => sub {
        my $channel      = shift;
        my $channels_num = shift;

        print "Unsubscribed: $channel. Remaining: $channels_num\n";
      },
    }
  );

  $redis->punsubscribe(
    qw( info_* err_* ),
    { on_done => sub {
        my $pattern      = shift;
        my $channels_num = shift;

        print "Unsubscribed: $pattern. Remaining: $channels_num\n";

        if ( $channels_num == 0 ) {
          $cv->send();
        }
      },
    }
  );

  my $timer;
  $timer = AE::timer( 5, 0,
    sub {
      undef( $timer );
      exit 0; # Emergency exit
    },
  );
};

my $int_w = AE::signal( INT => $on_signal );
my $term_w = AE::signal( TERM => $on_signal );

$cv->recv();

$redis->disconnect();
