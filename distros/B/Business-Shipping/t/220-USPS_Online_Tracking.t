#!/bin/env perl

# USPS_Online Tracking - just a few basic tests.

use strict;
use warnings;
use Test::More;
use Carp;
use Scalar::Util qw(blessed);
use Business::Shipping;

plan skip_all => ''
    unless Business::Shipping::Config::calc_req_mod('USPS_Online');
plan skip_all => 'No credentials'
    unless $ENV{USPS_USER_ID} and $ENV{USPS_PASSWORD};
plan 'no_plan';

use_ok('Business::Shipping::USPS_Online::Tracking');

my $tracker = Business::Shipping::USPS_Online::Tracking->new();
is( blessed($tracker),
    'Business::Shipping::USPS_Online::Tracking',
    'Get new Tracking object'
);

$tracker->init(
    test_mode => 1,
    user_id   => $ENV{USPS_USER_ID},
    password  => $ENV{USPS_PASSWORD},
);

$tracker->tracking_ids('EJ958083578US', 'EJ958083578US');

$tracker->submit() || logdie $tracker->user_error();
my $hash = $tracker->results();

#use Data::Dumper;
#print Data::Dumper->Dump([$hash]);

is(ref($hash),                  'HASH', 'Got results hash.');
is(ref($hash->{EJ958083578US}), 'HASH', 'Test tracking id in results.');
is(ref($hash->{EJ958083578US}{summary}), 'HASH', 'Has summary');
is($hash->{EJ958083578US}{summary}{status_description},
    'DELIVERED', 'Test tracking number status description is delivered.');
