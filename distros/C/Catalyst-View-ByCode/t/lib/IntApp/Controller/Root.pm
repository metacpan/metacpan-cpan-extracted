package IntApp::Controller::Root;
use strict;
use warnings;
use parent 'Catalyst::Controller';

__PACKAGE__->config(namespace => '');

sub index :Path() :Args(0) {
    my ( $self, $c ) = @_;
    
    $c->response->body('index works');
}

sub simple_template :Local :Args {
    my ( $self, $c, @extras ) = @_;
    
    $c->forward('View::ByCode');
}

1;
