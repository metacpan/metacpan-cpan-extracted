#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Carp;
diag( "Carp: " . Carp->VERSION);

use JSON::Validator;
diag( "JSON::Validator: " . JSON::Validator->VERSION);

use Mojolicious;
diag( "Mojolicious: " . Mojolicious->VERSION);

use Moo;
diag( "Moo: " . Moo->VERSION);

use MooX::Singleton;
diag( "MooX::Singleton: " . MooX::Singleton->VERSION);

use Types::Mojo;
diag( "Types::Mojo: " . Types::Mojo->VERSION);

use Types::Standard;
diag( "Types::Standard: " . Types::Standard->VERSION);

my $base    = "DNS::Hetzner";

my $methods = {
    $base                           => [qw/records zones primary_servers client token host base_uri/],
    $base . '::APIBase'             => [qw/request/],
    $base . '::API::Records'        => [qw/update get list delete create/],
    $base . '::API::Zones'          => [qw/update get list export_file import_file_plain delete create validate_file_plain/],
    $base . '::API::PrimaryServers' => [qw/update get list delete create/],
};

for my $mod ( sort keys %{$methods} ) {
    use_ok $mod;
}

for my $pkg ( sort keys %{$methods} ) {
    can_ok $pkg, @{ $methods->{$pkg} };
}

done_testing();
