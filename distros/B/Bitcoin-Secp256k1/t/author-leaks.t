
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test2::V0;
use Bitcoin::Secp256k1;

use constant HAS_TEST_MEMORYGROWTH => eval { require Test::MemoryGrowth; 1 };
plan skip_all => 'This test requires Test::MemoryGrowth module'
	unless HAS_TEST_MEMORYGROWTH;

################################################################################
# This tests whether Bitcoin::Secp256k1 leaks memory
################################################################################

my $private_key = "\x12" x 32;
my $message = 'a quick brown fox jumped over a lazy dog';

Test::MemoryGrowth::no_growth {
	my $secp = Bitcoin::Secp256k1->new;

	my $public_key = $secp->create_public_key($private_key);
	$public_key = $secp->compress_public_key($public_key, !!0);

	my $signature = $secp->sign_message($private_key, $message);
	die 'invalid sig?' unless $secp->verify_message($public_key, $signature, $message);
}
calls => 1000, 'construction/destruction of Bitcoin::Secp256k1 does not leak';

done_testing;
