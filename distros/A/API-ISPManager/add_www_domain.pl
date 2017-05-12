#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use API::ISPManager;

#
# Script for add www domains to certain user account in ISPManager
#

die "Params required: host / username / password / domain / docroot\n" unless scalar @ARGV == 5;

my $host     = $ARGV[0];
my $login    = $ARGV[1];
my $password = $ARGV[2];
my $domain   = $ARGV[3];
my $docroot  = $ARGV[4];
my $email    = '';
my $ip       = `/usr/bin/host -t A $host | head -1 | awk '{print \$4}'`;
chomp $ip;

unless ($ip && $ip =~ m/\d+\.\d+\.\d+\.\d+/) {
    die "Get ip failed!\n";
}

$API::ISPManager::DEBUG = '';

my %connection_params = (
    username => $login,
    password => $password,
    host     => $host,
    path     => 'manager',
);

my $user_params = API::ISPManager::misc::usrparam( { %connection_params } );
$email = $user_params->{email};
die "Cannot get user email from panel!\n" unless $email;

my $domain_creation_result = API::ISPManager::domain::create( {
    %connection_params,
    domain  => $domain,
    alias   => "www.$domain",
    owner   => $login,
    admin   => $email,
    ip      => $ip,
    ssi     => 'on',
    php     => 'phpfcgi',
    ssl     => 'on',
    sslport => 443,
    docroot => $docroot,
} );

if ($domain_creation_result) {
    print "$domain success added!\n";
} else {
    warn Dumper($API::ISPManager::last_answer);
}
