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

# Increment
$redis->incr( 'foo',
  sub {
    my $reply = shift;
    my $err   = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      return;
    }

    print "$reply\n";
  }
);

# Set value
$redis->set( 'bar', 'Some string',
  sub {
    my $reply = shift;
    my $err   = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      return;
    }

    print "SET is done\n";
  }
);

# Get value
$redis->get( 'bar',
  sub {
    my $reply = shift;
    my $err   = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      return;
    }

    print "$reply\n";
  }
);

# Push values
for ( my $i = 1; $i <= 3; $i++ ) {
  $redis->rpush( 'list', "element_$i",
    sub {
      my $reply = shift;
      my $err   = shift;

      if ( defined $err ) {
        warn $err->message . "\n";
        return;
      }

      print "$reply\n";
    }
  );
}

# Get list of values
$redis->lrange( 'list', 0, -1,
  sub {
    my $reply = shift;
    my $err   = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      return;
    }

    foreach my $value ( @{$reply} ) {
      print "$value\n";
    }
  }
);

# Transaction
$redis->multi(
  sub {
    my $reply = shift;
    my $err   = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      return;
    }

    print "Transaction begun\n";
  }
);
$redis->incr( 'foo',
  sub {
    my $reply = shift;
    my $err   = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      return;
    }

    print "$reply\n";
  }
);
$redis->lrange( 'list', 0, -1,
  sub {
    my $reply = shift;
    my $err   = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      return;
    }

    print "$reply\n";
  }
);
$redis->get( 'bar',
  sub {
    my $reply = shift;
    my $err   = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      return;
    }

    print "$reply\n";
  }
);
$redis->exec(
  sub {
    my $replies = shift;
    my $err     = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      return;
    }

    foreach my $reply ( @{$replies} ) {
      if ( ref( $reply ) eq 'ARRAY' ) {
        foreach my $value ( @{$reply} ) {
          print "$value\n";
        }
      }
      else {
        print "$reply\n";
      }
    }
  }
);

# Delete keys
$redis->del( qw( foo bar list ),
  sub {
    my $reply = shift;
    my $err   = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      return;
    }

    print "$reply keys removed\n";
  }
);

# Disconnect
$redis->quit(
  sub {
    my $reply = shift;
    my $err   = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
    }

    $cv->send;
  }
);

$cv->recv;
