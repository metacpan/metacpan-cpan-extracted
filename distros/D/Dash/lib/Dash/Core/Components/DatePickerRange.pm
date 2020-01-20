# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Core::Components::DatePickerRange;

use Moo;
use strictures 2;
use Dash::Core::ComponentsAssets;
use namespace::clean;

extends 'Dash::BaseComponent';

has 'id'                          => ( is => 'rw' );
has 'start_date'                  => ( is => 'rw' );
has 'start_date_id'               => ( is => 'rw' );
has 'end_date_id'                 => ( is => 'rw' );
has 'end_date'                    => ( is => 'rw' );
has 'min_date_allowed'            => ( is => 'rw' );
has 'max_date_allowed'            => ( is => 'rw' );
has 'initial_visible_month'       => ( is => 'rw' );
has 'start_date_placeholder_text' => ( is => 'rw' );
has 'end_date_placeholder_text'   => ( is => 'rw' );
has 'day_size'                    => ( is => 'rw' );
has 'calendar_orientation'        => ( is => 'rw' );
has 'is_RTL'                      => ( is => 'rw' );
has 'reopen_calendar_on_clear'    => ( is => 'rw' );
has 'number_of_months_shown'      => ( is => 'rw' );
has 'with_portal'                 => ( is => 'rw' );
has 'with_full_screen_portal'     => ( is => 'rw' );
has 'first_day_of_week'           => ( is => 'rw' );
has 'minimum_nights'              => ( is => 'rw' );
has 'stay_open_on_select'         => ( is => 'rw' );
has 'show_outside_days'           => ( is => 'rw' );
has 'month_format'                => ( is => 'rw' );
has 'display_format'              => ( is => 'rw' );
has 'disabled'                    => ( is => 'rw' );
has 'clearable'                   => ( is => 'rw' );
has 'style'                       => ( is => 'rw' );
has 'className'                   => ( is => 'rw' );
has 'updatemode'                  => ( is => 'rw' );
has 'loading_state'               => ( is => 'rw' );
has 'persistence'                 => ( is => 'rw' );
has 'persisted_props'             => ( is => 'rw' );
has 'persistence_type'            => ( is => 'rw' );
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

Dash::Core::Components::DatePickerRange

=head1 VERSION

version 0.06

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
