#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More;
use Crypt::DSA;

BEGIN {
	if ( not $INC{'Math/BigInt/GMP.pm'} and not $INC{'Math/BigInt/Pari.pm'} ) {
		plan( skip_all => 'Test is excessively slow without GMP or Pari' );
	} else {
		plan( tests => 4 );
	}
}

my $message = "Je suis l'homme a tete de chou.";

my $dsa = Crypt::DSA->new;
my $key = $dsa->keygen( Size => 512 );
my $sig = $dsa->sign(
	Message => $message,
	Key => $key,
);
my $verified = $dsa->verify(
	Key       => $key,
	Message   => $message,
	Signature => $sig,
);
ok($dsa, 'Crypt::DSA->new ok');
ok($key, 'Generated key correctly');
ok($sig, 'generated signature correctly');
ok($verified, 'verified signature correctly');
