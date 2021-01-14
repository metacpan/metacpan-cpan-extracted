use Test2::V0 -srand => 20201025;
use Test::Lib;
use TestCommon;
use Bot::IRC::Functions;

my $c = TestCommon->new;

ok( Bot::IRC::Functions->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::Functions::init( $c->bot ) }, 'init()' ) or note $@;
ok( lives { $c->hook( undef, { function => 'ord', input => 'c' } ) }, 'ord()' ) or note $@;
ok( lives { $c->hook( undef, { function => 'chr', input => '99' } ) }, 'chr()' ) or note $@;
ok( lives { $c->hook( undef, { function => 'rot13', input => 'abc' } ) }, 'rot13()' ) or note $@;
ok( lives { $c->hook( undef, { function => 'crypt', input => 'abc' } ) }, 'crypt()' ) or note $@;

is( $c->replies, [
    ['"c" has a numerical value of 99.'],
    ['99 has a character value of "c".'],
    ['The ROT13 of your input is "dbc".'],
    ['The crypt value of your input is "ijnkUIPeIgdfA".'],
], 'ord text' );

done_testing;
