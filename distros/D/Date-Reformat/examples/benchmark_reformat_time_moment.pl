#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark;
use Date::Reformat;

use Time::Moment;

my $strptime = '%Y-%m-%d %H:%M:%S%Z';
my $date_string = '2015-01-14 21:07:31Z';

my $strptime2time_moment = Date::Reformat->new(
    'parser' => {
        'strptime' => $strptime,
    },
    'formatter' => {
        'coderef' => sub {
            my ($year, $month, $day, $hour, $minute, $second, $time_zone) = @_;
            Time::Moment->new(
                'year'      => $year,
                'month'     => $month,
                'day'       => $day,
                'hour'      => $hour,
                'minute'    => $minute,
                'second'    => $second,
                'offset'    => 0,
            );
        },
        'params' => [qw(year month day hour minute second time_zone)],
    },
);

my $tests = [
    {
        'label'      => 'Reformat to Time::Moment',
        'iterations' => 100000,
        'coderef'    => sub {
            my $test_output = $strptime2time_moment->reformat_date($date_string);
        },
    },
];

foreach my $test (@$tests) {
    Benchmark::timethis(
        $test->{'iterations'},
        $test->{'coderef'},
        $test->{'label'},
    );
}

