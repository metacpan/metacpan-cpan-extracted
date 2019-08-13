package TestApp::Controller::Root;

use Moose;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->res->body('ok');
    $c->res->content_type('text/plain');
}

1;
