#!/usr/bin/perl -w

use strict;
use Business::DK::Postalcode qw(create_regex get_all_postalcodes);

my $zipcodes = get_all_postalcodes();

print STDERR create_regex(@{$zipcodes});
