#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More;

use lib 't/lib';
use LDAPTest;

my $server = LDAPTest::spawn_server();

use_ok("Catalyst::Authentication::Store::LDAP::Backend");

my $back = Catalyst::Authentication::Store::LDAP::Backend->new(
    {   'ldap_server' => LDAPTest::server_host(),

        # can test the timeout SKIP with this
        'ldap_server_options' =>
            { timeout => -1, debug => $ENV{PERL_DEBUG} || 0 },

        'binddn'      => 'anonymous',
        'bindpw'      => 'dontcarehow',
        'start_tls'   => 0,
        'user_basedn' => 'ou=foobar',
        'user_filter' => '(&(objectClass=person)(uid=%s))',
        'user_scope'  => 'one',
        'user_field'  => 'uid',
        'use_roles'   => 0,
    }
);
isa_ok( $back, "Catalyst::Authentication::Store::LDAP::Backend" );

ok( my $user_mixed = $back->find_user( { username => 'SOmeBOdy' } ), "find_user (mixed case)" );
isa_ok( $user_mixed, "Catalyst::Authentication::Store::LDAP::User" );

done_testing;
