package TestApp::Controller::Root;

use strict;
use warnings;
use base qw( Catalyst::Controller );

__PACKAGE__->config->{namespace} = '';

sub login : Local {
  my ($self, $c) = @_;

  $c->session;
  $c->res->body('logged in');
}

sub logout : Local {
  my ($self, $c) = @_;

  $c->res->body('logged out after '. $c->session->{counter} . ' requests' );
  $c->delete_session('logout');
}

sub page : Local {
  my ($self, $c) = @_;

  if ( $c->sessionid ) {
    $c->res->body('you are logged in');
    $c->session->{counter}++;
  }
  else {
    $c->res->body('please login');
  }
}

1;
