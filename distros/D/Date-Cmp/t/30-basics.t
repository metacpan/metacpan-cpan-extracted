#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

BEGIN { use_ok('Date::Cmp', qw(datecmp)) };

# A helper to trap errors without crashing the test
my $trap_errors = sub {
	my $code = shift;

	my $error;
	{
		local $@;
		eval { $code->(); 1 } or $error = $@;
	}
	return $error;
};

# Basic year comparisons
is(datecmp('1900', '1900'), 0, 'Same year');
cmp_ok(datecmp('1899', '1900'), '<', 0, 'Earlier year');
cmp_ok(datecmp('1901', '1900'), '>', 0, 'Later year');

# Approximate years
is(datecmp('Abt. 1900', '1900'), 0, 'Approximate year equals exact');
is(datecmp('ca 1900', '1900'), 0, 'ca format handled');
is(datecmp('1900 ?', '1900'), 0, 'Uncertain year matches');

# Before/after qualifiers
cmp_ok(datecmp('bef 1900', '1905'), '<', 0, 'Before qualifier works');
cmp_ok(datecmp('aft 1900', '1899'), '>', 0, 'After qualifier works');

# Ranges
is(datecmp('1902-1902', '1902'), 0, 'Range with same start/end equals year');
cmp_ok(datecmp('BET 1900 AND 1902', '1901'), '==', 0, 'RHS is within range');
cmp_ok(datecmp('BET 1900 AND 1902', '1903'), '<', 0, 'Outside range, high');
cmp_ok(datecmp('BET 1900 AND 1902', '1899'), '>', 0, 'Outside range, low');
cmp_ok(datecmp(1901, 'BET 1900 AND 1902'), '==', 0, 'LHS is within range');
cmp_ok(datecmp(1903, 'BET 1900 AND 1902'), '>', 0, 'Outside range, high');
cmp_ok(datecmp(1899, 'BET 1900 AND 1902'), '<', 0, 'Outside range, low');

# Month ranges
is(datecmp('Oct/Nov/Dec 1950', '1950'), 0, 'Month range treated as year');

# ISO and slash formats
is(datecmp('1941-08-02', '1941'), 0, 'ISO date vs year');
throws_ok( sub { datecmp('5/27/1872', '1872') }, qr/Date parse failure/, 'US-style date vs year');

# Objects with ->date method
{
	package FakeDateObj;
	sub new { my ($class, $date) = @_; bless { date => $date }, $class }
	sub date { $_[0]->{date} }
}

my $obj1 = FakeDateObj->new('1900');
my $obj2 = FakeDateObj->new('1901');
cmp_ok(datecmp($obj1, $obj2), '<', 0, 'Object comparison');

# Unknown/malformed date inputs
my $error = $trap_errors->(sub { datecmp('bad date', '1900') });
like($error, qr/Date parse failure/, 'Dies on malformed left date');

$error = $trap_errors->(sub { datecmp('1900', '??') });
like($error, qr/Date parse failure/, 'Dies on malformed right date');

# Edge cases
is(datecmp('1802 or 1802', '1802'), 0, 'Ambiguous same year');
cmp_ok(datecmp('1802 or 1803', '1803'), '<=', 0, 'Handles "or" with second match');

# Callbacks
my $warn;
datecmp('1802 or 1802', '1802', sub { $warn = shift });
is($warn, q{the years are the same '1802 or 1802'}, 'Complaint triggered');

# Null values (should not happen normally)
is(datecmp(undef, '1900'), 0, 'undef left handled');
is(datecmp('1900', undef), 0, 'undef right handled');
is(datecmp(undef, undef), 0, 'both undef handled');

done_testing();
