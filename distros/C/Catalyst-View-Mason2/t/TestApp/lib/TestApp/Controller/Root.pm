package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub hello : Local {
    my ( $self, $c ) = @_;

    $c->stash->{name}     = 'Joe';
    $c->stash->{template} = 'greet';
}

sub action : Local {
    my ( $self, $c ) = @_;

    $c->stash->{name} = 'Bob';
}

sub noautoextend : Local {
    my ( $self, $c ) = @_;

    $c->stash->{current_view} = 'Mason2::NoAutoextend';
    $c->stash->{name}         = 'Mary';
    $c->stash->{template}     = '/greet.mc';
}

sub end : ActionClass('RenderView') {
}

1;
