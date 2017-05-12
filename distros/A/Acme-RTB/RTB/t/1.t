# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Acme::RTB') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;

my $rand;
$rand.=chr(rand(25)+65) for 1..10;
my $robot = Acme::RTB->new({    Name    => 'Anarion PerlBot 1.0',
                                Colour  => 'ff0000 ff0000',
                                Log     => "/tmp/$$-$rand.log"} );

ok( $robot );
ok( $robot->modify_action(  Radar           => \&my_radar    ) );
ok( $robot->RotateAmount(7, 0.5, 2) );

sub my_radar { }
unlink("/tmp/$$-$rand.log");
