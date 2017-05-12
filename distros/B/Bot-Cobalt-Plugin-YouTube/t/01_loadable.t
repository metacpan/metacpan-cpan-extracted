use Test::More tests => 3;
use strict; use warnings;

BEGIN {
  use_ok( 'Bot::Cobalt::Plugin::YouTube' );
}

my $obj = new_ok( 'Bot::Cobalt::Plugin::YouTube' );
can_ok( $obj, 'Cobalt_register', 'Cobalt_unregister' );
