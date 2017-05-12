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

isa_ok( $back, "Catalyst::Authentication::Store::LDAP::Backend", 'LDAP backed' );

foreach (
    ['somebody', 'Some Body'],
    ['sunnO)))', 'Sunn O)))'],
    ['some*',    'Some Star'],
) {
    my ($username, $name) = @$_;

    my $user = $back->find_user( { username => $username } );
    isa_ok( $user, "Catalyst::Authentication::Store::LDAP::User", "find_user('$username') result" );
    my $displayname = $user->displayname;
    is( $displayname, $name, 'Display name' );

}

done_testing;
