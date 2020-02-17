package main;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;
use My::Module::Test::App;
use Astro::Coord::ECI::Utils 0.112 qw{ greg_time_gm };

BEGIN {

    load_or_skip 'DateTime', 'all';
    load_or_skip 'DateTime::TimeZone', 'all';
    # Note that load_or_skip() does a default import as well as loading
    # the module.
    load_or_skip 'Time::Local', 'all';

    require Astro::App::Satpass2::FormatTime::DateTime::Strftime;
}

use constant DATE_TIME_FORMAT => '%Y/%m/%d %H:%M:%S';

klass 'Astro::App::Satpass2::FormatTime::DateTime::Strftime';

call_m 'new', INSTANTIATE, 'Instantiate';

call_m gmt => 1, TRUE, 'Turn on gmt';

call_m 'gmt', 1, 'Confirm gmt is on';

my $time = greg_time_gm( 50, 0, 0, 1, 3, 2011 );	# 1-Apr-2011 00:00:50

call_m format_datetime => DATE_TIME_FORMAT, $time,
    '2011/04/01 00:00:50', 'Implicit GMT time';

call_m format_datetime_width => DATE_TIME_FORMAT, 19,
    'Compute width required for format';

call_m gmt => 0, TRUE, 'Turn off gmt';

call_m format_datetime => DATE_TIME_FORMAT, $time, 1,
    '2011/04/01 00:00:50', 'Explicit GMT time';

call_m round_time => 60, TRUE, 'Round to nearest minute';

call_m format_datetime => DATE_TIME_FORMAT, $time, 1,
    '2011/04/01 00:01:00', 'Explicit GMT time, rounded to minute';

call_m format_datetime => '%{year_with_christian_era} %{calendar_name}',
    $time, 1, '2011AD Gregorian', 'Explicit GMT year, with calendar';

SKIP: {
    my $tests = 8;

    my $back_end = 'DateTime::Calendar::Christian';

    load_or_skip $back_end, $tests;

    call_m 'new', back_end => $back_end, gmt => 1, INSTANTIATE, 'Instantiate';

    my $dt = $back_end->new(
	year	=> -43,
	month	=> 3,
	day	=> 15,
	time_zone	=> 'UTC',
    );

    SKIP: {
	$dt->is_julian()
	    or skip "$back_end 44BC not Julian(?!)", 1;

	call_m format_datetime =>
	    '%{year_with_christian_era:06}-%m-%d %{calendar_name:t3}',
	    $dt->epoch(), '0044BC-03-15 Jul', 'Julian date, with era';
    }

    $dt = $back_end->new(
	year	=> 1700,
	month	=> 1,
	day	=> 1,
	time_zone	=> 'UTC',
    );

    call_m 'new', back_end => $back_end,
	gmt => 1, INSTANTIATE, 'Instantiate';

    call_m back_end => $back_end, 'Get back end';

    SKIP: {
	$dt->is_gregorian()
	    or skip 'DateTime::Calendar::Christian 1700 not Gregorian', 1;
	call_m format_datetime =>
	    '%Y-%m-%d %{calendar_name}',
	    $dt->epoch(), '1700-01-01 Gregorian', 'Gregorian date';
    }

    $dt = $back_end->new(
	year	=> 1700,
	month	=> 1,
	day	=> 1,
	time_zone	=> 'UTC',
	reform_date	=> 'uk',
    );

    call_m 'new', back_end => "$back_end,reform_date=uk",
	gmt => 1, INSTANTIATE, 'Instantiate';

    call_m back_end => "$back_end,reform_date=uk", 'Get back end';

    SKIP: {
	$dt->is_julian()
	    or skip 'DateTime::Calendar::Christian 1700 not Julian under UK reform', 1;
	call_m format_datetime =>
	    '%Y-%m-%d %{calendar_name}',
	    $dt->epoch(), '1700-01-01 Julian', 'UK reform Julian date';
    }
}

done_testing;

1;

# ex: set textwidth=72 :
