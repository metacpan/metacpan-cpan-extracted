# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DVD-Read.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('DVD::Read') };
BEGIN { use_ok('DVD::Read::Dvd') };
BEGIN { use_ok('DVD::Read::Dvd::Ifo') };
BEGIN { use_ok('DVD::Read::Title') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

