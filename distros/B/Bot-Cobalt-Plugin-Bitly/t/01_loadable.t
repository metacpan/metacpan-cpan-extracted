use Test::More;

BEGIN {
   use_ok( 'Bot::Cobalt::Plugin::Bitly' );
}

new_ok( 'Bot::Cobalt::Plugin::Bitly' );
can_ok( 'Bot::Cobalt::Plugin::Bitly', 'Cobalt_register', 'Cobalt_unregister' );

done_testing();
