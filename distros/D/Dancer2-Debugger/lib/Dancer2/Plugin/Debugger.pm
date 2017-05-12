package Dancer2::Plugin::Debugger;

=head1 NAME

Dancer2::Plugin::Debugger - main debugger plugin for Dancer2 for Plack::Debugger

=head1 VERSION

0.008

=cut

our $VERSION = '0.008';

use strict;
use warnings;

use Module::Find qw/findallmod/;
use Module::Runtime qw/use_module/;
use Dancer2::Plugin;

=head1 CONFIGURATION

    plugins:
        Debugger:
            enabled: 1

=head2 enabled

Whether plugin is enabled. Defaults to false.

=head1 METHODS

=head2 BUILD

Load all C<Dancer2::Plugin::Debugger::Panel::*> classes if L</enabled> is true.

=cut

on_plugin_import {
    my $plugin = shift;

    return unless $plugin->config->{enabled};

    my @panels = findallmod Dancer2::Plugin::Debugger::Panel;

    foreach my $panel (@panels) {
        use_module($panel)->new( plugin => $plugin );
    }
};

register_plugin;

1;
