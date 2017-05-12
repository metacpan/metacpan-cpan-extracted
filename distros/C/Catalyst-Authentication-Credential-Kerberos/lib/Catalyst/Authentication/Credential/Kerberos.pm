package Catalyst::Authentication::Credential::Kerberos;
use base 'Class::Accessor::Fast';

use strict;
use warnings;

use Carp;
use Authen::Krb5::Simple;
use Catalyst::Exception;

our $VERSION = '0.01';

BEGIN {
    __PACKAGE__->mk_accessors(qw/ _config realm error_msg /);
}

=head1 NAME

Catalyst::Authentication::Credential::Kerberos

=head1 SYNOPSIS

    __PACKAGE__->config(

        'Plugin::Authentication' => {
            default_realm => 'your_realm',
            realms        => {
                your_realm => {
                    credential => {
                        class          => 'Kerberos',
                        password_field => 'password',
                        username_field => 'windows_username',
                        kerberos_realm => 'YOUR.REALM.HERE',
                    },
                },
            },
        },

    );

=head1 DESCRIPTION

This module allows you to authenticate your users against a Kerberos server.

=head1 CONFIG

=head2 class (required)

Must be set to C<Kerberos> so that this module is used for auth.

=head2 username_field (optional)

The name of the username field - defaults to C<username>.

=head2 password_field (optional)

The name of the password field - defaults to C<password>.

=head2 kerberos_realm (optional)

If not specified then the default for the local machine will be used. Note
that this is the Kerberos realm, which has nothing to do with the
Catalyst::Authentication realm.

=head1 METHODS

=head2 new

Checks that the config is complete by setting defaults if needed.

=cut

sub new {
    my ( $class, $config, $app, $realm ) = @_;

    my $self = { _config => $config };
    bless $self, $class;

    $self->realm($realm);

    # Set defaults if needed
    $self->_config->{password_field} ||= 'password';
    $self->_config->{username_field} ||= 'username';

    return $self;
}

=head2 authenticate

Find the user and check their password. Returns the user if success, false
otherwise. Will produce debug log output if in debug mode.

=cut

sub authenticate {
    my ( $self, $c, $realm, $authinfo ) = @_;

    # because passwords may be in a hashed format, we have to make sure that
    # we remove the password_field before we pass it to the user routine, as
    # some auth modules use all data passed to them to find a matching user...
    my $userfindauthinfo = { %{$authinfo} };
    delete( $userfindauthinfo->{ $self->_config->{'password_field'} } );

    my $user_obj = $realm->find_user( $userfindauthinfo, $c );

    # check that we got a user we can use
    if ( !ref($user_obj) ) {
        $c->log->debug("Unable to locate user matching user info provided")
            if $c->debug;
        return;
    }

    # check the password and return the user if it was good
    return $user_obj
        if $self->check_password( $user_obj, $authinfo );

    # didn't return - some issue with the password.
    $c->log->debug( $self->error_msg ) if $c->debug;
    return;

}

=head2 check_password

Returns true if the username and password were accepted by the kerberos
server, false otherwise.

=cut

sub check_password {
    my ( $self, $user, $authinfo ) = @_;

    # get the values out
    my $username       = $authinfo->{ $self->_config->{username_field} };
    my $password       = $authinfo->{ $self->_config->{password_field} };
    my $kerberos_realm = $self->_config->{kerberos_realm};

    # create the kerberos object and try to auth the user
    my %krb_config = ();
    $krb_config{realm} = $kerberos_realm if $kerberos_realm;
    my $krb = Authen::Krb5::Simple->new(%krb_config);
    my $authen = $krb->authenticate( $username, $password );

    return 1 if $authen;

    # store the error
    my $errmsg = $krb->errstr();
    $self->error_msg("Authentication failed for user: '$username': $errmsg");

    return;
}

=head1 SEE ALSO

L<Catalyst::Authentication::Credential::Password>, L<Authen::Krb5::Simple>

=head1 GOTCHAS

Remember that once authenticated your users will have a session created for
them. If you want to block them from the system you will need to not only
change their password / disable their accounts in kerberos, but also
invalidate their sessions.

=head1 BUGS

Test suite is minimal.

=head1 AUTHOR

Edmund von der Burg C<<evdb@ecclestoad.co.uk>>

Bug reports and suggestions very welcome.

=head1 ACKNOWLEDGMENTS

Developed whilst working at Foxtons - L<http://www.foxtons.co.uk>. Thank you
for letting me open source this code.

=head1 COPYRIGHT

Copyright (C) 2008 Edmund von der Burg. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

THERE IS NO WARRANTY.

=cut

1;

