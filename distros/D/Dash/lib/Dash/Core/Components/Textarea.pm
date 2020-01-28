# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Core::Components::Textarea;

use Moo;
use strictures 2;
use Dash::Core::ComponentsAssets;
use namespace::clean;

extends 'Dash::BaseComponent';

has 'id'                 => ( is => 'rw' );
has 'value'              => ( is => 'rw' );
has 'autoFocus'          => ( is => 'rw' );
has 'cols'               => ( is => 'rw' );
has 'disabled'           => ( is => 'rw' );
has 'form'               => ( is => 'rw' );
has 'maxLength'          => ( is => 'rw' );
has 'minLength'          => ( is => 'rw' );
has 'name'               => ( is => 'rw' );
has 'placeholder'        => ( is => 'rw' );
has 'readOnly'           => ( is => 'rw' );
has 'required'           => ( is => 'rw' );
has 'rows'               => ( is => 'rw' );
has 'wrap'               => ( is => 'rw' );
has 'accessKey'          => ( is => 'rw' );
has 'className'          => ( is => 'rw' );
has 'contentEditable'    => ( is => 'rw' );
has 'contextMenu'        => ( is => 'rw' );
has 'dir'                => ( is => 'rw' );
has 'draggable'          => ( is => 'rw' );
has 'hidden'             => ( is => 'rw' );
has 'lang'               => ( is => 'rw' );
has 'spellCheck'         => ( is => 'rw' );
has 'style'              => ( is => 'rw' );
has 'tabIndex'           => ( is => 'rw' );
has 'title'              => ( is => 'rw' );
has 'n_blur'             => ( is => 'rw' );
has 'n_blur_timestamp'   => ( is => 'rw' );
has 'n_clicks'           => ( is => 'rw' );
has 'n_clicks_timestamp' => ( is => 'rw' );
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

Dash::Core::Components::Textarea

=head1 VERSION

version 0.10

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
