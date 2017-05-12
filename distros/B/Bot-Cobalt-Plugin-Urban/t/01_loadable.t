use Test::More;

BEGIN {
   use_ok( 'Bot::Cobalt::Plugin::Urban' );
}

new_ok( 'Bot::Cobalt::Plugin::Urban' );
can_ok( 'Bot::Cobalt::Plugin::Urban', 'Cobalt_register', 'Cobalt_unregister' );

done_testing();
