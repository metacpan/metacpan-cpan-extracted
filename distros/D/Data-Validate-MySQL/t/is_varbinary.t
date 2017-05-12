#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_varbinary)) };

#########################

# valid tests
my @good = (
	['', 10],
	['x' x 65535, 65535]
);
foreach my $set (@good){
	ok(defined(is_varbinary($set->[0], $set->[1])), "valid: $set->[0], $set->[1]");
}

# invalid tests
my @bad = (
	['x' x 65535, 10]
);
foreach my $set (@bad){
	ok(!defined(is_varbinary($set->[0], $set->[1])), "invalid: $set->[0], $set->[1]");
}