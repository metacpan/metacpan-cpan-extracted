#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use DateTime;
use DateTime::SpanSet;


# Check that SpanSets return spans with the correct endpoints during daylight
# savings changeovers given a weekly recurrence.

BEGIN {
    if (eval 'use DateTime::Event::Recurrence; 1') {
        plan tests => 552;
    }
    else {
        plan skip_all => 'DateTime::Event::Recurrence required for this test.';
    }
}


test_span_set_on_day(4, 'Thursday', 27,  3);
test_span_set_on_day(5, 'Friday',   28,  3);
test_span_set_on_day(6, 'Saturday', 29,  3);

test_span_set_on_day(6, 'Saturday',  4, 10);
test_span_set_on_day(7, 'Sunday',    5, 10);
test_span_set_on_day(1, 'Monday',    6, 10);


sub test_span_set_on_day {
    my ($day_index, $day_name, $day_of_month, $month) = @_;

    my $span_set =
        DateTime::SpanSet
            ->from_sets(
                start_set   =>
                    DateTime::Event::Recurrence->weekly(
                        days => $day_index, hours => 8, minutes => 30,
                    ),
                end_set     =>
                    DateTime::Event::Recurrence->weekly(
                        days => $day_index, hours => 15, minutes => 30,
                    ),
            )
            ->set_time_zone('Asia/Jerusalem');


    my $expected_date  = new_as_of_time($month, $day_of_month, 0);


    my $expected_start =
        $expected_date->clone()->add(days => -7)->set_hour(8)->set_minute(30);
    my $expected_end   =
        $expected_date->clone()->add(days => -7)->set_hour(15)->set_minute(30);
    # Skip 2am due to daylight savings change.
    foreach my $hour (0..1, 3..8) {
        my $as_of_time = new_as_of_time($month, $day_of_month, $hour);
        my $span       = $span_set->current($as_of_time)->span();

        test_span_end_point(
            'start', $span->start(), $expected_start, $as_of_time,
        );
        test_span_end_point(
            'end', $span->end(), $expected_end, $as_of_time,
        );
    }


    $expected_start = $expected_date->clone()->set_hour(8)->set_minute(30);
    $expected_end   = $expected_date->clone()->set_hour(15)->set_minute(30);
    foreach my $hour (9..23) {
        my $as_of_time = new_as_of_time($month, $day_of_month, $hour);
        my $span       = $span_set->current($as_of_time)->span();

        test_span_end_point(
            'start', $span->start(), $expected_start, $as_of_time,
        );
        test_span_end_point(
            'end',   $span->end(),   $expected_end,   $as_of_time,
        );
    }

    return;
}


sub new_as_of_time {
    my ($month, $day_of_month, $hour) = @_;

    return
        DateTime->new(
            year        => 2008,
            month       => $month,
            day         => $day_of_month,
            hour        => $hour,
            time_zone => 'Asia/Jerusalem'
        );
}


sub test_span_end_point {
    my ($end_point_name, $end_point, $expected_time, $test_input_time) = @_;

    my $expected_ymd      = $expected_time->ymd();
    my $expected_hms      = $expected_time->hms();
    my $test_input_string =
        $test_input_time->ymd() . q< > . $test_input_time->hms();

    is(
        $end_point->ymd(),
        $expected_ymd,
        "Date for $end_point_name of span at $test_input_string.",
    );
    is(
        $end_point->hms(),
        $expected_hms,
        "Time of day for $end_point_name of span at $test_input_string.",
    );

    return;
}
