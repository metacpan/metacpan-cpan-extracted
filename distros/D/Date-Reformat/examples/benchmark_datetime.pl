#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark;
use DateTime::Format::Strptime;

my $strptime = '%Y-%m-%d %H:%M:%S%Z';
my $date_string = '2015-01-14 21:07:31Z';

my $strptime_parser = DateTime::Format::Strptime->new(
    'pattern' => $strptime,
);

my $tests = [
    {
        'label'      => 'Initialize',
        'iterations' => 10000,
        'coderef'    => sub {
            my $test_parser = DateTime::Format::Strptime->new(
                'pattern' => $strptime,
            );
        },
    },
    {
        'label'      => 'Parse strptime',
        'iterations' => 10000,
        'coderef'    => sub {
            my $test_output = $strptime_parser->parse_datetime($date_string);
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

