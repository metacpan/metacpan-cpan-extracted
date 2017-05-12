#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_decimal)) };

#########################

# valid tests
my @good = (
	[0,'','',0],
	['9' x 65,'','',0],
	['9' x 35 . '.' . '9' x 30,'','',0],
	[9999.9999,8,4,0],
);
foreach my $set (@good){
	ok(defined(is_decimal($set->[0], $set->[1], $set->[2], $set->[3])), "valid: $set->[0], $set->[1], $set->[2], $set->[3]");
}

# invalid tests
my @bad = (
	['', '','',0],
	['9' x 66,'','',0],
	['9' x 36 . '.' . '9' x 30,'','',0],
	['9' x 35 . '.' . '9' x 31,'','',0],
	[9999.9999,7,4,0],
);
foreach my $set (@bad){
	ok(!defined(is_decimal($set->[0], $set->[1], $set->[2], $set->[3])), "invalid: $set->[0], $set->[1], $set->[2], $set->[3]");
}