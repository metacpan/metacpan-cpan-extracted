package Example;
use strict;
use warnings;
use lib 'lib/', 'local/lib/perl5';

our $VERSION = '0.02';

use Dancer2;
use Example::Client::MetaCpan;
use Example::API::System;
use Example::API::MetaCpan;
use Example::EndpointConfig;

use Dancer2::Plugin::RPC::JSONRPC;
use Dancer2::Plugin::RPC::XMLRPC;
use Dancer2::Plugin::RPC::RESTRPC;

use Dancer2::RPCPlugin::DefaultRoute;

# Trail & Error...
$Log::Log4perl::caller_depth = 6;

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
            class        => 'Example::Client::MetaCpan',
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
    for my $plugin (qw{ RPC::JSONRPC RPC::RESTRPC RPC::XMLRPC}) {
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

setup_default_route();
1;

=head1 NAME

Example - An example RPC-application for L<Dancer2::Plugin::RPC>

=head1 SYNOPSIS

    $ cd example
    $ carton install
    $ APP_PORT=3030 carton exec -- bin/example.pl start
    $ carton exec -- bin/do-rpc -u http://localhost:3030/system -c status -t xmlrpc
    $ carton exec -- bin/example.pl stop

=head1 DESCRIPTION

This example application shows a way to use the L<Dancer2::Plugin::RPC> system.

=head2 Use of L<Bread::Board> for dynamcally building parts of applications

=head2 Split Controler from Model

=head2 Different ways of publishing APIs with the RPC-plugins

=over

=item POD

As the L<Example::API::System> module shows, one can use the special
POD-directives C<< =for <plugin-keyword> <rpc-name> <sub-name> [<path>] >> to
publish access to the API.

The code and the POD must be in the C<.pm>-file.

=item CONFIG

As the L<Example::API::MetaCpan> module shows, one can also use the
C<config.yml> file to set up the access to the API.

=back

=head1 COPYRIGHT

E<copy> MMXXII - Abe Timmerman <abeltje@cpan.org>

=cut
