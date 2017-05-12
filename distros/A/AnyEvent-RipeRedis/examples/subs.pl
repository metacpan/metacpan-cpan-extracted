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

my @channels = qw( foo bar );
my @patterns = qw( info_* err_* );

# Subscribe to channels by name
$redis->subscribe( @channels,
  { on_reply => sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        warn $err->message . "\n";
        return;
      };

      print 'Subscribed on: ' . join( ', ', @channels ). "\n";
    },

    on_message => sub {
      my $message = shift;
      my $channel = shift;

      print "$channel: $message\n";
    },
  }
);

# Subscribe to channels by pattern
$redis->psubscribe( @patterns,
  { on_reply => sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        warn $err->message . "\n";
        return;
      };

      print 'Subscribed on: ' . join( ', ', @patterns ). "\n";
    },

    on_message => sub {
      my $message = shift;
      my $pattern = shift;
      my $channel = shift;

      print "$pattern ($channel): $message\n";
    },
  }
);

# Unsubscribe
my $on_signal = sub {
  print "Stopped\n";

  $redis->unsubscribe( @channels,
    sub {
      my $msg = shift;
      my $err = shift;

      if ( defined $err ) {
        warn $err->message . "\n";
        return;
      };

      print 'Unsubscribed from: ' . join( ', ', @channels ). "\n";
    }
  );

  $redis->punsubscribe( @patterns,
    sub {
      my $msg = shift;
      my $err = shift;

      if ( defined $err ) {
        warn $err->message . "\n";
        return;
      };

      print 'Unsubscribed from: ' . join( ', ', @patterns ). "\n";

      $cv->send;
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

my $int_w  = AE::signal( INT  => $on_signal );
my $term_w = AE::signal( TERM => $on_signal );

$cv->recv;

$redis->disconnect;
