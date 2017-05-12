#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_mediumint)) };

#########################

# valid tests
my @good = (
	[0,0],
	[0,1],
	[-8388608, 0],
	[8388607, 0],
	[16777215, 1],
);
foreach my $set (@good){
	ok(defined(is_mediumint($set->[0], $set->[1])), "valid: $set->[0], $set->[1]");
}

# invalid tests
my @bad = (
	['', 0],
	['', 1],
	['abc', 0],
	['abc', 1],
	[-8388609,0],
	[8388608, 0],
	[16777216, 1],
);
foreach my $set (@bad){
	ok(!defined(is_mediumint($set->[0], $set->[1])), "invalid: $set->[0], $set->[1]");
}