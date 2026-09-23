#!/usr/bin/perl
##############################################################################
#
#  Data::Tools test suite -- Data::Tools::Math
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
use strict;
use lib 'lib', '../lib';
use Test::More;
use Data::Tools::Math;
use Math::BigFloat;

ok( defined $Data::Tools::Math::VERSION, 'Data::Tools::Math loaded' );

##############################################################################
# num_round()
##############################################################################

is( num_round( 3.14159, 2 ), '3.14', 'num_round() rounds down' );
is( num_round( 3.14159, 3 ), '3.142', 'num_round() rounds up' );
is( num_round( 3.14159, 0 ), '3',    'num_round() to integer' );
is( num_round( 1234.5678, 1 ), '1234.6', 'num_round() one decimal place' );
is( num_round( -3.14159, 2 ), '-3.14', 'num_round() negative number' );

is( num_round( 3.14159, -1 ), 3.14159, 'num_round() returns number unchanged for negative precision' );

# Math::BigFloat defaults to round-half-to-even
is( num_round( 2.5, 0 ), '2', 'num_round() half to even, down' );
is( num_round( 3.5, 0 ), '4', 'num_round() half to even, up' );

##############################################################################
# num_round_trunc()
##############################################################################

is( num_round_trunc( 3.19999, 2 ), '3.19', 'num_round_trunc() truncates instead of rounding' );
is( num_round_trunc( 3.19999, 0 ), '3',    'num_round_trunc() to integer' );
is( num_round_trunc( -3.19999, 2 ), '-3.19', 'num_round_trunc() negative number' );
is( num_round_trunc( 3.14159, -1 ), 3.14159, 'num_round_trunc() returns number unchanged for negative precision' );

isnt( num_round( 3.999, 2 ), num_round_trunc( 3.999, 2 ),
      'num_round() and num_round_trunc() differ where rounding matters' );

# num_round_trunc() must not change Math::BigFloat's global round mode
num_round_trunc( 1.11, 1 );
is( num_round( 3.999, 2 ), '4.00', 'num_round_trunc() does not leak its round mode into num_round()' );
is( Math::BigFloat->round_mode(), 'even', 'num_round_trunc() leaves the global round mode alone' );

##############################################################################
# num_pow()
##############################################################################

is( num_pow( 2, 10 ), '1024', 'num_pow() integer power' );
is( num_pow( 2,  0 ), '1',    'num_pow() zero exponent' );
is( num_pow( 5,  1 ), '5',    'num_pow() first power' );
is( num_pow( 10, 3 ), '1000', 'num_pow() power of ten' );
like( num_pow( 2, 0.5 ), qr/^1\.41421356/, 'num_pow() fractional exponent' );

# big numbers beyond native integer precision
is( num_pow( 2, 64 ), '18446744073709551616', 'num_pow() handles big integers exactly' );

##############################################################################

done_testing();
