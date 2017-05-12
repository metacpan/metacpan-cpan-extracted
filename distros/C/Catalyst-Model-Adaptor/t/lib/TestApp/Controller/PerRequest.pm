package TestApp::Controller::PerRequest;
use strict;
use warnings;

use base 'TestApp::BaseController::Adaptor';

__PACKAGE__->config( model => 'PerRequest' );

sub foo :Local {
    my ($self, $c) = @_;
    $c->res->body($c->model($self->model, { foo => 'perrequest' })->foo);
}

1;
