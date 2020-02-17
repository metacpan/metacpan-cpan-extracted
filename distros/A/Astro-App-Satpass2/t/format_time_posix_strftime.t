package main;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;
use My::Module::Test::App;

BEGIN {

    load_or_skip qw{ POSIX all -import strftime };
    load_or_skip qw{ Time::Local all };

    require Astro::App::Satpass2::FormatTime::POSIX::Strftime;
}

use constant DATE_TIME_FORMAT => '%Y/%m/%d %H:%M:%S';

use Astro::Coord::ECI::Utils 0.112 qw{ greg_time_gm };

klass 'Astro::App::Satpass2::FormatTime::POSIX::Strftime';

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

done_testing;

1;

# ex: set textwidth=72 :
