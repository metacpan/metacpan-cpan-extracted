#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $base    = "DNS::Hetzner";

my $methods = {
    $base                    => [qw/request client token host base_uri/],
    $base . '::API'          => [qw/load_namespace/],
    $base . '::Utils'        => [qw/_check_params _check_type/],
    $base . '::API::Records' => [qw/update get list/],
    $base . '::API::Zones'   => [qw/update get list get_export create_import/],
};

for my $mod ( sort keys %{$methods} ) {
    use_ok $mod;
}

for my $pkg ( sort keys %{$methods} ) {
    can_ok $pkg, @{ $methods->{$pkg} };
}

done_testing();