# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Core::Components::Upload;

use Dash::Core::Components;
use Mojo::Base 'Dash::BaseComponent';

has 'id';
has 'contents';
has 'filename';
has 'last_modified';
has 'children';
has 'accept';
has 'disabled';
has 'disable_click';
has 'max_size';
has 'min_size';
has 'multiple';
has 'className';
has 'className_active';
has 'className_reject';
has 'className_disabled';
has 'style';
has 'style_active';
has 'style_reject';
has 'style_disabled';
has 'loading_state';
my $dash_namespace = 'dash_core_components';

sub DashNamespace {
    return $dash_namespace;
}

sub _js_dist {
    return Dash::Core::Components::_js_dist;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Core::Components::Upload

=head1 VERSION

version 0.04

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
