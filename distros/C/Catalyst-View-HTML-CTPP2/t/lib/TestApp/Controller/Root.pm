package TestApp::Controller::Root;

use strict;
use warnings;

__PACKAGE__->config(namespace => q{});

use base qw/Catalyst::Controller/;

sub default : Private {
    my ($self, $c) = @_;

    $c->response->redirect($c->uri_for('test'));
}

sub test : Local {
    my ($self, $c) = @_;

    $c->stash->{message} = ($c->request->param('message') || $c->config->{default_message});
}

sub end : Private {
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    my $view = 'View::HTML::CTPP2::' . ($c->request->param('view') || $c->config->{default_view});
    $c->forward($view);
}

1;

