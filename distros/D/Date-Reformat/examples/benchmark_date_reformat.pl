#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark;
use Date::Reformat;

my $strptime = '%Y-%m-%d %H:%M:%S%Z';
my $date_string = '2015-01-14 21:07:31Z';

my $strptime_parser = Date::Reformat->new(
    'parser' => {
        'strptime' => $strptime,
    },
    'formatter' => {
        'strftime' => $strptime,
    },
);

my $heuristic_parser = Date::Reformat->new(
    'parser' => {
        'heuristic' => 'ymd',
    },
    'formatter' => {
        'strftime' => $strptime,
    },
);

my $tests = [
    {
        'label'      => 'Initialize',
        'iterations' => 10000,
        'coderef'    => sub {
            my $test_parser = Date::Reformat->new(
                'parser' => {
                    'strptime' => $strptime,
                },
            );
        },
    },
    {
        'label'      => 'Parse strptime',
        'iterations' => 100000,
        'coderef'    => sub {
            my $test_output = $strptime_parser->parse_date($date_string);
        },
    },
    {
        'label'      => 'Parse heuristic',
        'iterations' => 100000,
        'coderef'    => sub {
            my $test_output = $heuristic_parser->parse_date($date_string);
        },
    },
    {
        'label'      => 'Reformat strptime',
        'iterations' => 100000,
        'coderef'    => sub {
            my $test_output = $strptime_parser->reformat_date($date_string);
        },
    },
    {
        'label'      => 'Reformat heuristic',
        'iterations' => 100000,
        'coderef'    => sub {
            my $test_output = $heuristic_parser->reformat_date($date_string);
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

