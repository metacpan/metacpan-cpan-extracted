#11-put.t
#
#
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Validator::Item;

#Make a new (blank) Validator
my $Validator = Data::Validator::Item->new();

#Test the put function

my $sex_coderef = sub{
	my $datum = shift;
	my %transform = (
		1 => 'M',
		2 => 'F',
		3 => 'U',
		);
return $transform{$datum}
};




my $coderef  =   sub {
	my $datum  = shift;
	my $result = $datum - 50;
	return $result;
};

ok($Validator->transform($coderef), "transform (set)");
ok ($Validator->missing('MISS'), "missing (set)");

is($Validator->put(-50), -100,"Put - Transform works for -50");
is($Validator->put(0),     -50,"Put - Transform works for 0");
is($Validator->put(50),      0,"Put - Transform works for 50");
ok(!defined($Validator->put('MISS')),"Put - missing works for Missing");

ok($Validator->transform($sex_coderef),"Transform set to $sex_coderef");
ok($Validator->transform() eq $sex_coderef,"Transform is really set to test() - ".$sex_coderef." is ".$Validator->transform()."\n");

is($Validator->put(1), 'M');
is($Validator->put(2), 'F');
is($Validator->put(3), 'U');
isnt($Validator->put(4),'U');
ok(!defined($Validator->put(4)));
