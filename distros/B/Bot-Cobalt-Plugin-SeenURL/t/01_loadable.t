use Test::More;

BEGIN {
   use_ok( 'Bot::Cobalt::Plugin::SeenURL' );
}

new_ok( 'Bot::Cobalt::Plugin::SeenURL' );
can_ok( 'Bot::Cobalt::Plugin::SeenURL', 'Cobalt_register', 'Cobalt_unregister' );

done_testing();
