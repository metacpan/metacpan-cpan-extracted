#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::MockObject::Extends;
use Test::Exception;
use Net::LDAP::Entry;
use lib 't/lib';

use_ok("Catalyst::Authentication::Store::LDAP::Backend");


my $back_without_use_roles = Catalyst::Authentication::Store::LDAP::Backend->new({
    ldap_server => 'ldap://127.0.0.1:555',
    binddn      => 'anonymous',
    bindpw      => 'dontcarehow',
    user_basedn => 'ou=foobar',
    user_filter => '(&(objectClass=inetOrgPerson)(uid=%s))',
    user_scope  => 'one',
    user_field  => 'uid',
});
is $back_without_use_roles->use_roles, 1, 'use_roles enabled be default';

my $back_with_use_roles_disabled = Catalyst::Authentication::Store::LDAP::Backend->new({
    ldap_server => 'ldap://127.0.0.1:555',
    binddn      => 'anonymous',
    bindpw      => 'dontcarehow',
    user_basedn => 'ou=foobar',
    user_filter => '(&(objectClass=inetOrgPerson)(uid=%s))',
    user_scope  => 'one',
    user_field  => 'uid',
    use_roles   => 0,
});
is $back_with_use_roles_disabled->use_roles, 0, 'use_roles disabled when set
to 0';

my $back_with_use_roles_enabled = Catalyst::Authentication::Store::LDAP::Backend->new({
    ldap_server => 'ldap://127.0.0.1:555',
    binddn      => 'anonymous',
    bindpw      => 'dontcarehow',
    user_basedn => 'ou=foobar',
    user_filter => '(&(objectClass=inetOrgPerson)(uid=%s))',
    user_scope  => 'one',
    user_field  => 'uid',
    use_roles   => 1,
});
is $back_with_use_roles_enabled->use_roles, 1, 'use_roles enabled when set to
1';

my (@searches, @binds);
for my $i (0..1) {

    my $back = Catalyst::Authentication::Store::LDAP::Backend->new({
        'ldap_server' => 'ldap://127.0.0.1:555',
        'binddn'      => 'anonymous',
        'bindpw'      => 'dontcarehow',
        'start_tls'   => 0,
        'user_basedn' => 'ou=foobar',
        'user_filter' => '(&(objectClass=inetOrgPerson)(uid=%s))',
        'user_scope'  => 'one',
        'user_field'  => 'uid',
        'use_roles'   => 1,
        'role_basedn' => 'ou=roles',
        'role_filter' => '(&(objectClass=posixGroup)(memberUid=%s))',
        'role_scope'  => 'one',
        'role_field'  => 'userinrole',
        'role_value'  => 'cn',
        'role_search_as_user' => $i,
    });
    $back = Test::MockObject::Extends->new($back);
    my $bind_msg = Test::MockObject->new;
    $bind_msg->mock(is_error => sub {}); # Cause bind call to always succeed
    my $ldap = Test::MockObject->new;
    $ldap->mock('bind', sub { shift; push (@binds, [@_]); return $bind_msg});
    $ldap->mock('unbind' => sub {});
    $ldap->mock('disconnect' => sub {});
    my $search_res = Test::MockObject->new();
    my $search_is_error = 0;
    $search_res->mock(is_error => sub { $search_is_error });
    $search_res->mock(entries => sub {
        return map 
            {   my $id = $_; 
                Test::MockObject->new->mock(
                    get_value => sub { "quux$id" }
                ) 
            }
            qw/one two/
    });
    my @user_entries;
    $search_res->mock(pop_entry => sub { return pop @user_entries });
    $ldap->mock('search', sub { shift; push(@searches, [@_]); return $search_res; });
    $back->mock('ldap_connect' => sub { $ldap });
    my $user_entry = Net::LDAP::Entry->new;
    push(@user_entries, $user_entry);
    $user_entry->dn('ou=foobar');
    $user_entry->add(
        uid => 'somebody',
        cn => 'test',
    );
    my $user = $back->find_user( { username => 'somebody' } );
    isa_ok( $user, "Catalyst::Authentication::Store::LDAP::User" );
    $user->check_password('password');
    is_deeply( [sort $user->roles], 
               [sort qw/quuxone quuxtwo/], 
                "User has the expected set of roles" );

    $search_is_error = 1;
    lives_ok {
        ok !$back->find_user( { username => 'doesnotexist' } ),
            'Nonexistent user returns undef';
    } 'No exception thrown for nonexistent user';

}
is_deeply(\@searches, [ 
    ['base', 'ou=foobar', 'filter', '(&(objectClass=inetOrgPerson)(uid=somebody))', 'scope', 'one'],
    ['base', 'ou=roles', 'filter', '(&(objectClass=posixGroup)(memberUid=test))', 'scope', 'one', 'attrs', [ 'userinrole' ]],
    ['base', 'ou=foobar', 'filter', '(&(objectClass=inetOrgPerson)(uid=doesnotexist))', 'scope', 'one'],
    ['base', 'ou=foobar', 'filter', '(&(objectClass=inetOrgPerson)(uid=somebody))', 'scope', 'one'],
    ['base', 'ou=roles', 'filter', '(&(objectClass=posixGroup)(memberUid=test))', 'scope', 'one', 'attrs', [ 'userinrole' ]],
    ['base', 'ou=foobar', 'filter', '(&(objectClass=inetOrgPerson)(uid=doesnotexist))', 'scope', 'one'],
], 'User searches as expected');
is_deeply(\@binds, [
    [ undef ], # First user search
    [
        'ou=foobar',
        'password',
        'password'
    ], # Rebind to confirm user
    [
        undef
    ], # Rebind with initial credentials to find roles
    [ undef ], # Second user search
    # 2nd pass round main loop
    [  undef ], # First user search
    [
        'ou=foobar',
        'password',
        'password'
    ], # Rebind to confirm user
    [
        'ou=foobar',
        'password',
        'password'
    ], # Rebind with user credentials to find roles
    [ undef ], # Second user search
], 'Binds as expected');

done_testing;
