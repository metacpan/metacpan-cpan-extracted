#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 4;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

use File::Temp;

BEGIN { use_ok( 'Apache::Sling' ); }

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;
$sling->{'Verbose'} = $verbose;
$sling->{'Log'}     = $log;
# authn object:
my $authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
ok( $authn->login_user(), "log in successful" );

