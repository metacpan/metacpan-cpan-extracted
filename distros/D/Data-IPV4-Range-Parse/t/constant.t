# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-IPV4-Range-Parse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use lib qw(../lib lib .);
use Data::IPV4::Range::Parse qw(:CONSTANTS);

ok(ALL_BITS==0xffffffff,'ALL_BITS check');
ok(MIN_CIDR==0,'MIN_CIDR check');
ok(MAX_CIDR==32,'MAX_CIDR check');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

