package Catalyst::Plugin::Authentication::CDBI::Basic;
use strict;
use NEXT;
use MIME::Base64;

our $VERSION = '0.02';

=head1 NAME

Catalyst::Plugin::Authentication::CDBI::Basic - (DEPRECATED) Basic Authorization with Catalyst

=head1 SYNOPSIS

    use Catalyst qw/Session::FastMmap Authentication::CDBI Authentication::CDBI::Basic/;

    __PACKAGE__->config(
        authentication => {
            # Configure Autentication::CDBI
            :
            # and
            basic => {
                realm => 'Require Authorization', # Basic realm

                no_session => 1,                  # disable auth caching (optional)

                # auto error responsing
                #   use View::TT
                template => '401.tt',
                view     => 'MyApp::V::TT',

                #   or plain text
                error_msg => 'Authentication Failed !',
            },
        },
    );

=head1 DEPRECATION NOTICE

This module has been deprecated. The use of a new Authentication style is recommended.

See L<Catalyst::Plugin::Authetnication> for detail.

=head1 DESCRIPTION

This plugin privide Basic Authorization mechanism for Catalyst Application.

This plugin is required  C::P::Authentication::CDBI, for users info.
And also use Session Plugin for authorization caching (optional but recommanded).

=head1 METHODS

=over 4

=item prepare

=cut

sub prepare {
    my $c = shift;
    $c = $c->NEXT::prepare(@_);

    my $auth_header = $c->req->header('Authorization') || '';
    $c->log->debug("Authorization: $auth_header") if $auth_header;
    if ($auth_header =~ /^Basic (.+)$/) {
        my ( $username, $password ) = split q{:}, decode_base64($1);

        $c->log->debug("username: $username");
        $c->log->debug("password: $password");

        ( $c->can('session_login') and !$c->config->{authentication}->{basic}->{no_session} )
            ? $c->session_login($username, $password)
            : $c->login($username, $password)
                if $username and $password;
    }

    unless ( $c->req->{user} ) {
        $c->res->header('WWW-Authenticate' => q[Basic realm="]
                                            . ( $c->config->{authentication}->{basic}->{realm} || 'Require Authorization' )
                                            . q["] );

        if ( $c->config->{authentication}->{basic}->{error_msg}
                 or $c->config->{authentication}->{basic}->{view} & $c->config->{authentication}->{basic}->{template} ) {
            $c->res->status(401);

            if ( $c->config->{authentication}->{basic}->{error_msg} ) {
                $c->res->body( $c->config->{authentication}->{basic}->{error_msg} );
            }
            else {
                $c->stash->{template} = $c->config->{authentication}->{basic}->{template};
                $c->forward( $c->config->{authentication}->{basic}->{view} );
            }
        }
    }

    $c;
}

=back

=head1 AUTHOR

Daisuke Murase E<lt>typester@cpan.orgE<gt>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Catalyst::Plugin::Authentication::CDBI>

=cut

1;
