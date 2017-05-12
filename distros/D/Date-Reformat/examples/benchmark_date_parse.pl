#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark;
use Date::Parse;

my $strptime = '%Y-%m-%d %H:%M:%S%Z';
my $date_string = '2015-01-14 21:07:31Z';

my $tests = [
    {
        'label'      => 'Parse string',
        'iterations' => 100000,
        'coderef'    => sub {
            my $test_output = Date::Parse::str2time($date_string);
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

