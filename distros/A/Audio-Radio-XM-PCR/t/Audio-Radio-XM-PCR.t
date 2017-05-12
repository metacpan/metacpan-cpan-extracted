# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Audio-Radio-XM-PCR.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Audio::Radio::XM::PCR') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $radio = new Audio::Radio::XM::PCR;
isa_ok( $radio, 'Audio::Radio::XM::PCR' );

#ok($radio->open, 'Opening Port');
#is($radio->port_state, 'Open', 'Checking Port Status');
#ok($radio->close, 'Closing Port');
#is($radio->port_state, 'Closed', 'Checking Port Status');
#ok($radio->connect, 'Connect');
