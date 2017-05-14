package Catalyst::Authentication::Credential::OAuth2;
use Moose;
use MooseX::Types::Common::String qw(NonEmptySimpleStr);
use LWP::UserAgent;
use JSON::Any;
use Moose::Util;

# ABSTRACT: Authenticate against OAuth2 servers


has [qw(grant_uri token_uri client_id)] => (
  is       => 'ro',
  isa      => NonEmptySimpleStr,
  required => 1,
);

has client_secret => (
  is        => 'ro',
  isa       => NonEmptySimpleStr,
  required  => 0,
  predicate => 'has_client_secret'
);

has ua => ( is => 'ro', default => sub { LWP::UserAgent->new } );

sub BUILDARGS {
  my ( $class, $config, $app, $realm ) = @_;
  Moose::Util::ensure_all_roles( $realm, 'CatalystX::OAuth2::ClientInjector' );
  Moose::Util::ensure_all_roles( $realm->store, 'CatalystX::OAuth2::ClientPersistor');
  return $config;
}

sub authenticate {
  my ( $self, $ctx, $realm, $auth_info ) = @_;
  my $callback_uri = $self->_build_callback_uri($ctx);

  unless ( defined( my $code = $ctx->request->params->{code} ) ) {
    my $auth_url = $self->extend_permissions( $callback_uri, $auth_info );
    $ctx->response->redirect($auth_url);

    return;
  } else {
    my $token =
      $self->request_access_token( $callback_uri, $code, $auth_info );
    die 'Error validating verification code' unless $token;
    return $realm->find_user( { token => $token->{access_token}, }, $ctx );
  }
}

sub _build_callback_uri {
  my ( $self, $ctx ) = @_;
  my $uri = $ctx->request->uri->clone;
  $uri->query(undef);
  return $uri;
}

sub extend_permissions {
  my ( $self, $callback_uri, $auth_info ) = @_;
  my $uri   = URI->new( $self->grant_uri );
  my $query = {
    response_type => 'code',
    client_id     => $self->client_id,
    redirect_uri  => $callback_uri
  };
  $query->{state} = $auth_info->{state} if exists $auth_info->{state};
  $uri->query_form($query);
  return $uri;
}

my $j = JSON::Any->new;

sub request_access_token {
  my ( $self, $callback_uri, $code, $auth_info ) = @_;
  my $uri   = URI->new( $self->token_uri );
  my $query = {
    client_id    => $self->client_id,
    redirect_uri => $callback_uri,
    code         => $code,
    grant_type   => 'authorization_code'
  };
  $query->{state} = $auth_info->{state} if exists $auth_info->{state};
  $uri->query_form($query);
  my $response = $self->ua->get($uri);
  return unless $response->is_success;
  return $j->jsonToObj( $response->decoded_content );
}

1;

__END__

=pod

=head1 NAME

Catalyst::Authentication::Credential::OAuth2 - Authenticate against OAuth2 servers

=head1 VERSION

version 0.001004

=head1 SYNOPSIS

    __PACKAGE__->config(
      'Plugin::Authentication' => {
        default => {
          credential => {
            class     => 'OAuth2',
            grant_uri => 'http://authserver/request',
            token_uri => 'http://authserver/token',
            client_id => 'dead69beef'
          },
          store => { class => 'Null' }
        }
      }
    );

=head1 DESCRIPTION

This module implements authentication via OAuth2 credentials, giving you a
user object which stores tokens for accessing protected resources.

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
