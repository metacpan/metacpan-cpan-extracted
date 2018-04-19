# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-BR-CNJ.t'

#########################

use Test::More tests => 2;
BEGIN { use_ok('Business::BR::CNJ::Format') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Very besic things we need working
ok(  Business::BR::CNJ::Format::cnj_format("00589677720168190000") eq '0058967-77.2016.8.19.0000', 'check format OK' );
