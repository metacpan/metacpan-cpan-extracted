package Example;
use lib 'lib/';

our $VERSION = '0.01';

use Dancer ':syntax';
use Example::EndpointConfig;

use Bread::Board;
my $system_api = container 'System' => as {
    container 'apis' => as {
        service 'Example::API::System' => (
            class => 'Example::API::System',
            dependencies => {
                app_version  => literal $VERSION,
                app_name     => literal __PACKAGE__,
                active_since => literal time(),
            },
        );
    };
};
my $example_api = container 'Example' => as {
    container 'clients' => as {
        service 'MetaCpan' => (
            class        => 'Client::MetaCpan',
            lifecycle    => 'Singleton',
            dependencies => {
                map {
                    ( $_ => literal config->{metacpan}{$_} )
                } keys %{ config->{metacpan} },
            },
        );
    };
    container 'apis' => as {
        service 'Example::API::MetaCpan' => (
            class        => 'Example::API::MetaCpan',
            dependencies => {
                mc_client => '../clients/MetaCpan',
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
    for my $plugin (qw/RPC::JSONRPC RPC::RESTRPC RPC::XMLRPC/) {
        $system_config->register_endpoint($plugin, '/system');
    }
}
{
    my $example_config = Example::EndpointConfig->new(
        publish     => 'config',
        bread_board => $example_api,
    );
    my $plugins = config->{plugins};
    for my $plugin (keys %$plugins) {
        for my $path (keys %{$plugins->{$plugin}}) {
            $example_config->register_endpoint($plugin, $path);
        }
    }
}

1;
