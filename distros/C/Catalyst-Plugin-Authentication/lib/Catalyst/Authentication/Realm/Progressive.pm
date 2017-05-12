package Catalyst::Authentication::Realm::Progressive;

use Carp;
use warnings;
use strict;

use base 'Catalyst::Authentication::Realm';

=head1 NAME

Catalyst::Authentication::Realm::Progressive - Authenticate against multiple realms

=head1 SYNOPSIS

This Realm allows an application to use a single authenticate() call during
which multiple realms are used and tried incrementally until one performs
a successful authentication is accomplished.

A simple use case is a Temporary Password that looks and acts exactly as a
regular password. Without changing the authentication code, you can
authenticate against multiple realms.

Another use might be to support a legacy website authentication system, trying
the current auth system first, and upon failure, attempting authentication against
the legacy system.

=head2 EXAMPLE

If your application has multiple realms to authenticate, such as a temporary
password realm and a normal realm, you can configure the progressive realm as
the default, and configure it to iteratively call the temporary realm and then
the normal realm.

 __PACKAGE__->config(
    'Plugin::Authentication' => {
        default_realm => 'progressive',
        realms => {
            progressive => {
                class => 'Progressive',
                realms => [ 'temp', 'normal' ],
                # Modify the authinfo passed into authenticate by merging
                # these hashes into the realm's authenticate call:
                authinfo_munge => {
                    normal => { 'type' => 'normal' },
                    temp   => { 'type' => 'temporary' },
                }
            },
            normal => {
                credential => {
                    class => 'Password',
                    password_field => 'secret',
                    password_type  => 'hashed',
                    password_hash_type => 'SHA-1',
                },
                store => {
                    class      => 'DBIx::Class',
                    user_model => 'Schema::Person::Identity',
                    id_field   => 'id',
                }
            },
            temp => {
                credential => {
                    class => 'Password',
                    password_field => 'secret',
                    password_type  => 'hashed',
                    password_hash_type => 'SHA-1',
                },
                store => {
                    class    => 'DBIx::Class',
                    user_model => 'Schema::Person::Identity',
                    id_field   => 'id',
                }
            },
        }
    }
 );

Then, in your controller code, to attempt authentication against both realms
you just have to do a simple authenticate call:

 if ( $c->authenticate({ id => $username, password => $password }) ) {
     if ( $c->user->type eq 'temporary' ) {
         # Force user to change password
     }
 }

=head1 CONFIGURATION

=over

=item realms

An array reference consisting of each realm to attempt authentication against,
in the order listed.  If the realm does not exist, calling authenticate will
die.

=item authinfo_munge

A hash reference keyed by realm names, with values being hash references to
merge into the authinfo call that is subsequently passed into the realm's
authenticate method.  This is useful if your store uses the same class for each
realm, separated by some other token (in the L<EXAMPLE> authinfo_mungesection,
the 'realm' is a column on C<Schema::Person::Identity> that will be either
'temp' or 'local', to ensure the query to fetch the user finds the right
Identity record for that realm.

=back

=head1 METHODS

=head2 new ($realmname, $config, $app)

Constructs an instance of this realm.

=head2 authenticate

This method iteratively calls each realm listed in the C<realms> configuration
key.  It returns after the first successful authentication call is done.

=cut

sub authenticate {
    my ( $self, $c, $authinfo ) = @_;
    my $realms = $self->config->{realms};
    carp "No realms to authenticate against, check configuration"
        unless $realms;
    carp "Realms configuration must be an array reference"
        unless ref $realms eq 'ARRAY';
    foreach my $realm_name ( @$realms ) {
        my $realm = $c->get_auth_realm( $realm_name );
        carp "Unable to find realm: $realm_name, check configuration"
            unless $realm;
        my $auth = { %$authinfo };
        $auth->{realm} ||= $realm->name;
        if ( my $info = $self->config->{authinfo_munge}->{$realm->name} ) {
            $auth = Catalyst::Utils::merge_hashes($auth, $info);
        }
        if ( my $obj = $realm->authenticate( $c, $auth ) ) {
            $c->set_authenticated( $obj, $realm->name );
            return $obj;
        }
    }
    return;
}

## we can not rely on inheriting new() because in this case we do not
## load a credential or store, which is what new() sets up in the
## standard realm.  So we have to create our realm object, set our name
## and return $self in order to avoid nasty warnings.

sub new {
    my ($class, $realmname, $config, $app) = @_;

    my $self = { config => $config };
    bless $self, $class;

    $self->name($realmname);
    return $self;
}

=head1 AUTHORS

J. Shirley C<< <jshirley@cpan.org> >>

Jay Kuri C<< <jayk@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008 the aforementioned authors. All rights reserved. This program
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

1;
