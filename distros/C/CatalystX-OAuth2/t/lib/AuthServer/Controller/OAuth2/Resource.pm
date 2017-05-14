package AuthServer::Controller::OAuth2::Resource;
use Moose;

BEGIN { extends 'Catalyst::Controller::ActionRole' }

with 'CatalystX::OAuth2::Controller::Role::WithStore';

__PACKAGE__->config(
  store => {
    class => 'DBIC',
    client_model => 'DB::Client'
  }
);

sub gold : Chained('/') Args(0) Does('OAuth2::ProtectedResource') {
  my ( $self, $c ) = @_;
  $c->res->body( 'gold' );
}

sub lead :Chained('/') Args(0) {}

1;
