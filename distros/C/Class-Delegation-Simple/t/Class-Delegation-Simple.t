#!perl -w

use strict;
use warnings 'all';
use Test::More tests => 1006;
use lib 't';
use Delegator1;

my $del = eval { Delegator1->new() };
ok( $del, 'Delegator1 instance created' );

ok( $del->steer( 'left' ), 'steer(left)' );

ok( $del->wipe( 'fast' ), 'wipe(fast)' );

is( $del->steer('right'), "Method 'turn'(right) called on 'wheel'!", 'steer(right) returns 1 result' );
is( $del->wipe('medium'), 2, 'wipe(medium) returns 2 results' );

ok( (! eval { $del->missing_method() }) && $@, '! missing_method()' );

for( 1...1000 )
{
  ok( $del->steer('wildly') );
}# end for()

