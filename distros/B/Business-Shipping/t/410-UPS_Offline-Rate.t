#!/bin/env perl

# UPS_Offline RateRequest - suite of tests. (Compares a lot to UPS_Online.)

use strict;
use warnings;
use Test::More;
use Carp;
use Business::Shipping;
use Data::Dumper;

plan skip_all => 'Required modules for UPS_Offline are not installed'
    unless Business::Shipping::Config::calc_req_mod('UPS_Offline');

plan skip_all => 'DataFiles version 1.02+ is required.'
    unless $Business::Shipping::DataFiles::VERSION >= 1.02;

plan 'no_plan';

$::UPS_Online = 1 if Business::Shipping::Config::calc_req_mod('UPS_Online');

unless ($ENV{UPS_USER_ID} and $ENV{UPS_PASSWORD} and $ENV{UPS_ACCESS_KEY}) {
    $::UPS_Online     = 0;
    $::UPS_Online_msg = 'No credentials. Set three UPS_* variables to run.';
}

if ($ENV{DISABLE_UPS_ONLINE}) {
    $::UPS_Online     = 0;
    $::UPS_Online_msg = 'Comparison to UPS_Online is disabled. '
        . 'Unset DISABLE_UPS_ONLINE to run.';
}

if (not $ENV{TEST_SLOW}) {
    $::UPS_Online = 0;
    $::UPS_Online_msg
        = 'Comparison to UPS_Online is too slow. Set TEST_SLOW to run.';
}

# How to test for performance: time DIABLE_UPS_ONLINE=1 /usr/local/perl/bin/perl t/45_UPS_Offline.t
# Currently 1.8 - 2.2 seconds.

use constant CLOSE_ENOUGH_PERCENT => 10;

my %user = (
    user_id    => $ENV{UPS_USER_ID},
    password   => $ENV{UPS_PASSWORD},
    access_key => $ENV{UPS_ACCESS_KEY},
);

sub test {
    my (%args) = @_;
    my $shipment = Business::Shipping->rate_request(
        from_state => 'Washington',
        shipper    => 'UPS_Offline',
        cache      => 0,
    );

    $shipment->submit(%args) or print STDERR $shipment->user_error();
    return $shipment;
}

sub test_online {
    my (%args) = @_;
    my $shipment = Business::Shipping->rate_request(
        shipper => 'UPS_Online',
        cache   => 0,
        %user
    );

    $shipment->submit(%args) or print STDERR $shipment->user_error();
    return $shipment;
}

sub close_enough {
    my ($n1, $n2, $percent) = @_;

    $percent ||= CLOSE_ENOUGH_PERCENT;

    my ($greater, $lesser) = $n1 > $n2 ? ($n1, $n2) : ($n2, $n1);
    my $percentage_of_difference = 1 - ($lesser / $greater);
    my $required_percentage = $percent * .01;

#print "percentage_of_difference = $percentage_of_difference, required = $required_percentage\n";

    return 1 if ($percentage_of_difference <= $required_percentage);
    return 0;
}

{
###########################################################################
##  Domestic Single-package API
###########################################################################

    my %one_da_light_us = (
        service        => '1DA',
        weight         => '3.45',
        from_zip       => '98682',
        to_residential => '0',
        to_zip         => '98270',
    );

    my $shipment = test(%one_da_light_us);
    ok($shipment->total_charges(),
        'UPS domestic single-package API total_charges > 0');
    print "offline 1DA light close: " . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%one_da_light_us);
        ok($shipment_online->total_charges(),
            'UPS domestic single-package API total_charges > 0');
        print "online 1DA light close: "
            . $shipment_online->total_charges() . "\n";
    }

}

{
    my %ground_res_heavy_far_us = (
        service        => 'GNDRES',
        weight         => '45.00',
        from_zip       => '98682',
        to_residential => '',
        to_zip         => '22182',
    );

    my $shipment = test(%ground_res_heavy_far_us);
    ok($shipment->total_charges(),
        'UPS domestic single-package API total_charges > 0');
    print "Offline: GNDRES, heavy, far: " . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%ground_res_heavy_far_us);
        ok($shipment_online->total_charges(),
            'UPS domestic single-package API total_charges > 0');
        print "Online: GNDRES, heavy, far: "
            . $shipment_online->total_charges() . "\n";
    }

}

{
    my %ground_res_light_far_us = (
        service        => 'GNDRES',
        weight         => '3.00',
        from_zip       => '98682',
        to_residential => '',
        to_zip         => '22182',
    );

    my $shipment = test(%ground_res_light_far_us);
    ok($shipment->total_charges(),
        'UPS domestic single-package API total_charges > 0');
    print "Offline: GNDRES, light, far: " . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%ground_res_light_far_us);
        ok($shipment_online->total_charges(),
            'UPS domestic single-package API total_charges > 0');
        print "Online: GNDRES, light, far: "
            . $shipment_online->total_charges() . "\n";
    }
}

{
    my %ground_res_light_close_us = (
        service        => 'GNDRES',
        weight         => '3.00',
        from_zip       => '98682',
        to_residential => '',
        to_zip         => '98270',
    );

    my $shipment = test(%ground_res_light_close_us);
    ok($shipment->total_charges(),
        'UPS domestic single-package API total_charges > 0');
    print "Offline: GNDRES, light, close: "
        . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%ground_res_light_close_us);
        ok($shipment_online->total_charges(),
            'UPS domestic single-package API total_charges > 0');
        print "Online: GNDRES, light, close: "
            . $shipment_online->total_charges() . "\n";
    }
}

{
    my %ground_res_medium_close_us = (
        service        => 'GNDRES',
        weight         => '22.50',
        from_zip       => '98682',
        to_residential => '1',
        to_zip         => '22182',
    );

    my $shipment = test(%ground_res_medium_close_us);
    ok($shipment->total_charges(),
        'UPS domestic single-package API total_charges > 0');
    print "Offline: GNDRES, medium, close, residential: "
        . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%ground_res_medium_close_us);
        ok($shipment_online->total_charges(),
            'UPS domestic single-package API total_charges > 0');
        print "Online: GNDRES, medium, close, residential: "
            . $shipment_online->total_charges() . "\n";
    }
}

{
    my %ground_res_medium_close_us_98075 = (
        service        => 'GNDRES',
        weight         => '22.50',
        from_zip       => '98682',
        to_residential => '1',
        to_zip         => '98075',
    );

    my $shipment = test(%ground_res_medium_close_us_98075);
    ok($shipment->total_charges(),
        'UPS domestic single-package API total_charges > 0');
    print "Offline: GNDRES, medium, close, residential: "
        . $shipment->total_charges() . "\n";
}

{
###########################################################################
##  International
###########################################################################
    my %test = (
        from_state => 'Washington',
        from_zip   => '98682',
        service    => 'XPD',
        weight     => 20,
        to_country => 'GB',
        to_zip     => 'RH98AX',
    );

    my $shipment = test(%test);
    ok($shipment->total_charges(), 'UPS offline intl to gb');
    print "Offline: intl to gb " . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%test);
        ok($shipment_online->total_charges(), 'UPS intl XPD to gb');
        print "Online: intl to gb: "
            . $shipment_online->total_charges() . "\n";
    }
}

ok(1, 'TODO: UPS no longer offers XPR or XDM to RH98AX, GB, for 20 pounds.');
ok(1, 'TODO: Setup a test to make sure that it warns the user.');

{
    my %test = (
        shipper    => 'Offline::UPS',
        service    => 'XPR',
        to_country => 'CA',
        weight     => '0.5',
        to_zip     => 'M1V 2Z9',
    );
    my $this_test_desc = "0.5 XPR to Canada M1V: ";

    my $shipment = test(%test);
    ok($shipment->total_charges(), "UPS Offline: " . $this_test_desc);
    print "UPS Offline: "
        . $this_test_desc
        . $shipment->total_charges() . "\n";
}

###########################################################################
##  Hawaii / Alaska
###########################################################################
{
    my %test = (
        service    => '2DA',
        weight     => 20,
        from_zip   => '98682',
        from_state => 'Washington',
        to_zip     => '96826',
    );
    my $this_test_desc = "Hawaii 2DA: ";

    my $shipment = test(%test);
    ok($shipment->total_charges(), "UPS Offline: " . $this_test_desc);
    print "UPS Offline: "
        . $this_test_desc
        . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%test);
        ok( $shipment_online->total_charges(),
            "UPS Online: " . $this_test_desc
        );
        "UPS Online: "
            . $this_test_desc
            . $shipment_online->total_charges() . "\n";
    }
}

{
    my $rr2 = Business::Shipping->rate_request(shipper => 'Offline::UPS');

    $rr2->submit(
        service    => '1DA',
        weight     => 20,
        from_zip   => '98682',
        from_state => 'Washington',
        to_zip     => '96826',

    ) or print STDERR $rr2->user_error();

    print "Hawaii 2DA (alternate calling method):"
        . $rr2->total_charges() . "\n";
    ok($rr2->total_charges, "Hawaii 2DA (alternate calling method):");
}

{
    my %test = (
        service    => '1DA',
        weight     => 20,
        from_zip   => '98682',
        from_state => 'Washington',
        to_zip     => '96826',
    );
    my $this_test_desc = "Hawaii 1DA: ";

    my $shipment = test(%test);
    ok($shipment->total_charges(), "UPS Offline: " . $this_test_desc);
    print "UPS Offline: "
        . $this_test_desc
        . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%test);
        ok($shipment_online->total_charges(),
                  "UPS Online: "
                . $this_test_desc
                . $shipment_online->total_charges());
    }
}

{
    my %test = (
        service    => '2DA',
        weight     => 20,
        from_zip   => '98682',
        from_state => 'Washington',
        to_zip     => '99501',
    );
    my $this_test_desc = "Alaska 2DA: ";

    my $shipment = test(%test);
    ok($shipment->total_charges(), "UPS Offline: " . $this_test_desc);
    print "UPS Offline: "
        . $this_test_desc
        . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%test);
        ok($shipment_online->total_charges(),
                  "UPS Online: "
                . $this_test_desc
                . $shipment_online->total_charges());
    }
}

{
    my %test = (
        service    => '1DA',
        weight     => 20,
        from_zip   => '98682',
        from_state => 'Washington',
        to_zip     => '99501',
    );
    my $this_test_desc = "Alaska 1DA: ";

    my $shipment = test(%test);
    ok($shipment->total_charges(), "UPS Offline: " . $this_test_desc);
    print "UPS Offline: "
        . $this_test_desc
        . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%test);
        ok($shipment_online->total_charges(),
                  "UPS Online: "
                . $this_test_desc
                . $shipment_online->total_charges());
    }
}

###################
##  Mexico
###################

{
    my %test = (
        from_zip   => '98682',
        from_state => 'Washington',
        service    => 'XPD',
        weight     => 2.25,
        to_country => 'MX',
        to_zip     => '06400',
    );
    my $this_test_desc = "Mexico XPD: ";

    my $shipment = test(%test);
    ok($shipment->total_charges(), "UPS Offline: " . $this_test_desc);
    print "UPS Offline: "
        . $this_test_desc
        . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%test);
        ok($shipment_online->total_charges(),
                  "UPS Online: "
                . $this_test_desc
                . $shipment_online->total_charges());
    }
}

###################
##  NetherLands
###################
{
    my %test = (
        from_zip   => '98682',
        from_state => 'Washington',
        service    => 'XPD',
        to_country => 'NL',
        weight     => '12.75',
    );
    my $this_test_desc = "Netherlands XPD: ";

    my $shipment = test(%test);
    ok($shipment->total_charges(), "UPS Offline: " . $this_test_desc);
    print "UPS Offline: "
        . $this_test_desc
        . $shipment->total_charges() . "\n";
}
###################
##  Israel
###################
{
    my %test = (
        from_zip   => '98682',
        from_state => 'Washington',
        shipper    => 'Offline::UPS',
        service    => 'XPR',
        to_country => 'IL',
        weight     => '1.75',
        to_zip     => '034296',
    );
    my $this_test_desc = "Israel XPR: ";

    my $shipment = test(%test);
    ok($shipment->total_charges(), "UPS Offline: " . $this_test_desc);
    print "UPS Offline: "
        . $this_test_desc
        . $shipment->total_charges() . "\n";

#SKIP: {
#    skip( $::UPS_Online_msg, 1 ) unless $::UPS_Online;
#
#    $shipment_online = test_online( %test );
#    ok( $shipment_online->total_charges(),    "UPS Online: " . $this_test_desc . $shipment_online->total_charges() );
#}
}
###################
##  UPS Standard to Canada
###################
{
    my %test = (
        from_zip   => '98682',
        from_state => 'Washington',
        shipper    => 'Offline::UPS',
        service    => 'UPSSTD',
        to_country => 'CA',
        weight     => '20',
        to_zip     => 'N2H6S9',
    );
    my $this_test_desc = "Canada UPS Standard: ";

    my $shipment = test(%test);
    ok($shipment->total_charges(), "UPS Offline: " . $this_test_desc);
    print "UPS Offline: "
        . $this_test_desc
        . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my $shipment_online = test_online(%test);
        ok($shipment_online->total_charges(),
                  "UPS Online: "
                . $this_test_desc
                . $shipment_online->total_charges());
    }
}
########################################################################
##  Make sure that it handles zip+4 zip codes correctly (by throwing
##  away the +4.
########################################################################
if (0) {
    my %test = (
        from_country   => 'US',
        to_country     => 'US',
        from_state     => 'WA',
        service        => '2DA',
        to_residential => '1',
        from_zip       => '98682',
        weight         => '4.25',
        to_zip         => '96720-1749',
    );
    my $this_test_desc = "Zip+4: ";

    my $shipment = test(%test);
    ok($shipment->total_charges(), "UPS Offline: " . $this_test_desc);
    print "UPS Offline: "
        . $this_test_desc
        . $shipment->total_charges() . "\n";

SKIP: {
        skip($::UPS_Online_msg, 1) unless $::UPS_Online;

        my %r1 = (
            from_city => 'Vancouver',
            from_zip  => '98682',

            to_city        => 'Enterprise',
            to_zip         => '36330',
            to_residential => 1,

            weight  => 2.75,
            service => 'GNDRES',
        );

        my $rr_off = Business::Shipping->rate_request(
            shipper => 'Offline::UPS',
            %r1
        );
        $rr_off->submit or print STDERR $rr_off->user_error();

        my $rr_on = Business::Shipping->rate_request(
            shipper => 'Online::UPS',
            %r1, %user
        );
        $rr_on->submit or print STDERR $rr_on->user_error();

        my $rr_off_rate = $rr_off->rate;
        my $rr_on_rate  = $rr_on->rate;

        ok( close_enough($rr_off_rate, $rr_on_rate),
            "UPS Offline ($rr_on_rate) and Online ($rr_off_rate) are close enough for GNDRES, light, far"
        );
    }
}
########################################################################
## Multi-package
########################################################################
if (0) {
    my %test = (
        service  => '2DA',
        from_zip => '98682',
        to_zip   => '98270',
    );
    my $this_test_desc = "UPS Offline: Multi-package: ";

    my $rr = Business::Shipping->rate_request(shipper => 'UPS_Offline');
    $rr->init(%test);
    $rr->shipment->add_package(weight => 5);
    $rr->shipment->add_package(weight => 15);
    $rr->shipment->add_package(weight => 7);

    $rr->execute or die $rr->user_error;

    ok($rr->total_charges(), $this_test_desc);
    print $this_test_desc . $rr->total_charges() . "\n";
}
########################################################################
## Overweight split shipments
########################################################################
{
    my %test = (
        service  => 'GNDRES',
        from_zip => '98682',
        to_zip   => '98270',
        weight   => 151,
    );
    my $this_test_desc = "UPS Offline: Over max package weight: ";
    my $rr = Business::Shipping->rate_request(shipper => 'UPS_Offline');
    $rr->init(%test);
    $rr->execute or die $rr->user_error;
    ok($rr->total_charges(), $this_test_desc);
    print $this_test_desc . $rr->total_charges() . "\n";
}

########################################################################
## Hundredweight
########################################################################
{
    my %test = (
        service  => 'GNDRES',
        from_zip => '98682',
        to_zip   => '98270',
        weight   => 455,
    );
    my $this_test_desc = "UPS Offline: Hundredweight: ";
    my $rr = Business::Shipping->rate_request(shipper => 'UPS_Offline');
    $rr->init(%test);
    $rr->execute or die $rr->user_error;
    ok($rr->total_charges(), $this_test_desc);
    print $this_test_desc . $rr->total_charges() . "\n";
}
########################################################################
## Hundredweight with tiers
########################################################################
{
    my %test = (
        service        => 'gndcom',
        weight         => '330',
        from_zip       => '98682',
        to_zip         => '87110',
        to_city        => 'Albuquerque',
        tier           => 3,
        to_residential => 0,
    );
    my $this_test_desc = "UPS Offline: Hundredweight: tier 3:  ";
    my $rr = Business::Shipping->rate_request(shipper => 'UPS_Offline');
    $rr->init(%test);
    $rr->execute or die $rr->user_error;
    ok(close_enough(127.06, $rr->total_charges()), $this_test_desc);
    print $this_test_desc . $rr->total_charges() . "\n";
}
########################################################################
## Named services
########################################################################
{
    my %test = (
        service  => 'Ground Residential',
        from_zip => '98682',
        to_zip   => '98270',
        weight   => 5,
    );
    my $this_test_desc = "UPS Offline: Use the long name of the service: ";
    my $rr = Business::Shipping->rate_request(shipper => 'UPS_Offline');
    $rr->init(%test);
    $rr->execute or die $rr->user_error;
    ok($rr->total_charges(), $this_test_desc);
    print $this_test_desc . $rr->total_charges() . "\n";
}

while (defined(my $data = <DATA>)) {
    my $autotest_count = 0;
    foreach my $line (split("\n", $data)) {

        $autotest_count++;

        #print "TEST $autotest_count...line=$line\n";
        my @values = split("\t", $line);

        # exp_price = Expected price
        my ($exp_price, $service, $weight, $from_zip, $to_zip, $to_city,
            $to_residential)
            = @values;

        # to_city is not currently used.

        my %test = (
            service        => $service,
            from_zip       => $from_zip,
            to_zip         => $to_zip,
            weight         => $weight,
            to_residential => $to_residential,
        );
        my $this_test_desc
            = "UPS Offline: Autotest "
            . $autotest_count
            . " is close enough to $exp_price.";
        my $rr = Business::Shipping->rate_request(shipper => 'UPS_Offline');
        $rr->init(%test);
        $rr->execute or die $rr->user_error;
        ok(close_enough($exp_price, $rr->total_charges()), $this_test_desc);
        print $this_test_desc . "  " . $rr->total_charges() . "\n";
    }

}

# Price, Service, Weight, from_zip, to_zip, to_city, to_residential
__DATA__
5.85	GNDRES	1	98682	85028	Phoenix	1
18.07	1DA	1	98682	97015	Clackamas	1
39.82	GNDRES	65	98682	36330	Enterprise	1
5.00	Ground Commercial	0.8	98682	98532	Chehalis	0
7.32	Ground Residential	0.8	98682	98532	Chehalis	1
17.52	Next Day Air	0.8	98682	98532	Chehalis	0
20.26	Next Day Air	0.8	98682	98532	Chehalis	1
6.02	GNDRES	1	33124	85028	Phoenix	1
5.85	GNDRES	1	97015	85028	Phoenix	1
5.26	GNDRES	1	98682	97015	Clackamas	1
35.44	Next Day Air	1	98683	96826	Honolulu	1
35.44	Next Day Air	1	98683	00906	San Juan	1
