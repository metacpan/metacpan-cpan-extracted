use Test2::V0;
use Test::Lib;
use TestCommon;
use Bot::IRC::Ping;

my $c = TestCommon->new;

ok( Bot::IRC::Ping->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::Ping::init( $c->bot ) }, 'init()' ) or note $@;

done_testing;
