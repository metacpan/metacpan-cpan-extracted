use 5.008000;
use strict;
use warnings;

use Test::More tests => 3;

my $t_class;

BEGIN {
  $t_class = 'AnyEvent::RipeRedis::Cluster';
  use_ok( $t_class );
}

can_ok( $t_class, 'new' );

my $cluster = new_ok( $t_class,
  [ startup_nodes => [
      { host => 'localhost', port => 7000 },
      { host => 'localhost', port => 7001 },
      { host => 'localhost', port => 7002 },
    ],
    lazy => 1,
  ],
);
