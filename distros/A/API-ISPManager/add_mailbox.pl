#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use API::ISPManager;

#
# Script for add mail account to certain mail-domain in ISPManager
#

die "Params required: host / username / password / mailbox_name / password\n" unless scalar @ARGV == 5;

my $host          = $ARGV[0];
my $login         = $ARGV[1];
my $password      = $ARGV[2];
my $mailbox_name  = $ARGV[3];
my $mailbox_pass  = $ARGV[4];

my @raw_mail = split '@', $mailbox_name;

my $name   = $raw_mail[0];
my $domain = $raw_mail[1];

$API::ISPManager::DEBUG = '';

my %connection_params = (
    username => $login,
    password => $password,
    host     => $host,
    path     => 'manager',
);


my $mailbox_creation_result = API::ISPManager::mailbox::create( {
    %connection_params,
    quota   => 0,
    name    => $name,   
    domain  => $domain,
    passwd  => $mailbox_pass,
    confirm => $mailbox_pass,
} );


if ($mailbox_creation_result) {
    print "$mailbox_name success added!\n";
} else {
    warn Dumper($API::ISPManager::last_answer);
}


