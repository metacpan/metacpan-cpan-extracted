#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_bigint)) };

#########################

# valid tests
my @good = (
	[0,0],
	[0,1],
	['-9223372036854775808', 0],
	['9223372036854775807', 0],
	['18446744073709551615', 1],
);
foreach my $set (@good){
	ok(defined(is_bigint($set->[0], $set->[1])), "valid: $set->[0], $set->[1]");
}

# invalid tests
my @bad = (
	['', 0],
	['', 1],
	['abc', 0],
	['abc', 1],
	['-9223372036854775809',0],
	['9223372036854775808', 0],
	['18446744073709551616', 1],
);
foreach my $set (@bad){
	ok(!defined(is_bigint($set->[0], $set->[1])), "invalid: $set->[0], $set->[1]");
}