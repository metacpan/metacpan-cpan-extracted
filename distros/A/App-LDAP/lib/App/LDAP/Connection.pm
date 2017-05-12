package App::LDAP::Connection;

use Modern::Perl;

use base 'Net::LDAP';

our $instance;

sub new {
    $instance = Net::LDAP::new(@_);
}

sub instance {
    $instance;
}

1;

=pod

=head1 NAME

App::LDAP::Connection - Singleton of Net::LDAP

=head1 SYNOPSIS

    App::LDAP::Connection->new(
        "ldap://localhost",
        port    => 389,
        version => 3,
        onerror => "die",
    );

    App::LDAP::Connection->instance->bind(
        "cn=admin,dc=example,dc=org",
        password => "password",
    );

    App::LDAP::Connection->instance->search(
        base   => "ou=People,dc=example,dc=org",
        scope  => "sub",
        filter => "uid=foo",
    );

=cut
