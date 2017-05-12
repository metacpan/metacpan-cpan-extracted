#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use API::ISPManager;

#
# Script for add mail account to certain mail-domain in ISPManager
#

die "Params required: host / username / password / filename /path\n" unless scalar @ARGV == 5;

my $host          = $ARGV[0];
my $login         = $ARGV[1];
my $password      = $ARGV[2];
my $filename      = $ARGV[3];
my $plid          = $ARGV[4];


$API::ISPManager::DEBUG = 1;

my %connection_params = (
    username => $login,
    password => $password,
    host     => $host,
    path     => 'manager',
);


my $upload_result = API::ISPManager::file::upload( {
    %connection_params,
    plid => $plid,
    file => $filename,
} );


if ($upload_result) {
    print "file success uploaded!\n";
} else {
    warn Dumper($API::ISPManager::last_answer);
}


