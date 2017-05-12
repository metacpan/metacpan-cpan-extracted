#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More;
use Math::BigInt try => 'GMP, Pari';

BEGIN {
	if ( not $INC{'Math/BigInt/GMP.pm'} and not $INC{'Math/BigInt/Pari.pm'} ) {
		plan( skip_all => 'Test is excessively slow without GMP or Pari' );
	} else {
		plan( tests => 18 );
	}
}

use Crypt::DSA;
use Crypt::DSA::Util qw( mod_exp );

my $dsa = Crypt::DSA->new;
my $two = Math::BigInt->new(2);
for my $bits (qw( 512 768 1024 )) {
	my $key = $dsa->keygen( Size => $bits );
	ok($key, "Key generated of size $bits bits");
	ok($key->size, "Key is $bits bits");
	ok(($key->p < ($two ** $bits)) && ($key->p > ($two ** ($bits-1))), "p of appropriate size ($bits bits)");
	ok(($key->q < ($two ** 160)) && ($key->q > ($two ** 159)), "q of appropriate size ($bits bits)");
	ok(0 == ($key->p - 1) % $key->q, "Consistency check 1 ($bits bits)");
	ok($key->pub_key == mod_exp($key->g, $key->priv_key, $key->p), "Consistency check 2 ($bits bits)");
}
