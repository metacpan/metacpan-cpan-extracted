package Chart::GGPlot::Coord;

# ABSTRACT: The role for coordinates

use Chart::GGPlot::Role qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0005'; # VERSION

use Types::Standard qw(Bool);

# Renders the horizontal axes.
has render_axis_h => ( is => 'rw' );

# Renders the vertical axes.
has render_axis_v => ( is => 'rw' );

with qw(Chart::GGPlot::HasCollectibleFunctions);


classmethod is_linear() { false; }


requires 'transform';
requires 'distance';

# Returns the desired aspect ratio for the plot.
method aspect () { return; }

# Returns a list containing labels for x and y.
method labels ($panel_params) { $panel_params }

method range ($panel_params) {
    return {
        x => $panel_params->at('x_range'),
        y => $panel_params->at('y_range'),
    };
}

method setup_panel_params ($scale_x, $scale_y, $params = {}) { {}; }

method setup_params ($data)  { {}; }
method setup_data ($data, $params)  { $data }
method setup_layout ($layout, $params) { $layout }

# Optionally, modifies list of x and y scales in place. Currently
# used as a fudge for CoordFlip and CoordPolar
method modify_scales ($scales_x, $scales_y) { }

classmethod expand_default ($scale,
        $discrete = [0, 0.6, 0, 0.6], $continuous = [0.05, 0, 0.05, 0]) {
    return (
        (
            $scale->expand
              // ( $scale->$_DOES('Chart::GGPlot::Scale::Discrete') )
        )
        ? $discrete
        : $continuous
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Coord - The role for coordinates

=head1 VERSION

version 0.0005

=head1 DESCRIPTION

This module is a Moose role for "coord".

For users of Chart::GGPlot you would mostly want to look at
L<Chart::GGPlot::Coord::Functions> instead.

=head1 CLASS METHODS

=head2 is_linear

    is_linear()

Returns true if the coordinate system is linear; false otherwise.

=head1 METHODS

=head2 render_bg($panel_params, $theme) 

Renders background elements.

=head2 render_axis_h($panel_params, $theme)

Renders the horizontal axes.

=head2 render_axis_v($panel_params, $theme)

Renders the vertical axes.

=head2 range($panel_params)

Returns the x and y ranges.

=head2 transform($data, $range)

Transforms x and y coordinates.

=head2 distance($x, $y, $panel_params)

Calculates distance.

=head2 setup_data($data, $params)

Allows the coordinate system to manipulate the plot data.
Returns a hash ref of dataframes.

=head2 setup_layout($layout, $params)

Allows the coordinate system to manipulate the "layout" data frame
which assigns data to panels and scales.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
