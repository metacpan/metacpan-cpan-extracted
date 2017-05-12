package TestApp::Controller::Root;
use base 'Catalyst::Controller';
__PACKAGE__->config(namespace => '');

sub default : Private {
    my ($self, $c) = @_;

    $c->response->redirect($c->uri_for('test'));
}

sub test : Local {
    my ($self, $c) = @_;
    $c->stash->{message} = $c->request->param('message') || $c->config->{default_message};
}

sub test_prepend_dispatchto : Local {
    my ($self, $c) = @_;
    $c->stash->{message}  = $c->request->param('message') || $c->config->{default_message};
    $c->stash->{template} = $c->request->param('template');
    if ( my $class = $c->request->param('additionalclass') ){
        $c->stash->{prepend_template_classes} = [$class];
    }
    if ( my $class = $c->request->param('addclass') ){
        my $view = $c->view($c->request->param('view') || $c->config->{default_view});
        push @{ $view->dispatch_to}, $class;
    }
    if ( my $class = $c->request->param('setclass') ){
        my $view = $c->view($c->request->param('view') || $c->config->{default_view});
        $view->dispatch_to([$class]);
    }
}

sub test_append_dispatchto : Local {
    my ($self, $c) = @_;
    $c->stash->{message}  = $c->request->param('message') || $c->config->{default_message};
    $c->stash->{template} = $c->request->param('template');
    if ( my $class = $c->request->param('additionalclass') ){
        $c->stash->{append_template_classes} = [$class];
    }
    if ( my $class = $c->request->param('addclass') ){
        my $view = $c->view($c->request->param('view') || $c->config->{default_view});
        push @{ $view->dispatch_to}, $class;
    }
    if ( my $class = $c->request->param('setclass') ){
        my $view = $c->view($c->request->param('view') || $c->config->{default_view});
        $view->dispatch_to([$class]);
    }
}

sub test_render : Local {
    my ($self, $c) = @_;

    my $out = eval {
        $c->stash->{message} = $c->view('Appconfig')->render(
            $c, $c->req->param('template'),
            {param => $c->req->param('param') || ''}
        )
    };

    if (my $err = $@) {
        $c->response->body($err);
        $c->response->status(403);
    } else {
        $c->stash->{template} = 'test';
    }

}

sub test_msg : Local {
    my ($self, $c) = @_;
    my $tmpl = $c->req->param('msg');
    # Test commented-out in 07render.t: TD does not support template text as a
    # scalar ref, because templates are not text, they're code.
    $c->stash->{message} = $c->view('AppConfig')->render($c, \$tmpl);
    $c->stash->{template} = 'test';
}

sub end : Private {
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    my $view = 'View::' . ($c->request->param('view') || $c->config->{default_view});
    $c->forward($view);
}

1;
