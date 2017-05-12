#!/usr/bin/perl

# use strict;
use Test::More tests => 9;

use_ok('Acme::AutoColor', 'X', 'HTML');

ok( RED()   eq 'ff0000', "red" );
ok( GREEN() eq '00ff00', "green" );
ok( BLUE()  eq '0000ff', "blue" );

my @red = RED();
ok( $red[0] == 255 );
ok( $red[1] == 0   );
ok( $red[2] == 0   );
ok( @red == 3 );

eval { non_color(); };
ok($@, "non_color");
