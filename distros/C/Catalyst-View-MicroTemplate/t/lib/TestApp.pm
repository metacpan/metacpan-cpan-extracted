package TestApp;

use strict;
use warnings;

use Catalyst qw/-Debug/;
use Path::Class;

our $VERSION = '0.01';

__PACKAGE__->config(
    name                  => 'TestApp',
    default_message       => 'hi',
    default_view          => 'Default',
    'View::MT::AppConfig' => {
        template_suffix => '.mt',
    },
);

__PACKAGE__->setup;

sub default : Private {
    my ($self, $c) = @_;

    $c->response->redirect($c->uri_for('test'));
}

sub test : Local {
    my ($self, $c) = @_;

    $c->stash->{message} = ($c->request->param('message') || $c->config->{default_message});
}

sub test_extends : Local {
    my ($self, $c) = @_;

    $c->stash->{message} = ($c->request->param('message') || $c->config->{default_message});
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
        my $view = 'TestApp::View::MT::' . ($c->request->param('view') || $c->config->{default_view});
        no strict "refs";
        push @{$view . '::include_path'}, "$additionalpath";
        use strict;
    }
}

sub test_render : Local {
    my ($self, $c) = @_;

    my $out = $c->stash->{message} = $c->view('MT::AppConfig')->render($c, $c->req->param('template'), {param => $c->req->param('param') || ''});
    if (UNIVERSAL::isa($out, 'Template::Exception')) {
        $c->response->body($out);
        $c->response->status(403);
    } else {
        $c->stash->{template} = 'test.tt';
    }

}

sub test_msg : Local {
    my ($self, $c) = @_;
    my $tmpl = $c->req->param('msg');
    
    $c->stash->{message} = $c->view('MT::AppConfig')->render($c, \$tmpl);
    $c->stash->{template} = 'test.tt';
}

sub end : Private {
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    my $view = 'MT::' . ($c->request->param('view') || $c->config->{default_view});
    $c->forward($c->view($view));
}

1;