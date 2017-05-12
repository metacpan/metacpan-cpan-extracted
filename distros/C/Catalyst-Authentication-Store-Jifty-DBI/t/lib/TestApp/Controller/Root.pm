package TestApp::Controller::Root;

use strict;
use warnings;
use base qw( Catalyst::Controller );

__PACKAGE__->config->{namespace} = '';

sub error : Local {
  my ($self, $c) = @_;

  $c->res->status(500);
  $c->res->body('not ok');
}

1;
