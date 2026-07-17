package Catalyst::Plugin::OAuth2::ResourceServer::Error;
use v5.36;
use Moo;
use namespace::clean;

our $VERSION = '0.003';

has error             => ( is => 'ro' );    # optional: a bare challenge has none
has error_description => ( is => 'ro' );
has scope             => ( is => 'ro' );    # for insufficient_scope
has http_status       => ( is => 'ro', default => 401 );

sub throw ( $class, %args ) {
    die $class->new(%args);
}

=head1 NAME

Catalyst::Plugin::OAuth2::ResourceServer::Error - a Bearer-challenge error

=head1 DESCRIPTION

Thrown by the engine/seam to signal a bearer-auth failure. Attributes: C<error>
(optional RFC 6750 code, one of C<invalid_token> / C<insufficient_scope> /
C<invalid_request>; absent for a plain challenge), C<error_description>,
C<scope> (echoed on C<insufficient_scope>), C<http_status> (default 401). The
seam turns one of these into a C<WWW-Authenticate: Bearer ...> response.

=head1 METHODS

=head2 throw( error => $code, ... )

Construct and C<die> a new instance.

=cut

1;
