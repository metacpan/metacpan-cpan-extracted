use Test2::V0;
use Test::Lib;
use TestCommon;
use Bot::IRC::History;

my $c = TestCommon->new;

ok( Bot::IRC::History->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::History::init( $c->bot ) }, 'init()' ) or note $@;

done_testing;
