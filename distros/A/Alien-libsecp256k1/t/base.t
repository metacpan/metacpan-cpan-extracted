use Test2::V0;
use Test::Alien;
use Alien::libsecp256k1;

################################################################################
# This is a standard test recommended by the Alien documentation:
# https://metacpan.org/dist/Alien-Build/view/lib/Alien/Build/Manual/AlienAuthor.pod#Testing
################################################################################

alien_ok 'Alien::libsecp256k1';

xs_ok do { local $/; <DATA> }, with_subtest {
	Secp256k1Test::secp256k1_selftest();
	pass;    # selftest should abort the program if it fails
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <secp256k1.h>

MODULE = Secp256k1Test PACKAGE = Secp256k1Test

void secp256k1_selftest()

