use strict;
use warnings;

use Date::Cmp qw(datecmp);
use Test::More;
use Test::Returns;

my @cases = (
	# Exact years
	['1914', '1918', -1],
	['1918', '1918',  0],
	['1919', '1918',  1],

	# Approximate years
	['Abt. 1900', '1900', 0],
	['ca. 1899', 'Abt. 1900', -1],
	['1901 ?', '1901', 0],

	# Ranges
	['BET 1830 AND 1832', '1831', 0],
	['BET 1830 AND 1832', '1829', 1],
	['BET 1830 AND 1832', '1833', -1],
	['BET 1830 AND 1832', '1830', 0],
	['BET 1830 AND 1832', '1832', 0],
	['1831', 'BET 1830 AND 1832', 0],

	# Simple range
	['1802-1803', '1802', 0],
	['1802-1803', '1804', -1],

	# Month range
	['Oct/Nov/Dec 1950', '1951', -1],
	['Oct/Nov/Dec 1950', '1950', 0],

	# Before/After
	['BEF 1965', '1969', -1],
	['AFT 1965', '1969', -1],  # not fully handled, expect tolerance

	# Mixed format
	# ['5/27/1872', '1872', 0],
	['26 Aug 1744', '1673-02-22T00:00:00', 1],
);

plan tests => scalar(@cases) * 4;

for my $case (@cases) {
	my ($left, $right, $expected) = @{$case};
	my $complaints = '';
	my $actual = datecmp($left, $right, sub { $complaints .= "@_\n" });

	returns_is($actual, { 'type' => 'integer', 'min' => -1, 'max' => 1 });

	is($actual, $expected, "'$left' <=> '$right' => $expected" . ($complaints ? " [warned: $complaints]" : ''));

	# Invert the test
	$complaints = '';
	$actual = datecmp($right, $left, sub { $complaints .= "@_\n" });

	returns_is($actual, { 'type' => 'integer', 'min' => -1, 'max' => 1 });

	if($expected == -1) {
		$expected = 1;
	} elsif($expected == 1) {
		$expected = -1;
	}

	is($actual, $expected, "'$left' <=> '$right' => $expected" . ($complaints ? " [warned: $complaints]" : ''));
}

done_testing();
