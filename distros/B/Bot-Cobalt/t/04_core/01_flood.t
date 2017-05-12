use Test::More tests => 12;
use strict; use warnings;

BEGIN {
  use_ok('Bot::Cobalt::IRC::FloodChk')
}

my $flood = new_ok('Bot::Cobalt::IRC::FloodChk' => [ count => 2, in => 180]);

is( $flood->check('c', 'key'), 0, 'First OK' );
is( $flood->check('c', 'key'), 0, 'Second OK' );
cmp_ok( $flood->check('c', 'key'), '>', 0, 'Third delayed' );
cmp_ok( $flood->check('c', 'key'), '>', 0, 'Fourth delayed' );
is( $flood->check('c', 'otherkey'), 0, 'check() a new key #1' );
is( $flood->check('c', 'otherkey'), 0, 'check() a new key #2' );

ok( $flood->clear('c', 'key'), 'clear() key' );
is( $flood->check('c', 'key'), 0, 'check() after clear #1' );
is( $flood->check('c', 'key'), 0, 'check() after clear #2' );
ok( $flood->clear('c'), 'clear() context' );
