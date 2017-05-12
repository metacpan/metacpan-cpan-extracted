use strict;
use warnings;
use Test::More qw(no_plan);

use DateTimeX::ISO8601::Interval;

my $c = 'DateTimeX::ISO8601::Interval';
my $interval = $c->parse('P1D', abbreviate => 1);
is "$interval", 'P1D', 'duration-only';

$interval = $c->parse('2013-12-01/2013-12-04', abbreviate => 1);
is "$interval", '2013-12-01/04', 'start/end';
is $interval->abbreviate(0)->format, '2013-12-01/2013-12-04', 'abbreviate turned off';

is $interval->abbreviate->format, '2013-12-01/04', 'abbreviate turned on';

is $interval->abbreviate->format(abbreviate => 0), '2013-12-01/2013-12-04', 'abbreviate turned off (per invocation)';
is "$interval", '2013-12-01/04', 'per-invocation not sticky';
is $interval->abbreviate(0)->format(abbreviate => 1), '2013-12-01/04', 'abbreviate turned on (per invocation)';
is "$interval", '2013-12-01/2013-12-04', 'per-invocation not sticky';
