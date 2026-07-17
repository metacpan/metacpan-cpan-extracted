package TestApp::Controller::Root;
use v5.36;
use Moose;
use namespace::autoclean;
use TestProviders;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub mcp :Path('/mcp') :Args(0) {
    my ( $self, $c ) = @_;
    $c->mcp_register_provider( TestProviders::Tools->new );
    $c->mcp_register_provider( TestProviders::Resources->new );
    $c->mcp_dispatch;
}

1;
