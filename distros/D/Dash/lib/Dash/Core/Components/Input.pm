# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Core::Components::Input;

use Moo;
use strictures 2;
use Dash::Core::ComponentsAssets;
use namespace::clean;

extends 'Dash::BaseComponent';

has 'id'                 => ( is => 'rw' );
has 'value'              => ( is => 'rw' );
has 'style'              => ( is => 'rw' );
has 'className'          => ( is => 'rw' );
has 'debounce'           => ( is => 'rw' );
has 'type'               => ( is => 'rw' );
has 'autoComplete'       => ( is => 'rw' );
has 'autoFocus'          => ( is => 'rw' );
has 'disabled'           => ( is => 'rw' );
has 'inputMode'          => ( is => 'rw' );
has 'list'               => ( is => 'rw' );
has 'max'                => ( is => 'rw' );
has 'maxLength'          => ( is => 'rw' );
has 'min'                => ( is => 'rw' );
has 'minLength'          => ( is => 'rw' );
has 'multiple'           => ( is => 'rw' );
has 'name'               => ( is => 'rw' );
has 'pattern'            => ( is => 'rw' );
has 'placeholder'        => ( is => 'rw' );
has 'readOnly'           => ( is => 'rw' );
has 'required'           => ( is => 'rw' );
has 'selectionDirection' => ( is => 'rw' );
has 'selectionEnd'       => ( is => 'rw' );
has 'selectionStart'     => ( is => 'rw' );
has 'size'               => ( is => 'rw' );
has 'spellCheck'         => ( is => 'rw' );
has 'step'               => ( is => 'rw' );
has 'n_submit'           => ( is => 'rw' );
has 'n_submit_timestamp' => ( is => 'rw' );
has 'n_blur'             => ( is => 'rw' );
has 'n_blur_timestamp'   => ( is => 'rw' );
has 'loading_state'      => ( is => 'rw' );
has 'persistence'        => ( is => 'rw' );
has 'persisted_props'    => ( is => 'rw' );
has 'persistence_type'   => ( is => 'rw' );
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

Dash::Core::Components::Input

=head1 VERSION

version 0.11

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
