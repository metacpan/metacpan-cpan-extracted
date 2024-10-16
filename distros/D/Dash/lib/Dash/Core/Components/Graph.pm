# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Core::Components::Graph;

use Moo;
use strictures 2;
use Dash::Core::ComponentsAssets;
use namespace::clean;

extends 'Dash::BaseComponent';

has 'id'                  => ( is => 'rw' );
has 'responsive'          => ( is => 'rw' );
has 'clickData'           => ( is => 'rw' );
has 'clickAnnotationData' => ( is => 'rw' );
has 'hoverData'           => ( is => 'rw' );
has 'clear_on_unhover'    => ( is => 'rw' );
has 'selectedData'        => ( is => 'rw' );
has 'relayoutData'        => ( is => 'rw' );
has 'extendData'          => ( is => 'rw' );
has 'restyleData'         => ( is => 'rw' );
has 'figure'              => ( is => 'rw' );
has 'style'               => ( is => 'rw' );
has 'className'           => ( is => 'rw' );
has 'animate'             => ( is => 'rw' );
has 'animation_options'   => ( is => 'rw' );
has 'config'              => ( is => 'rw' );
has 'loading_state'       => ( is => 'rw' );
my $dash_namespace = 'dash_core_components';

sub DashNamespace {
    return $dash_namespace;
}

sub _js_dist {
    return Dash::Core::ComponentsAssets::_js_dist;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Core::Components::Graph

=head1 VERSION

version 0.11

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
