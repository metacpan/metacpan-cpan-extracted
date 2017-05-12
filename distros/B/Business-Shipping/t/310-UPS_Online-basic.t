#!/bin/env perl

# UPS_Online RateRequest suite of tests.

use strict;
use warnings;
use Test::More;
use Carp;
use Data::Dumper;
use Business::Shipping;

plan skip_all => 'Required modules not installed'
    unless Business::Shipping::Config::calc_req_mod('UPS_Online');
plan skip_all => 'No credentials'
    unless $ENV{UPS_USER_ID}
        and $ENV{UPS_PASSWORD}
        and $ENV{UPS_ACCESS_KEY};

plan skip_all => 'Slow tests. Set TEST_SLOW to run.'
    unless $ENV{TEST_SLOW};

plan 'no_plan';

$::debug = 0;

my $standard_method
    = new Business::Shipping->rate_request('shipper' => 'UPS');
ok(defined $standard_method, 'UPS standard object construction');

my $other_method = new Business::Shipping::UPS_Online::RateRequest;
ok(defined $other_method, 'UPS alternate object construction');

my $package_one = new Business::Shipping::UPS_Online::Package;
ok(defined $package_one, 'UPS package object construction');

#goto wwe_uk;
sub debug {
    print STDERR $_[0] . "\n" if $::debug;
}

sub test {
    my (%args) = @_;
    my $shipment = Business::Shipping->rate_request(
        'shipper'    => 'Online::UPS',
        'user_id'    => $ENV{UPS_USER_ID},
        'password'   => $ENV{UPS_PASSWORD},
        'access_key' => $ENV{UPS_ACCESS_KEY},
        'cache'      => 0,
    );
    $shipment->submit(%args) or confess $shipment->user_error();
    return $shipment;
}

sub simple_test {
    my (%args) = @_;
    my $shipment = test(%args);
    $shipment->submit() or die $shipment->user_error();
    my $total_charges = $shipment->total_charges();
    my $msg           = "UPS Simple Test: "
        . (
          $args{weight}
        ? $args{weight} . " pounds"
        : ($args{pounds} . "lbs and " . $args{ounces} . "ounces")
        )
        . " to "
        . ($args{to_city} ? $args{to_city} . " " : '')
        . $args{to_zip} . " via "
        . $args{service} . " = "
        . ($total_charges ? '$' . $total_charges : "undef");
    ok($total_charges, $msg);
}

###########################################################################
##  Should fail on missing user_id or password
##  - Test disabled until we can disable error output for individual tests
##    (e.g. with a new version of event_handlers => {} )
###########################################################################
#
#my $UPS_USER_ID = $ENV{ UPS_USER_ID };
#delete $ENV{ UPS_USER_ID };
#
#my $rr100 = Business::Shipping->rate_request(
#    shipper        => 'Online::UPS',
#    service        => 'GNDRES',
#    weight         => 5,
#    to_residential => 1,
#    from_zip       => '98682',
#    to_zip         => '98270',
#);
#
#eval { $rr100->submit or die 'bob'; };
#ok( $@, "UPS Died on missing user_id as expected" );
#
#$ENV{ UPS_USER_ID } = $UPS_USER_ID;

my $shipment;

###########################################################################
##  Domestic Single-package API
###########################################################################
#Business::Shipping->log_level('debug');

$shipment = test(
    'pickup_type'    => 'daily pickup',
    'from_zip'       => '98682',
    'from_country'   => 'US',
    'to_country'     => 'US',
    'service'        => '1DA',
    'to_residential' => '1',
    'to_zip'         => '98270',
    'weight'         => '3.45',
    'packaging'      => '02',
);
$shipment->submit() or die $shipment->user_error();
ok($shipment->total_charges(),
    'UPS domestic single-package API total_charges > 0');

###########################################################################
##  Domestic Multi-package API
##  TODO: Re-enable.  Currently disabled.
###########################################################################

my $rate_request;

use Business::Shipping;
use Business::Shipping::UPS_Online::Shipment;

$rate_request = Business::Shipping->rate_request(shipper => 'Online::UPS');
$shipment = Business::Shipping::UPS_Online::Shipment->new();

$rate_request->init(
    'shipper'    => 'Online::UPS',
    'user_id'    => $ENV{UPS_USER_ID},
    'password'   => $ENV{UPS_PASSWORD},
    'access_key' => $ENV{UPS_ACCESS_KEY},
    'cache'      => 0,
);

$shipment->init(
    from_zip => '98682',
    to_zip   => '98270',
    service  => 'GNDRES',
);

#$shipment->add_package(
#    id         => '0',
#    weight     => 5,
#    packaging  => '02',
#);

#$shipment->add_package(
#    id         => '1',
#    weight     => 3,
#    packaging  => '02',
#);

#$rate_request->shipment( $shipment );
#$rate_request->submit() or die $rate_request->user_error();
#ok( $rate_request->total_charges(),    'UPS domestic multi-package API total_charges > 0' );

###########################################################################
##  International Single-package API
###########################################################################

#$rate_request = test(
#    'pickup_type'    => 'daily pickup',
#    'from_zip'       => '98682',
#    'from_country'   => 'US',
#    'to_country'     => 'GB',
#    'service'        => 'XPR',
#    'to_residential' => '1',
#    'to_city'        => 'Godstone',
#    'to_zip'         => 'RH98AX',
#    'weight'         => '3.45',
#);
#$rate_request->submit() or die $rate_request->user_error();
#ok( $rate_request->total_charges(),        'UPS intl single-package API total_charges > 0' );
ok(1, 'TODO: Fix UPS intl single-package API total_charges > 0');

###########################################################################
##  International Multi-package API
###########################################################################
#    $shipment = test(
#        'pickup_type'         => 'daily pickup',
#        'from_zip'            => '98682',
#        'from_country'        => 'US',
#        'to_country'        => 'GB',
#        'service'            => 'XDM',
#        'to_residential'    => '1',
#        'to_city'            => 'Godstone',
#        'to_zip'            => 'RH98AX',
#    );
#
#    $shipment->add_package(
#        'weight'            => '3.45',
#        'packaging'         => '02',
#    );
#
#    $shipment->add_package(
#        'weight'        => '6.9',
#        'packaging'     =>  '02',
#    );
#    $shipment->submit() or die $shipment->user_error();
#    ok( $shipment->total_charges(),    'UPS intl multi-package API total_charges > 0' );

###########################################################################
##  Cache Test
##  Multiple sequential queries should give *different* results, even if
##  they only differ by 10 pounds.
###########################################################################
my %similar = (
    'pickup_type'    => 'daily pickup',
    'from_zip'       => '98682',
    'from_country'   => 'US',
    'to_country'     => 'US',
    'service'        => '1DA',
    'to_residential' => '1',
    'to_zip'         => '98270',
    'packaging'      => '02',
);
my $rr1 = test(
    %similar,
    'cache'  => 1,
    'weight' => 2,
);
$rr1->submit() or die $rr1->user_error();
my $total_charges_2_pounds = $rr1->total_charges();
debug("Cache test. 2 pounds = $total_charges_2_pounds");

my $rr2 = test(
    %similar,
    'cache'  => 1,
    'weight' => 12,
);
$rr2->submit() or die $rr2->user_error();
my $total_charges_12_pounds = $rr2->total_charges();
debug("Cache test. 12 pounds = $total_charges_12_pounds");
ok( $total_charges_2_pounds != $total_charges_12_pounds,
    'UPS domestic cache, sequential charges are different'
);

###########################################################################
##  World Wide Expedited
###########################################################################
wwe_uk:

#Business::Shipping->log_level('info');
$shipment = test(
    'pickup_type'  => 'daily pickup',
    'from_zip'     => '98682',
    'from_country' => 'US',

    'to_country'     => 'GB',
    'service'        => 'XPD',
    'to_residential' => '1',

    #'to_city'            => 'Godstone',
    'to_zip'    => 'RH98AX',
    'weight'    => '3.45',
    'packaging' => '02',
);
$shipment->submit() or print $shipment->user_error();

#print "shipment = " . Dumper($shipment);
ok($shipment->total_charges(), 'UPS World Wide Expedited > 0');
###########################################################################
##  UPS One Day Air -- Specific cases
###########################################################################
my %std_opts = (
    'pickup_type'    => 'daily pickup',
    'from_zip'       => '98682',
    'to_residential' => '1',
    'packaging'      => '02',
);

simple_test(
    %std_opts,
    service => '1DA',

    #'to_city'            => 'Atlantic',
    'to_zip'    => '50022',
    'weight'    => '5.00',
    'packaging' => '02',
);

simple_test(
    %std_opts,
    'service' => '1DA',

    #'to_city'            => 'Allison Park',
    'to_zip' => '15101',
    'weight' => '15.00',
);

simple_test(
    %std_opts,
    'service' => '1DA',

    #'to_city'            => 'Costa Mesa',
    'to_zip' => '92626',
    'weight' => '15.00',
);

###########################################################################
##  Perth, Western Australia
###########################################################################
simple_test(
    %std_opts,
    service    => 'XPD',
    to_country => 'AU',
    to_city    => 'Bicton',
    to_zip     => '6157',
    weight     => 5.5,
);

#
# XDM not allowed to australia?
#
#simple_test(
#    %std_opts,
#    service            => 'XDM',
#    to_country        => 'AU',
#    to_city            => 'Bicton',
#    to_zip            => '6157',
#    weight            => 5.5,
#);

# XPD not available?
#simple_test(
#    %std_opts,
#    service            => 'XPD',
#    to_country        => 'AU',
#    to_city            => 'Bicton',
#    to_zip            => '6157',
#    weight            => 5.5,
#);

###########################################################################
##  Standard to Canada
###########################################################################
simple_test(
    %std_opts,
    service    => 'UPSSTD',
    to_country => 'CA',
    to_city    => 'Kitchener',
    to_zip     => 'N2H6S9',
    weight     => 5.5,
);

simple_test(
    %std_opts,
    service    => 'UPSSTD',
    to_country => 'CA',
    to_city    => 'Richmond',
    to_zip     => 'V6X3E1',
    weight     => 0.5,
);

###########################################################################
##  From Canada, To Canada
###########################################################################
simple_test(

    # Should be ~ $22.50

    service        => 'UPSSTD',
    weight         => 5,
    to_residential => 1,
    packaging      => '02',

    from_country => 'CA',
    from_city    => 'Richmond',
    from_zip     => 'V6X3E1',

    to_country => 'CA',
    to_city    => 'Kitchener',
    to_zip     => 'N2H6S9',
);

my $print = 0;

$rate_request = Business::Shipping->rate_request('shipper' => 'UPS_Online');
$rate_request->init(to_country => 'US');
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok($rate_request->to_country,
    'UPS_Online init( to_country => \'US\' ) works');

$rate_request = Business::Shipping->rate_request('shipper' => 'UPS_Online');
$rate_request->to_country('US');
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok($rate_request->to_country, 'UPS_Online to_country() works');

$rate_request = Business::Shipping->rate_request('shipper' => 'UPS');
$rate_request->init(to_country => 'US');
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok($rate_request->to_country, 'UPS init( to_country => \'US\' ) works');

$rate_request = Business::Shipping->rate_request('shipper' => 'UPS');
$rate_request->to_country('US');
print "\tto_country = " . $rate_request->to_country() . "\n" if $print;
ok($rate_request->to_country, 'UPS to_country() works');

1;
