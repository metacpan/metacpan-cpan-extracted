#!/usr/bin/perl

#######
# Test::MockTime is a bit sensitive with regards to it's loading order.
# If you 'use' it after Test::More it might fail to run under Test::Aggregate
# So we run this sanity check at the very end of our test suit, to make sure
# that it's working.
# If it's not, then there is a high likelyhood of other tests being broken
# for not being able to mock time back and forth.
#######

use strict;
use warnings;

use Test::MockTime;
use Test::More qw( no_plan );

use Date::Utility;

subtest 'testing Test::MockTime' => sub {
    my $past = Date::Utility->new('2011-02-28T18:30:15Z');
    my $now  = Date::Utility->new;
    ok($now->days_between($past) > 0, "First sanity check, past is in the past :)");

    Test::MockTime::set_absolute_time('2009-04-27T17:00:00Z');
    my $mocked_time = Date::Utility->new;
    is($mocked_time->datetime_iso8601, '2009-04-27T17:00:00Z', "moving time to the past");

    Test::MockTime::set_absolute_time('2015-04-27T17:00:00Z');
    is(Date::Utility->new->datetime_iso8601, '2015-04-27T17:00:00Z', "moving time to the future");
};

