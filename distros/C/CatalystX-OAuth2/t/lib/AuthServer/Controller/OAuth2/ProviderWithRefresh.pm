package AuthServer::Controller::OAuth2::ProviderWithRefresh;
use Moose;

BEGIN { extends 'Catalyst::Controller::ActionRole' }

use URI;

with 'CatalystX::OAuth2::Controller::Role::Provider';

__PACKAGE__->config(
  store => {
    class        => 'DBIC',
    client_model => 'DB::Client'
  }
);

sub base : Chained('/') PathPart('withrefresh') CaptureArgs(0) {
}

sub request : Chained('base') Args(0) Does('OAuth2::RequestAuth') {
}

sub grant : Chained('base') Args(0) Does('OAuth2::GrantAuth') {
  my ( $self, $c ) = @_;

  my $oauth2 = $c->req->oauth2;

  $c->user_exists and $oauth2->user_is_valid(1)
    or $c->detach('/passthrulogin');

  $oauth2->approved(1) if $c->req->query_parameters->{approved};
}

sub token : Chained('base') Args(0) Refresh
  Does('OAuth2::AuthToken::ViaAuthGrant') {
}

sub refresh : Chained('base') Args(0)
  Does('OAuth2::AuthToken::ViaRefreshToken') {
}

1;
