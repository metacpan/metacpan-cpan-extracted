package Dancer2::Plugin::Auth::Extensible::Provider::LDAP;

use Carp qw/croak/;
use Dancer2::Core::Types qw/HashRef Str/;
use Net::LDAP;

use Moo;
with "Dancer2::Plugin::Auth::Extensible::Role::Provider";
use namespace::clean;

our $VERSION = '0.705';

=head1 NAME 

Dancer2::Plugin::Auth::Extensible::Provider::LDAP - LDAP authentication provider for Dancer2::Plugin::Auth::Extensible

=head1 DESCRIPTION

This class is a generic LDAP authentication provider.

See L<Dancer2::Plugin::Auth::Extensible> for details on how to use the
authentication framework.

=head1 ATTRIBUTES

=head2 host

The LDAP host name or IP address passed to L<Net::LDAP/CONSTRUCTOR>.

Required.

=cut

has host => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 options

Extra options to be passed to L<Net::LDAP/CONSTRUCTOR> as a hash reference.

=cut

has options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

=head2 basedn

The base dn for all searches (e.g. 'dc=example,dc=com').

Required.

=cut

has basedn => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 binddn

This must be the distinguished name of a user capable of binding to
and reading the directory (e.g. 'cn=admin,dc=example,dc=com').

Not required, as some LDAP setups allow for anonymous binding.

=cut

has binddn => (
    is       => 'ro',
    isa      => Str,
    required => 0,
);

=head2 bindpw

The password for L</binddn>.

Not required, as some LDAP setups allow for anonymous binding.

=cut

has bindpw => (
    is       => 'ro',
    isa      => Str,
    required => 0,
);

=head2 username_attribute

The attribute to match when searching for a username.

Defaults to 'cn'.

=cut

has username_attribute => (
    is      => 'ro',
    isa     => Str,
    default => 'cn',
);

=head2 name_attribute

The attribute which contains the full name of the user. See also:

L<Dancer2::Plugin::Auth::Extensible::Role::User/name>.

Defaults to 'displayName'.

=cut

has name_attribute => (
    is      => 'ro',
    isa     => Str,
    default => 'displayName',
);

=head2 user_filter

Filter used when searching for users.

Defaults to '(objectClass=person)'.

=cut

has user_filter => (
    is      => 'ro',
    isa     => Str,
    default => '(objectClass=person)',
);

=head2 role_attribute

The attribute used when searching for role names.

Defaults to 'cn'.

=cut

has role_attribute => (
    is      => 'ro',
    isa     => Str,
    default => 'cn',
);

=head2 role_filter

Filter used when searching for roles.

Defaults to '(objectClass=groupOfNames)'

=cut

has role_filter => (
    is      => 'ro',
    isa     => Str,
    default => '(objectClass=groupOfNames)',
);

=head2 role_member_attribute_name

The attribute of a user object who's value should be the value used to identify
which roles a specific user is a member of.

Defaults to 'dn'

=cut

has role_member_attribute_name => (
    is      => 'ro',
    isa     => Str,
    default => 'dn',
);

=head2 role_member_attribute

The attribute of a role object who's value should be the value of a user's
L</role_member_attribute_name> attribute to look up which roles a user is a
member of.

Defaults to 'member'.

=cut

has role_member_attribute => (
    is      => 'ro',
    isa     => Str,
    default => 'member',
);

sub _bind_ldap {
    my ( $self, $username, $dummy, $password ) = @_;

    my $ldap = $self->ldap or return;

    # If either username or password is defined, ensure we have both,
    # otherwise we cannot bind to LDAP. Otherwise, assume we are going
    # to anonymously bind.
    my $mesg;
    if( !defined $username && !defined $password ) {
        $self->plugin->app->log( debug => "Binding to LDAP anonymously" );
        $mesg = $ldap->bind;
    }
    else {
        croak "username and password must be defined"
            unless defined $username && defined $password;

        $self->plugin->app->log( debug => "Binding to LDAP with credentials" );
        $mesg = $ldap->bind( $username, password => $password );
    }

    return $mesg;
}

=head1 METHODS

=head2 ldap

Returns a connected L<Net::LDAP> object.

=cut

sub ldap {
    my $self = shift;
    Net::LDAP->new( $self->host, %{ $self->options } )
      or croak "LDAP connect failed for: " . $self->host;
}

=head2 authenticate_user $username, $password

=cut

sub authenticate_user {
    my ( $self, $username, $password ) = @_;

    croak "username and password must be defined"
      unless defined $username && defined $password;

    my $user = $self->get_user_details($username) or return;

    my $ldap = $self->ldap or return;

    my $mesg = $self->_bind_ldap( $user->{dn}, password => $password );

    $ldap->unbind;
    $ldap->disconnect;

    return not $mesg->is_error;
}

=head2 get_user_details $username

=cut

sub get_user_details {
    my ( $self, $username ) = @_;

    croak "username must be defined"
      unless defined $username;

    my $ldap = $self->ldap or return;

    my $mesg = $self->_bind_ldap( $self->binddn, password => $self->bindpw );

    if ( $mesg->is_error ) {
        croak "LDAP bind error: " . $mesg->error;
    }

    $mesg = $ldap->search(
        base   => $self->basedn,
        sizelimit => 1,
        filter => '(&'
          . $self->user_filter
          . '(' . $self->username_attribute . '=' . $username . '))',
    );

    if ( $mesg->is_error ) {
        croak "LDAP search error: " . $mesg->error;
    }

    my $user;
    if ( $mesg->count > 0 ) {
        my $entry = $mesg->entry(0);
        $self->plugin->app->log(
            debug => "User $username found with DN: ",
            $entry->dn
        );

        # now get the roles

        my $role_member_attribute_value;
        if ( $self->role_member_attribute_name eq 'dn' ) {
            $role_member_attribute_value = $entry->dn;
        } else {
            $role_member_attribute_value = $entry->get_value( $self->role_member_attribute_name );
        }
        $mesg = $ldap->search(
            base   => $self->basedn,
            filter => '(&'
              . $self->role_filter . '('
              . $self->role_member_attribute . '='
              . $role_member_attribute_value . '))',
        );

        if ( $mesg->is_error ) {
            $self->plugin->app->log(
                warning => "LDAP search error: " . $mesg->error );
        }

        my @roles =
          map { $_->get_value( $self->role_attribute ) } $mesg->entries;

        $user = {
            username => $username,
            name     => $entry->get_value( $self->name_attribute ),
            dn       => $entry->dn,
            roles    => \@roles,
            map { $_ => scalar $entry->get_value($_) } $entry->attributes,
        };
    }
    else {
        $self->plugin->app->log(
            debug => "User not found via LDAP: $username" );
    }

    $ldap->unbind;
    $ldap->disconnect;

    return $user;
}

=head2 get_user_roles

=cut

sub get_user_roles {
    my ( $self, $username ) = @_;

    croak "username must be defined"
      unless defined $username;

    my $user = $self->get_user_details($username) or return;

    return $user->{roles};
}

1;

