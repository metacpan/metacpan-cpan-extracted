package TestApp::Controller::MyURI;

use parent 'Catalyst::Controller';

sub test_my_uri : Global {
    my ($self, $c) = @_;
    $c->res->output($c->uri_for('/dummy')->mtfnpy)
}

1;
