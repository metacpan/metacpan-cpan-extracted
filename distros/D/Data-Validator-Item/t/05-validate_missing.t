#05-validate_missing.t
#
#
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Validator::Item;

#Make a new (blank) Validator
my $Validator = Data::Validator::Item->new();

#TODO tests for verify section; lookup section

#Test the Validate function
# Return values 	1 	ok or error value

#Test validate on missing values
ok(!defined($Validator->values()));

ok($Validator->missing("9"), "missing(set) to 9");
is($Validator->missing(), "9","missing() is ".$Validator->missing());

ok(!defined($Validator->error()));

is($Validator->validate(9), 1, "Doesn't object to the missing value 9");
ok(defined($Validator->error()));

is($Validator->validate(-3), 1, "Doesn't object to -3");
ok(!defined($Validator->error()));

is($Validator->validate(-2), 1, "Doesn't object to -2");
ok(!defined($Validator->error()));

is($Validator->validate(0), 1, "Doesn't object to 0");
ok(!defined($Validator->error()));

is($Validator->validate(1), 1, "Doesn't object to 1");
ok(!defined($Validator->error()));

is($Validator->validate("X"), 1, "Doesn't object to X");
ok(!defined($Validator->error()));

is($Validator->validate(""), 1, "Doesn't object to the empty string");
ok(!defined($Validator->error()));

is($Validator->validate(''), 1, "Doesn't object to the other empty string");
ok(!defined($Validator->error()));
