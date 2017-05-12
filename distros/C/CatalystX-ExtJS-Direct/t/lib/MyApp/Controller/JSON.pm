#
# This file is part of CatalystX-ExtJS-Direct
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package
  MyApp::Controller::JSON;
  
use Moose;
BEGIN { extends 'Catalyst::Controller' };
with 'CatalystX::Controller::ExtJS::Direct';

sub index : PathPart('') Direct {
    my ($self, $c) = @_;
    $c->stash->{json} = { foo => 'bar' };
    $c->forward($c->view('JSON'));
}

sub exception : PathPart('') Direct {
    my ($self, $c) = @_;
    $c->res->content_type('application/json');
    $c->error(bless({}, 'ABC'))
}


1;