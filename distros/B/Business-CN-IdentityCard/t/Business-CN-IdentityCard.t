# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-CN-IdentityCard.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Business::CN::IdentityCard') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $idv = new Business::CN::IdentityCard;

is($idv->validate('11010519491231002X'), 1, 'test a certain ture id no.');
is($idv->validate('110105194912310021'), 0, 'test a faked id no.');
is($idv->err, 'POSTFIX', 'test the $idv->err');