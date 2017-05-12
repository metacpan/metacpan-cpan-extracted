use Test::More;

BEGIN {
   use_ok( 'Bot::Cobalt::Plugin::Twitter' );
}

new_ok( 'Bot::Cobalt::Plugin::Twitter' );
can_ok( 'Bot::Cobalt::Plugin::Twitter', 'Cobalt_register', 'Cobalt_unregister' );

done_testing();
