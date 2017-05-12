package Dancer2::Plugin::Auth::Extensible::Provider::IMAP;

use Carp qw/croak/;
use Dancer2::Core::Types qw/HashRef Str/;
use Net::IMAP::Simple;

use Moo;
with "Dancer2::Plugin::Auth::Extensible::Role::Provider";
use namespace::clean;

our $VERSION = '0.003';

=head1 NAME

Dancer2::Plugin::Auth::Extensible::Provider::IMAP - IMAP authentication provider for Dancer2::Plugin::Auth::Extensible

=head1 DESCRIPTION

This class is a generic IMAP authentication provider.

See L<Dancer2::Plugin::Auth::Extensible> for details on how to use the
authentication framework.

=head1 ATTRIBUTES

=head2 host

IMAP server name or IP address. Required.

=cut

has host => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 options

A hash reference of options to be passed to L<Net::IMAP::Simple/new>.

Defaults to:

    {
        port        => 993,
        use_ssl     => 1,
        ssl_version => 'TLSv1',
    }

=cut

has options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{ port => 993, use_ssl => 1, ssl_version => 'TLSv1' } },
);

=head1 METHODS

=head2 authenticate_user $username, $password

=cut

sub authenticate_user {
    my ( $self, $username, $password ) = @_;
    croak "username and password must be defined"
      unless defined $username && defined $password;

    my $imap = Net::IMAP::Simple->new( $self->host, %{ $self->options } );
    croak "IMAP connect failed: $Net::IMAP::Simple::errstr"
      unless $imap;

    my $ret = $imap->login($username, $password);
    if ( $ret ) {
        $imap->logout;
    }
    else {
        $self->plugin->app->log(
            debug => "IMAP login failed: $Net::IMAP::Simple::errstr" );
    }
    return $ret;
}

=head1 SEE ALSO

L<Dancer2>, L<Dancer2::Plugin::Auth::Extensible>, L<Net::IMAP::Simple>.

=head1 AUTHOR

Peter Mottram (SysPete), C<< <peter at sysnix.com> >>

=head1 BUGS

Please report any bugs or feature requests via the project's GitHub
issue tracker:

L<https://github.com/SysPete/Dancer2-Plugin--Auth-Extensible-Provider-IMAP/issues>

I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes. PRs are always welcome.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Auth::Extensible::Provider::IMAP

You can also look for information at:

=over 4

=item * L<GitHub repository|https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible-Provider-IMAP>

=item * L<meta::cpan|https://metacpan.org/pod/Dancer2::Plugin::Auth::Extensible::Provider::IMAP>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Peter Mottram (SysPete).

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

1; # End of Dancer2::Plugin::Auth::Extensible::Provider::IMAP
