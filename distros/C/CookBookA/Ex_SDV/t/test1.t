#!perl -w

use strict;
use CookBookA::Ex_SDV;

print "1..2\n";

my $str = "Forty-Two";
my $num = 42;
my $var;

SetDualVar( $var, $str, $num );

# $var in string context
print( (($var eq 'Forty-Two')? "ok ": "not ok "), "1\n" );

# $var in number context
print( (($var == 42)? "ok ": "not ok "), "2\n" );

