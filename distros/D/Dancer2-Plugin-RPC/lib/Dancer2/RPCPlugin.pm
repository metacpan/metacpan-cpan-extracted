package Dancer2::RPCPlugin;
use Moo::Role;

with qw(
    Dancer2::RPCPlugin::ValidationTemplates
    MooX::Params::CompiledValidators
);

our $VERSION = '2.00';

use Dancer2::RPCPlugin::DispatchFromConfig;
use Dancer2::RPCPlugin::DispatchFromPod;
use Dancer2::RPCPlugin::DispatchItem;
use Dancer2::RPCPlugin::DispatchMethodList;
use Dancer2::RPCPlugin::PluginNames;

# returns xmlrpc for Dancer2::Plugin::RPC::XMLRPC
# returns jsonrpc for Dancer2::Plugin::RPC::JSONRPC
# returns restrpc for Dancer2::Plugin::RPC::RESTRPC
sub rpcplugin_tag {
    my $full_name = ref($_[0]) ? ref($_[0]) : $_[0];
    (my $proto = $full_name) =~ s{.*::}{};
    return "\L${proto}";
}

sub dispatch_builder {
    my $self = shift;
    $self->validate_positional_parameters(
        [
            $self->parameter(endpoint  => $self->Required, {store => \my $endpoint}),
            $self->parameter(publish   => $self->Required, {store => \my $publish}),
            $self->parameter(arguments => $self->Optional, {store => \my $arguments}),
            $self->parameter(settings  => $self->Optional, {store => \my $settings}),
        ],
        \@_
    );

    $publish //= 'config';
    if ($publish eq 'config') {
        return sub {
            $self->app->log(
                debug => "[build_dispatch_table_from_config]"
            );
            my $dispatch_builder = Dancer2::RPCPlugin::DispatchFromConfig->new(
                plugin_object => $self,
                plugin        => $self->rpcplugin_tag,
                config        => $settings,
                endpoint      => $endpoint,
            );
            return $dispatch_builder->build_dispatch_table();
        };
    }
    elsif ($publish eq 'pod') {
        return sub {
            $self->app->log(
                debug => "[build_dispatch_table_from_pod]"
            );
            my $dispatch_builder = Dancer2::RPCPlugin::DispatchFromPod->new(
                plugin_object => $self,
                plugin        => $self->rpcplugin_tag,
                packages      => $arguments,
                endpoint      => $endpoint,
            );
            return $dispatch_builder->build_dispatch_table();
        };
    }

    return $publish;
}

sub partial_method_lister {
    my $self = shift;
    $self->validate_parameters(
        {
            $self->parameter(protocol => $self->Required, {store => \my $protocol}),
            $self->parameter(endpoint => $self->Required, {store => \my $endpoint}),
            $self->parameter(methods  => $self->Required, {store => \my $methods}),
        },
        { @_ }
    );

    my $lister = Dancer2::RPCPlugin::DispatchMethodList->new();
    $lister->set_partial(
        protocol => $protocol,
        endpoint => $endpoint,
        methods  => $methods,
    );
    return $lister;
}

sub code_wrapper {
    my $self = shift;
    $self->validate_positional_parameters(
        [ $self->parameter(config => $self->Required, {store => \my $config}) ],
        \@_
    );
    return $config->{code_wrapper}
        ? $config->{code_wrapper}
        : sub {
            my $code = shift;
            my $pkg  = shift;
            $code->(@_);
        };
}

1;

__END__

=head1 NAME

Dancer2::RPCPlugin - Role to support generic dispatch-table-building

=head1 DESCRIPTION

=head2 dispatch_builder(%parameters)

=head3 Parameters

Positional:

=over

=item 1. endpoint

=item 2. publish

=item 3. arguments (list of packages for POD-publishing)

=item 4. settings (config->{plugins}{RPC::proto})

=back

=head2 rpcplugin_tag

=head3 Parameters

None.

=head3 Responses

    <jsonrpc|restrpc|xmlrpc>

=head2 dispatch_item(%parameters)

=head3 Parameters

Named:

=over

=item code => $code_ref [Required]

=item package => $package [Optional]

=back

=head3 Responses

An instance of the class L<Dancer2::RPCPlugin::DispatchItem>.

=head2 partial_method_lister

Setup the structure for listing the rpc-methods that should be in the dispatch-table.

=head3 Arguments

Named:

=over

=item protocol => $plugin-name

=item endpoint => $endpoint

=item methods => $list_of_methodnames

=back

=head2 code_wrapper

Returns a CodeRef that will be used in the execution of the remote procedure call.

=head3 Arguments

Positional:

=over

=item \%config

A hashref that may contain a C<code_wrapper> key and value.

=back

=head3 Responses

When passed via the C<\%config> HashRef, that code_wrapper, otherwise the default code_wrapper:

    sub {
        my $code = shift;
        my $pkg  = shift;
        $code->(@_);
    }

=begin internal

=head2 ValidationTemplates

These are internal validation templates for the C<dispatch_builder> sub.

=end internal

=head1 COPYRIGHT

E<copy> MMXXII - Abe Timmerman <abeltje@cpan.org>

=cut
