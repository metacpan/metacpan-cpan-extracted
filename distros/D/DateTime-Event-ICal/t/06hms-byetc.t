#!/usr/bin/env perl
use strict;
use warnings;

use DateTime;
use DateTime::Event::ICal;
use DateTime::Span;
use Test::More;

my $dt20140101 = DateTime->new(
    year => 2014, month => 1, day => 1, hour => 0, minute => 0, second => 0,
);

my $dt20140101a4 = DateTime->new(
    year => 2014, month => 1, day => 2, hour => 4, minute => 0, second => 0,
);

my $dt20140101a9 = $dt20140101->clone->set( hour => 9 );

my @test_cases = (
    {
        name       => 'Every 15 minutes of the 4th hour of the 1th of January',
        start      => $dt20140101,
        recurrence => {
            freq => 'minutely',
            interval => 15,
            byhour => [ 4 ],
            bymonth => [ 1 ],
            bymonthday => [ 2 ],
        },
        expect     => [ 
            map { $dt20140101a4->clone->set( minute => $_ ) }
            map { $_ * 15 } 0 .. 3
        ],
    },
    {
        name       => 'Every 30 minutes in January from 9:00 to 10:00',
        start      => $dt20140101a9,
        recurrence => {
            freq => 'minutely',
            interval => 30,
            bymonth => [ 1 ],
            byday => [ qw( su mo tu we th fr sa ) ],
            byhour => [ 9 ],
        },
        expect     => [
            map { (
                $_->clone->set( minute => 0 ),
                $_->clone->set( minute => 30 ),
            ) }
            map { $dt20140101a9->clone->set( day => $_ ) } 1 .. 4
        ],
    },
    {
        name       => 'Every 8 hours on January 10th through 12th',
        start      => $dt20140101,
        recurrence => {
            freq => 'hourly',
            interval => 8,
            bymonth => [ 1 ],
            bymonthday => [ 2, 3, 4 ],
        },
        expect     => [ 
            map { (
                $_->clone->set( hour => 0 ),
                $_->clone->set( hour => 8 ),
                $_->clone->set( hour => 16 ),
            ) } map { $dt20140101->clone->set( day => $_ ) } 2, 3, 4
        ],
    },
);

my $test_count = 0;
$test_count += @{ $_->{expect} } for @test_cases;

plan tests => $test_count;

my $span = DateTime::Span->new(
    start => DateTime->new(
        year => 2014, month => 1, day => 1, hour => 0, minute => 0, second => 0,
    ),
    end => DateTime->new(
        year => 2014, month => 1, day => 4, hour => 23, minute => 59, second => 59,
    ),
);

for my $case (@test_cases) {
    my $set = DateTime::Event::ICal->recur(
        dtstart    => $case->{start},
        %{ $case->{recurrence} },
    );

    my @all_expected = @{ $case->{expect} };
    my $iter = $set->iterator( span => $span );
    while (my $got = $iter->next) {
        my $expected = shift @all_expected;
        is($got, $expected, "$case->{name}: $expected matches");
    }
    fail("$case->{name}: $_ matches") for @all_expected;
}

