package <% dist_module %>::Controller::Root;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller' }
__PACKAGE__->config(namespace => '');

sub default : Path {
    my ($self, $c) = @_;
    $c->stash(error_msg => 'Page not found');
    $c->detach('/error404');
}

sub denied : Private {
    my ($self, $c) = @_;
    $c->stash(error_msg => 'Access denied');
    $c->res->status(403);
    $c->detach('/error');
}

sub error404 : Private {
    my ($self, $c) = @_;
    unless ($c->stash->{error_msg}) {
        $c->stash(error_msg => 'Page not found. 404');
    }
    $c->res->status(404);
    $c->detach('/error');
}

sub error : Private {
    my ($self, $c) = @_;
    unless ($c->stash->{error_msg}) {
        $c->stash(error_msg => 'Unknown error.');
    }
    $c->stash(template => 'error.tt');
}
sub index : Does('NeedsLogin') : Path : Args(0) { }
sub end : ActionClass('RenderView')             { }
__PACKAGE__->meta->make_immutable;
1;
