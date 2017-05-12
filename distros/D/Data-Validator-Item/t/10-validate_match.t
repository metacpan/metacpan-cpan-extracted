#10-validate_match.t
#
#
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Validator::Item;

#Make a new (blank) Validator
my $Validator = Data::Validator::Item->new();

#Validate for numeric min and max
ok($Validator->match('r'), , "match(set) to ".$Validator->match());

print "\n \$Validator->match() is ".$Validator->match()."\n";

print "\n-->".'r' =~/$Validator->match()/."<--\n";

if ('r' =~/$Validator->match()/) {print "\nMatched\n";}
my $match = $Validator->match();
if ('r' =~/$match/) {print "\nMatched second time around\n";}

my %tests = (
	-50 		=> 0, #2
	-5		=> 0, #3
	'a' 		=> 0, #4
	a 		=> 0, #5
	"a" 		=> 0, #6
	'b' 		=> 0, #7
	'c' 		=> 0, #8
	'd' 		=> 0, #9
	'r' 		=> 1, #10
	'fghi' 	=> 0, #11
	'ght' 		=> 0, #12
	'345-4'	=> 0, #13
	'4X$' 	=> 0, #14
	'A' 		=> 0, #15
	A 		=> 0, #0
	"A"		=> 0, #17
	5 		=> 0, #18
	50 		=> 0, #19
	500 		=> 0, #20
	0.001 	=> 0, #21
	0.000001 	=> 0, #22
	'C' 		=> 0, #23
	'X' 		=> 0, #24
	'WETrWT' => 1, #25
	4.0001	=>0, #26
	4.000001	=>0, #27
		);

foreach my $key (keys(%tests)){
	my $value =$tests{$key};
	ok(($Validator->validate($key) ==$value), "Handles $key correctly");
}
