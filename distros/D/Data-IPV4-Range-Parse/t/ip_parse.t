# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-IPV4-Range-Parse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
use lib qw(../lib lib .);
use Data::IPV4::Range::Parse qw(:PARSE_IP);

ok(1==ip_to_int('0.0.0.1'),'ip_to_int 1');
ok(1==Data::IPV4::Range::Parse->ip_to_int('0.0.0.1'),'ip_to_int 2');
ok('0.0.0.1' eq int_to_ip(1),'int_to_ip 1');
ok('0.0.0.1' eq Data::IPV4::Range::Parse->int_to_ip(1),'int_to_ip 2');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

