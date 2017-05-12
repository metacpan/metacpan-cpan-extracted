#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_tinytext)) };

#########################

# valid tests
my @good = (
	'',
	'x' x 255,
);
foreach my $value (@good){
	ok(defined(is_tinytext($value)), "valid: $value");
}

# invalid tests
my @bad = (
	'x' x 256
);
foreach my $value (@bad){
	ok(!defined(is_tinytext($value)), "invalid: $value");
}