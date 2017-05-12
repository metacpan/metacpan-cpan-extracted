package Catalyst::Authentication::Credential::Fallback;

use strict;
use warnings;

use base 'Class::Accessor::Fast';

our $VERSION = 1.001;

BEGIN {
    __PACKAGE__->mk_accessors(qw/realm_list realm/);
}

sub new {
    my ( $class, $config, $app, $realm ) = @_;

    my $self = { };
    bless $self, $class;

    if (! defined($config->{realms}) || (ref [] ne ref $config->{realms})) {
        Catalyst::Exception->throw("realms configuration parameter must be an ARRAY ref");
    }
    if (defined($config->{realms}) && (0 == scalar @{$config->{realms}})) {
        Catalyst::Exception->throw("a value in realms configuration parameter is required");
    }

    $self->realm_list($config->{realms});
    $self->realm($realm);
    return $self;
}

sub authenticate {
    my ( $self, $c, $realm, $authinfo ) = @_;

    foreach my $rlm (@{ $self->realm_list }) {
        my $u_obj = eval { $c->authenticate($authinfo, $rlm) };
        return $u_obj if $u_obj;
    }

    return;
}

1;

__END__
 
=pod
 
=head1 NAME
 
Catalyst::Authentication::Credential::Fallback - Try a list of AuthN Realms until one succeeds or all fail
 
=head1 SYNOPSIS
 
    # in your MyApp.pm
    __PACKAGE__->config(
 
        'Plugin::Authentication' => {
            default_realm => 'fallbackrealm',
            realms => {
                fallbackrealm => {
                    credential => {
                        class  => 'Fallback',
                        realms => ['remote', 'ldap', 'anotherrealm'],
                    },
                },
                # ... the other realms (remote, ldap, etc)
                # should follow, as per their own documentation ...
            },
        },
         
    );
 
=head1 DESCRIPTION

This module allows you to configure a sequence of authentication realms to
be used in a Catalyst application. A user will be authentication against one
member of the sequence, or else authentication will fail.

For example, if you have a local password database and also an LDAP server,
then you can use this module to have the application try first the database,
then LDAP, and finally to reject the server. Without this module you would
only be able to associate the user with one authentication realm at any time.
 
=head1 CONFIG
 
=head2 class
 
For this module to be used, you must set this value to "C<Fallback>".
 
=head2 realms

A Perl list of other realms which are tried in order, for user authentication.

You must also fully configure these realms in your application configuration!!
 
=head1 METHODS
 
=head2 authenticate ( $realmname, $authinfo )

Returns the user object if authenticated, else returns nothing.

=head1 AUTHOR
 
Oliver Gorwits <oliver@cpan.org>
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2013 by Oliver Gorwits. 
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
 
=cut
