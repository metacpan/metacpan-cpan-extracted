use Test::More;
use strict; use warnings;

BEGIN {
  use_ok( 'Bot::Cobalt::Plugin::Calc' );
}
new_ok( 'Bot::Cobalt::Plugin::Calc' );
can_ok( 'Bot::Cobalt::Plugin::Calc', 'Cobalt_register', 'Cobalt_unregister' );

done_testing
