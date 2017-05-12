package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(namespace => q{});

sub default : Action {
    my ($self, $c) = @_;
    $c->res->body( $c->req->base );
    $c->res->content_type('text/plain');
}

__PACKAGE__->meta->make_immutable;

