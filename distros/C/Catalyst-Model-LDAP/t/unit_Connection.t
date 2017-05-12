use strict;
use warnings;
use Catalyst::Model::LDAP::Connection;
use Test::More;

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};
plan tests    => 3;

{
    eval {
        my $ldap = Catalyst::Model::LDAP::Connection->new(
            host    => 'example.com',
            base    => 'ou=People,dc=ufl,dc=edu',
            timeout => 2,
        );
    };

    diag($@);
    ok($@, 'failed to connect to invalid host');
}

{
    my $ldap = Catalyst::Model::LDAP::Connection->new(
        host    => 'ldap.ufl.edu',
        base    => 'ou=People,dc=ufl,dc=edu',
        timeout => 2,
    );

    ok(!$@, 'connected to valid host');
    isa_ok($ldap, 'Catalyst::Model::LDAP::Connection');
}
