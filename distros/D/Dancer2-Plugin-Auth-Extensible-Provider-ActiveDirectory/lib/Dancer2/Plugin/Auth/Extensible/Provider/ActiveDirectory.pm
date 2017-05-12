package Dancer2::Plugin::Auth::Extensible::Provider::ActiveDirectory;

use feature qw/state/;
use Carp qw/croak/;
use Dancer2::Core::Types qw/HashRef Str Int ArrayRef/;
use Auth::ActiveDirectory;

use Moo;
with "Dancer2::Plugin::Auth::Extensible::Role::Provider";
use namespace::clean;

our $VERSION = '0.04';

=head1 NAME

Dancer2::Plugin::Auth::Extensible::Provider::ActiveDirectory - ActiveDirectory authentication provider for Dancer2::Plugin::Auth::Extensible

=head1 DESCRIPTION

This class is an ActiveDirectory authentication provider.

See L<Dancer2::Plugin::Auth::Extensible> for details on how to use the
authentication framework.

=head1 ATTRIBUTES

=head2 host

The ActiveDirectory host name or IP address passed to L<Auth::ActiveDirectory>.

Required.

=cut

has host => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 port

The ActiveDirectory port. Defaults to 389.

=cut

has port => (
    is       => 'ro',
    isa      => Int,
    default  => 389,
);

=head2 timeout

Connection timeout in seconds. Defaults to 60.

=cut

has timeout => (
    is       => 'ro',
    isa      => Int,
    timeout  => 60,
);

=head2 domain

The ActiveDirectory domain.

Required.

=cut

has domain => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 principal

The ActiveDirectory principal.

Required.

=cut

has principal => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 allowed_groups

List of groups allowed to login. If empty, all groups are allowed.

=cut

has allowed_groups => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { return [] },
);

=head1 METHODS

=head2 authenticate_user $username, $password

Returns true if the user could be authenticated. Returns also false if the user could be
authenticated, but is member of any allowed group.

=cut

sub authenticate_user {
    my ( $self, $username, $password ) = @_;

    croak "username and password must be defined"
      unless defined $username && defined $password;

    my $ad = $self->_active_directory or return;

    my $user = $ad->authenticate( $username, $password ) || return;

    my $allowed = 1;
    if ( @{ $self->allowed_groups } ) {
        $allowed = 0;
        for my $allowed_group ( @{ $self->allowed_groups } ) {
            if (grep { $_ eq $allowed_group } map { $_->name } @{ $user->groups } ) {
                $allowed = 1;
                last;
            }
        }
    }

    if ($allowed) {
        $self->_user_cache($username, $user);
        return 1;
    }
    return;
}

=head2 get_user_details $username

=cut

sub get_user_details {
    my ( $self, $username ) = @_;

    croak "username must be defined" unless defined $username;

    my $user = $self->_user_cache($username);
    if (!$user) {
        $self->plugin->app->log( debug => "User information not found: $username" );
    }

    return {
        username     => $user->uid,
        display_name => $user->display_name,
        firstname    => $user->firstname,
        surname      => $user->surname,
        email        => $user->mail,
        roles        => [ map { $_->name } @{ $user->groups } ],
    };
}

=head2 get_user_roles

=cut

sub get_user_roles {
    my ( $self, $username ) = @_;

    croak "username must be defined"
      unless defined $username;

    my $user = $self->_user_cache($username);
    if (!$user) {
        $self->plugin->app->log( debug => "User information not found: $username" );
        return;
    }

    return [ map { $_->name } @{ $user->groups } ];
}

=head1 PRIVATE METHODS

=head2 _active_directory

Returns a connected L<Auth::ActiveDirectory> object.

=cut

sub _active_directory {
    my $self = shift;

    my $ad = Auth::ActiveDirectory->new(
        host      => $self->host,
        port      => $self->port,
        timeout   => $self->timeout,
        domain    => $self->domain,
        principal => $self->principal,
    ) || croak "ActiveDirectory connect failed for: " . $self->host;

    return $ad;
}

=head2 _user_cache $username [, $value]

Implements the user data cache. As we can only receive the user 
information from L<Auth::ActiveDirectory> when authenticating,
we save it in the cache and can use it when asked via the get_user_details or get_user_roles methods.

=cut

sub _user_cache {
    my ( $self, $username, $value ) = @_;
    state $usercache = {};
    return $usercache->{$username} if not defined $value;
    return $usercache->{$username} = $value;
}

1;

=head1 TODO

I was not able to create useful tests for this module. I tried to adopt the tests
from L<Dancer2::Plugin::Auth::Extensible::Provider::LDAP>, but I was not able to fill
the mock object with the correct data for the Test App to work. Please tell me if you
can help out.


=head1 AUTHOR

Dominic Sonntag, C<< <dsonntag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-auth-extensible-provider-activedirectory at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-Auth-Extensible-Provider-ActiveDirectory>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Auth::Extensible::Provider::ActiveDirectory

If you want to contribute to this module, write me an email or create a
Pull request on Github: L<https://github.com/sonntagd/Dancer2-Plugin-Auth-Extensible-Provider-ActiveDirectory>


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Dominic Sonntag.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Dancer2::Plugin::Auth::Extensible::Provider::ActiveDirectory
