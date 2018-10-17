package StatsApp::Controller::Root;

use Moose;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->res->body('Ok');
    $c->res->content_type('text/plain');
}

1;
