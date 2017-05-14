package AuthServer::Controller::OAuth2::ProviderWithSecret;
use Moose;

BEGIN { extends 'Catalyst::Controller::ActionRole' }

use URI;

with 'CatalystX::OAuth2::Controller::Role::Provider';

__PACKAGE__->config(
  store => {
    class        => 'DBIC',
    client_model => 'DB::Client'
  },
  action => { request => { enable_client_secret => 1 } }
);

sub base : Chained('/') PathPart('secret') CaptureArgs(0) {}

sub request : Chained('base') Args(0) Does('OAuth2::RequestAuth') {}

sub grant : Chained('base') Args(0) Does('OAuth2::GrantAuth') {
  my ( $self, $c ) = @_;

  my $oauth2 = $c->req->oauth2;

  $c->user_exists and $oauth2->user_is_valid(1)
    or $c->detach('/passthrulogin');
}

sub token : Chained('base') Args(0) Does('OAuth2::AuthToken::ViaAuthGrant') {}

sub refresh : Chained('base') Args(0) Does('OAuth2::AuthToken::ViaRefreshToken') {}

1;
