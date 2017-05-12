use 5.008000;
use strict;
use warnings;

use Test::More tests => 3;

my $T_CLASS;

BEGIN {
  $T_CLASS = 'AnyEvent::Redis::RipeRedis';
  use_ok( $T_CLASS );
}

can_ok( $T_CLASS, 'new' );
my $redis = new_ok( $T_CLASS );
