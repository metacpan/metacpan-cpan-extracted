#!/bin/env perl

# USPS_Online RateRequest suite of tests.

use strict;
use warnings;
use Test::More;
use Carp;
use Business::Shipping;
use Data::Dumper;
use Scalar::Util qw(blessed);

plan skip_all => 'Required modules not installed'
    unless Business::Shipping::Config::calc_req_mod('USPS_Online');

plan skip_all => 'No credentials'
    unless $ENV{USPS_USER_ID} and $ENV{USPS_PASSWORD};

plan skip_all => 'Slow tests. Set TEST_SLOW to run.'
    unless $ENV{TEST_SLOW};

plan 'no_plan';

#goto letter_is_cheaper;

{
    my $standard_method
        = new Business::Shipping->rate_request(shipper => 'Online::USPS');
    ok(defined $standard_method, 'USPS standard object construction');

    my $other_method = new Business::Shipping::USPS_Online::RateRequest;
    ok(defined $other_method, 'USPS alternate object construction');

    my $package = new Business::Shipping::USPS_Online::Package;
    ok(defined $package, 'USPS package object construction');
}

{
    my $shipment = Business::Shipping::USPS_Online::Shipment->new();
    is( blessed($shipment),
        'Business::Shipping::USPS_Online::Shipment',
        'Business::Shipping::USPS_Online::Shipment created successfully'
    );

    $shipment->to_zip('98683');
    is($shipment->to_zip(), '98683', 'Shipment: set and get zip code.');
}

{
    my $rate_request = Business::Shipping->rate_request(
        shipper  => 'USPS_Online',
        service  => 'Priority',
        from_zip => '98683',
        to_zip   => '98270',
        weight   => 5.00,
    );

    is($rate_request->to_zip(), '98270',
        'rate_request() to set, then get zip code.');
}

{
    my $rate_request = Business::Shipping->rate_request(
        shipper      => 'USPS_Online',
        'service'    => 'Priority Mail International',
        'weight'     => 1,
        'ounces'     => 0,
        'mail_type'  => 'Package',
        'to_country' => 'Great Britain',
        'from_zip'   => '98682',
    );

    #is($rate_request->to_country(), 'Great Britain',
    #    'rate_request() to set, then get to_country.');
    ok(1, 'do nothing');
}

sub test {
    my (%args) = @_;
    my $shipment = Business::Shipping->rate_request(
        shipper  => 'USPS',
        user_id  => $ENV{USPS_USER_ID},
        password => $ENV{USPS_PASSWORD},
        cache    => 0,

        #event_handlers => {
        #
        #},
    );
    $shipment->submit(%args) or croak $shipment->user_error();
    return $shipment;
}

sub simple_test {
    my (%args) = @_;
    my $shipment = test(%args);
    $shipment->submit() or die $shipment->user_error();
    my $total_charges = $shipment->total_charges();
    my $msg           = "USPS Simple Test: "
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

if (0) {
    my $shipment;
    $shipment = test(
        'test_mode' => 1,
        'service'   => 'EXPRESS',
        'from_zip'  => '20770',
        'to_zip'    => '20852',
        'pounds'    => 10,
        'ounces'    => 0,
        'size'      => 'REGULAR',
    );
    ok($shipment->total_charges(), 'USPS domestic test total_charges > 0');

    $shipment = test(
        'test_mode'  => 1,
        'pounds'     => 0,
        'ounces'     => 1,
        'mail_type'  => 'Postcards or Aerogrammes',
        'to_country' => 'Algeria',
    );
    ok($shipment->total_charges(), 'USPS intl test total_charges > 0');

}

# TODO: Update with V3 rate requests, these V2 no longer work.
if (0) {
    my $shipment;
    $shipment = test(
        'test_mode' => 1,
        'service'   => 'PRIORITY',
        'from_zip'  => '10022',
        'to_zip'    => '20008',
        'pounds'    => 10,
        'ounces'    => 5,
        'container' => 'Flat-Rate Box',
        'size'      => 'REGULAR',
    );
    ok($shipment->total_charges(), 'USPS domestic test total_charges > 0');

    $shipment = test(
        test_mode  => 1,
        service    => 'All',
        from_zip   => '10022',
        to_zip     => '20008',
        'pounds'   => 10,
        'ounces'   => 5,
        'size'     => 'LARGE',
        machinable => 'TRUE',
    );
    ok($shipment->total_charges(),
        'USPS domestic all services test total_charges > 0');

}
{
    my $shipment = test(
        'test_mode'    => 0,
        'from_zip'     => '98682',
        'to_country'   => 'United States',
        'service'      => 'Priority',
        'to_zip'       => '96826',
        'from_country' => 'US',
        'pounds'       => '2',
    );
    ok($shipment->total_charges(),
        'USPS domestic production total_charges > 0');
}

if (0) {
    my $shipment;

    # These are just more domestic production tests for "Priority Mail"
    $shipment = test(
        'from_zip' => '98682',
        weight     => 0.2,
        to_zip     => '98270',
        service    => 'Priority',
    );

    print test_domestic(
        weight  => 3.5,
        to_zip  => '99501',
        service => 'Priority',
    );

    print test_domestic(
        'to_zip'  => '96826',
        'weight'  => '2',
        'service' => 'Priority',
    );
}

{

    #Business::Shipping->log_level('debug');
    my $shipment = test(
        'test_mode'  => 0,
        'service'    => 'Priority Mail International',
        'weight'     => 1,
        'ounces'     => 0,
        'mail_type'  => 'Package',
        'to_country' => 'Great Britain',
        'from_zip'   => '98682',

        #to_zip => 'SW1A 1AA'
    );
    ok($shipment->total_charges(), 'USPS intl production total_charges > 0');
}

{

    # Cache Test
    # - Multiple sequential queries should give *different* results.
    my $shipment = test(
        'cache'      => 1,
        'test_mode'  => 0,
        'service'    => 'Express Mail International',
        'weight'     => 1,
        'ounces'     => 0,
        'mail_type'  => 'Package',
        'to_country' => 'Great Britain',
    );
    my $total_charges_1_pound = $shipment->total_charges();

    my $shipment2 = test(
        'cache'      => 1,
        'test_mode'  => 0,
        'service'    => 'Express Mail International',
        'weight'     => 10,
        'ounces'     => 0,
        'mail_type'  => 'Package',
        'to_country' => 'Great Britain',
    );

    my $total_charges_5_pounds = $shipment2->total_charges();

    ok( $total_charges_1_pound != $total_charges_5_pounds,
        'USPS intl cache saves results separately'
    );
}
###########################################################################
##  High weight should be a high price
###########################################################################

{
    my $shipment = test(
        service  => 'Priority',
        weight   => 22.5,
        to_zip   => 27713,
        from_zip => 98682,
    );

    #print "\ttotal charges = " . $shipment->total_charges() . "\n";
    ok($shipment->total_charges() > 20.00, 'USPS high weight is high price');
}
###########################################################################
##  Zip Code Testing
###########################################################################

# This test doesn't work anymore because Priority service always returns
# "Priority Mail Flat-Rate Box (11.25" x 8.75" x 6")'" for $7.70

if (0) {

    # Vancouver, Vermont, Alaska, Hawaii
    my @several_very_different_zip_codes = ('98682', '22182', '99501');
    my %charges;

    #Business::Shipping->log_level( 'DEBUG' );
    foreach my $zip (@several_very_different_zip_codes) {
        my $shipment = test(
            'cache'    => 0,
            'service'  => 'Priority',
            'weight'   => 5,
            'to_zip'   => $zip,
            'from_zip' => 98682
        );
        $charges{$zip} = $shipment->total_charges();
        print Dumper($shipment->results);
    }

    #use Data::Dumper; print Dumper( \%charges ); exit;

    # Somehow make sure that all the values in %charges are unique.
    my $found_duplicate;
    foreach my $zip1 (keys %charges) {
        foreach my $zip2 (keys %charges) {

            # Skip this zip code, only testing the others.
            next if $zip2 eq $zip1;

            if ($charges{$zip1} == $charges{$zip2}) {
                $found_duplicate = $zip1;
            }
        }
    }

    ok(!$found_duplicate,
        'USPS different zip codes give different prices (caching enabled)');

}

##########################################################################
##  SPECIFIC CIRCUMSTANCES
##########################################################################

#simple_test(
#    from_zip    => '98682',
#    service        => 'Airmail Parcel Post',
#    to_country    => 'Bosnia-Herzegowina',
#    weight        => 5,
#);

# This tries to test to make sure that the shipping matches up right
#  - So that Airmail parcel post goes to Airmail parcel post, etc.
#
letter_is_cheaper:
{

    #Business::Shipping->log_level('debug');
    my $shipment = test(
        service => 'Priority Mail International Medium Flat Rate Box',

        from_zip => '98682',
        user_id  => $ENV{USPS_USER_ID},
        password => $ENV{USPS_PASSWORD},

        to_zip     => 6157,
        to_country => 'Australia',
        weight     => 0.50,
    );
    my $airmail_parcel_post_to_AU = $shipment->total_charges();
    ok($airmail_parcel_post_to_AU, 'USPS australia');

    # Test the letter service.
    my $shipment2 = test(
        service => 'Priority Mail International Flat-Rate Envelope',

        from_zip => '98682',
        user_id  => $ENV{USPS_USER_ID},
        password => $ENV{USPS_PASSWORD},

        to_zip     => 6157,
        to_country => 'Australia',
        weight     => 0.50,
    );
    my $airmail_letter_post_to_AU = $shipment2->total_charges();

    #print "airmail letter post to Australia = $airmail_letter_post_to_AU\n";
    #print "airmail parcel post to australia = $airmail_parcel_post_to_AU\n";
    #use Data::Dumper; print Dumper($shipment2->results());
    ok( $airmail_letter_post_to_AU < $airmail_parcel_post_to_AU,
        "USPS Letter to AU (\$$airmail_letter_post_to_AU) is cheaper than "
            . "Parcel (\$$airmail_parcel_post_to_AU) to AU"
    );

    #print Dumper($shipment2);
}

{

    #
    # Letter to Canada:
    #
    my $shipment = test(
        service => 'Priority Mail International Small Flat Rate Envelope',

        from_zip => '98682',
        user_id  => $ENV{USPS_USER_ID},
        password => $ENV{USPS_PASSWORD},

        'to_zip'   => "N2H6S9",
        to_country => 'Canada',
        'weight'   => "0.25",
    );
    my $airmail_letter_post_to_CA = $shipment->total_charges();

    #print "\ttotal charges = $airmail_letter_post_to_CA\n";
    ok($airmail_letter_post_to_CA,
        "Got a price ($airmail_letter_post_to_CA) for PMISFRE to Canada");
}

#######################################################################
##  Canada Services
#######################################################################

{
    my $shipment = test(
        service => 'Priority Mail International Medium Flat Rate Box',

        from_zip => '98682',
        user_id  => $ENV{USPS_USER_ID},
        password => $ENV{USPS_PASSWORD},

        to_country => 'Canada',
        to_zip     => 'N2H6S9',
        weight     => 5.5,
    );
    ok($shipment->total_charges(), 'USPS Parcel Post to Canada');
}
