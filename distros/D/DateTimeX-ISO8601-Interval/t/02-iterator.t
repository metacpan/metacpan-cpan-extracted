use strict;
use warnings;
use Test::More qw(no_plan);

use DateTimeX::ISO8601::Interval;

subtest single_interval => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('2013-04-15/17');
	my $iter = $interval->iterator;
	my $sub_interval = $iter->();
	is $sub_interval->start->ymd, "2013-04-15", "expected start date";
	my $second = $iter->();
	is $second, undef, 'no more dates';
};

subtest 'date precision' => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('2013-04-15/17');
	my $iter = $interval->iterator();
	my $range = $iter->();
	is $range->start->ymd, "2013-04-15", "expected start date";
	is $range->end->ymd, "2013-04-18", "expected end date is the following date";
	is $iter->(), undef, 'no more dates';
};

subtest 'repeat X times (daily)' => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('R10/2013-04-15/P1D');
	my $iter = $interval->iterator;
	my @dates = grep { defined } map { $iter->() } 1..15;
	is @dates, 10, 'ten dates returned';
	is_deeply [map { $_->start->day } @dates], [15..24], 'correct interval';
};
subtest 'repeat X times (monthly, end of month)' => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('R12/2013-01-31/P1M');
	my $iter = $interval->iterator;
	my @dates = grep { defined } map { $iter->() } 1..12;
	is @dates, 12, 'twelve dates returned';
	is_deeply [map { $_->start->ymd } @dates], [qw(2013-01-31 2013-02-28 2013-03-31 2013-04-30 2013-05-31 2013-06-30 2013-07-31 2013-08-31 2013-09-30 2013-10-31 2013-11-30 2013-12-31)], 'correct interval';
};

subtest 'repeat X times (monthly + 1 day)' => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('R12/2013-01-31/P1M1D');
	my $iter = $interval->iterator;
	my @dates = grep { defined } map { $iter->() } 1..12;
	is @dates, 12, 'twelve dates returned';
	is_deeply [ map { $_->start->ymd } @dates ],
	  [ qw(2013-01-31 2013-03-01 2013-04-02 2013-05-03 2013-06-04 2013-07-05 2013-08-06 2013-09-07 2013-10-08 2013-11-09 2013-12-10 2014-01-11)
	  ], 'correct interval';
};
subtest 'repeat N times (1 hour)' => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('R/2013-03-10/PT1H', time_zone => 'America/New_York');
	my $iter = $interval->iterator();
	my @intervals = grep { defined } map { $iter->() } 1..24;
	is @intervals, 24, '24 intervals returned';
	foreach my $interval(@intervals) {
		is $interval->duration->hours, 1, 'one hour range: ' . $interval;
	}
};

subtest 'repeat + skip (3 months)' => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('R/2013-12-31/P3M', time_zone => 'America/New_York');
	my $iter = $interval->iterator(skip => 4);
	my $next = $iter->();
	is "$next", "2014-12-31T00:00:00-0500/2015-03-31T00:00:00-0400", "skips ahead 4 * 3 months";
	$next = $iter->();
	is "$next", "2015-03-31T00:00:00-0400/2015-06-30T00:00:00-0400", "expected following interval";
};

subtest 'repeat X times + skip (1 week)' => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('R4/2013-12-31/P3W', time_zone => 'America/New_York');
	my $iter = $interval->iterator(skip => 4);
	is $iter->(), undef, 'past the end';
	is $iter->(), undef, 'still past the end';
};

subtest 'repeat X times + steps (12 days)' => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('R4/2013-01-01/P12D', time_zone => 'America/New_York');
	my $iter = $interval->iterator;
	is $iter->(2)->start->ymd, "2013-01-13", 'no steps';
	is $iter->(1)->start->ymd, "2013-01-25", 'one step';
	is $iter->(2), undef, 'no more left';
};

subtest 'after XYZ' => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('R/2013-01-01/P1D', time_zone => 'America/New_York');
	my $iter = $interval->iterator(after => DateTime->new(year => 2013, month => 1, day => 15, time_zone => 'America/New_York'));
	is $iter->()->start->ymd, '2013-01-15', 'expected next start date';
	is $iter->()->start->ymd, '2013-01-16', 'expected next start date';
};

subtest 'until date' => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('R/2013-01-01/P1D', time_zone => 'America/New_York');
	my $iter = $interval->iterator(
		after => DateTime->new(
			year      => 2013,
			month     => 1,
			day       => 30,
			time_zone => 'America/New_York'
		),
		until => DateTime->new(
			year      => 2013,
			month     => 2,
			day       => 2,
			hour      => 1,
			time_zone => 'America/New_York'
		)
	);
	my @dates = grep { defined } map {$iter->()} 1..5;
	is @dates, 3, 'expected number of dates';
	is $dates[0]->start->ymd, '2013-01-30', 'first date';
	is $dates[-1]->start->ymd, '2013-02-01', 'last date';
};

subtest 'no start/end' => sub {
	my $interval = DateTimeX::ISO8601::Interval->parse('R/PT1H');
	my $iter = $interval->iterator(
		after => DateTime->new( year => 2013, month => 12, day => 30, time_zone => 'America/New_York'),
		until => DateTime->new( year => 2013, month => 12, day => 31, time_zone => 'America/New_York'),
	);
	my @intervals = grep { defined } map { $iter->() } 1..30;
	is @intervals, 24, 'expected number of intervals';
	is $intervals[0]->format, '2013-12-30T00:00:00-0500/2013-12-30T01:00:00-0500', 'expected first interval';
	is $intervals[-1]->format, '2013-12-30T23:00:00-0500/2013-12-31T00:00:00-0500', 'expected last interval';
};
