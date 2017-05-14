package CatalystX::OAuth2::Request::RequestAuth;
use Moose;

# ABSTRACT: Role for the initial request in the oauth2 flow

with 'CatalystX::OAuth2::Grant';

has client_secret =>
  ( isa => 'Str', is => 'ro', predicate => 'has_client_secret' );
has enable_client_secret => ( isa => 'Bool', is => 'rw', default => 0 );

around _params => sub {
  my $orig = shift;
  return $orig->(@_), qw(client_secret)
};

# cargo-culted, a small refactor of the action roles should remove the need to do this
sub has_approval { 1 }

sub _build_query_parameters {
  my ($self) = @_;

  my %q = $self->has_state ? ( state => $self->state ) : ();

  $self->response_type eq 'code'
    or return {
    error             => 'unsuported_response_type',
    error_description => 'this server does not support "'
      . $self->response_type
      . "' as a method for obtaining an authorization code",
    %q
    };

  $q{response_type} = $self->response_type;

  my $store  = $self->store;
  my $client = $store->find_client( $self->client_id )
    or return {
    error             => 'unauthorized_client',
    error_description => 'the client identified by '
      . $self->client_id
      . ' is not authorized to access this resource'
    };

  $store->verify_client_secret( $self->client_id, $self->client_secret )
    or return {
    error             => 'unauthorized_client',
    error_description => 'the client identified by '
      . $self->client_id
      . ' is not authorized to access this resource'
    }
    if $self->enable_client_secret;

  $q{client_id} = $self->client_id;

  $client->endpoint eq $self->redirect_uri
    or return {
    error => 'invalid_request',
    error_description =>
      'redirection_uri does not match the registered client endpoint'
    };

  $q{redirect_uri} = $self->redirect_uri;

  my $code = $store->create_client_code( $self->client_id );
  $q{code} = $code->as_string;

  return \%q;
}

sub next_action_uri {
  my ( $self, $controller, $c ) = @_;
  $c->uri_for( $controller->_get_auth_token_via_auth_grant_action,
    $self->query_parameters );
}

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Request::RequestAuth - Role for the initial request in the oauth2 flow

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
