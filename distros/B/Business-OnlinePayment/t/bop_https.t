#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

my $package = "Business::OnlinePayment::HTTPS";
eval "use $package;";

# HTTPS support is optional
plan( $@ ? ( skip_all => "$package: $@\n" ) : ( tests => 1 ) );

can_ok( $package, qw(https_get https_post) );
