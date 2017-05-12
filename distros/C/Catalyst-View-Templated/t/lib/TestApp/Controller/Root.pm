package TestApp::Controller::Root;
use strict;
use warnings;

use base 'Catalyst::Controller';

__PACKAGE__->config(namespace => q{});

sub template_detach :Local {
    my ($self, $c) = @_;
    
    $c->view('View::Something')->template('hello_world');
    $c->stash(hello => 'world');
    
    $c->detach($c->view('View::Something'));
}

sub action_detach :Local {
    my ($self, $c) = @_;
    $c->stash(action => 'detach');    
    $c->detach($c->view('View::Something'));
}

1;
