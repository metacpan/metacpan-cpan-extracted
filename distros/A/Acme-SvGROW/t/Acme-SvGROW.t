# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Acme-SvGROW.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use Acme::SvGROW;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

eval {
	# growing a constant should fail
	SvGROW("this is a constant",999);
};
ok ($@||warn "It is possible to grow constants using this module\n");

my $x = q:abcdef:;
SvGROW $x, 9000;

ok ($x eq 'abcdef');


