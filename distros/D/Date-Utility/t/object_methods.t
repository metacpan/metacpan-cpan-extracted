use strict;
use warnings;

use Test::Exception;
use Test::More tests => 14;
use Test::NoWarnings;
use Date::Utility;

subtest 'days_between' => sub {
    my $baseline = 1278382486;
    my $base_date = Date::Utility->new({epoch => $baseline});
    # Two days, 3 hours, 8 minutes and 14 seconds later.
    my $later_date = Date::Utility->new({epoch => $baseline + (86400 * 2) + (3600 * 3) + (60 * 8) + 14});
    # 6 days, 1 hour,  12 minutes and 22 seconds earlier.
    my $earlier_date =
        Date::Utility->new({epoch => $baseline - (86400 * 6) + (3600 * 1) + (60 * 12) + 22});

    is($base_date->days_between($base_date),     0,  'base to base days_between');
    is($base_date->days_between($earlier_date),  6,  'base to earlier days_between');
    is($base_date->days_between($later_date),    -2, 'base to later days_between');
    is($earlier_date->days_between($base_date),  -6, 'earlier to base days_between');
    is($earlier_date->days_between($later_date), -8, 'earlier to later days_between');
    is($later_date->days_between($base_date),    2,  'later to base days_between');
    is($later_date->days_between($earlier_date), 8,  'later to later days_between');
};

my $jul08 = Date::Utility->new('1-Jul-08');
my $jan08 = Date::Utility->new('15-Jan-08');
my $dec00 = Date::Utility->new('25-Dec-00');
my $jan00 = Date::Utility->new('6-Jan-00');
my $oct99 = Date::Utility->new('31-Oct-99');

subtest 'months_ahead' => sub {
# months_ahead can take both positive and negative numbers...
# And returns a crazy string.
    is($jul08->months_ahead(0),   'Jul-08', 'Jul-08: Same month check');
    is($jul08->months_ahead(-1),  'Jun-08', 'Jul-08: Recent month check');
    is($jan08->months_ahead(-1),  'Dec-07', 'Jan-08: Wrap to previous year check');
    is($dec00->months_ahead(-1),  'Nov-00', 'Dec-00: Check that Dec works as it iss the last month in the year');
    is($jan00->months_ahead(-1),  'Dec-99', 'Jan-00: Wrap to previous century');
    is($oct99->months_ahead(-1),  'Sep-99', 'Oct-99: Ordinary date in previous century');
    is($jul08->months_ahead(-2),  'May-08', 'Jul-08: 2 months back');
    is($jul08->months_ahead(-12), 'Jul-07', 'Jul-08: 12 months back');
    is($jan08->months_ahead(-13), 'Dec-06', 'Jan-08: 13 months back, which means spanning 2 years');
    is($dec00->months_ahead(-12), 'Dec-99', 'Dec-00: 12 months back, which means spanning 1 century');
    is($oct99->months_ahead(-24), 'Oct-97', 'Oct-99: 2 years back');
    is($oct99->months_ahead(1),   'Nov-99', 'Oct-99: Ordinary date in previous century');
    is($jul08->months_ahead(2),   'Sep-08', 'Jul-08: 2 months forward');
    is($jul08->months_ahead(12),  'Jul-09', 'Jul-08: 12 months forward');
    is($jan08->months_ahead(13),  'Feb-09', 'Jan-08: 13 months forward');
    is($dec00->months_ahead(12),  'Dec-01', 'Dec-00: 12 months forward');
    is($oct99->months_ahead(24),  'Oct-01', 'Oct-99: 2 years forward');
};

subtest 'is_before' => sub {
    is($jul08->is_before($jul08), undef, '1-Jul-08 is not before 1-Jul-08');
    is($jul08->is_before($jan08), undef, '1-Jul-08 is not before 15-Jan-08');
    is($jan00->is_before($dec00), 1,     '15-Jan-00 is before 25-Dec-00');
    is($jan00->is_before($oct99), undef, '15-Jan-00 is not before 31-Oct-99');
    is($oct99->is_before($jan08), 1,     '31-Oct-99 is before 15-Jan-08');
};

subtest 'is_after' => sub {
    is($jul08->is_after($jul08), undef, '1-Jul-08 is not after 1-Jul-08');
    is($jul08->is_after($jan08), 1,     '1-Jul-08 is after 15-Jan-08');
    is($jan00->is_after($dec00), undef, '15-Jan-00 is not after 25-Dec-00');
    is($jan00->is_after($oct99), 1,     '15-Jan-00 is after 31-Oct-99');
    is($oct99->is_after($jan08), undef, '31-Oct-99 is not after 15-Jan-08');
};

subtest 'is_same_as' => sub {
    is($jul08->is_same_as($jul08), 1,     '1-Jul-08 is same_as 1-Jul-08');
    is($jul08->is_same_as($jan08), undef, '1-Jul-08 is not same_as 15-Jan-08');
    is($jan00->is_same_as($dec00), undef, '15-Jan-00 is not same_as 25-Dec-00');
    is($jan00->is_same_as($oct99), undef, '15-Jan-00 is not same_as 31-Oct-99');
    is($oct99->is_same_as($jan08), undef, '31-Oct-99 is not same_as 15-Jan-08');
};

my $datetime1 = Date::Utility->new('2011-12-13 07:03:01');
my $datetime2 = Date::Utility->new('2011-12-13 19:30:10');
my $datetime3 = Date::Utility->new('2011-12-14 19:30:10');

subtest 'truncate_to_day' => sub {
    is($datetime1->truncate_to_day->datetime_iso8601, "2011-12-13T00:00:00Z", "Truncates time correctly");
    is($datetime1->truncate_to_day->is_same_as($datetime2->truncate_to_day), 1,     "is_same_as for truncated objects on the same day");
    is($datetime2->truncate_to_day->is_same_as($datetime3->truncate_to_day), undef, "is_same_as for truncated objects on the different days");
};

my $datetime4 = Date::Utility->new('2011-12-13 07:59:59');
my $datetime5 = Date::Utility->new('2011-12-14 07:03:01');

subtest 'truncate_to_hour' => sub {
    is($datetime1->truncate_to_hour->datetime_iso8601, "2011-12-13T07:00:00Z", "Truncates time correctly");
    is($datetime1->truncate_to_hour->is_same_as($datetime4->truncate_to_hour), 1,     "is_same_as for truncated objects on the same day");
    is($datetime2->truncate_to_hour->is_same_as($datetime4->truncate_to_hour), undef, "is_same_as for truncated objects on the different days");
};

subtest 'plus_time_interval' => sub {
    is($datetime2->plus_time_interval('1d')->is_same_as($datetime3),  1,          'plus_time_interval("1d") yields one day ahead.');
    is($datetime1->plus_time_interval(0),                             $datetime1, 'plus_time_interval(0) yields the same object');
    is($datetime3->plus_time_interval('-1d')->is_same_as($datetime2), 1,          'plus_time_interval("-1d") yields one day back.');
};

subtest 'minus_time_interval' => sub {
    is($datetime3->minus_time_interval('1d')->is_same_as($datetime2),  1,          'minus_time_interval("1d") yields one day back.');
    is($datetime1->minus_time_interval(0),                             $datetime1, 'minus_time_interval(0) yields the same object');
    is($datetime2->minus_time_interval('-1d')->is_same_as($datetime3), 1,          'minus_time_interval("-1d") yields one day ahead.');
    throws_ok { $datetime3->minus_time_interval("one") } qr/Bad format/, 'minus_time_interval("one") is not a mind-reader..';
};

subtest 'plus years & minus years' => sub {
    throws_ok { $datetime1->plus_time_interval("12.3y") } qr/Need a integer/, 'need integer';
    my @test_cases = (['2000-01-01', 1, '2001-01-01'], ['2000-01-1', 2, '2002-01-01'], ['2000-02-29', 1, '2001-02-28']);
    for my $t (@test_cases) {
        is(Date::Utility->new($t->[0])->plus_time_interval("$t->[1]y")->date_yyyymmdd, $t->[2], "date $t->[0] plus $t->[1] years should be $t->[2]");
    }

};

subtest 'plus months & minus months' => sub {
    throws_ok { $datetime1->plus_time_interval("12.3mo") } qr/Need a integer/, 'need integer';
    my @test_cases = (
        ['2000-01-01', 1,  '2000-02-01'],
        ['2000-01-01', 2,  '2000-03-01'],
        ['2000-01-01', 12, '2001-01-01'],
        ['2000-01-29', 1,  '2000-02-29'],
        ['2000-01-30', 1,  '2000-02-29'],
        ['2000-01-31', 1,  '2000-02-29'],
        ['2000-01-31', 3,  '2000-04-30'],
        ['2000-05-31', 13, '2001-06-30'],
    );
    for my $t (@test_cases) {
        is(Date::Utility->new($t->[0])->plus_time_interval("$t->[1]mo")->date_yyyymmdd, $t->[2],
            "date $t->[0] plus $t->[1] months should be $t->[2]");
    }
    @test_cases = (
        ['2000-02-01', 1,  '2000-01-01'],
        ['2000-03-01', 2,  '2000-01-01'],
        ['2001-01-01', 12, '2000-01-01'],
        ['2000-02-29', 1,  '2000-01-29'],
        ['2000-3-30',  1,  '2000-02-29'],
        ['2000-03-31', 1,  '2000-02-29'],
        ['2000-07-31', 3,  '2000-04-30'],
        ['2001-07-31', 13, '2000-06-30'],
        ['2001-01-01', 13, '1999-12-01'],
    );
    for my $t (@test_cases) {
        is(Date::Utility->new($t->[0])->minus_time_interval("$t->[1]mo")->date_yyyymmdd,
            $t->[2], "date $t->[0] minus $t->[1] months should be $t->[2]");
    }
};

subtest 'move_to_nth_dow' => sub {
    is($datetime1->move_to_nth_dow(3,   'Wed')->day_of_month,      21,    'Third Wednesday of Dec 2011 is the 21st');
    is($datetime1->move_to_nth_dow(5,   'SuNdaY'),                 undef, '... and there is no 5th Sunday that year.');
    is($datetime1->move_to_nth_dow(-50, 'Mon'),                    undef, '... nor a -50th Monday.');
    is($datetime1->move_to_nth_dow(105, 'Tue'),                    undef, '... nor a 105th Tuesday.');
    is($datetime1->move_to_nth_dow(5,   'Saturday')->day_of_month, 31,    '... but there is a 5th Saturday.');
    is($datetime1->move_to_nth_dow(1,   5)->day_of_month,          2,     '... and a first Friday.');
    is($datetime1->move_to_nth_dow(1,   'THU')->day_of_month,      1,     '... and a first Thursday.');
    throws_ok { $datetime1->move_to_nth_dow(1, 'abc') } qr/Invalid day/, 'Failing for invalid day of week names';
    throws_ok { $datetime1->move_to_nth_dow(1, 7) } qr/Invalid day/,     'Does not handle Sunday as day 7';
    subtest 'stress test' => sub {
        my $today = Date::Utility->today;
        my $d     = Date::Utility->new($today->year . '-' . $today->month . '-01 12:00');
        my @dow;
        my $M = '';
        for (0 .. 4e2 - 1) {
            unless ($M eq $d->year . $d->month) {
                $M   = $d->year . $d->month;
                @dow = ();
            }
            $dow[$d->day_of_week]++;
            foreach my $base (1 .. 20) {
                my $base_date = Date::Utility->new(join '-', $d->year, $d->month, $base);
                is +Date::Utility->new(join '-', $d->year, $d->month, $base)->move_to_nth_dow($dow[$d->day_of_week], $d->day_of_week)->date, $d->date,
                      'Move from '
                    . $base_date->date . ' to '
                    . $dow[$d->day_of_week] . ' '
                    . $d->full_day_name . ' of '
                    . $d->month_as_string . ' '
                    . $d->year . ' is '
                    . $d->date;
            }
            $d = $d->plus_time_interval('1d');
        }
    };
};

subtest truncate_to_month => sub {
    my $d = Date::Utility->new('2001-03-02');
    is($d->truncate_to_month->datetime_yyyymmdd_hhmmss, '2001-03-01 00:00:00');
};

1;
