
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

# HARNESS-DURATION-LONG
use Test2::V0;

BEGIN {
	eval { require JSON::MaybeXS; 1 }
		or skip_all 'This test requires module JSON::MaybeXS';
}

use lib 't/lib';
use BitcoinCoreTest;

# test data from Bitcoin Core, mentioned in
# https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#test-vectors
#
# test data was prepared as follows:
# - bogus test cases with empty signature and witness were truncated
# - long and short tests were moved to separate json files
# - flags and final flag was truncated from each test to save space

BitcoinCoreTest::test_validation('taproot-short');

done_testing;
