use Test::More;
use strict; use warnings;

BEGIN {
  use_ok( 'Bot::Cobalt::Plugin::Ohm' );
}
new_ok( 'Bot::Cobalt::Plugin::Ohm' );
can_ok( 'Bot::Cobalt::Plugin::Ohm', 'Cobalt_register', 'Cobalt_unregister' );

done_testing
