# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Core::Components::Loading;

use Moo;
use strictures 2;
use Dash::Core::ComponentsAssets;
use namespace::clean;

extends 'Dash::BaseComponent';

has 'id'            => ( is => 'rw' );
has 'children'      => ( is => 'rw' );
has 'type'          => ( is => 'rw' );
has 'fullscreen'    => ( is => 'rw' );
has 'debug'         => ( is => 'rw' );
has 'className'     => ( is => 'rw' );
has 'style'         => ( is => 'rw' );
has 'color'         => ( is => 'rw' );
has 'loading_state' => ( is => 'rw' );
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

Dash::Core::Components::Loading

=head1 VERSION

version 0.10

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
