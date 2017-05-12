#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 16;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_time)) };

#########################

# valid tests
my @good = (
	'0 00:00:00.0',
	'34 22:00:00.0',
	'0 00:00:00',
	'34 22:00:00',
	'22:00:10',
	'22:00',
	'22',
	'122438',
	'122438.0',
	'2438',
);
foreach my $d (@good){
		#warn "$d = " . is_time($d);
		ok(defined(is_time($d)), "valid: $d");
}

# invalid tests
my @bad = (
	'',
	'abc',
	'8005',
	'35 00:00:00.0',
	'0 839:00:00.0',
);
foreach my $d (@bad){
		ok(!defined(is_time($d)), "invalid: $d");
}