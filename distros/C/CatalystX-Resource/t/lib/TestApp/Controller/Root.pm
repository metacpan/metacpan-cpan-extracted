package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->response->body( 'TestApp' );
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

# CatalystX::Resource detaches to /error404 in case of an error
sub error404 : Private {
    my ( $self, $c ) = @_;
    unless ($c->stash->{error_msg}) {
        $c->stash(error_msg => 'Page not found. 404');
    }
    $c->res->status(404);
    $c->stash(template => 'error.tt');
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
