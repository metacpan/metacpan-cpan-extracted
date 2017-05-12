#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 140;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_bit)) };

#########################

# valid integer tests
my @good = (
	[0,1,0],
	[1,1,0],
	[4294967295,32,0]
);

foreach my $set (@good){
	ok(defined(is_bit($set->[0], $set->[1], $set->[2])), "valid integer test: $set->[0], $set->[1], $set->[2]");
}

# should-fail integer tests
my @bad = (
	[-1,1,0],
	[9999999999,32,0]
);

foreach my $set (@bad){
	ok(!defined(is_bit($set->[0], $set->[1], $set->[2])), "invalid integer test: $set->[0], $set->[1], $set->[2]");
}

# should-fail non-integer tests
@bad = (
	['abc',1,0],
	['abc',32,0],
	['',32,0],
);

foreach my $set (@bad){
	ok(!defined(is_bit($set->[0], $set->[1], $set->[2])), "invalid text test: $set->[0], $set->[1], $set->[2]");
}

# valid bit tests
@good = ();
for(1..64){
	my $string = '1' x $_;
	push(@good, [$string, $_, 1]);
	$string = '0' x $_;
	push(@good, [$string, $_, 1]);
}

foreach my $set (@good){
	ok(defined(is_bit($set->[0], $set->[1], $set->[2])), "valid bit test: $set->[0], $set->[1], $set->[2]");
}

# bad bit tests
@bad = (
	['11',1,1],
	['',1,1],
	['234',32,1],
);

foreach my $set (@bad){
	ok(!defined(is_bit($set->[0], $set->[1], $set->[2])), "invalid bit test: $set->[0], $set->[1], $set->[2]");
}
