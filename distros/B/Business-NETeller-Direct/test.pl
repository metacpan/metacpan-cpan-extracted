# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
require Business::NETeller::Direct;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $nd = new NetDirect(
        amount => 100,
        merchant_id => 12345,
        net_account => 54321
);

ok($nd);

ok($nd->request_vars()->{amount} == 100);

ok($nd->post() ? 0 : 1);

