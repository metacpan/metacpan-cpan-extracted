# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Convert-Temperature.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;

BEGIN { use_ok('Convert::Temperature') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $c = new Convert::Temperature();
isa_ok($c, 'Convert::Temperature');

my $res = $c->from_fahr_to_cel('59');
is($res, 15, 'Temperature is ok');

my $res = $c->from_cel_to_fahr('15');
is($res, 59, 'Temperature is ok');

my $res = $c->from_fahr_to_kelvin('59');
is($res, 288.15, 'Temperature is ok');

my $res = $c->from_kelvin_to_fahr('215');
is($res, -72.67, 'Temperature is ok');

my $res = $c->from_fahr_to_rankine('59');
is($res, 518.67, 'Temperature is ok');
