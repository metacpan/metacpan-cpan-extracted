use Test::More;

BEGIN {
   use_ok( 'Bot::Cobalt::Plugin::URLTitle' );
}

new_ok( 'Bot::Cobalt::Plugin::URLTitle' );
can_ok( 'Bot::Cobalt::Plugin::URLTitle', 'Cobalt_register', 'Cobalt_unregister' );

done_testing();
