package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => q{});

sub base : Chained('/') PathPart('') CaptureArgs(0) {

}

sub main : Chained('base') PathPart('main') Args(0) {
    my ($self, $ctx) = @_;
    $ctx->stash->{template} = 'main';
}

sub invalid : Chained('base') PathPart('invalid') Args(0) {
    my ($self, $ctx) = @_;
    $ctx->stash->{template} = 'invalid';
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;
