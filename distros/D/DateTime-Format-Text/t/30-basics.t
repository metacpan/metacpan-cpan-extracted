#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 13;

BEGIN { use_ok('DateTime::Format::Text') }

my $parser = new_ok('DateTime::Format::Text');

# Test cases for valid dates
my @test_cases = (
	# Format: input text, expected day, expected month, expected year
	{ input => '01/01/2023', day => 1, month => 1, year => 2023 },
	{ input => '12th March 2022', day => 12, month => 3, year => 2022 },
	{ input => 'Sunday, 1 March 2015', day => 1, month => 3, year => 2015 },
	{ input => '31-12-1999', day => 31, month => 12, year => 1999 },
	{ input => 'July 4, 1776', day => 4, month => 7, year => 1776 },
	{ input => '1st February 2000', day => 1, month => 2, year => 2000 },
	{ input => '25 Dec 2021', day => 25, month => 12, year => 2021 },
	{ input => 'Christmas Day: 25 Dec 2021', day => 25, month => 12, year => 2021 },
	{ input => 'Boxing Day:26 Dec 2021', day => 26, month => 12, year => 2021 },
);

foreach my $case (@test_cases) {
	subtest "Parsing: $case->{input}" => sub {
		my $dt = $parser->parse($case->{input});
		isa_ok($dt, 'DateTime', 'Returned a DateTime object');
		is($dt->day, $case->{day}, 'Day matches');
		is($dt->month, $case->{month}, 'Month matches');
		is($dt->year, $case->{year}, 'Year matches');
	};
}

# Test for no date found
my @no_date = (
	'Not a date',
);

foreach my $input (@no_date) {
	subtest 'Parsing no date: ' . (defined $input ? $input : 'undef') => sub {
		my $dt;
		lives_ok { $dt = $parser->parse($input) } 'Parsing not date input should live';
		ok(!defined($dt));
	};
}

# Test for invalid inputs
my @invalid_inputs = (
	'32/01/2023',	# Invalid day
	'30 February 2020',	# Invalid date
	'',	# Empty string
	undef,	# Undefined input
);

# Edge cases
subtest 'Ambiguous date format' => sub {
	my $dt = $parser->parse('12/11/10');
	isa_ok($dt, 'DateTime', 'Returned a DateTime object');
	ok($dt->year >= 2000, 'Assumes 21st century for ambiguous years');
};
