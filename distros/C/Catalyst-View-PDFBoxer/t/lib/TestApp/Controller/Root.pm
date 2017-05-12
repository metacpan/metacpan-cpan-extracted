package TestApp::Controller::Root;
use base 'Catalyst::Controller';
__PACKAGE__->config(namespace => '');

sub default : Private {
    my ($self, $c) = @_;

    $c->response->redirect($c->uri_for('test'));
}

sub test : Local {
    my ($self, $c) = @_;
    $c->stash->{message} = ($c->request->param('message') || $c->config->{default_message});
    $c->stash->{template} = $c->request->param('template');
}

sub end : Private {
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    my $view = 'View::' . ($c->request->param('view') || $c->config->{default_view});
    $c->forward($view);
}

1;
