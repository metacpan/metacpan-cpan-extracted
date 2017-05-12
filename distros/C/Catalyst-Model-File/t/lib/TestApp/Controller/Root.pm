package TestApp::Controller::Root;

use strict;
use warnings;

use base 'Catalyst::Controller';

__PACKAGE__->config(namespace => '');


sub cd : Global { 
  my ($self, $c) = @_;
  $c->model('File')->cd('foo');
  $c->res->body( $c->model('File')->pwd );
}

sub pwd : Global { 
  my ($self, $c) = @_;
  $c->res->body( $c->model('File')->pwd );
}
