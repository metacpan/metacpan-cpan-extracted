# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Acme-XKCD-DebianRandom.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1001;
BEGIN { use_ok('Acme::XKCD::DebianRandom') };

#########################

# stress test custom dice roll
for(my $i = 1; $i <= 1000; $i++) {
    $Acme::XKCD::DebianRandom::randomNumber = $i;
    is(getRandomNumber(), $i, "stress test custom dice roll");
}

