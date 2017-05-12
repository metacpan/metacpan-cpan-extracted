package TestApp::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN {
    extends 'Catalyst::Controller::ActionRole';
}

__PACKAGE__->config(
    namespace    => '',
    action_roles => ['MatchRequestMethod'],
);

sub default : Path Args {
    my ($self, $ctx) = @_;
    $ctx->response->body('default');
}

sub get : Path('foo') Method('GET') {
    my ($self, $ctx) = @_;
    $ctx->response->body('get');
}

sub post : Path('foo') Method('POST') {
    my ($self, $ctx) = @_;
    $ctx->response->body('post');
}

sub get_or_post : Path('bar') Method('GET') Method('POST') {
    my ($self, $ctx) = @_;
    $ctx->response->body('get or post');
}

sub any_method : Path('baz') {
    my ($self, $ctx) = @_;
    $ctx->response->body('any');
}

__PACKAGE__->meta->make_immutable;

1;
