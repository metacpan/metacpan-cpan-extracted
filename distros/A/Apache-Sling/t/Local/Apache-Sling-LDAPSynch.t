#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::LDAPSynch' ); }

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
my $authn = new Apache::Sling::Authn(\$sling);
throws_ok { my $ldap_synch = new Apache::Sling::LDAPSynch() } qr/no authn provided!/, 'Check creating ldap_synch object croaks without authn';
my $ldap_synch = new Apache::Sling::LDAPSynch('','','','','',\$authn);
isa_ok $ldap_synch, 'Apache::Sling::LDAPSynch', 'ldap_synch';
ok( Apache::Sling::LDAPSynch::parse_attributes(), 'Check parse_attributes function without args' );
my $ldap_attrs = 'a,b';
my $sling_attrs = 'c,d';
my @ldap_attrs_array;
my @sling_attrs_array;
ok( Apache::Sling::LDAPSynch::parse_attributes($ldap_attrs, $sling_attrs, \@ldap_attrs_array, \@sling_attrs_array), 'Check parse_attributes function with args' );
$sling_attrs = 'c,d,e';
throws_ok { Apache::Sling::LDAPSynch::parse_attributes($ldap_attrs, $sling_attrs, \@ldap_attrs_array, \@sling_attrs_array) } qr/Number of ldap attributes must match number of sling attributes, 2 != 3/, 'Check parse_attributes function with mismatched args';
ok( $ldap_synch->check_for_property_modifications(), 'Check check_for_property_modifications function' );

ok( my $ldap_synch_config = Apache::Sling::LDAPSynch->config($sling), 'check config function' );
ok( Apache::Sling::LDAPSynch->run($sling,$ldap_synch_config), 'check run function' );
throws_ok { Apache::Sling::LDAPSynch->run() } qr/No ldap_synch config supplied!/, 'check run function croaks with no config supplied';
