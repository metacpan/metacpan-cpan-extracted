package Example::JSONRPC::Controller::Root;
use v5.36;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

# A JSON-RPC endpoint. Handlers are registered per request (cheap here); a real
# app would register them once at setup. Each handler gets the request's params
# and returns the result; an unregistered method yields a -32601 error.
sub rpc :Path('/rpc') :Args(0) {
    my ( $self, $c ) = @_;
    $c->jsonrpc_register( echo => sub ($p) { $p } );
    $c->jsonrpc_register( sum  => sub ($p) { my $t = 0; $t += $_ for @$p; $t } );
    $c->jsonrpc_dispatch;
}

__PACKAGE__->meta->make_immutable;

1;
