package Dancer::RPCPlugin::PluginNames;
use warnings;
use strict;

use constant DEFAULT_PLUGINS => [qw/ jsonrpc restrpc xmlrpc /];

my $_plugins;
sub new {
    my $class = shift;

    if (!defined $_plugins) {
        $_plugins = bless @_ ? [@_] : [ @{DEFAULT_PLUGINS()} ], $class;
    }
    return $_plugins;
}

sub _reset { undef $_plugins }

sub add_names {
    my $self = shift;

    for my $new_plugin (@_) {
        if (!grep $_ eq $new_plugin, @{$self}) {
            push @{$self}, $new_plugin;
        }
    }
    return $self;
}

sub names {
    my $self = shift;
    return sort { length($b) <=> length($a) || $a cmp $b } @{$self};
}

sub regex {
    my $self = shift;
    my $alts = join('|', $self->names);

    return qr/(?:$alts)/;
}

1;

=head1 NAME

Dancer::RPCPlugin::PluginNames - Register Dancer::Plugin::RPC plugin-names

=head1 SYNOPSIS

    use Dancer::RPCPlugin::PluginNames;
    my $pt = Dancer::RPCPlugin::PluginNames->new();

    say "Plugin: $_" for $pt->names;

    if ($my_name =~ $pt->regex) {
        say "$my_name is a registered plugin-name";
    }

=head1 DESCRIPTION

=head2 Dancer::RPCPlugin::PluginNames->new(@names)

Returns a singleton-object of this class.

=head3 Arguments

List of names or none.

=head2 $pn->add_names(@names)

Adds the names given to the singleton-object and returns that.

=head2 $pn->names

Returns a list of registered plugin-names ordered by:

=over

=item 1. length of the name

=item 2. ASCII-betical

=back

=head2 $pn->regex

Returns a C<Regexp> object with all the names as alternatives.

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abetim@cpan.org>

=cut
