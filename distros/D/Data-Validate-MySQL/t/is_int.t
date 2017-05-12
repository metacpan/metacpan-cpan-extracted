#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_int)) };

#########################

# valid tests
my @good = (
	[0,0],
	[0,1],
	['-2147483648', 0],
	['2147483647', 0],
	['4294967295', 1],
);
foreach my $set (@good){
	ok(defined(is_int($set->[0], $set->[1])), "valid: $set->[0], $set->[1]");
}

# invalid tests
my @bad = (
	['', 0],
	['', 1],
	['abc', 0],
	['abc', 1],
	['-2147483649',0],
	['2147483648', 0],
	['4294967296', 1],
);
foreach my $set (@bad){
	ok(!defined(is_int($set->[0], $set->[1])), "invalid: $set->[0], $set->[1]");
}