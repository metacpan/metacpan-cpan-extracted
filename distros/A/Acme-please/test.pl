# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use Acme::please;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$thousandtrials = grep { $please } (1 .. 10000);
print "of ten thousand trials, $thousandtrials were true.\n";
ok ($thousandtrials > 2000);	# more than one fifth
ok ($thousandtrials < 3333);	# less than one third

