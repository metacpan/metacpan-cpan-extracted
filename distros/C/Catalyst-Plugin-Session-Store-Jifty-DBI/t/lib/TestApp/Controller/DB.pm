package TestApp::Controller::DB;

use strict;
use warnings;
use base qw( Catalyst::Controller );

sub setup : Local {
  my ($self, $c) = @_;

  my $database = $c->model('DB')->database;
  if ( $database && -f $database ) {
    $c->model('DB')->disconnect;
    unlink $database;
  }
  $c->model('DB')->setup_database;
  $c->res->body('set up');
}

sub teardown : Local {
  my ($self, $c) = @_;

  my $database = $c->model('DB')->database;
  if ( $database && -f $database ) {
    $c->model('DB')->disconnect;
    unlink $database;
  }
  $c->res->body('teared down');
}

1;
