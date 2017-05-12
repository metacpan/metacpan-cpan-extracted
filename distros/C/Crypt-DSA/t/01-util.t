#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 13;
use Math::BigInt;
use Crypt::DSA::Util qw( bin2mp mp2bin bitsize mod_exp mod_inverse );

my $string = "abcdefghijklmnopqrstuvwxyz-0123456789";
my $number = Math::BigInt->new(
	'48431489725691895261376655659836964813311343' .
	'892465012587212197286379595482592365885470777'
);
my $n = bin2mp($string);
is( $n, $number, 'bin2mp is correct for long string'             );
is( bitsize($number), 295, 'bitsize is correct for large number' );
is( bitsize($n), 295, 'bitsize is correct for large mp'          );
is( mp2bin($n), $string, 'mp2bin is correct for large number'    );

$string = "abcd";
$number = 1_633_837_924;
$n = bin2mp($string);
is( $n, $number, 'bin2mp is correct for short string'           );
is( bitsize($number), 31, 'bitsize is correct for small number' );
is( bitsize($n), 31, 'bitsize is correct for small mp'          );
is( mp2bin($n), $string, 'mp2bin is correct for small number'   );

$string = "";
$number = 0;
$n = bin2mp($string);
is( $n, $number, 'bin2mp is correct for empty string'         );
is( mp2bin($n), $string, 'mp2bin is correct for empty string' );

my ($n1, $n2, $n3, $n4) = map {
	Math::BigInt->new($_)
} qw{
	23098230958
	35
	10980295809854
	5115018827600
};
$number = mod_exp($n1, $n2, $n3);
is( $number, $n4, 'mod_exp is correct' );

($n1, $n2, $n3) = map {
	Math::BigInt->new($_)
} qw{
	34093840983
	23509283509
	7281956166
};
$number = mod_inverse($n1, $n2);
is( $number, $n3, 'mod_inverse is correct' );
is( 1, ($n1*$number)%$n2, 'mod_inverse reverses correctly' );
