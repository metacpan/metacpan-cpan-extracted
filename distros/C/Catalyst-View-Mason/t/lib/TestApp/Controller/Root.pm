package TestApp::Controller::Root;

use strict;
use warnings;
use base qw/Catalyst::Controller/;

__PACKAGE__->config(namespace=>'');

sub test : Local {
    my ($self, $c) = @_;

    $c->stash->{message} = ($c->request->param('message') || $c->config->{default_message});
}

sub test_set_template : Local {
    my ($self, $c) = @_;

    $c->forward('test');
    $c->stash->{template} = 'test';
}

sub test_content_type : Local {
    my ($self, $c) = @_;

    $c->forward('test');

    $c->stash->{template} = '/test';

    $c->response->content_type('text/html; charset=iso8859-1')
}

sub exception : Local {
    my ($self, $c) = @_;

    $c->log->abort(1); #silence errors
}

sub render : Local {
    my ($self, $c) = @_;

    my $out = $c->view->render(
            $c, $c->request->param('template'),
            { param => $c->req->param('param') || '' },
    );

    $c->response->body($out);

    if (ref($out) && $out->isa('HTML::Mason::Exception')) {
        $c->response->status(403);
    }
}

sub match : Local Args(1) {
    my ($self, $c) = @_;

    $c->stash->{message} = $c->request->args->[0];
}

sub action_match : Local Args(1) {
    my ($self, $c) = @_;

    $c->stash->{message} = $c->request->args->[0];
}

sub globals : Local {
}

sub additional_globals : Local {
}

sub comp_path : Local {
    my ($self, $c) = @_;

    $c->stash->{param} = 'bar';
}

sub end : Private {
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    my ($requested_view) = $c->request->param('view');
    $c->forward($c->view( $requested_view ? "Mason::$requested_view" : () ));
}


1;
