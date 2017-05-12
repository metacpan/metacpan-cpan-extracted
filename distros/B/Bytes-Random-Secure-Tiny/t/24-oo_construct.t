## no critic (RCS,VERSION,encapsulation,Module,eval,constant)

use strict;
use warnings;
use Test::More;
use 5.006000;
use Bytes::Random::Secure::Tiny;

# Test the constructor, and its helper functions.

can_ok( 'Bytes::Random::Secure::Tiny', qw/ new / );

$Math::Random::ISAAC::Embedded::EMBEDDED_CSPRNG = 1;

# Instantiate with a dummy callback so we don't drain entropy.
my $random = new_ok 'Bytes::Random::Secure::Tiny' => [Bits=>128,NonBlocking=>1];

isa_ok $random, 'Bytes::Random::Secure::Tiny';
is $random->{'bits'}, 128, 'Seed is 128 bits.';

new_ok 'Bytes::Random::Secure::Tiny' => [NonBlocking=>0,Bits=>64]
    if $ENV{RELEASE_TESTING};

done_testing();
