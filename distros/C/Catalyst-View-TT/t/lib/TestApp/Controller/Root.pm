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

sub test_includepath : Local {
    my ($self, $c) = @_;
    $c->stash->{message} = ($c->request->param('message') || $c->config->{default_message});
    $c->stash->{template} = $c->request->param('template');
    if ( $c->request->param('additionalpath') ){
        my $additionalpath = Path::Class::dir($c->config->{root}, $c->request->param('additionalpath'));
        $c->stash->{additional_template_paths} = ["$additionalpath"];
    }
    if ( $c->request->param('addpath') ){
        my $additionalpath = Path::Class::dir($c->config->{root}, $c->request->param('addpath'));
        my $p_view = $c->request->param('view');
        my $view = 'TestApp::View::' . ($p_view ? "TT::$p_view" : $c->config->{default_view});
        no strict "refs";
        push @{$view . '::include_path'}, "$additionalpath";
        use strict;
    }
}

sub test_render : Local {
    my ($self, $c) = @_;

    $c->stash->{message} = eval { $c->view('TT::Appconfig')->render($c, $c->req->param('template'), {param => $c->req->param('param') || ''}) };
    if (my $err = $@) {
        $c->response->body($err);
        $c->response->status(403);
    } else {
        $c->stash->{template} = 'test.tt';
    }

}

sub test_msg : Local {
    my ($self, $c) = @_;
    my $tmpl = $c->req->param('msg');

    $c->stash->{message} = $c->view('TT::Appconfig')->render($c, \$tmpl);
    $c->stash->{template} = 'test.tt';
}

sub test_alt_content_type : Local {
    my ($self, $c) = @_;
    $c->stash( message => 'test_alt_content_type');
    $c->forward('View::TT::AltContentType');
}

sub end : Private {
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    my $p_view = $c->request->param('view');
    my $view = 'View::' . ($p_view ? "TT::$p_view" : $c->config->{default_view});
    $c->forward($view);
}

1;
