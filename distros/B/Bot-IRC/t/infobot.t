use Test2::V0;
use Test::Lib;
use TestCommon;
use Bot::IRC::Infobot;

my $c = TestCommon->new;

ok( Bot::IRC::Infobot->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::Infobot::init( $c->bot ) }, 'init()' ) or note $@;

done_testing;
