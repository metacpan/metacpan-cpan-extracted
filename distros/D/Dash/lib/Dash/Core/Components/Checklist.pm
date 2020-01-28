# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Core::Components::Checklist;

use Moo;
use strictures 2;
use Dash::Core::ComponentsAssets;
use namespace::clean;

extends 'Dash::BaseComponent';

has 'id'               => ( is => 'rw' );
has 'options'          => ( is => 'rw' );
has 'value'            => ( is => 'rw' );
has 'className'        => ( is => 'rw' );
has 'style'            => ( is => 'rw' );
has 'inputStyle'       => ( is => 'rw' );
has 'inputClassName'   => ( is => 'rw' );
has 'labelStyle'       => ( is => 'rw' );
has 'labelClassName'   => ( is => 'rw' );
has 'loading_state'    => ( is => 'rw' );
has 'persistence'      => ( is => 'rw' );
has 'persisted_props'  => ( is => 'rw' );
has 'persistence_type' => ( is => 'rw' );
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

Dash::Core::Components::Checklist

=head1 VERSION

version 0.10

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
