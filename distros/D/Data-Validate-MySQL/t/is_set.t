#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_set)) };

#########################

# valid tests
my @good = (
	[[], ['x','y','z']],
	[['x'], ['x','y','z']],
	[['X'], ['X','y','z']],
	[['X','y','z'], ['X','y','z']],
);
foreach my $set (@good){
		ok(defined(is_set($set->[0], @{$set->[1]})), "valid: " . join(",", @{$set->[0]}) . " - " . join(",", @{$set->[1]}));
}

# invalid tests
my @bad = (
	[['x'], ['y','z']],
	[['X'], ['x','y','z']],
	[['x','Y','z'], ['x','y','z']],
	[[split('', 'x' x 65)], ['a']],
);
foreach my $set (@bad){
	ok(!defined(is_set($set->[0], @{$set->[1]})), "invalid: " . join(",", @{$set->[0]}) . " - " . join(",", @{$set->[1]}));
}