package TestApp::Controller::Root;
use strict;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub auto :Private {
    my ($self, $c) = @_;
    $c->res->content_type('text/html');
    1;
}

sub hello :Local {
    my ($self, $c) = @_;
    $c->res->body($c->req->param('q'));
}

sub redirect :Local {
    my ($self, $c) = @_;
    $c->res->redirect('/foo');
}

sub end :Private {
    my ($self, $c) = @_;
    $c->forward( $c->view('MobileJpFilter') );
}

1;
