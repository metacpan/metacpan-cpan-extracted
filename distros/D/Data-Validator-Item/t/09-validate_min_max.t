#09-validate_min_max.t
#
#
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Validator::Item;

#Make a new (blank) Validator
my $Validator = Data::Validator::Item->new();

#Validate for numeric min and max
ok($Validator->min(-50), "min(set) to ".$Validator->min());
ok($Validator->max(50), "max(set) to ".$Validator->max());
is($Validator->validate(0), 1, "Accepts 0");
is($Validator->validate(-50.00001), 0, "Rejects -50.00001 - Too small");
is($Validator->validate(50.00001), 0, "Rejects 50.00001 - Too big");
