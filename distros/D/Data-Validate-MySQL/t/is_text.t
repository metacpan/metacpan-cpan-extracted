#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_text)) };

#########################

# valid tests
my @good = (
	'',
	'x' x ((2**16) - 1),
);
foreach my $value (@good){
	ok(defined(is_text($value)), "valid: $value");
}

# invalid tests
my @bad = (
	'x' x 2**16
);
foreach my $value (@bad){
	ok(!defined(is_text($value)), "invalid: $value");
}