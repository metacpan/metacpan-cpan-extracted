# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-BR-CNJ.t'

#########################

use Test::More tests => 3;
BEGIN { use_ok('Business::BR::CNJ') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Very besic things we need working
ok(  Business::BR::CNJ::cnj_check_number("0058967-77.2016.8.19.0000"), 'check valid number' );
ok( !Business::BR::CNJ::cnj_check_number("0058967-77.2016.8.19.0001"), 'check wrong number' );
