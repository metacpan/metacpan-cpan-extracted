#!perl

use 5.010001;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time);
BEGIN {
    set_fixed_time(1467244800); # 2016-06-30T00:00:00Z
}

use Test::DateTime::Format::Alami;
use Test::MockTime;
use Test::More 0.98;

test_datetime_format_alami(
    "ID",
    {
        time_zone => 'UTC',
        parse_datetime_tests => [
            ["foo", undef],

            # p_now
            ["saat inilah" , undef], # sanity
            ["saat ini" , "2016-06-30T00:00:00"],
            ["saat  ini", "2016-06-30T00:00:00"], # test multiple spaces
            ["Saat Ini" , "2016-06-30T00:00:00"], # test case
            ["sekarang" , "2016-06-30T00:00:00"],
            ["skrg"     , "2016-06-30T00:00:00"],

            # p_today
            ["hari ini", "2016-06-30T00:00:00"],

            # p_tomorrow
            ["besok", "2016-07-01T00:00:00"],
            ["esok" , "2016-07-01T00:00:00"],

            # p_yesterday
            ["kemarin", "2016-06-29T00:00:00"],
            ["kemaren", "2016-06-29T00:00:00"],
            ["kmrn"   , "2016-06-29T00:00:00"],

            # p_dateymd
            ["28martian" , undef], # sanity
            ["28feb"     , "2016-02-28T00:00:00"],
            ["28februari", "2016-02-28T00:00:00"],
            ["28 feb"    , "2016-02-28T00:00:00"],
            ["28-feb"    , "2016-02-28T00:00:00"],
            ["28/feb"    , "2016-02-28T00:00:00"],

            ["2/1"   , "2016-01-02T00:00:00"],
            ["28/2"  , "2016-02-28T00:00:00"],
            ["28/299", undef], # sanity

            ["8 mei 2011", "2011-05-08T00:00:00"],
            ["8-mei-2011", "2011-05-08T00:00:00"],
            ["8-05-2011" , "2011-05-08T00:00:00"],
            ["8-5-2011"  , "2011-05-08T00:00:00"],
            ["8-5-11"    , "2011-05-08T00:00:00"],
            ["8/5/11"    , "2011-05-08T00:00:00"],

            # p_dateym
            ["mei-2018" , "2018-05-01T00:00:00"],
            ["mei '18"  , "2018-05-01T00:00:00"],

            # p_dur_ago, p_dur_later
            ["1 hari lagi"     , "2016-07-01T00:00:00"],
            ["2 hari yang lalu", "2016-06-28T00:00:00"],

            # p_which_dow
            ["senin ini"         , "2016-06-27T00:00:00"],
            ["senin minggu ini"  , "2016-06-27T00:00:00"],
            ["sen mgg ini"       , "2016-06-27T00:00:00"], # test: abbrev

            ["senin lalu"        , "2016-06-20T00:00:00"],
            ["sen mgg lalu"      , "2016-06-20T00:00:00"],

            ["senin depan"       , "2016-07-04T00:00:00"],
            ["sen mg dpn"        , "2016-07-04T00:00:00"],

            # p_time
            ["11:00"   , "2016-06-30T11:00:00"],
            ["11:00:05", "2016-06-30T11:00:05"],
            ["23.00"   , "2016-06-30T23:00:00"],

            # p_date_time
            ["28 jun 11:00"       , "2016-06-28T11:00:00"],
            ["28 jun 11 11:00"    , "2011-06-28T11:00:00"],
            ["28 jun 2011 11.00"  , "2011-06-28T11:00:00"],
            ["28 jun, 11 23:00:05", "2011-06-28T23:00:05"],

        ],

        parse_datetime_duration_tests => [
            ["foo", undef],

            # pdur_dur
            ["2h 3j", "P2DT3H"],
            ["2 hari, 3 jam", "P2DT3H"],
        ],
    },
);

done_testing;
