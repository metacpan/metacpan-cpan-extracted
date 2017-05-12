#!/usr/bin/perl

# use strict;
use Test::More tests => 7;

use_ok('Acme::AutoColor', 'X', 'HTML');

ok( OCTARINE()  eq '000000ff', "octarine" );

my @octarine = OCTARINE();
ok( $octarine[0] == 0 );    # Red
ok( $octarine[1] == 0 );    # Green
ok( $octarine[2] == 0 );    # Blue
ok( $octarine[3] == 255 );  # Octarine
ok( @octarine == 4 );
