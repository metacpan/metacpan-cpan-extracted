use Test2::V0;
use Test::Lib;
use TestCommon;
use Bot::IRC::Convert;

my $c = TestCommon->new;

ok( Bot::IRC::Convert->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::Convert::init( $c->bot ) }, 'init()' ) or note $@;
ok( lives { $c->hook( undef, { amount => 20, in_unit => 'C', out_unit => 'F' } ) }, 'C to F' ) or note $@;
is( $c->replies, [['20 C is 68 F']], 'convert text' );

done_testing;
