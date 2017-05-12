package main;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;
use My::Module::Test::App;
use Astro::Coord::ECI::Utils 0.077 qw{ time_gm };

BEGIN {

    load_or_skip 'DateTime', 'all';
    load_or_skip 'DateTime::TimeZone', 'all';
    # Note that load_or_skip() does a default import as well as loading
    # the module.
    load_or_skip 'Time::Local', 'all';

    require Astro::App::Satpass2::FormatTime::DateTime::Cldr;
}

use constant DATE_TIME_FORMAT => 'yyyy/MM/dd HH:mm:ss';

class 'Astro::App::Satpass2::FormatTime::DateTime::Cldr';

method 'new', INSTANTIATE, 'Instantiate';

method gmt => 1, TRUE, 'Turn on gmt attribute';

method 'gmt', 1, 'The gmt attribute is on';

my $time = time_gm( 50, 0, 0, 1, 3, 2011 );	# 1-Apr-2011 00:00:50

method format_datetime => DATE_TIME_FORMAT, $time,
    '2011/04/01 00:00:50', 'Implicit GMT time';

method format_datetime_width => DATE_TIME_FORMAT, 19,
    'Compute width required for format';

method gmt => 0, TRUE, 'Turn off gmt';

method format_datetime => DATE_TIME_FORMAT, $time, 1,
    '2011/04/01 00:00:50', 'Explicit GMT time';

method round_time => 60, TRUE, 'Round to nearest minute';

method format_datetime => DATE_TIME_FORMAT, $time, 1,
    '2011/04/01 00:01:00', 'Explicit GMT time, rounded to minute';

SKIP: {
    check_datetime_timezone_local
	or skip 'Cannot determine local time zone', 1;

    method format_datetime => q<'%{calendar_name}'>, 1,
	'Gregorian', 'Calendar name';
}

SKIP: {
    my $tests = 2;

    my $back_end = 'DateTime::Calendar::Christian';

    load_or_skip $back_end, $tests;

    method 'new', back_end => $back_end, gmt => 1, INSTANTIATE, 'Instantiate';

    SKIP: {

	my $dt = $back_end->new(
	    year	=> -43,
	    month	=> 3,
	    day		=> 15,
	    time_zone	=> 'UTC',
	);

	$dt->is_julian()
	    or skip 'DateTime::Calendar::Christian thinks date is not Julian', $tests;

	method format_datetime =>
	    q<'%{year_with_christian_era:06}'-MM-dd '%{calendar_name:t3}'>,
	    $dt->epoch(), '0044BC-03-15 Jul',
	    'Method and Julian calendar name';
    }

}

done_testing;

1;

# ex: set textwidth=72 :
