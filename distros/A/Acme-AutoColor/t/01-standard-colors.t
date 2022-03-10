#!/usr/bin/perl

# use strict;
use Test::More tests => 10;

use_ok('Acme::AutoColor', 'X', 'HTML');

my $red = RED();

ok( RED()   eq 'ff0000', "red" );
ok( GREEN() eq '00ff00', "green" );
ok( BLUE()  eq '0000ff', "blue" );

my @red = RED();
ok( $red[0] == 255 );
ok( $red[1] == 0   );
ok( $red[2] == 0   );
ok( @red == 3 );

my $nonfailed = 0;
my $noncolor;
eval { $noncolor = non_color(); $nonfailed = 1};

ok($nonfailed == 1);
ok(defined($noncolor) && $noncolor == '');
