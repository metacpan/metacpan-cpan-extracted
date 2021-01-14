use Test2::V0;
use Test::Lib;
use TestCommon;
use Bot::IRC::Seen;

my $c = TestCommon->new;

ok( Bot::IRC::Seen->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::Seen::init( $c->bot ) }, 'init()' ) or note $@;

done_testing;
