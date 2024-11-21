#!perl -wT

use strict;
use warnings;
use Class::Simple;
use Test::Most tests => 99;
use Test::Deep;
use Test::NoWarnings;

BEGIN {
	use_ok('DateTime::Format::Text');
}

TEXT: {
	my $dft = new_ok('DateTime::Format::Text');

	cmp_deeply($dft->parse('Today is 10/1/19'), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)));
	cmp_deeply(DateTime::Format::Text::parse('Today is 10/1/19'), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '::');
	cmp_deeply(DateTime::Format::Text::parse(string => 'Today is 10/1/19'), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '::');
	cmp_deeply(DateTime::Format::Text::parse({ string => 'Today is 10/1/19' }), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '::');
	cmp_deeply(DateTime::Format::Text->parse('Today is 10/1/19'), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '->');
	cmp_deeply(DateTime::Format::Text->parse(string => 'Today is 10/1/19'), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '->');
	cmp_deeply(DateTime::Format::Text->parse({ string => 'Today is 10/1/19' }), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '->');
	cmp_deeply($dft->parse({ string => '9/1/19 was yesterday' }), methods('day' => num(9), 'month' => num(1), 'year' => num(2019)));
	cmp_deeply($dft->parse_datetime(string => '9/1/19 was yesterday'), methods('day' => num(9), 'month' => num(1), 'year' => num(2019)));
	cmp_deeply($dft->parse_datetime(string => 'yesterday was January the 9th in the year 2019'), methods('day' => num(9), 'month' => num(1), 'year' => num(2019)));

	cmp_deeply($dft->parse_datetime('Today is 10/1/19'), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)));

	my $text = new_ok('Class::Simple');
	$text->as_string('Today is 10/1/19');
	cmp_deeply($dft->parse(string => $text), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)));

	# Sic - Sunnday
	cmp_deeply($dft->parse('Sunnday 29 Sep 1939'), methods('day' => num(29), 'month' => num(9), 'year' => num(1939)));

	cmp_deeply(DateTime::Format::Text::parse_datetime('Today is 10/1/19'), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '::');
	cmp_deeply(DateTime::Format::Text::parse_datetime(string => 'Today is 10/1/19'), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '::');
	cmp_deeply(DateTime::Format::Text::parse_datetime({ string => 'Today is 10/1/19' }), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '::');
	cmp_deeply(DateTime::Format::Text->parse_datetime('Today is 10/1/19'), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '->');
	cmp_deeply(DateTime::Format::Text->parse_datetime(string => 'Today is 10/1/19'), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '->');
	cmp_deeply(DateTime::Format::Text->parse_datetime({ string => 'Today is 10/1/19' }), methods('day' => num(10), 'month' => num(1), 'year' => num(2019)), '->');
	# cmp_deeply(DateTime::Format::Text->parse_datetime("Ernest Newton  (12 September 1856 \x{2013} 25 January 1922) was an English architect and President of Royal Institute of British Architects."), methods('day' => num(12), 'month' => num(9), 'year' => num(1856)), '->');
	my @dates = DateTime::Format::Text->parse_datetime("Ernest Newton  (12 September 1856 \x{2013} 25 January 1922) was an English architect and President of Royal Institute of British Architects.");
	cmp_ok(scalar(@dates), '==', 2, 'Matches exactly two dates');
	cmp_deeply($dates[0], methods('day' => num(12), 'month' => num(9), 'year' => num(1856)), '->');
	cmp_deeply($dates[1], methods('day' => num(25), 'month' => num(1), 'year' => num(1922)), '->');

	# Mix of international and US format
	@dates = DateTime::Format::Text->parse_datetime("Francis Eric Irving Bloy (17 December 1904 - 23 May 1993) served as the third Episcopal Bishop of Los Angeles from April 21, 1948 until December 31, 1973.");
	cmp_ok(scalar(@dates), '==', 4, 'Matches exactly four dates');

	cmp_deeply($dates[0], methods('day' => num(17), 'month' => num(12), 'year' => num(1904)), '->');
	cmp_deeply($dates[1], methods('day' => num(23), 'month' => num(5), 'year' => num(1993)), '->');
	cmp_deeply($dates[2], methods('day' => num(21), 'month' => num(4), 'year' => num(1948)), '->');
	cmp_deeply($dates[3], methods('day' => num(31), 'month' => num(12), 'year' => num(1973)), '->');

	# Test that this doesn't match 70-18/19 as a date
	@dates = DateTime::Format::Text->parse_datetime('Albert Johan Petersson (6 February 1870-18/19 August 1914) was a Swedish chemist, engineer and industrialist. He is most known as the developer of the Alby-furnace for producing of Calcium carbide and as the first director of the carbide and cyanamide factories in Odda in Norway. He was born in Landskrona, Sweden and probably died during a boat trip between Odda and Bergen.');
	cmp_deeply($dates[0], methods('day' => num(6), 'month' => num(2), 'year' => num(1870)), '->');
	cmp_deeply($dates[1], methods('day' => num(19), 'month' => num(8), 'year' => num(1914)), '->');

	$text = new_ok('Class::Simple');
	$text->as_string('25/12/2022');
	cmp_deeply($dft->parse($text), methods('day' => num(25), 'month' => num(12), 'year' => num(2022)));

	for my $test (
		'Sunday, 1 March 2015',
		'Sunday 1st March 2015',
		'Sunday, 1 March 2015',
		'Sun 1 Mar 2015',
		'Sun-1-March-2015',
		'March 1st 2015',
		'March 1 2015',
		# 'March-1st-2015',
		'1 March 2015',
	) {
		cmp_deeply(DateTime::Format::Text::parse($test), methods('day' => num(1), 'month' => num(3), 'year' => num(2015)), $test);
		cmp_deeply(DateTime::Format::Text::parse_datetime($test), methods('day' => num(1), 'month' => num(3), 'year' => num(2015)), $test);
		cmp_deeply($dft->parse($test), methods('day' => num(1), 'month' => num(3), 'year' => num(2015)), $test);
		my $s = "foo $test bar";
		cmp_deeply($dft->parse_datetime($s), methods('day' => num(1), 'month' => num(3), 'year' => num(2015)), $s);
		$s = "foo $test";
		cmp_deeply($dft->parse_datetime($s), methods('day' => num(1), 'month' => num(3), 'year' => num(2015)), $s);
		$s = "$test bar";
		cmp_deeply($dft->parse_datetime($s), methods('day' => num(1), 'month' => num(3), 'year' => num(2015)), $s);
		cmp_deeply($dft->parse_datetime($test), methods('day' => num(1), 'month' => num(3), 'year' => num(2015)), $test);
	};
}

# Final set of test cases

# Instantiate the module
my $parser = DateTime::Format::Text->new();

my @test_cases = (
	{
		input  => 'Today is 25th December 2024',
		output => DateTime->new(day => 25, month => 12, year => 2024),
	}, {
		input  => 'Event on 1 Jan 2023',
		output => DateTime->new(day => 1, month => 1, year => 2023),
	}, {
		input  => 'Meeting scheduled for 12/05/2022',
		output => DateTime->new(day => 12, month => 5, year => 2022),
	}, {
		input  => '29th February 2020 was in a leap year',
		output => DateTime->new(day => 29, month => 2, year => 2020),
	}, {
		input  => 'leap year test: 29th February 2020',
		output => DateTime->new(day => 29, month => 2, year => 2020),
	}, {
		input  => '29th February 2020',
		output => DateTime->new(day => 29, month => 2, year => 2020),
	}, {
		input  => 'December 2023',
		output => DateTime->new(day => 1, month => 12, year => 2023),
	}
);

# Run tests
foreach my $test (@test_cases) {
	my $parsed_date = $parser->parse($test->{input});
	is_deeply($parsed_date, $test->{output}, "Parsed: $test->{input}");
}

ok(!defined($parser->parse('abc')));
