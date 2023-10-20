package MyApp05::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
    namespace => '',
);

# default to avoid "No default action defined"
sub foo : Path : ActionClass('REST') { }

sub foo_GET  {
    my ($self, $c) = @_;
    
    $c->res->body('index');
}

sub foo_POST {
    my ($self, $c) = @_;
    $c->res->body('POST received');
}

sub index {
    my ($self, $c) = @_;
    $c->res->body("DEFAULT");
}

1;

