#07-validate_numeric_values.t
#
#
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Validator::Item;

#Make a new (blank) Validator
my $Validator = Data::Validator::Item->new();

#Test validate on a list of defined numeric values
ok($Validator->values([-4,-3,-2,-1,0,1,2,3,4]), "Values(set)");

my %tests = (4=>1,-500 => 0,-50 => 0,-5 => 0,
		-4 => 1,-3 => 1,-2 => 1,-1 => 1,0 => 1,2 => 1,3 => 1,
		5 => 0, 50 => 0,500 => 0,	0.001 => 0,0.000001 => 0,
		4.0001=>0,4.00000000001=>0,3.000000001=>0,
		);

foreach my $key (keys(%tests)){
	my $value =$tests{$key};
	is($Validator->validate($key), $value,
		"Handles $key correctly as ".$Validator->validate($key).", should be $value");
}
