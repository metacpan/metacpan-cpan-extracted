#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $base    = "DNS::Hetzner";

my $methods = {
    $base                    => [qw/records zones client token host base_uri/],
    $base . '::API'          => [qw/load_namespace/],
    $base . '::APIBase'      => [qw/request/],
    $base . '::API::Records' => [qw/update get list delete create/],
    $base . '::API::Zones'   => [qw/update get list export_file import_file_plain delete create validate_file_plain/],
};

for my $mod ( sort keys %{$methods} ) {
    use_ok $mod;
}

for my $pkg ( sort keys %{$methods} ) {
    can_ok $pkg, @{ $methods->{$pkg} };
}

done_testing();
