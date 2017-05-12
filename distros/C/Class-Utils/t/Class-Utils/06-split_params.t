# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(split_params);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my ($ret1_ar, $ret2_ar) = split_params([], 'key', 'value');
is_deeply(
	$ret1_ar,
	[],
	'Object parameters 1.',
);
is_deeply(
	$ret2_ar,
	['key', 'value'],
	'Other parameters 1.',
);

# Test.
($ret1_ar, $ret2_ar) = split_params(
	['foo'],
	'key', 'value',
	'foo', 'bar',
);
is_deeply(
	$ret1_ar,
	['foo', 'bar'],
	'Object parameters 2.',
);
is_deeply(
	$ret2_ar,
	['key', 'value'],
	'Other parameters 2.',
);
