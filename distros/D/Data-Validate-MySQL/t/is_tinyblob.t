#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_tinyblob)) };

#########################

# valid tests
my @good = (
	'',
	'x' x 255,
);
foreach my $value (@good){
	ok(defined(is_tinyblob($value)), "valid: $value");
}

# invalid tests
my @bad = (
	'x' x 256
);
foreach my $value (@bad){
	ok(!defined(is_tinyblob($value)), "invalid: $value");
}