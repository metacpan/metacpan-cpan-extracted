package Dancer::RPCPlugin::DispatchFromConfig;
use warnings;
use strict;
use Exporter 'import';
our @EXPORT = qw/dispatch_table_from_config/;

use Dancer qw/error warning info debug/;

use Dancer::RPCPlugin::DispatchItem;
use Params::Validate ':all';

sub dispatch_table_from_config {
    my $args = validate(
        @_,
        {
            key      => { regex => qr/^(xmlrpc|jsonrpc|restrpc)$/ },
            config   => { type  => HASHREF },
            endpoint => { type  => SCALAR, optional => 0 },
        }
    );
    my $config = $args->{config}{ $args->{endpoint} };

    my @pkgs = keys %$config;

    my $dispatch;
    for my $pkg (@pkgs) {
        eval "require $pkg";
        error("Loading $pkg: $@") if $@;

        my @rpc_methods = keys %{ $config->{$pkg} };
        for my $rpc_method (@rpc_methods) {
            my $subname = $config->{$pkg}{$rpc_method};
            debug("[bdfc] $args->{endpoint}: $rpc_method => $subname");
            if (my $handler = $pkg->can($subname)) {
                $dispatch->{$rpc_method} = dispatch_item(
                    package => $pkg,
                    code    => $handler
                );
            }
            else {
                die "Handler not found for $rpc_method: $pkg\::$subname doesn't seem to exist.\n";
            }
        }
    }

    # we don't want "Encountered CODE ref, using dummy placeholder"
    # thus we use Data::Dumper::Dumper().
    debug(
        "[build_dispatcher_from_config]->{$args->{key}} ",
        Data::Dumper::Dumper($dispatch)
    );

    return $dispatch;
}

1;

=head1 NAME

Dancer::RPCPlugin::DispatchFromConfig - Build dispatch-table from the Dancer Config

=head1 SYNOPSIS

    use Dancer::Plugin;
    use Dancer::RPCPlugin::DispatchFromConfig;
    sub dispatch_call {
        my $config = plugin_setting();
        return dispatch_table_from_config($config);
    }

=head1 DESCRIPTION

=head2 dispatch_table_from_config(%arguments)

=head3 Arguments

Named:

=over

=item key => <xmlrpc|jsonrpc>

=item config => $config_from_plugin

=back

=head3 Returns

=head1 COPYRIGHT

(c) MMXV - Abe Timmerman <abeltje@cpan.org>

=cut
