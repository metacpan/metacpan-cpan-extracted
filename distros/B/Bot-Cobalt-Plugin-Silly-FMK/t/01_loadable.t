use Test::More;

BEGIN {
   use_ok( 'Bot::Cobalt::Plugin::Silly::FMK' );
}

new_ok( 'Bot::Cobalt::Plugin::Silly::FMK' );
can_ok( 'Bot::Cobalt::Plugin::Silly::FMK', 'Cobalt_register', 'Cobalt_unregister' );

done_testing();
