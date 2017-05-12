#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use API::ISPManager;

#
# Script for add databases account to certain user account in ISPManager
#

die "Params required: host / username / password / db_name / db_user / db_password\n" unless scalar @ARGV == 6;

my $host     = $ARGV[0];
my $login    = $ARGV[1];
my $password = $ARGV[2];
my $db_name  = $ARGV[3];
my $db_user  = $ARGV[4];
my $db_pass  = $ARGV[5];

$API::ISPManager::DEBUG = '';

my %connection_params = (
    username => $login,
    password => $password,
    host     => $host,
    path     => 'manager',
);


my $db_creation_result = API::ISPManager::db::create( {
    %connection_params,
    name        => $db_name,
    dbtype      => 'MySQL',
    dbencoding  => 'default',
    dbuser      => 'newuser', 
    dbusername  => $db_user,
    dbpassword  => $db_pass,
    dbconfirm   => $db_pass,
} );


if ($db_creation_result) {
    print "$db_name success added!\n";
} else {
    warn Dumper($API::ISPManager::last_answer);
}


