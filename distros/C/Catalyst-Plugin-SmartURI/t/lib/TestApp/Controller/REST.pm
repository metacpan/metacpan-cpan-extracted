package TestApp::Controller::REST;

use parent 'Catalyst::Controller';
use Class::Load ();

eval { Class::Load::load_class('Catalyst::Action::REST') } && eval q{
    sub foo : Global ActionClass('REST') {}

    sub foo_GET {
        my ($self, $c) = @_;

# should break if request_class is not set correctly
        $c->req->accepted_content_types;

        $c->res->output($c->req->uri_with({foo => 'bar'}));
    }
};

1;
