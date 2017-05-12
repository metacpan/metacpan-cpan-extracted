use Test::More;

BEGIN {
   use_ok( 'Bot::Cobalt::Plugin::RandomQuote' );
}

new_ok( 'Bot::Cobalt::Plugin::RandomQuote' );
can_ok( 'Bot::Cobalt::Plugin::RandomQuote', 'Cobalt_register', 'Cobalt_unregister' );

done_testing();
