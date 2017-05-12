# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use Crypt::Caesar;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
ok(caesar('Cnbcrwp, cnbcrwp, cnbcrwp - Cqrb rb j cnbc.') eq 'Testing, testing, testing - This is a test.');
ok(caesar('xka pl fp qefp... :)') eq 'and so is this... :)');
ok(caesar("\n1234\cB") eq "\n1234\cB");

