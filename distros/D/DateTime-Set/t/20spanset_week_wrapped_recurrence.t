#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use DateTime;
use DateTime::SpanSet;


# Check that SpanSets return Spans with the correct endpoints given
# the same week recurrence as its starting and ending sets.

BEGIN {
    if (eval 'use DateTime::Event::Recurrence; 1') {
        plan tests => 60;
    }
    else {
        plan skip_all => 'DateTime::Event::Recurrence required for this test.';
    }
}


my $recurrence =
    DateTime::Event::Recurrence->weekly(
        days => 1, hours => 8, minutes => 30,
    );

my $base_span_set =
    DateTime::SpanSet
        ->from_sets(start_set => $recurrence, end_set => $recurrence);

my $test_time_zone = 'Australia/Adelaide';

test_end_points(
    $base_span_set,
    'no time zone changes',
    undef,
);
test_end_points(
    $base_span_set
        ->clone()
        ->set_time_zone($test_time_zone),
    'time zone specified',
    $test_time_zone,
);
test_end_points(
    $base_span_set
        ->clone()
        ->set_time_zone('floating')
        ->set_time_zone($test_time_zone),
    'intermediary floating time zone',
    $test_time_zone,
);

sub test_end_points {
    my ($span_set, $name, $time_zone) = @_;

    foreach my $hour (6..7) {
        test_end_points_for_hour($span_set, $name, $time_zone, $hour, 8);
    }
    foreach my $hour (8..10) {
        test_end_points_for_hour($span_set, $name, $time_zone, $hour, 15);
    }

    return;
}


sub test_end_points_for_hour {
    my ($span_set, $name, $time_zone, $hour, $expected_start_day_of_month) = @_;

    my $current_time   = new_test_time(15, $hour, $time_zone);
    my $expected_start =
        new_test_time($expected_start_day_of_month,      8,    $time_zone);
    my $expected_end   =
        new_test_time($expected_start_day_of_month + 7,  8,    $time_zone);

    my $span = $span_set->current($current_time)->span();

    test_span_end_point(
        'start', $name, $span->start(), $expected_start, $current_time,
    );
    test_span_end_point(
        'end',   $name, $span->end(),   $expected_end,   $current_time,
    );

    return;
}


sub new_test_time {
    my ($day_of_month, $hour, $time_zone) = @_;

    my %constructor_arguments = (
        year    => 2008,
        month   => 12,
        day     => $day_of_month,
        hour    => $hour,
        minute  => 30,
    );

    if ($time_zone) {
        $constructor_arguments{time_zone} = $time_zone;
    }

    return DateTime->new(%constructor_arguments);
}


sub test_span_end_point {
    my ($end_point_name, $spanset_name, $end_point, $expected_time, $test_input_time) = @_;

    my $expected_ymd      = $expected_time->ymd();
    my $expected_hms      = $expected_time->hms();
    my $test_input_string =
        $test_input_time->ymd() . q< > . $test_input_time->hms();

    is(
        $end_point->ymd(),
        $expected_ymd,
        "Date for $end_point_name of SpanSet with $spanset_name at $test_input_string.",
    );
    is(
        $end_point->hms(),
        $expected_hms,
        "Time of day for $end_point_name of SpanSet with $spanset_name at $test_input_string.",
    );

    return;
}
