package Catalyst::Plugin::Authentication::Store::HTTP;
use strict;
use warnings;

our $VERSION = '0.05';

use Catalyst::Exception;
use Catalyst::Plugin::Authentication::Store::HTTP::Backend;

=head1 NAME

Catalyst::Plugin::Authentication::Store::HTTP - Remote HTTP authentication storage

=head1 SYNOPSIS

    # load plugins
    use Catalyst qw/
        Session
        Session::State::Cookie
        Session::Store::FastMmap

        Authentication
        Authentication::Store::HTTP
        Authentication::Credential::Password
        # or Authentication::Credential::HTTP
        /;

    # configure your authentication host
    MyApp->config(
        authentication => {
            http => {
                auth_url => 'http://example.com/',
            },
        },
    );

    # and in action
    sub login : Global {
        my ( $self, $c ) = @_;

        $c->login( $username, $password );
    }

=head1 DESCRIPTION

This module is Catalyst authentication storage plugin that
authenticates based on a URL HTTP HEAD fetch using the supplied
credentials.  If the fetch succeeds then the authentication succeeds.

L<LWP::UserAgent> is used to fetch the URL which requires authentication,
so any authentication method supported by that module can be used.

Remote authentication methods known to work are:-

=over 4

=item *

Basic

=item *

Digest

=item *

NTLM - but see notes below

=back

This is re-implementation of L<Catalyst::Plugin::Authentication::Basic::Remote>.

=head1 CONFIGURATION

Configuration is done in the standard Catalyst fashion.  All
configuration keys are under C<authentication/http>.

The supported keys are:-

=over 4

=item auth_url

The URL that is fetched to demonstrate that the supplied credentials
work.  This can be any URL that L<LWP::UserAgent> will support and
that will support a C<HEAD> method.  This item must be supplied.

=item keep_alive

A boolean value that sets whether keep alive is used on the URL
fetch. This must be set for NTLM authentication - and the I<ntlm>
configuration key forces it to be set.

=item domain

An optional domain value for authentication.  If set the presented
username for authentication has this domain prepended to it - this is
really of use only for NTLM authentication mode.

=item ntlm

A boolean value that should be set if NTLM authentication is
required. If this is set then I<domain> must be set and I<keep_alive>
is forced on.

=back

=head1 EXTENDED METHODS

=head2 setup

Checks the configuration information and sets up the
C<default_auth_store>.  This method is not intended to be called
directly by user code.


=cut

sub setup {
    my $c = shift;

    unless ($c->config->{authentication}{http}{auth_url}) {
        Catalyst::Exception->throw(
            message => q/Require auth_url for Authentication::Store::HTTP/);
    }

    if ($c->config->{authentication}{http}{ntlm}) {

        # force keep_alive to be set
        $c->config->{authentication}{http}{keep_alive} ||= 1;

        #
        # domain needs to be set
        unless ($c->config->{authentication}{http}{domain}) {
            Catalyst::Exception->throw(message =>
                  q/Require domain to be set in NTLM mode for Authentication::Store::HTTP/
            );
        }
    }

    $c->default_auth_store(
        Catalyst::Plugin::Authentication::Store::HTTP::Backend->new(
            $c->config->{authentication}{http}
        )
    );

    $c->NEXT::setup(@_);
}

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut

1;

