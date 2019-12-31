# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Core::Components::Input;

use Dash::Core::Components;
use Mojo::Base 'Dash::BaseComponent';

has 'id';
has 'value';
has 'style';
has 'className';
has 'debounce';
has 'type';
has 'autoComplete';
has 'autoFocus';
has 'disabled';
has 'inputMode';
has 'list';
has 'max';
has 'maxLength';
has 'min';
has 'minLength';
has 'multiple';
has 'name';
has 'pattern';
has 'placeholder';
has 'readOnly';
has 'required';
has 'selectionDirection';
has 'selectionEnd';
has 'selectionStart';
has 'size';
has 'spellCheck';
has 'step';
has 'n_submit';
has 'n_submit_timestamp';
has 'n_blur';
has 'n_blur_timestamp';
has 'loading_state';
has 'persistence';
has 'persisted_props';
has 'persistence_type';
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

Dash::Core::Components::Input

=head1 VERSION

version 0.02

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
