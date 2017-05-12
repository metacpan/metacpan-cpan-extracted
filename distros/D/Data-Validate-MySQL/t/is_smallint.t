#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_smallint)) };

#########################

# valid tests
my @good = (
	[0,0],
	[0,1],
	[-32768, 0],
	[32767, 0],
	[65535, 1],
);
foreach my $set (@good){
	ok(defined(is_smallint($set->[0], $set->[1])), "valid: $set->[0], $set->[1]");
}

# invalid tests
my @bad = (
	['', 0],
	['', 1],
	['abc', 0],
	['abc', 1],
	[-32769,0],
	[32768, 0],
	[65536, 1],
);
foreach my $set (@bad){
	ok(!defined(is_smallint($set->[0], $set->[1])), "invalid: $set->[0], $set->[1]");
}