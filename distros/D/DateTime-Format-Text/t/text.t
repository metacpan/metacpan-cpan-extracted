#!perl -wT

use strict;
use warnings;
use Test::Most tests => 63;
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
	cmp_deeply($dates[0], methods('day' => num(12), 'month' => num(9), 'year' => num(1856)), '->');
	cmp_deeply($dates[1], methods('day' => num(25), 'month' => num(1), 'year' => num(1922)), '->');

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
