#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Carp;
diag( "Carp: " . Carp->VERSION);

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

my $base    = "API::MailboxOrg";

my $methods = {
    $base                          => [qw/user password client token host base_uri/],
    $base . '::APIBase'            => [qw/_request/],
    $base . '::API::Account'       => [qw/add del get set list/],
    $base . '::API::Backup'        => [qw/backup_import list/],
    $base . '::API::Base'          => [qw/auth deauth search/],
    $base . '::API::Blacklist'     => [qw/add del list/],
    $base . '::API::Capabilities'  => [qw/set/],
    $base . '::API::Context'       => [qw/list/],
    $base . '::API::Domain'        => [qw/add del get list set/],
    $base . '::API::Hello'         => [qw/innerworld world/],
    $base . '::API::Invoice'       => [qw/get list/],
    $base . '::API::Mailinglist'   => [qw/add del get list set/],
    $base . '::API::Mail'          => [qw/add del get list register set/],
    $base . '::API::Passwordreset' => [qw/listmethods sendsms setpassword/],
    $base . '::API::Spamprotect'   => [qw/get set/],
    $base . '::API::Test'          => [qw/accountallowed domainallowed/],
    $base . '::API::Utils'         => [qw/validator/],
    $base . '::API::Validate'      => [qw/spf/],
    $base . '::API::Videochat'     => [qw/add del update list/],
};

for my $mod ( sort keys %{$methods} ) {
    use_ok $mod;
}

for my $pkg ( sort keys %{$methods} ) {
    can_ok $pkg, @{ $methods->{$pkg} };
}

done_testing();
