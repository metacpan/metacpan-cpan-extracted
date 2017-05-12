#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 521;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_tinyint)) };

#########################

# valid tests
my @good = ();
for(0..255){
	push(@good, [$_, 1]);
}
for(0..128){
	push(@good, [$_ * -1, 0]);
}
for(1..127){
	push(@good, [$_, 0]);
}
foreach my $set (@good){
	ok(defined(is_tinyint($set->[0], $set->[1])), "valid: $set->[0], $set->[1]");
}

# invalid tests
my @bad = (
	['', 0],
	['', 1],
	[-255, 0],
	[-1, 1],
	[128, 0],
	[256, 1],
	['abc', 0],
	['abc', 1]
);
foreach my $set (@bad){
	ok(!defined(is_tinyint($set->[0], $set->[1])), "invalid: $set->[0], $set->[1]");
}