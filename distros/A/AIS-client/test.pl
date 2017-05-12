# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
BEGIN {print <<EOF };
AIS::client redirects and exits, only achieving it's
aim of authenticating a user against a central AIS server
after at least three state-altering calls to itself.

If you can figure out a way to write a test harness for
it I'll gladly accept the patch.

under these lines you should see something like
Set-Cookie:/AIS_session=SomE1RanDoM5GaRBagE
Location: http://?AIS_INITIAL
--------------------------------------------
EOF
ok(0);
use AIS::client;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.




