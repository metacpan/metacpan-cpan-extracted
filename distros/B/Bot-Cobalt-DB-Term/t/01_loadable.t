use Test::More tests => 2;

BEGIN {
  use_ok('Bot::Cobalt::DB::Term');
}
can_ok( 'Bot::Cobalt::DB::Term', 'new', 'interactive' );
