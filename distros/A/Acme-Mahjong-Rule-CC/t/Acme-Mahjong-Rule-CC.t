# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Acme-Mahjong-Rule-CC.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 6;
use Acme::Mahjong::Rule::CC qw/:all/;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my @non = nondealer(200,100,50,20);
my @deal = dealer(200,100,50,20);
my @draw = draw(200,100,50,20);

ok( $non[3] == -390,'nondealer()');
ok( $non[0] == 800,'nondealer()');
ok( $deal[3] ==-510,'dealer()');
ok( $deal[0] == 1200, 'dealer()');
ok( $draw[3] == -470,'draw()');
ok( $draw[0] == 860,'draw()');
