# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use SecSess;
use SecSess::DBI;
use SecSess::Wrapper;
use SecSess::Cookie;
use SecSess::URL;
use SecSess::Cookie::BasicAuth;
use SecSess::Cookie::LoginForm;
use SecSess::Cookie::X509;
use SecSess::Cookie::X509PIN;
use SecSess::Cookie::URL;
use SecSess::URL::Cookie;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

