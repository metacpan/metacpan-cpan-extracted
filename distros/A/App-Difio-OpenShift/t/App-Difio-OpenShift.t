# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl App-Difio-OpenShift.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More skip_all => "Tests fail when run on OpenShift";
BEGIN { use_ok('App::Difio::OpenShift') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
