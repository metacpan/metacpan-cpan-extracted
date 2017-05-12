package Catalyst::Authentication::Credential::Testing;
use base 'Catalyst::Authentication::Credential::Password';

use strict;
use warnings;

use Carp;
use Catalyst::Exception;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Authentication::Credential::Testing

=head1 SYNOPSIS

    # Setup the auth in your config on your dev machines only
    __PACKAGE__->config(

        'Plugin::Authentication' => {
            default_realm => 'your_realm',
            realms        => {
                your_realm => {
                    credential => {
                        class           => 'Testing',
                        password_field  => 'password',
                        global_password => 'secret',  # password for all users
                    },
                },
            },
        },

    );

=head1 DESCRIPTION

When your developing an app it is often convenient to be able to log in as any
user. You can either achieve this by disabling authentication (but then you
can't test failed logins) or by setting all the passwords to be the same
(which is annoying).

Or you can use this module and set one password for all users at the
authentication level. This leaves the rest of your code untouched.

=head1 HOW IT WORKS

This module is based on L<Catalyst::Authentication::Credential::Password> and
overides the C<new> and C<check_password> methods.

=head2 new

Checks that the config is complete.

=head2 check_password

Returns true if the password is the same as that set in the config, false
otherwise.

=cut

sub new {
    my ( $class, $config, $app, $realm ) = @_;

    my $self = { _config => $config };
    bless $self, $class;

    $self->realm($realm);

    foreach my $key (qw( global_password password_field )) {

        # we just want to check that this config exists
        next if $self->_config->{$key};

        # produce a message that should be helpful enough to the user that
        # they can debug using it.
        my $msg
            = "ERROR in %s: you must specify '%s' in your credential config";
        Catalyst::Exception->throw( sprintf( $msg, __PACKAGE__, $key ) );

    }

    return $self;
}

sub check_password {
    my ( $self, $user, $authinfo ) = @_;

    # get the values out
    my $password        = $authinfo->{ $self->_config->{password_field} };
    my $global_password = $self->_config->{global_password};

    # success if the two passwords are the same
    return $password eq $global_password;
}

=head1 SEE ALSO

L<Catalyst::Authentication::Credential::Password>

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

