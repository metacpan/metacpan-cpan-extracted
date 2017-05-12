# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-PayPal-EWP.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Business::PayPal::EWP') };
TODO: {
    local $TODO="PKCS7 block seems to differ each time";
    is(Business::PayPal::EWP::SignAndEncrypt("Testing, 123!","test.key","test.crt","paypal.pem"),join("",<DATA>),"Ran SignAndEncrypt");
}
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

__DATA__
