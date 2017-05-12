package TestApp::Controller::Root;

use Moose;

BEGIN {
  extends 'Catalyst::Controller';
};

__PACKAGE__->config->{'namespace'} = '';

sub index :Path :Args(0) { }

sub default :Path { }

sub language_independent_stuff :Local { }


__PACKAGE__->meta->make_immutable;

1;
