# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-Session-ID-SHA.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;

BEGIN {
    use_ok('CGI::Session::ID::sha');
    use_ok('CGI::Session::ID::sha256');
    use_ok('CGI::Session::ID::sha512');
};

require_ok('CGI::Session::ID::sha');
require_ok('CGI::Session::ID::sha256');
require_ok('CGI::Session::ID::sha512');


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

