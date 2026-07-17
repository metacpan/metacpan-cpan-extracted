package Example::MCP;
use v5.36;
use Catalyst qw/
    +Catalyst::Plugin::JSONRPC::Server
    +Catalyst::Plugin::MCP
/;

our $VERSION = '0.001';

__PACKAGE__->config(
    'Catalyst::Plugin::MCP' => {
        server_info => { name => 'example-mcp', version => '0.001' },
    },
);

__PACKAGE__->setup;

1;
