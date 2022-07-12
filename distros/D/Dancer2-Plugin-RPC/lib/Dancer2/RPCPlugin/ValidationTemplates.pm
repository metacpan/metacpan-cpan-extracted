package Dancer2::RPCPlugin::ValidationTemplates;
use Moo::Role;

use Type::Tiny;
use Types::Standard qw( ArrayRef CodeRef Dict HashRef Maybe Ref Str StrMatch );

use Dancer2::RPCPlugin::PluginNames;

sub ValidationTemplates {
    my $publisher_check = sub {
        my ($value) = @_;
        if (!ref($value)) {
            return $value =~ m{ ^(config | pod) $}x ? 1 : 0;
        }
        return ref($value) eq 'CODE' ? 1 : 0;
    };
    my $publisher = Type::Tiny->new(
        name       => 'Any',
        constraint => $publisher_check,
        message    => sub { "'$_' must be 'config', 'pod' or a CodeRef" },
    );
    # we cannot have Types::Standard::Optional imported
    # it interfers with our own ->Optional
    my $plugin_config = Dict [
        publish      => Types::Standard::Optional [ Maybe [$publisher] ],
        arguments    => Types::Standard::Optional [ Maybe [ArrayRef] ],
        callback     => Types::Standard::Optional [CodeRef],
        code_wrapper => Types::Standard::Optional [CodeRef],
    ];
    my $plugins = Dancer2::RPCPlugin::PluginNames->new->regex;
    my $any_plugin = qr{(?:any|$plugins)};
    return {
        endpoint => { type => StrMatch [qr{^ [\w/\\%]+ $}x] },
        publish  => {
            type    => Maybe [$publisher],
            default => 'config'
        },
        arguments     => { type => Maybe [ArrayRef] },
        settings      => { type => Maybe [HashRef] },
        protocol      => { type => StrMatch [$plugins] },
        any_protocol  => { type => StrMatch [$any_plugin] },
        methods       => { type => ArrayRef [ StrMatch [qr{ . }x] ] },
        config        => { type => $plugin_config },
        status_map    => { type => HashRef },
        handler_name  => { type => Maybe [Str] },
        error_handler => { type => Maybe [CodeRef] },
    };
}

use namespace::autoclean;
1;

=head1 NAME

Dancer2::RPCPlugin::ValidationTemplates - Parameters used in the project.

=head1 SYNOPSIS

    package MyThing;
    use Moo;
    with qw(
        Dancer2::RPCPlugin::ValidationTemplates
        MooX::Params::CompiledValidators
    );
    ...

=head1 DESCRIPTION

This L<Moo::Role> defines the parameters used in the L<Dancer2::Plugin::RPC>
project for use with L<MooX::Params::CompiledValidators>

=head2 ValidationTemplates

=head1 COPYRIGHT

E<copy> MMXXII - Abe Timmerman <abeltje@cpan.org>

=cut
