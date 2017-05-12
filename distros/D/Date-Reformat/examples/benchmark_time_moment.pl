#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark;
use Time::Moment;

my $strptime = '%Y-%m-%d %H:%M:%S%Z';
my $date_string = '2015-01-14 21:07:31Z';

my $tests = [
    {
        'label'      => 'Parse string',
        'iterations' => 1000000,
        'coderef'    => sub {
            my $test_output = Time::Moment->from_string($date_string, 'lenient' => 1);
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

