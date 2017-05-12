#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_enum)) };

#########################

# valid tests
my @good = (
	['x', ['x','y','z']],
	['X', ['X','y','z']],
);
foreach my $set (@good){
	ok(defined(is_enum($set->[0], @{$set->[1]})), "invalid: $set->[0] " . join(",", @{$set->[1]}));
}

# invalid tests
my @bad = (
	['', ['x','y','z']],
	['x', ['y','z']],
	['X', ['x','y','z']],
);
foreach my $set (@bad){
	ok(!defined(is_enum($set->[0], @{$set->[1]})), "invalid: $set->[0] " . join(",", @{$set->[1]}));
}