package Dancer2::RPCPlugin::PluginNames;
use Moo;

our $VERSION = '2.00';

use constant DEFAULT_PLUGINS => [qw/ jsonrpc restrpc xmlrpc /];

# Singleton Class
my $_plugins;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if (!defined $_plugins) {
        $_plugins = @_ ? [@_] : [ @{DEFAULT_PLUGINS()} ];
    }
    return $class->$orig(@_);
};

sub _reset { undef($_plugins) }

sub add_names {
    my $self = shift;

    for my $new_plugin (@_) {
        if (!grep $_ eq $new_plugin, @{$_plugins}) {
            push @{$_plugins}, $new_plugin;
        }
    }
    return $_plugins;
}

sub names {
    my $self = shift;
    return sort { length($b) <=> length($a) || $a cmp $b } @{$_plugins};
}

sub regex {
    my $self = shift;
    my $alts = join('|', $self->names);

    return qr/(?:$alts)/;
}

use namespace::autoclean;
1;

=head1 NAME

Dancer2::RPCPlugin::PluginNames - Register Dancer2::Plugin::RPC plugin-names

=head1 SYNOPSIS

    use Dancer2::RPCPlugin::PluginNames;
    my $pt = Dancer2::RPCPlugin::PluginNames->new();

    say "Plugin: $_" for $pt->names;

    if ($my_name =~ $pt->regex) {
        say "$my_name is a registered plugin-name";
    }

=head1 DESCRIPTION

=head2 Dancer2::RPCPlugin::PluginNames->new(@names)

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

=begin pod_coverage

=head2 BUILDARGS

Set the "global" C<$_plugins> if this is the first instantiation.

=head2 DEFAULT_PLUGINS

The list of plugins that are supplied with this distribution.

=end pod_coverage

=head1 COPYRIGHT

E<copy> MMXXII - Abe Timmerman <abetim@cpan.org>

=cut
