#06-validate_alpha_values.t
#
#
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Validator::Item;

#Make a new (blank) Validator
my $Validator = Data::Validator::Item->new();

#Test validate on a list of defined alphanumeric values
ok($Validator->values(['a','b','c','d','e','fghi','ght','345-4','4X$']), "Values(set)");

my %tests = (
	-50 		=> 0, #2
	-5		=> 0, #3
	'a' 		=> 1, #4
	a 		=> 1, #5
	"a" 		=> 1, #6
	'b' 		=> 1, #7
	'c' 		=> 1, #8
	'd' 		=> 1, #9
	'e' 		=> 1, #10
	'fghi' 	=> 1, #11
	'ght' 		=> 1, #12
	'345-4'	=> 1, #13
	'4X$' 	=> 1, #14
	'A' 		=> 0, #15
	A 		=> 0, #32
	"A"		=> 0, #17
	5 		=> 0, #18
	50 		=> 0, #19
	500 		=> 0, #20
	0.001 	=> 0, #21
	0.000001 	=> 0, #22
	'C' 		=> 0, #23
	'X' 		=> 0, #24
	'WETRWT' => 0, #25
	4.0001	=>0, #26
	4.000001	=>0, #27
		);

foreach my $key (keys(%tests)){
	my $value =$tests{$key};
	ok(($Validator->validate($key) ==$value), "Handles $key correctly");
}
