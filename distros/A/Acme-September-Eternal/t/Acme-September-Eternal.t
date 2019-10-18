# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Acme-September-Eternal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Acme::September::Eternal') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(eternalseptemberize('2019-10-18 10:28:00'), 'Fri, 9544th et. Sept. 1993 10:28:00', 'Positive date');
is(eternalseptemberize('1960-10-18 10:28:00'), 'Tue, -12004th et. Sept. 1993 10:28:00', 'Negative date');
