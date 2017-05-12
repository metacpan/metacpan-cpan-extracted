#!/usr/bin/perl -w

use strict;
use Test;
BEGIN { plan tests => 169 };
use Data::Types qw(:all);
ok(1); # If we made it this far, we're ok.

#########################

# Test is_whole.
ok( is_whole(10) );
ok( is_whole(22) );
ok( is_whole(1) );
ok( is_whole(700) );
ok( is_whole(0) );
ok( ! is_whole(.22) );
ok( ! is_whole(-33) );
ok( ! is_whole(-0.1) );

# Test to_whole.
ok( to_whole(10) == 10 );
ok( to_whole(1) == 1 );
ok( to_whole('foo33') ==  33);
ok( to_whole('ri+4') == 4 );
ok( to_whole('+45ts') == 45 );
ok( to_whole(1.23e99) == 1) ;  # This should probably be changed somehow.
ok( to_whole(0) eq '0' );
ok( ! defined to_whole('blech') );
ok( ! defined to_whole('') );
ok( ! defined to_whole(undef) );
ok( to_whole('foo00') eq '0' );
ok( to_whole(.44) eq '0' );
ok( ! defined to_whole('foo-33') );
ok( ! defined to_whole(-44) );
ok( ! defined to_whole(-0.33) );
ok( ! defined to_whole('sep-0.1') );

# Test is_count.
ok( is_count(10) );
ok( is_count(22) );
ok( is_count(1) );
ok( is_count(700) );
ok( ! is_count(0) );
ok( ! is_count(.22) );
ok( ! is_count(-33) );
ok( ! is_count(-0.1) );

# Test to_count.
ok( to_count(10) == 10 );
ok( to_count(1) == 1 );
ok( to_count('foo33') ==  33);
ok( to_count('ri+4') == 4 );
ok( to_count('+45ts') == 45 );
ok( to_count(1.23e99) == 1) ;  # This should probably be changed somehow.
ok( ! defined to_count(0) );
ok( ! defined to_count('blech') );
ok( ! defined to_count('') );
ok( ! defined to_count(undef) );
ok( ! defined to_count('foo00') );
ok( ! defined to_count(.44) );
ok( ! defined to_count('foo-33') );
ok( ! defined to_count(-44) );
ok( ! defined to_count(-0.33) );
ok( ! defined to_count('sep-0.1') );

# Test is_int.
ok( is_int(10) );
ok( is_int(0) );
ok( is_int(-33) );
ok( is_int(+23) );
ok( ! is_int('+') );
ok( ! is_int('-') );
ok( ! is_int(22.2) );
ok( ! is_int(0.44) );
ok( ! is_int('foo') );
ok( ! is_int('33foo') );
ok( ! is_int(-33.2) );
ok( ! is_int(undef));
ok( ! is_int(''));

# Test to_int.
ok( to_int(10) == 10 );
ok( to_int(10.22) == 10 );
ok( to_int(0.44) == 0 );
ok( to_int(0.54) == 1 );
ok( to_int(10.468473895043) == 10 );
ok( to_int(+10.51) == 11);
ok( to_int("10.44foo") == 10 );
ok( to_int(-22) == -22 );
ok( to_int(-22.6) == -23);
ok( to_int(1.23e99) == 1) ;  # This should probably be changed somehow.
ok( ! defined to_int(undef) );
ok( ! defined to_int('') );
ok( ! defined to_int('foo') );

# Test is_decimal.
ok( is_decimal(.22) );
ok( is_decimal(0.4) );
ok( is_decimal(22.44) );
ok( is_decimal(-0.44) );
ok( is_decimal(-100.45) );
ok( is_decimal(0) );
ok( is_decimal(22) );
ok( is_decimal(-33) );
ok( is_decimal(-33.0) );
ok( ! is_decimal('+') );
ok( ! is_decimal('-') );
ok( ! is_decimal(undef) );
ok( ! is_decimal('foo') );
ok( ! is_decimal('foo22') );
ok( ! is_decimal('22foo') );
ok( ! is_decimal(1.23e99) );

# Test to_decimal.
ok( to_decimal(0) == 0 );
ok( to_decimal(100) == 100 );
ok( to_decimal(0.22) == 0.22 );
ok( to_decimal(-4) == -4 );
ok( to_decimal(-3.4) == -3.4 );
ok( to_decimal('foo3.5') == 3.5 );
ok( to_decimal('-35foo') == -35 );
ok( to_decimal('foo-3') == -3 );
ok( to_decimal('40foo') == 40 );
ok( to_decimal(1.23e99) == 1.23 ); # This should probably be changed somehow.
ok( to_decimal(10.500009) == 10.50001 );
ok( to_decimal(10.500009, 10) == 10.500009 );
ok( ! defined to_decimal(undef) );
ok( ! defined to_decimal('') );
ok( ! defined to_decimal('foo'));

# Test is_real.
ok( is_real(0) );
ok( is_real(100) );
ok( is_real(0.22) );
ok( is_real(-4) );
ok( is_real(-4.9) );
ok( is_real(12043.3423) );
ok( ! is_real('foo') );
ok( ! is_real('+') );
ok( ! is_real('-') );
ok( ! is_real(undef) );
ok( ! is_real('foo34.33') );
ok( ! is_real(1.23e99) );

# Test to_real.
ok( to_real(0) == 0 );
ok( to_real(100) == 100 );
ok( to_real(0.22) == 0.22 );
ok( to_real(-4) == -4 );
ok( to_real(-3.4) == -3.4 );
ok( to_real('foo3.5') == 3.5 );
ok( to_real('-35foo') == -35 );
ok( to_real('foo-3') == -3 );
ok( to_real('40foo') == 40 );
ok( to_real(1.23e99) == 1.23 ); # This should probably be changed somehow.
ok( ! defined to_real(undef) );
ok( ! defined to_real('') );
ok( ! defined to_real('foo'));

# Test is_float.
ok( is_float(10) );
ok( is_float(11.2) );
ok( is_float(0.2) );
ok( is_float(345.96948383) );
ok( is_float(1.23e99) );
ok( is_float(-938.54) );
ok( is_float(+234.5) );
ok( !is_float('foo') );
ok( !is_float('22.34foo') );
ok( !is_float(undef) );
ok( !is_float('+') );
ok( !is_float('-') );
ok( !is_float('') );

# Test to_float.
ok( to_float(10) == 10 );
ok( to_float(11.2) == 11.2 );
ok( to_float(456.98765) == 456.98765 );
ok( to_float(0) == 0 );
ok( to_float('44.334foo') == 44.334 );
ok( to_float(-34.3) == -34.3 );
ok( to_float(+456.04) == 456.04 );
ok( to_float(1.23e99) == 1.23000e99 );
ok( to_float(1.23e99, 1) == 1.2e99 );
ok( to_float('foo1.23e99') == 1.23000e99 );
ok( ! defined to_float(undef) );
ok( ! defined to_float('') );
ok( ! defined to_float('foo'));

# Test is_string.
ok( is_string('foo') );
ok( is_string(4) );
my $var = [];
ok( is_string("$var") );
ok( ! is_string($var) );
ok( ! is_string(undef) );

# Test is_string.
ok( to_string(44) eq '44' );
ok( to_string('foo') eq 'foo' );
ok( to_string('') eq '' );
ok( to_string(0) eq '0' );
ok( to_string($var) eq "$var" );
ok( ! defined to_string(undef) );
ok( to_string('hello', 4) eq 'hell' );

__END__
