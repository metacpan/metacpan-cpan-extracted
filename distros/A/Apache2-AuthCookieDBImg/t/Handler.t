# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PGHandler.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { 
        use_ok('Apache::DBI');
        use_ok('Apache2::AuthCookie');
        use_ok('Apache2::Const');
        use_ok('Date::Calc');
        use_ok('Digest::MD5');
      };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

