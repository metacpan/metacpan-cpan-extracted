#!/bin/env perl

# Ensure that pre-requisites for at least one shipper are installed.

use strict;
use warnings;
use Test::More 'no_plan';

use_ok('Business::Shipping');

foreach my $shipper (Business::Shipping::Config::calc_req_mod()) {
    ok(1, "All required modules for $shipper installed");
    my @required_modules
        = Business::Shipping::Config::get_req_mod(shipper => $shipper);
    foreach my $mod_name (@required_modules) {
        use_ok($mod_name);
    }
}

# Make sure that enough modules are installed for at least ONE shipper
my @installed_shippers = Business::Shipping::Config::calc_req_mod();
if (not @installed_shippers) {
    ok(0, "Required modules are not installed.  See INSTALL file.");
}
else {
    my $shippers2 = join(', ', @installed_shippers);
    ok(1, "Required modules installed for: $shippers2");
}

