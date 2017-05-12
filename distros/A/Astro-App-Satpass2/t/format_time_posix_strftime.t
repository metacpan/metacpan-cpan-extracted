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

use Astro::Coord::ECI::Utils 0.077 qw{ time_gm };

class 'Astro::App::Satpass2::FormatTime::POSIX::Strftime';

method 'new', INSTANTIATE, 'Instantiate';

method gmt => 1, TRUE, 'Turn on gmt';

method 'gmt', 1, 'Confirm gmt is on';

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

done_testing;

1;

# ex: set textwidth=72 :
