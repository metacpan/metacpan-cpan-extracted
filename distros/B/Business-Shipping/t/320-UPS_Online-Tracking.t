#!/bin/env perl

# UPS_Online Tracking - some basic tests.

use strict;
use warnings;
use Test::More;
use Carp;
use Business::Shipping;

plan skip_all => 'Required modules not installed'
    unless Business::Shipping::Config::calc_req_mod('UPS_Online');
plan skip_all => 'No credentials'
    unless $ENV{UPS_USER_ID}
        and $ENV{UPS_PASSWORD}
        and $ENV{UPS_ACCESS_KEY};

#plan skip_all => 'SLOW_TESTS is not set, skipping.' unless $ENV{SLOW_TESTS};
plan 'no_plan';

#Business::Shipping->log_level('DEBUG');

use_ok('Business::Shipping::UPS_Online::Tracking');
use Scalar::Util qw(blessed);
my $tracker = Business::Shipping::UPS_Online::Tracking->new();
is( blessed($tracker),
    'Business::Shipping::UPS_Online::Tracking',
    'Get new Tracking object'
);

$tracker->init(
    test_mode  => 1,
    user_id    => $ENV{UPS_USER_ID},
    password   => $ENV{UPS_PASSWORD},
    access_key => $ENV{UPS_ACCESS_KEY},
);

$tracker->tracking_ids('1Z12345E0291980793');

$tracker->submit() || logdie $tracker->user_error();
my $hash = $tracker->results();

#use Data::Dumper;
#print Dumper($hash);
#print Dumper($hash->{'1Z12345E0291980793'}{activity}[0]);

is(ref($hash),                         'HASH', 'Got results hash.');
is(ref($hash->{'1Z12345E0291980793'}), 'HASH', 'Test tracking id exists.');
is(ref($hash->{'1Z12345E0291980793'}{summary}), 'HASH', 'Has summary');
is($hash->{'1Z12345E0291980793'}{activity}[0]{status_description},
    'DELIVERED', 'Long-form access to description is DELIVERED');
is($hash->{'1Z12345E0291980793'}{summary}{status_description},
    'DELIVERED', 'Test tracking number status description is delivered.');
