use strict;
use warnings;
use Data::Password::Filter;
use Test::More;

my $password = Data::Password::Filter->new();

# Need at least one passing  call _checkDictionary() first or _checkVariation()
# skips its checking
ok(!$password->_checkDictionary('appliance'),   "'Fail: seed _checkDictionary()");
ok( $password->_checkDictionary('aB4Ds4Xfj'),   "'Pass: seed _checkDictionary()");

ok(!$password->_checkVariation('appliance'),    "Fail: Straight dictionary word");
ok(!$password->_checkVariation('Xppliance'),    "Fail: Change one char (first)");
ok(!$password->_checkVariation('applXance'),    "Fail: Change one char (mid)");
ok(!$password->_checkVariation('appliancX'),    "Fail: Change one char (final)");
ok( $password->_checkVariation('applXXnce'),    "Pass: Change two chars (mid)");
ok( $password->_checkVariation('XppliancX'),    "Pass: Change two chars (first & final)");
ok( $password->_checkVariation('applXancX'),    "Pass: Change two chars (mid & final)");

done_testing();