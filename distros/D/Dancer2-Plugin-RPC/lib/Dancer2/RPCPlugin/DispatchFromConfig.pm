package Dancer2::RPCPlugin::DispatchFromConfig;
use Moo;

use Dancer2::RPCPlugin::DispatchItem;
use Scalar::Util 'blessed';

has plugin_object => (
    is       => 'ro',
    isa      => sub { blessed($_[0]) },
    required => 1,
);
has plugin => (
    is       => 'ro',
    isa      => sub { $_[0] =~ qr/^(?:jsonrpc|restrpc|xmlrpc)$/ },
    required => 1,
);
has config => (
    is       => 'ro',
    isa      => sub { ref($_[0]) eq 'HASH' },
    required => 1,
);
has endpoint => (
    is       => 'ro',
    isa      => sub { $_[0] && !ref($_[0]) },
    required => 1,
);

sub build_dispatch_table {
    my $self = shift;
    my $app = $self->plugin_object->app;
    my $config = $self->config->{ $self->endpoint };

    my @packages = keys %$config;

    my $dispatch;
    for my $package (@packages) {
        eval "require $package";
        if (my $error = $@) {
            $app->log(error => "Cannot load '$package': $error");
            die "Cannot load $package ($error) in build_dispatch_table_from_config\n";
        }

        my @rpc_methods = keys %{ $config->{$package} };
        for my $rpc_method (@rpc_methods) {
            my $subname = $config->{$package}{$rpc_method};
            $app->log(
                debug => "[bdfc] @{[$self->endpoint]}: $rpc_method => $subname"
            );
            if (my $handler = $package->can($subname)) {
                $dispatch->{$rpc_method} = Dancer2::RPCPlugin::DispatchItem->new(
                    package => $package,
                    code    => $handler
                );
            }
            else {
                die "Handler not found for $rpc_method: $package\::$subname doesn't seem to exist.\n";
            }
        }
    }

    my $dispatch_dump = do {
        require Data::Dumper;
        local ($Data::Dumper::Indent, $Data::Dumper::Sortkeys, $Data::Dumper::Terse) = (0, 1, 1);
        Data::Dumper::Dumper($dispatch);
    };
    $app->log(
        debug => "[dispatch_table_from_config]->{$self->plugin} ", $dispatch_dump
    );

    return $dispatch;
}

1;

__END__

=head1 NAME

Dancer2::RPCPlugin::DispatchFromConfig - Build dispatch-table from the Dancer Config

=head1 SYNOPSIS

    use Dancer2::RPCPlugin::DispatchFromConfig;
    sub dispatch_call {
        my $config = plugin_setting();
        my $dtb = Dancer2::RPCPlugin::DispatchFromConfig->new(
            ...
        );
        return $dtb->build_dispatch_table();
    }

=head1 DESCRIPTION

=head2 $dtb->new(\%parameters)

=head3 Parameters

Named, list:

=over

=item plugin_object => $plugin

=item plugin => <xmlrpc|jsonrpc|jsonrpc>

=item config => $config_from_plugin

=item endpoint => $endpoint

=back

=head3 Responses

An instantiated object.

=head2 $dtb->build_dispatch_table()

=head3 Parameters

None

=head3 Responses

A hashref of rpc-method names as key and L<Dancer2::RPCPlugin::DispatchItem>
objects as values.

=head1 COPYRIGHT

(c) MMXV - Abe Timmerman <abeltje@cpan.org>

=cut
