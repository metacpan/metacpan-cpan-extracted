#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Catalyst::Authentication::Store::LDAP::Backend;
use lib 't/lib';
use LDAPTest;

my $server = LDAPTest::spawn_server();

# the tests  currently don't require a real Catalyst app instance
my $c;

my $stringy_session_value;
subtest "persist_in_session unset" => sub {
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
        }
    );

    my $user = $back->find_user( { username => 'somebody' } );
    ok($stringy_session_value = $user->for_session, 'for_session ok');
    is($stringy_session_value, 'somebody', 'for_session returns correct data');
    ok($back->from_session($c, $stringy_session_value), 'from_session ok');
};

my $hash_session_value;
subtest "persist_in_session 'all'" => sub {
    my $back = Catalyst::Authentication::Store::LDAP::Backend->new(
        {   ldap_server         => LDAPTest::server_host(),
            binddn              => 'anonymous',
            bindpw              => 'dontcarehow',
            start_tls           => 0,
            user_basedn         => 'ou=foobar',
            user_filter         => '(&(objectClass=person)(uid=%s))',
            user_scope          => 'one',
            user_field          => 'uid',
            use_roles           => 0,
            persist_in_session  => 'all',
        }
    );
    my $user = $back->find_user( { username => 'somebody' } );
    ok($hash_session_value = $user->for_session, 'for_session ok');
    is_deeply($hash_session_value,
        {
            persist_in_session => 'all',
            user => $user->user,
            _roles => [],
        },
        "for_session returns correct data");
    ok($back->from_session($c, $hash_session_value), 'from_session ok');
    ok($back->from_session($c, $stringy_session_value), 'from_session ok for stringy value');
};

subtest "persist_in_session 'username'" => sub {
    my $back = Catalyst::Authentication::Store::LDAP::Backend->new(
        {   ldap_server         => LDAPTest::server_host(),
            binddn              => 'anonymous',
            bindpw              => 'dontcarehow',
            start_tls           => 0,
            user_basedn         => 'ou=foobar',
            user_filter         => '(&(objectClass=person)(uid=%s))',
            user_scope          => 'one',
            user_field          => 'uid',
            use_roles           => 0,
            persist_in_session  => 'username',
        }
    );
    my $user = $back->find_user( { username => 'somebody' } );
    ok(my $session = $stringy_session_value = $user->for_session, 'for_session ok');
    is($session, 'somebody', 'for_session returns correct data');
    ok($back->from_session($c, $session), 'from_session ok');
    ok($back->from_session($c, $hash_session_value), 'from_session ok for hash value')
        or diag explain $hash_session_value;
};

done_testing;
