package Catalyst::Plugin::OAuth2::AuthorizationServer::Error;
use v5.36;
use Moo;
use namespace::clean;

our $VERSION = '0.003';

has error             => ( is => 'ro', required => 1 );
has error_description => ( is => 'ro' );
has state             => ( is => 'ro' );
has redirect_uri      => ( is => 'ro' );
has http_status       => ( is => 'ro', default => 400 );

sub throw ( $class, %args ) {
    die $class->new(%args);
}

sub to_response ( $self ) {
    my %body = ( error => $self->error );
    $body{error_description} = $self->error_description
        if defined $self->error_description;
    return ( \%body, $self->http_status );
}

=head1 NAME

Catalyst::Plugin::OAuth2::AuthorizationServer::Error - a structured OAuth error

=head1 DESCRIPTION

Thrown by the engine and the plugin to signal an OAuth error. Attributes:
C<error> (required, the RFC error code string), C<error_description>
(optional), C<state> and C<redirect_uri> (optional, used by the authorize
redirect-on-error path, RFC 6749 4.1.2.1, not the JSON body), C<http_status>
(default 400). C<to_response> returns C<< (\%body, $status) >> for direct
rendering; the body carries only C<error> + C<error_description>.

=head1 METHODS

=head2 throw( error => $code, ... )

Construct and C<die> a new instance.

=head2 to_response

Return the RFC envelope hashref and the HTTP status.

=cut

1;
