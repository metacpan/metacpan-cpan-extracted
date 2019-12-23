use strict;
use warnings;

use Test::Fatal;
use Test::More;
use Dancer2::Plugin::Auth::Extensible::Test;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_ENVDIR}      = 't/environments';
    $ENV{DANCER_ENVIRONMENT} = 'provider-ldap';
}

use Test::Net::LDAP::Mock;

Test::Net::LDAP::Mock->mock_target('ldap://127.0.0.1:389');
Test::Net::LDAP::Mock->mock_target(
    'localhost',
    port   => 389,
    schema => 'ldap'
);

BEGIN {
    my $ldap = Test::Net::LDAP::Mock->new( '127.0.0.1', port => 389 );

    $ldap->mock_root_dse( namingContexts => 'dc=localnet' );

    $ldap->add( 'cn=admin, dc=localnet', attrs => [], );
    $ldap->mock_password( 'cn=admin, dc=localnet', 'Eec8aireiZ0bo7Shooxe' );

    $ldap->add(
        'uid=dave, ou=People, dc=localnet',
        attrs => [
            objectClass =>
              [ 'inetOrgPerson', 'organizationalPerson', 'person', 'top' ],
            cn  => 'David Precious',
            sn  => 'Precious',
            uid => 'dave',
        ]
    );
    $ldap->mock_password( 'uid=dave, ou=People, dc=localnet', 'beer' );
    $ldap->add(
        'cn=BeerDrinker, ou=Groups, dc=localnet',
        attrs => [
            objectClass => [ 'groupOfNames', 'top' ],
            cn          => 'BeerDrinker',
            member      => 'uid=dave, ou=People, dc=localnet',
        ]
    );
    $ldap->add(
        'cn=Motorcyclist, ou=Groups, dc=localnet',
        attrs => [
            objectClass => [ 'groupOfNames', 'top' ],
            cn          => 'Motorcyclist',
            member      => 'uid=dave, ou=People, dc=localnet',
        ]
    );

    $ldap->add(
        'uid=bob, ou=People, dc=localnet',
        attrs => [
            objectClass =>
              [ 'inetOrgPerson', 'organizationalPerson', 'person', 'top' ],
            cn  => 'Bob Smith',
            sn  => 'Smith',
            uid => 'bob',
        ]
    );
    $ldap->mock_password( 'uid=bob, ou=People, dc=localnet', 'cider' );
    $ldap->add(
        'cn=CiderDrinker, ou=Groups, dc=localnet',
        attrs => [
            objectClass => [ 'groupOfNames', 'top' ],
            cn          => 'CiderDrinker',
            member      => 'uid=bob, ou=People, dc=localnet',
        ]
    );

    $ldap->add(
        'cn=burt, ou=People, dc=localnet',
        attrs => [
            objectClass =>
              [ 'inetOrgPerson', 'organizationalPerson', 'person', 'top' ],
            cn           => 'burt',
            sn           => 'Burt',
            displayName  => 'Burt',
            employeeType => 'staff',
        ]
    );
    $ldap->mock_password( 'cn=burt, ou=People, dc=localnet', 'bacharach' );

    $ldap->add(
        'cn=hashedpassword,ou=People,dc=localnet',
        attrs => [
            objectClass =>
              [ 'inetOrgPerson', 'organizationalPerson', 'person', 'top' ],
            cn           => 'hashedpassword',
            sn           => 'hashedpassword',
            displayName  => 'hashedpassword',
            employeeType => 'staff',
        ]
    );
    $ldap->mock_password( 'cn=hashedpassword, ou=People, dc=localnet',
        'password' );

    $ldap->add(
        'cn=bananarepublic, ou=People, dc=localnet',
        attrs => [
            objectClass =>
              [ 'inetOrgPerson', 'organizationalPerson', 'person', 'top' ],
            cn           => 'bananarepublic',
            sn           => 'bananarepublic',
            displayName  => 'bananarepublic',
            employeeType => 'external',
        ]
    );
    $ldap->mock_password( 'cn=bananarepublic, ou=People, dc=localnet',
        'whatever' );

    use Dancer2::Plugin::Auth::Extensible::Provider::LDAP;
    package Dancer2::Plugin::Auth::Extensible::Provider::LDAP;

    no warnings 'redefine';
    sub ldap {
        my $self = shift;
        return $ldap;
    }
}
{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible::Test::App;

}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

Dancer2::Plugin::Auth::Extensible::Test::runtests($app);

done_testing;
