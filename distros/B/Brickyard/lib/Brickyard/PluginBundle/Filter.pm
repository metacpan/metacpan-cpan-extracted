
package Brickyard::PluginBundle::Filter;

use 5.010;
use warnings;
use strict;

use Brickyard::Accessor rw => [qw(bundle remove)];
use Role::Basic 'with';
with 'Brickyard::Role::PluginBundle';

sub bundle_config {
    my $self    = shift;
    my $package = $self->_exp($self->bundle);
    eval "require $package";
    die "Cannot require $package: $@" if $@;

    # config keys given to this plugin bundle whose name starts with a dash
    # are intended for the plugin bundle that's being filtered.
    my %args;
    while (my ($key, $value) = each %$self) {
        next unless $key =~ s/^-//;
        $args{$key} = $value;
    }
    my $bundle_config =
      $package->new(brickyard => $self->brickyard, %args)->bundle_config;
    if (my $remove = $self->remove) {
        $remove = [$remove] unless ref $remove eq 'ARRAY';
        $self->remove_from_config($bundle_config, $remove);
    }
    $bundle_config;
}

sub remove_from_config {
    my ($self, $bundle_config, $remove) = @_;
    for my $i (reverse 0 .. $#$bundle_config) {
        next unless grep { $bundle_config->[$i][1] eq $_ } @$remove;
        splice @$bundle_config, $i, 1;
    }
}
1;

=head1 NAME

Brickyard::PluginBundle::Filter - Plugin bundle to filter another plugin bundle

=head1 SYNOPSIS

In your F<registry.ini>:

  ; use [@MyBundle], but replace the [FooBar] plugin with a custom one
  [*@Filter]
  bundle = @MyBundle
  remove = FooBar
  mybundle_config1 = value1
  mybundle_config2 = value2

  [Better::FooBar]
  baz = frobnule
  baz = frobnule2

=head1 DESCRIPTION

This plugin bundle wraps and modifies another plugin bundle. It includes all
the configuration for the bundle named in the C<bundle> attribute, but removes
all the entries whose package is given in the C<remove> attributes.

Options prefixed with C<-> will be passed to the bundle to be filtered.

=head1 METHODS

=head2 bundle

Read-write accessor for the name of the bundle that should be filtered. It
will be expanded as per L<Brickyard>'s C<expand_package()> method.

=head2 remove

Read-write accessor for the name(s) of plugins that should be removed from the
bundle. These names too will be expanded as per L<Brickyard>'s
C<expand_package()> method.

=head2 bundle_config

Loads the target bundle's configuration, filters the plugins and returns the
remaining configuration.

=head2 remove_from_config

Takes a bundle configuration and a reference to an array of package names that
should be removed from the bundle configuration. Returns the filtered
configuration.
