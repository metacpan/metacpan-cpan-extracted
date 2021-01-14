use Test2::V0;
use Test::Lib;
use TestCommon;
use Bot::IRC::Join;

my $c = TestCommon->new;

ok( Bot::IRC::Join->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::Join::init( $c->bot ) }, 'init()' ) or note $@;

done_testing;
