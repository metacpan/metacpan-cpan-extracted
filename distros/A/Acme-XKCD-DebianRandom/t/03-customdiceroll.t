# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Acme-XKCD-DebianRandom.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Acme::XKCD::DebianRandom') };

#########################

# Custom dice roll
$Acme::XKCD::DebianRandom::randomNumber = 10;
is(getRandomNumber(), 10, "Correct custom dice roll");

