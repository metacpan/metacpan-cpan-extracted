package TestApp::Controller::Root;
our $VERSION = '0.01';

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub foo : Path {
    my ($self, $ctx) = @_;
    $ctx->response->body(
        $ctx->request->is_xhr ? 1 : 0
    );
}

__PACKAGE__->meta->make_immutable;

1;
