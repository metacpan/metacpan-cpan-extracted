package Catalyst::Authentication::Credential::OAuth2;
use Moose;
use MooseX::Types::Common::String qw(NonEmptySimpleStr);
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON::Any;
use Moose::Util;

# ABSTRACT: Authenticate against OAuth2 servers


has [qw(grant_uri token_uri client_id)] => (
  is       => 'ro',
  isa      => NonEmptySimpleStr,
  required => 1,
);

has token_uri_method => (is=>'ro', required=>1, default=>'GET');
has token_uri_post_content_type => (is=>'ro', required=>1, default=>'application/x-www-form-urlencoded');
has extra_find_user_token_fields => (is=>'ro', required=>0, predicate=>'has_extra_find_user_token_fields');
has scope => (is=>'ro', required=>0, predicate=>'has_scope');
has audience => (is=>'ro', required=>0, predicate=>'has_audience');

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

    my %find_user_fields = (token => $token->{access_token});
    if($self->has_extra_find_user_token_fields) {
      $find_user_fields{$_} = $token->{$_} for @{$self->extra_find_user_token_fields};
    }
    return $realm->find_user( \%find_user_fields, $ctx );
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
    redirect_uri  => $callback_uri,
  };
  $query->{state} = $auth_info->{state} if exists $auth_info->{state};
  $query->{scope} = $self->scope if $self->has_scope;
  $query->{scope} = $auth_info->{scope} if exists $auth_info->{scope};
  $query->{audience} = $self->audience if $self->has_audience;
  $query->{audience} = $auth_info->{audience} if exists $auth_info->{audience};

  $uri->query_form($query);
  return $uri;
}

my $j = JSON::Any->new;

sub request_access_token {
  my ( $self, $callback_uri, $code, $auth_info ) = @_;
  my $uri   = URI->new( $self->token_uri );
  my @data = (
    client_id    => $self->client_id,
    redirect_uri => "$callback_uri", #stringify for JSON
    code         => $code,
    grant_type   => 'authorization_code');
  push(@data, (state=>$auth_info->{state})) if exists $auth_info->{state};
  push(@data, (client_secret=>$self->client_secret)) if $self->has_client_secret;

  my $req;
  if($self->token_uri_method eq 'GET') {
    $uri->query_form(+{@data});
    $req = GET $uri;
  } elsif($self->token_uri_method eq 'POST') {
    if($self->token_uri_post_content_type eq 'application/json') {
      $req = POST $uri, 'Content_Type' => 'application/json', Content => $j->to_json(+{@data});
    } elsif($self->token_uri_post_content_type eq 'application/x-www-form-urlencoded') {
      $req = POST $uri, 'Content_Type' => 'application/x-www-form-urlencoded', Content => \@data;
    } else {
      die "Unrecognized 'token_uri_post_content_type' of '${\$self->token_uri_post_content_type}'";
    }
  } else {
    die "Unrecognized 'token_uri_method' of '${\$self->token_uri_method}'";
  }

  my $response = $self->ua->request($req);
  if($response->is_success) {
    my $data = $j->jsonToObj( $response->decoded_content ); # Eval wrap
    return $data;
  } else {
    return;
  }
}

1;

__END__

=pod

=head1 NAME

Catalyst::Authentication::Credential::OAuth2 - Authenticate against OAuth2 servers

=head1 VERSION

version 0.001008

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

=head1 ATTRIBUTES

=head2 grant_uri

=head2 token_uri

=head2 client_id

Required attributes that you get from your Oauth2 provider

=head2 client_secret

optional secret code from your Oauth2 provider (you need to review the docs from
your provider).

=head2 scope

Value of 'scope' field submitted to the grant_uri.  Optional.

=head2 audience

Value of 'audience' field submitted to the grant_uri.  Optional.

=head2 token_uri_method

Default is GET; some providers require POST

=head2 token_uri_post_content_type

Default is 'application/x-www-form-urlencoded', some providers support 'application/json'. 

=head2 has_extra_find_user_token_fields

By default we call ->find_user on the store with a hashref that contains key 'token' and the
value of the access_token (which we get from calling the 'token_uri').  The results of calling
the token_uri is usually a JSON named array structure which can contain other fields such as
id_token (typically a JWT).  You can set this to an arrayref of extra fields you want to pass.

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
