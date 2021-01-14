use Test2::V0;
use Test::Lib;
use TestCommon;
use Bot::IRC::Karma;

my $c = TestCommon->new;

ok( Bot::IRC::Karma->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::Karma::init( $c->bot ) }, 'init()' ) or note $@;

done_testing;
