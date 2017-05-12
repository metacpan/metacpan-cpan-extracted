#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_year)) };

#########################

# valid tests
my @good = (
	'1901',
	'2155',
	'00',
	'69',
	'70',
	'1'
);
foreach my $d (@good){
		#warn "$d = " . is_time($d);
		ok(defined(is_year($d)), "valid: $d");
}

# invalid tests
my @bad = (
	'',
	'abc',
	'1900',
	'2156'
);
foreach my $d (@bad){
		ok(!defined(is_year($d)), "invalid: $d");
}