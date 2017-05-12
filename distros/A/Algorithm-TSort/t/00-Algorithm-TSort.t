# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Algorithm-TSort.t'

#########################
# vim: ft=perl ts=8 sw=4 sts=4 et ff=unix
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Algorithm::TSort') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

