# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-BR-CNJ.t'

#########################

use Test::More tests => 3;
BEGIN { use_ok('Business::BR::CNJ::NumberExtractor') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Very besic things we need working
use_ok( 'Business::BR::CNJ::NumberExtractor' );
ok( join('',Business::BR::CNJ::NumberExtractor::cnj_extract_numbers("This is a CNJ number:0058967-77.2016.8.19.0001, but this is not: 81723671623.")) eq '0058967-77.2016.8.19.0001', 'Extract one number' );
