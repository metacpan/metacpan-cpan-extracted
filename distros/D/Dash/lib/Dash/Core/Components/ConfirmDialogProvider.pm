# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Core::Components::ConfirmDialogProvider;

use Moo;
use strictures 2;
use Dash::Core::ComponentsAssets;
use namespace::clean;

extends 'Dash::BaseComponent';

has 'id'                        => ( is => 'rw' );
has 'message'                   => ( is => 'rw' );
has 'submit_n_clicks'           => ( is => 'rw' );
has 'submit_n_clicks_timestamp' => ( is => 'rw' );
has 'cancel_n_clicks'           => ( is => 'rw' );
has 'cancel_n_clicks_timestamp' => ( is => 'rw' );
has 'displayed'                 => ( is => 'rw' );
has 'children'                  => ( is => 'rw' );
has 'loading_state'             => ( is => 'rw' );
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

Dash::Core::Components::ConfirmDialogProvider

=head1 VERSION

version 0.06

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
