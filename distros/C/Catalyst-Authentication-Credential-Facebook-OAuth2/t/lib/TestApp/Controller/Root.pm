package TestApp::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub auth : Local {
    my ($self, $ctx) = @_;

    my $user = $ctx->authenticate({
        scope => ['offline_access', 'publish_stream'],
    });

    $ctx->detach unless $user;

    $ctx->response->body('success');
}

__PACKAGE__->meta->make_immutable;

1;
