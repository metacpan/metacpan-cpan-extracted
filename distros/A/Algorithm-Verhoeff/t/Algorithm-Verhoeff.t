# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Algorithm-Verhoeff.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Algorithm::Verhoeff') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(verhoeff_get(123456654321) == 9, 'Generate from int') or diag('Mis-generated check digit');
ok(verhoeff_check(1234566543219) == 1, 'Check from int')or diag('Check failed, but should have worked');
ok(verhoeff_check(1243566543219) == 0, 'Simulate failure')or diag('Check worked, but should have failed');
ok(verhoeff_get('5743839105748193475681981039847561718657489228374') == 3, 'Generate from str')or diag('Mis-generated check digit');
ok(verhoeff_check('57438391057481934756819810398475617186574892283743') == 1, 'Check from str')or diag('Check failed, but should have worked');
