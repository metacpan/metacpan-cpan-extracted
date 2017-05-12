use strict;
use warnings;
use Test::More qw(no_plan);

use DateTimeX::ISO8601::Interval;

ok !eval { DateTimeX::ISO8601::Interval->parse }, 'fails';

chomp(my @tests = <DATA>);
foreach my $t(@tests) {
	next if $t =~ /^(#.*|$)/;
	my($in,$out,$todo) = split(/\t/, $t);
	my $parsed = DateTimeX::ISO8601::Interval->parse($in);
	if($todo && $todo =~ s/TODO //) {
		TODO: {
			local $TODO = $todo;
			is "$parsed", "$out", "parsing $in == $out";
		}
	} else {
		is "$parsed", "$out", "parsing $in == $out";
	}
}

my $interval = DateTimeX::ISO8601::Interval->parse('2013-04-15/2013-04-16', time_zone => 'America/New_York');
is $interval->start->time_zone->name, 'America/New_York', 'correct time_zone set';

$interval = DateTimeX::ISO8601::Interval->parse('2013-04-15/16', time_zone => 'America/New_York');
is $interval->duration->in_units('days'), 2, 'expected number of days';

$interval = DateTimeX::ISO8601::Interval->parse('2013-04-15/P1D', time_zone => 'America/New_York');
is $interval->duration->in_units('days'), 1, 'expected number of days';

my $success = eval { DateTimeX::ISO8601::Interval->parse('2013-12-01'); 1 };
ok !$success, 'failed on garbage input';
like $@, qr{Invalid interval: 2013-12-01}, 'expected error';

$success = eval { DateTimeX::ISO8601::Interval->parse('2013-01-01/P1D', time_zone => 'fake'); 1 };
ok !$success, 'failed on bogus time_zone';
like $@, qr{Invalid time_zone: fake}, 'expected error';

__DATA__
# Dates
2013--2014	2013-01-01/2014-12-31	TODO partial date (year)
2013-01/2013-12	2013-01-01/2014-01-01	TODO partial date (month)
2013-04-15/2014-01-01	2013-04-15/2014-01-01
2013-04-15/05-17	2013-04-15/2013-05-17
2013-01-01/6	2013-01-01/2013-01-06
2013-04-15/17	2013-04-15/2013-04-17

# date/times
2007-03-01T13:00:00Z/2008-05-11T15:30:00Z	2007-03-01T13:00:00Z/2008-05-11T15:30:00Z
2007-03-01T13:00:00-04:00/2008-05-11T15:30:00-05:00	2007-03-01T13:00:00-0400/2008-05-11T15:30:00-0500
2007-03-01T13:00:00.123-04:00/2008-05-11T15:30:00.234-05:00	2007-03-01T13:00:00.123-0400/2008-05-11T15:30:00.234-0500

# partial date/times
2007-03-01T13:00:00Z/14:10:30Z	2007-03-01T13:00:00Z/2007-03-01T14:10:30Z
2007-03-01T13:00:00Z/10:30Z	2007-03-01T13:00:00Z/2007-03-01T13:10:30Z
2007-03-01T13:00:00Z/30Z	2007-03-01T13:00:00Z/2007-03-01T13:00:30Z

# date/times + period
2007-03-01T13:00:00Z/P1Y2M10DT2H30M	2007-03-01T13:00:00Z/P1Y2M1W3DT2H30M
P1Y2M10DT2H30M/2008-05-11T15:30:00Z	P1Y2M1W3DT2H30M/2008-05-11T15:30:00Z
2012-02-29/P1Y	2012-02-29/P1Y

# period only
P1Y2M10DT2H30M	P1Y2M1W3DT2H30M
P1Y	P1Y

# repeating intervals
R/2007-03-01T13:00:00Z/P1Y2M10DT2H30M	R/2007-03-01T13:00:00Z/P1Y2M1W3DT2H30M
R10/2007-03-01T13:00:00Z/P1Y2M10DT2H30M	R10/2007-03-01T13:00:00Z/P1Y2M1W3DT2H30M
