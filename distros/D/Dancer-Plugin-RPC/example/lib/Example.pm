package Example;
use warnings;
use strict;
use lib 'lib/';

use Dancer ':syntax';
use Dancer::Plugin::RPC::XMLRPC;
use Dancer::Plugin::RPC::JSONRPC;
use Dancer::Plugin::RPC::RESTRPC;

use MetaCpanClient;
use System;
use MetaCpan;

# Map plugin-name to protocol-tag
my %plugin_map = (
    'RPC::XMLRPC'  => 'xmlrpc',
    'RPC::JSONRPC' => 'jsonrpc',
    'RPC::RESTRPC' => 'restrpc',
);
# Map protocol-tag to registrar function
my %proto_map = (
    xmlrpc  => \&xmlrpc,
    jsonrpc => \&jsonrpc,
    restrpc => \&restrpc,
);

# prepare MetaCpanClient
my $mc_client = MetaCpanClient->new(
    endpoint => config->{metacpan}{endpoint},
);
# Prepare the code-wrapper for the classes
my $code_wrapper = sub {
    my ($code, $package, $method, @arguments) = @_;
    my $instance = instance_for_module($package);
    return $instance->$code(@arguments);
};

# Register all endpoints for all configured plugins
my $plugins = config->{plugins};
for my $plugin (keys %$plugins) {
    next if !exists($plugin_map{$plugin});

    my $registrar = $proto_map{ $plugin_map{$plugin} };
    for my $path (keys %{ $plugins->{$plugin} }) {
        debug("register $plugin => $path");

        $registrar->(
            $path => {
                publish      => 'config',
                code_wrapper => $code_wrapper,
            }
        );
    }
}

# Every class has its own instantiation
sub instance_for_module {
    my ($module) = @_;

    my $instance;
    if ($module eq 'MetaCpan') {
        $instance = MetaCpan->new(mc_client => $mc_client);
    }
    else {
        $instance = System->new();
    }
    return $instance;
}

1;
