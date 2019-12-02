package Example::EndpointConfig;
use Moo;
use Scalar::Util qw/ blessed /;

=head1 NAME

Example::EndpointConfig - Takes away the details of L<Dancer::Plugin::RPC>

=head1 SYNOPSIS

    use Dancer ':syntax';
    use Bread::Board;
    use Example::EndpointConfig { plugins => ['RPC::JSONRPC', 'RPC::XMLRPC'] };
    my $config = Example::EndpointConfig->new(
        publish     => 'pod',
        bread_board => container(
            app => as {
                container apis => as {
                    service 'Example::API::MetaCpan' => as (
                        class => 'Example::API::MetaCpan',
                        dependencies => {
                            # attributes needed for instantiation
                            # or objects from the same container
                            mc_client => '../clients/Client::MetaCpan',
                        },
                    ),
                };
                container clients => as {
                    service 'Client::MetaCpan' => as (
                        class => 'Client::MetaCpan',
                        dependencies => {
                            base_uri => literal config->{base_uri},
                    ),
                };
            };
        ),
    );

    $config->register_endpoint('RPC::JSONRPC' => '/metacpan');
    $config->register_endpoint('RPC::XMLRPC'  => '/metacpan');

=head1 ATTRIBUTES

=head2 publish  [required]

This attribute can have the value of B<config> or B<pod>, it will be bassed to
L<Dancer::Plugin::RPC>

=head2 callback [optional]

This attribute is passed directly to L<Dancer::Plugin::RPC>

=head2 bread_board [required]

This is an instatiated L<Bread::Board::Container> object, that defines the
components of this service and their interaction.

=head2 code_wrapper [optional/lazy]

The code-wrapper is passed to L<Dancer::Plugin::RPC>. The default code-wrapper
uses the L<Bread::Board::Container> to spawn the code for the
Remote-Procedure-Call.

=head2 plugin_arguments [optional]

This hashref is directly passed to L<Dancer::Plugin::RPC>

=cut

has publish => (
    is       => 'ro',
    isa      => sub { $_[0] =~ m/^(?:config|pod)$/ },
    required => 1
);
has callback => (
    is       => 'ro',
    isa      => sub { ref($_[0]) eq 'CODE' || !defined($_[0]) },
    required => 0
);
has bread_board => (
    is       => 'ro',
    isa      => sub { blessed($_[0]) eq 'Bread::Board::Container' },
    required => 1
);
has code_wrapper => (
    is   => 'lazy',
    isa  => sub { ref($_[0]) eq 'CODE' },
);
has plugin_arguments => (
    is       => 'ro',
    isa      => sub { ref($_[0]) eq 'HASH' || !defined($_[0]) },
    required => 0,
);

my %_plugin_info;
use Dancer::RPCPlugin::PluginNames;

sub import {
    # Make sure all plugins are loaded before calling
    # `use Example::EndpointConfig;`
    my @loaded_plugins = map {
        (my $module = $_) =~ s{/}{::}g;
        $module =~ s{.pm$}{};
        $module
    } grep { m{^Dancer/Plugin/RPC/} } keys %INC;

    for my $full_plugin (@loaded_plugins) {
        (my $plugin = $full_plugin) =~ s{^Dancer::Plugin::}{};
        eval "use $full_plugin";
        die "Cannot load $full_plugin ($plugin): $@" if $@;

        (my $plugin_name = $plugin) =~ s{RPC::(\w+)}{\L$1};
        $_plugin_info{$plugin} = {
            name      => $plugin_name,
            registrar => $full_plugin->can($plugin_name),
        };
    }
}

=head1 DESCRIPTION

=cut

sub _build_code_wrapper {
    my $self = shift;
    return sub {
        my ($code, $package, $method, @arguments) = @_;
        my $instance = $self->bread_board->resolve(service => "apis/$package");
        return $instance->$code(@arguments);
    };
}

sub _registrar_for_plugin {
    my $self = shift;
    my ($plugin) = @_;
    return $_plugin_info{$plugin}{registrar} // die "Cannot find plugin '$plugin'";
}

=head2 endpoint_config($path)

Returns a config-hash for the C<Dancer::Plugin::RPC::*> plugins.

=cut

sub endpoint_config {
    my $self = shift;
    my ($path) = @_;

    return {
        publish      => $self->publish,
        code_wrapper => $self->code_wrapper,
        (defined $self->callback
            ? (callback => $self->callback)
            : ()
        ),
        (defined $self->plugin_arguments
            ? (%{ $self->plugin_arguments })
            : ()
        ),
    };
}

=head2 register_endpoint($plugin, $path)

=cut

sub register_endpoint {
    my $self = shift;
    my ($plugin, $path) = @_;

    my $registrar = $self->_registrar_for_plugin($plugin);
    $registrar->($path, $self->endpoint_config($path));
}

use namespace::autoclean;
1;

=head1 COPYRIGHT

(c) MMXIX - Abe Timmerman <abeltje@cpan.org>

=cut
