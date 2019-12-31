# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Core::Components::DatePickerSingle;

use Dash::Core::Components;
use Mojo::Base 'Dash::BaseComponent';

has 'id';
has 'date';
has 'min_date_allowed';
has 'max_date_allowed';
has 'initial_visible_month';
has 'day_size';
has 'calendar_orientation';
has 'is_RTL';
has 'placeholder';
has 'reopen_calendar_on_clear';
has 'number_of_months_shown';
has 'with_portal';
has 'with_full_screen_portal';
has 'first_day_of_week';
has 'stay_open_on_select';
has 'show_outside_days';
has 'month_format';
has 'display_format';
has 'disabled';
has 'clearable';
has 'style';
has 'className';
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

Dash::Core::Components::DatePickerSingle

=head1 VERSION

version 0.02

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
