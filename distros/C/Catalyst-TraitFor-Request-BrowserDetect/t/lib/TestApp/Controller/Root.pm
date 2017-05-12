package TestApp::Controller::Root;
our $VERSION = '0.02';


use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub index : Path Args(0) {
    my ($self, $ctx) = @_;
    $::browser = $ctx->request->browser;
    $ctx->response->body('foo');
}

1;
