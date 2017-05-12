#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Crypt::DSA::GMP;

BEGIN {
  if ( not     $INC{'Math/BigInt/GMP.pm'}
       and not $INC{'Math/BigInt/Pari.pm'} ) {
    plan( skip_all => 'Test is excessively slow without GMP or Pari' );
  } else {
    plan( tests => 4 );
  }
}

my $message = "Je suis l'homme a tete de chou.";

my $dsa = Crypt::DSA::GMP->new;
my $key = $dsa->keygen( Size => 512, NonBlockingKeyGeneration => 1 );
my $sig = $dsa->sign(
	Message => $message,
	Key => $key,
);
my $verified = $dsa->verify(
	Key       => $key,
	Message   => $message,
	Signature => $sig,
);
ok($dsa, 'Crypt::DSA::GMP->new ok');
ok($key, 'Generated key correctly');
ok($sig, 'generated signature correctly');
ok($verified, 'verified signature correctly');
