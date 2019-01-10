#!perl -wT

use strict;
use warnings;
use Test::Most tests => 27;
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

	for my $test (
		'Sunday, 1 March 2015',
		'Sunday 1st March 2015',
		'Sunday, 1 March 2015',
		'Sun 1 Mar 2015',
		'Sun-1-March-2015',
		'March 1st 2015',
		'March 1 2015',
		'March-1st-2015',
	) {
		cmp_deeply($dft->parse($test), methods('day' => num(1), 'month' => num(3), 'year' => num(2015)), $test);
		my $s = "foo $test bar";
		cmp_deeply($dft->parse($s), methods('day' => num(1), 'month' => num(3), 'year' => num(2015)), $s);
	};
}
