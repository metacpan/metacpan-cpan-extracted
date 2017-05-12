#!perl

use 5.010001;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time);
BEGIN {
    set_fixed_time(1467244800); # 2016-06-30T00:00:00Z
}

use Test::DateTime::Format::Alami;
use Test::More 0.98;

test_datetime_format_alami(
    "EN",
    {
        time_zone => 'UTC',
        parse_datetime_tests => [
            ["foo", undef],

            # p_now
            ["nowadays"   , undef], # sanity
            ["now"        , "2016-06-30T00:00:00"],
            ["right   now", "2016-06-30T00:00:00"], # test multiple spaces
            ["right now"  , "2016-06-30T00:00:00"],
            ["just now"   , "2016-06-30T00:00:00"],
            ["JUST NOW"   , "2016-06-30T00:00:00"], # test case
            ["immediately", "2016-06-30T00:00:00"],

            # p_today
            ["today"   , "2016-06-30T00:00:00"],
            ["this day", "2016-06-30T00:00:00"],

            # p_tomorrow
            ["tomorrow", "2016-07-01T00:00:00"],
            ["tom"     , "2016-07-01T00:00:00"],

            # p_yesterday
            ["yesterday", "2016-06-29T00:00:00"],
            ["yest"     , "2016-06-29T00:00:00"],

            # p_dateymd
            ["28febby"   , undef], # sanity
            ["28feb"     , "2016-02-28T00:00:00"],
            ["28february", "2016-02-28T00:00:00"],
            ["28 feb"    , "2016-02-28T00:00:00"],
            ["28th feb"  , "2016-02-28T00:00:00"],
            ["feb 28"    , "2016-02-28T00:00:00"],
            ["feb 28th"  , "2016-02-28T00:00:00"],

            ["2/1"       , "2016-02-01T00:00:00"],
            ["2/28"      , "2016-02-28T00:00:00"],
            ["28/299"    , undef], # sanity

            ["8 may 2011" , "2011-05-08T00:00:00"],
            ["8 may, 2011", "2011-05-08T00:00:00"],
            ["5-8-2011"   , "2011-05-08T00:00:00"],
            ["5-8-11"     , "2011-05-08T00:00:00"],
            ["5/8/11"     , "2011-05-08T00:00:00"],

            # p_dateym
            ["may-2018" , "2018-05-01T00:00:00"],
            ["may '18"  , "2018-05-01T00:00:00"],

            # p_dur_ago, p_dur_later
            ["1 day later"     , "2016-07-01T00:00:00"],
            ["in 2 mins 3 secs", "2016-06-30T00:02:03"],
            ["2 day ago"       , "2016-06-28T00:00:00"], # test: plural but no -s

            # p_which_dow
            ["this monday", "2016-06-27T00:00:00"],
            ["last monday", "2016-06-20T00:00:00"],
            ["next mon"   , "2016-07-04T00:00:00"], # test: abbrev

            # p_time
            ["11:00"      , "2016-06-30T11:00:00"],
            ["11:00:05 am", "2016-06-30T11:00:05"],
            ["11.00pm"    , "2016-06-30T23:00:00"],

            # p_date_time
            ["jun 28 11:00"      , "2016-06-28T11:00:00"],
            ["jun 28 11 11:00"   , "2011-06-28T11:00:00"],
            ["jun 28 2011 11:00" , "2011-06-28T11:00:00"],
            ["jun 28, 11 11:00pm", "2011-06-28T23:00:00"],

        ],

        parse_datetime_duration_tests => [
            ["foo", undef],

            # pdur_dur
            ["2h 3min", "PT2H3M"],
            ["2 hours, 3 minute", "PT2H3M"],
        ],
    },
);

done_testing;
