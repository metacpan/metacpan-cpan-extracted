#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;

use App::Countdown;

{
    my $obj = App::Countdown->new({argv => [1]});

    # TEST
    is ($obj->_calc_delay('1'), 1, "_calc_delay(1) == 1");

    # TEST
    is ($obj->_calc_delay('60'), 60, "_calc_delay(60) == 60");

    # TEST
    is ($obj->_calc_delay('2m'), 120, "_calc_delay(2m) == 120 (2 minutes)");

    # TEST
    is ($obj->_calc_delay('1m'), 60, "_calc_delay(1m) == 60 (1 minute)");

    # TEST
    is ($obj->_calc_delay('1h'), 60*60, "_calc_delay(1h) == 60*60 (1 hour)");

    # TEST
    is ($obj->_calc_delay('5h'), 5*60*60, "_calc_delay(5h) == 5*60*60 (5 hours)");

    # TEST
    is ($obj->_calc_delay('1.5m'), 60+30, "_calc_delay(1.5m) == 60*1.5 (fractional minutes)");

    # TEST
    is ($obj->_calc_delay('1.5h'), 3600 + 1800, "_calc_delay(1.5h) == 3600*1.5 (fractional hours)");

    # TEST
    is ($obj->_calc_delay('0.5m'), 30, "_calc_delay(0.5m) == 30 (leading zero)");

    # TEST
    is ($obj->_calc_delay('90s'), 90, "_calc_delay(90s) == 90 (seconds)");

    # TEST
    is ($obj->_calc_delay('1m30s'), 60+30, "_calc_delay(1m30s) == 60+30 (seconds)");

    # TEST
    is ($obj->_calc_delay('200m5s'), 200*60+5, "_calc_delay(200m5s) == 200*60+5 (seconds)");

    # TEST
    is ($obj->_calc_delay('10m03s'), 10*60+3, "_calc_delay(10m03s) == 10*60+ 3 (seconds)");

    # TEST
    is ($obj->_calc_delay('1h30m20s'), ((1*60+30)*60+20), "_calc_delay(1h30m20s) == right number (seconds)");

    # TEST
    is ($obj->_calc_delay('1h04s'), (1*60*60+4), "_calc_delay(1h04s) == right number (seconds)");

    # TEST
    is ($obj->_calc_delay('1h4s'), (1*60*60+4), "_calc_delay(1h4s) == right number (seconds)");

    # TEST
    is ($obj->_calc_delay('1h50m'), ((1*60+50)*60), "_calc_delay(1h50m) == right number (seconds)");

    # TEST
    is ($obj->_calc_delay('1h05m'), ((1*60+5)*60), "_calc_delay(1h05m) (leading 0s in minutes) == right number (seconds)");
}

