use Test::More;

BEGIN {
   use_ok( 'Bot::Cobalt::Plugin::Figlet' );
}

new_ok( 'Bot::Cobalt::Plugin::Figlet' );
can_ok( 'Bot::Cobalt::Plugin::Figlet', 'Cobalt_register', 'Cobalt_unregister' );

done_testing();
