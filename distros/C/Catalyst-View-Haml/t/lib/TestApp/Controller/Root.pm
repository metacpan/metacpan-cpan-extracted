package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN {
    extends 'Catalyst::Controller';
}

__PACKAGE__->config(namespace => '');

sub test_render
    :Local
{
    my ($self, $c) = @_;

    $c->stash->{message} = eval {
        my $template = Path::Class::File->new( $c->path_to('root'), $c->req->param('template') );
        $c->view('Haml::Appconfig')->render($c, $template, {param => $c->req->param('param') || ''})
    };
    if (my $err = $@) {
        $c->response->body($err);
        $c->response->status(403);
    } else {
        $c->stash->{template} = 'test.haml';
    }
}


sub end 
    :Private
{
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    my $view = 'View::Haml::' . ($c->request->param('view') || $c->config->{default_view});
    $c->forward($view);
}


__PACKAGE__->meta->make_immutable();

1;
