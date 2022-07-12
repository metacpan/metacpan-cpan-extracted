package Example::ValidationTemplates;
use Moo::Role;

our $VERSION = '0.01';

use Types::Standard qw(Str Num StrMatch);

use Dancer2::RPCPlugin::PluginNames;

=head1 NAME

Example::ValidationTemplates - ValidationTemplates for the Expamle app.

=head SYNOPSIS

    package MyPackage;
    use Moo;
    with qw(
        Example::ValidationTemplates
        MooX::Params::CompiledValidators
    );
    ...

=head1 DESCRIPTION

This is the place to specify every parameter in the Example project.

=head2 ValidationTemplates

=cut

sub ValidationTemplates {
    my $plugin_regex = Dancer2::RPCPlugin::PluginNames->new->regex . '|any';
    return {
        plugin => {default => 'any', type => StrMatch[ qr{^ $plugin_regex $}x ]},
    };
}


use namespace::autoclean;
1;
