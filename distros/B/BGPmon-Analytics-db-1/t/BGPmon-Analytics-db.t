# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BGPmon-Analytics-db.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;

require_ok('Net::IP');

done_testing();

1;
