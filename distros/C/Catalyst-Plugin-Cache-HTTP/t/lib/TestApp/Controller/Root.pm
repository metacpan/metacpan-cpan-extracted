package TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config(namespace => '');

use base 'Catalyst::Controller';

my $CONTENT_TYPE = 'text/html';
my $LAST_MODIFIED = 'Thu, 21 Feb 2008 10:37:07 GMT';
my $ETAG = 'foo-0815-bar';
my $BODY = '<h1>It works</h1>';

sub root : PathPart('') Chained('/') CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->response->header('Content-Type' => $CONTENT_TYPE);
    $c->response->body($BODY);
}

sub main : PathPart('') Chained('/root') Args(0) {}

sub etag : PathPart Chained('/root') Args(0) {
    my ($self, $c) = @_;

    $c->response->header('ETag' => $ETAG);
}

sub last_modified : PathPart Chained('/root') Args(0) {
    my ($self, $c) = @_;

    $c->response->header('Last-Modified' => $LAST_MODIFIED);
}

sub all : PathPart Chained('/root') Args(0) {
    my ($self, $c) = @_;

    $c->response->header('ETag' => $ETAG);
    $c->response->header('Last-Modified' => $LAST_MODIFIED);
}

1;
