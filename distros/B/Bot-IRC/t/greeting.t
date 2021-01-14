use Test2::V0;
use Test::Lib;
use TestCommon;
use Bot::IRC::Greeting;

my $c = TestCommon->new;

ok( Bot::IRC::Greeting->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::Greeting::init( $c->bot ) }, 'init()' ) or note $@;
ok( lives { $c->hook( { forum => '#test', nick => 'gRyphon' }, undef ) }, 'hook()' ) or note $@;
is( $c->replies, [['gReetings']], 'greeting text' );

done_testing;
