#!perl

use strict;
use warnings;
use Test::More 0.98;

use Date::Format::ISO8601 qw(
     gmtime_to_iso8601_date
     gmtime_to_iso8601_time
     gmtime_to_iso8601_datetime

     localtime_to_iso8601_date
     localtime_to_iso8601_time
     localtime_to_iso8601_datetime
);

subtest "all" => sub {
    my $ts         = 1529780523;
    my $ts_frac    = 1529780523.456;

    subtest "gmtime_to_iso8601_date" => sub {
        is(gmtime_to_iso8601_date($ts), "2018-06-23");
        is(gmtime_to_iso8601_date({date_sep=>"/"}, $ts), "2018/06/23");
    };
    subtest "gmtime_to_iso8601_time" => sub {
        is(gmtime_to_iso8601_time($ts), "19:02:03Z");
        is(gmtime_to_iso8601_time({tz=>''}, $ts), "19:02:03");
        is(gmtime_to_iso8601_time({time_sep=>"_"}, $ts), "19_02_03Z");
        is(gmtime_to_iso8601_time({second_precision=>3}, $ts     ), "19:02:03.000Z");
        is(gmtime_to_iso8601_time({second_precision=>2}, $ts_frac), "19:02:03.46Z");
    };
    subtest "gmtime_to_iso8601_datetime" => sub {
        is(gmtime_to_iso8601_datetime($ts), "2018-06-23T19:02:03Z");
    };

    # TODO
    # subtest "localtime_to_iso8601_date" => sub {
    #     is(localtime_to_iso8601_date($ts), "2018-06-23");
    #     is(localtime_to_iso8601_date({date_sep=>"/"}, $ts), "2018/06/23");
    # };
    # subtest "localtime_to_iso8601_time" => sub {
    #     is(localtime_to_iso8601_time($ts), "19:02:03Z");
    #     is(localtime_to_iso8601_time({tz=>''}, $ts), "19:02:03");
    #     is(localtime_to_iso8601_time({time_sep=>"_"}, $ts), "19_02_03Z");
    #     is(localtime_to_iso8601_time({second_precision=>3}, $ts     ), "19:02:03.000Z");
    #     is(localtime_to_iso8601_time({second_precision=>2}, $ts_frac), "19:02:03.46Z");
    # };
    # subtest "localtime_to_iso8601_datetime" => sub {
    #     is(localtime_to_iso8601_datetime($ts), "2018-06-23T19:02:03Z");
    # };
};

DONE_TESTING:
done_testing;
