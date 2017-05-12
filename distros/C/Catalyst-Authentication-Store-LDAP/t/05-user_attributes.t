#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use LDAPTest;

my $server = LDAPTest::spawn_server();

use_ok("Catalyst::Authentication::Store::LDAP::Backend");

my $back = Catalyst::Authentication::Store::LDAP::Backend->new(
    {   'ldap_server' => LDAPTest::server_host(),
        'binddn'      => 'anonymous',
        'bindpw'      => 'dontcarehow',
        'start_tls'   => 0,
        'user_basedn' => 'ou=foobar',
        'user_filter' => '(&(objectClass=person)(uid=%s))',
        'user_scope'  => 'one',
        'user_field'  => 'uid',
        'use_roles'   => 0,
        'entry_class' => 'EntryClass',
    }
);

isa_ok( $back, "Catalyst::Authentication::Store::LDAP::Backend" );
my $user = $back->find_user( { username => 'somebody' } );
isa_ok( $user, "Catalyst::Authentication::Store::LDAP::User" );

#Check DN
ok $user->dn,"Get DN from AUTOLOAD"; #THIS ONLY WORKS BECAUSE dn is included as a user attribute in the test LDAP server.
ok defined $user->has_attribute('dn'),"Get dn from has_attribute";

#Check Username
ok $user->username, "Get username from AUTOLOAD";
ok defined $user->has_attribute('username'),"Get username from has_attribute";

#Make sure both methods match output
ok $user->username eq $user->has_attribute('username'),"username from AUTOLOAD and has_attribute should match";
ok $user->dn eq $user->has_attribute('dn'),"dn from AUTOLOAD and has_attribute should match";

done_testing;
