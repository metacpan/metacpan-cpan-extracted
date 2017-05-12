package TestApp::Controller::Root;

use parent 'Catalyst::Controller';

sub test_uri_for_redirect : Global {
    my ($self, $c) = @_;
    $c->res->redirect($c->uri_for('/test_uri_for_redirect'));
}

sub test_req_uri_with : Global {
    my ($self, $c) = @_;
    $c->res->output($c->req->uri_with({
        the_word_that_must_be_heard => 'mtfnpy' 
    })); 
}

sub test_uri_object : Global {
    my ($self, $c) = @_;
    $c->res->output($c->uri_for('/test_uri_object')->path);
}

sub per_request : Global {
    my ($self, $c) = @_;
    $c->uri_disposition('relative');
    $c->res->output($c->uri_for('/dummy'));
}

sub host_header : Global {
    my ($self, $c) = @_;
    $c->uri_disposition('host-header');
    $c->res->output($c->uri_for('/dummy'));
}


sub host_header_with_port : Global {
    my ($self, $c) = @_;
    $c->uri_disposition('host-header');
    $c->res->output($c->uri_for('/dummy'));
}

sub req_uri_class : Global {
    my ($self, $c) = @_;
    $c->res->output(ref($c->req->uri).' '.$c->req->uri);
}

sub req_referer_class : Global {
    my ($self, $c) = @_;
    $c->res->output(ref $c->req->referer);
}

sub say_referer : Global {
    my ($self, $c) = @_;

    my $r = $c->req->referer;

    $c->res->output((!defined $r) ? 'undef' : $r eq '' ? 'blank' : $r);
}

sub dummy : Global {}

1;
