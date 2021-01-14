use Test2::V0;
use Test::Lib;
use TestCommon;
use Bot::IRC::Math;

my $c = TestCommon->new;

ok( Bot::IRC::Math->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::Math::init( $c->bot ) }, 'init()' ) or note $@;

done_testing;
