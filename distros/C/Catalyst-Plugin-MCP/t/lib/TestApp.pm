package TestApp;
use v5.36;
use Catalyst qw/
    +Catalyst::Plugin::JSONRPC::Server
    +Catalyst::Plugin::MCP
/;

our $VERSION = '0.001';

__PACKAGE__->setup;

1;
