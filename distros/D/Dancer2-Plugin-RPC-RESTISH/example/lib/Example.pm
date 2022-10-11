package Example;
use lib 'lib/';
use Data::Dumper; $Data::Dumper::Indent = 1;

our $VERSION = '0.999';

use Dancer2;

use Dancer2::Plugin::RPC::JSONRPC;
use Dancer2::Plugin::RPC::RESTISH;

use Example::API::System;
use Example::API::MockDB;
use Example::EndpointConfig;

use Bread::Board;
my $system_api = container 'System' => as {
    container 'apis' => as {
        service 'Example::API::System' => (
            class        => 'Example::API::System',
            lifecycle    => 'Singleton',
            dependencies => {
                app_version  => literal $VERSION,
                app_name     => literal __PACKAGE__,
                active_since => literal time(),
            },
        );
    };
};
my $db_api = container 'MockDB' => as {
    container 'apis' => as {
        service 'Example::API::MockDB' => (
            class        => 'Example::API::MockDB',
            lifecycle    => 'Singleton',
            dependencies => {
                db => literal(
                    { persons => {} }
                ),
            },
        );
    };
};
no Bread::Board;

{
    my $system_config = Example::EndpointConfig->new(
        publish          => 'pod',
        bread_board      => $system_api,
        plugin_arguments => {
            arguments => ['Example::API::System'],
        },
    );
    my @plugins = grep { /^RPC::/ } keys %{ config->{plugins} };
    for my $plugin (@plugins) {
        $system_config->register_endpoint($plugin, '/system');
    }
}

{
    my $db_config = Example::EndpointConfig->new(
        publish          => 'config',
        bread_board      => $db_api,
        plugin_arguments => {
            plugin_args => { cors_allow_origin => '*' },
        }
    );
    my @plugins = grep { /^RPC::/ } keys %{ config->{plugins} };
    for my $plugin (@plugins) {
        for my $path (keys %{ config->{plugins}{$plugin} }) {
            $db_config->register_endpoint($plugin, $path);
        }
    }
}

1;
