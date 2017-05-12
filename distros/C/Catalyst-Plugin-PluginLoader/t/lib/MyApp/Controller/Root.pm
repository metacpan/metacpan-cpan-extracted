package MyApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub root : Chained('/') PathPart('') {
  my ($self, $c) = @_;

  $c->res->body($c->plugin_one . " " . $c->plugin_two . " " . $c->plugin_three);
}

sub test_role : Local {
  my ($self, $c) = @_;

  $c->res->body($c->hello_from_role);
}

1;
