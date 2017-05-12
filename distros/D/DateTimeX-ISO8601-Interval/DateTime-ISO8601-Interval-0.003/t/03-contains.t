use strict;
use warnings;
use Test::More qw(no_plan);

use DateTimeX::ISO8601::Interval;
use DateTime::Format::ISO8601;

ok !eval { DateTimeX::ISO8601::Interval->parse }, 'fails';

my $parser = DateTime::Format::ISO8601->new;
chomp(my @tests = <DATA>);
foreach my $t(@tests) {
	next if $t =~ /^(#.*|$)/;
	my($interval,$criteria,$date) = split(/\t/, $t);
	my $parsed = DateTimeX::ISO8601::Interval->parse($interval);
	if($criteria eq 'contains') {
		ok $parsed->contains($parser->parse_datetime($date)), "$parsed $criteria $date";
	} else {
		ok !$parsed->contains($parser->parse_datetime($date)), "$parsed $criteria $date";
	}
}

my $interval = DateTimeX::ISO8601::Interval->parse('P7D');
my $success = eval { $interval->contains('2013-01-01'); 1 };
ok !$success, 'contains fails if no start/end';
like $@, qr{Unable to determine}, 'expected error';

$interval->start('2013-01-01');
ok $interval->contains('2013-01-01'), 'contains works with start date';

delete $interval->{start};
$interval->end('2013-01-10');
ok $interval->contains('2013-01-04'), 'contains works with end date';

__DATA__
# date precision
2013-01-01/10	contains	2013-01-01
2013-01-01/10	contains	2013-01-10
2013-01-01/10	does not contain	2013-01-11
2013-01-01/10	does not contain	2012-12-31
2013-01-01/10	contains	2013-01-10T23:59:59

# date/time precision
2013-01-01T00:00:00/01:00	contains	2013-01-01T00:00:00
2013-01-01T00:00:00/01:00	contains	2013-01-01T00:00:59.999

# with a time zone
2013-01-01T00:00:00Z/01:00Z	contains	2012-12-31T20:00:30-04:00
