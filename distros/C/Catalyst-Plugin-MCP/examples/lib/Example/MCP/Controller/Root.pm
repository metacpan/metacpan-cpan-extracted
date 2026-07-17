package Example::MCP::Controller::Root;
use v5.36;
use Moose;
use namespace::autoclean;
use Example::MCP::Providers;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub mcp :Path('/mcp') :Args(0) {
    my ( $self, $c ) = @_;
    $c->mcp_register_provider( Example::MCP::Providers::Tools->new );
    $c->mcp_register_provider( Example::MCP::Providers::Resources->new );
    $c->mcp_dispatch;
}

__PACKAGE__->meta->make_immutable;

1;
