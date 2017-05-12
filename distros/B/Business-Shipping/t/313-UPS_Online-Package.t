#!/bin/env perl

# UPS_Online Package - basic unit tests of the OO-arch.

use strict;
use warnings;
use Test::More 'no_plan';

use_ok('Business::Shipping::Package');

my $p = Business::Shipping::Package->new();

ok( ref($p) eq 'Business::Shipping::Package',
    'Business::Shipping::Package new object created'
);

use_ok('Business::Shipping::UPS_Online::Package');

my $package = Business::Shipping::UPS_Online::Package->new();

ok( ref($package) eq 'Business::Shipping::UPS_Online::Package',
    'Business::Shipping::UPS_Online::Package created'
);

$package->weight(1.5);

is($package->weight(), 1.5, 'Package weight set and retreived.');

use_ok('Business::Shipping::UPS_Online::Shipment');
my $s1 = Business::Shipping::UPS_Online::Shipment->new();
$s1->service('GNDRES');
is($s1->service(), 'GNDRES', 'Set and get service');
print $s1->service_code() . "\n";
