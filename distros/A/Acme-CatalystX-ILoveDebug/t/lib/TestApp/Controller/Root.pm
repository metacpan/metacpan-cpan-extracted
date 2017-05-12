package TestApp::Controller::Root;
use Moose;
use Test::More;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => q{});

sub base : Chained('/') PathPart('') CaptureArgs(0) {}

sub main : Chained('base') PathPart('') Args(0) {
    my ($self, $ctx) = @_;
    $ctx->res->body($ctx->uri_for($self->action_for('foo'), 222));
}

sub foo : Chained('base') PathPart('foo') Args(1) {
    my ($self, $ctx, $arg) = @_;
    is $arg, 222, 'Arg is 222 in foo';
    $ctx->res->body($ctx->uri_for($self->action_for('foo'), 333, { bar => 'baz'}));
}

sub end : Action {
    my ($self, $ctx) = @_;
    die("ERK") if $ctx->req->parameters->{dump_info} && $ctx->debug;
}

__PACKAGE__->meta->make_immutable;

