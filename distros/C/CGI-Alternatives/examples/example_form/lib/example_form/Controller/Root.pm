package example_form::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub example_form : Local {

    my ( $self,$c ) = @_;

    $c->stash(
        template => 'example_form.html.tt',
        result   => $c->req->params->{user_input},
    );
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
