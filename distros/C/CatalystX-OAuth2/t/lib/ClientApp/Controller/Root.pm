package ClientApp::Controller::Root;
use Moose;
use namespace::autoclean;
use HTTP::Request;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub auth : Local Args(0) {
  my ( $self, $c ) = @_;
  $c->res->body('auth ok') if $c->authenticate();
}

sub lead : Local Args(0) {
  my ( $self, $c ) = @_;
  $c->res->body('ok');
}

sub gold : Local Args(0) {
  my ( $self, $c ) = @_;
  return unless $c->user_exists;
  my $res = $c->user->oauth2->request(
    HTTP::Request->new( GET => 'http://resourceserver/gold' )
  );

  $c->res->body( $res->content );
}

1;
