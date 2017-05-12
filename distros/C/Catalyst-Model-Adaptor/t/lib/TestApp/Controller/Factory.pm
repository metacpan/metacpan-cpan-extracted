package TestApp::Controller::Factory;
use strict;
use warnings;

use base 'TestApp::BaseController::Adaptor';

__PACKAGE__->config( model => 'Factory' );

sub foo :Local {
    my ($self, $c) = @_;
    $c->res->body($c->model($self->model, foo => 'factory')->foo);
}

1;
