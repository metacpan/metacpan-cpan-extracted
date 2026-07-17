package TestApp::Controller::Root;
use v5.36;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub rpc :Path('/rpc') :Args(0) {
    my ( $self, $c ) = @_;

    # Register handlers (idempotent; fine to do per-request in a test).
    $c->jsonrpc_register( echo => sub ($p) { $p } );
    $c->jsonrpc_register( add  => sub ($p) { $p->{a} + $p->{b} } );

    # No body arg: the plugin reads the raw request body itself.
    $c->jsonrpc_dispatch;
}

1;
