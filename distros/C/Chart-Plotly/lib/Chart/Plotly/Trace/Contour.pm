package Chart::Plotly::Trace::Contour;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Contour::Colorbar;
use Chart::Plotly::Trace::Contour::Contours;
use Chart::Plotly::Trace::Contour::Hoverlabel;
use Chart::Plotly::Trace::Contour::Line;
use Chart::Plotly::Trace::Contour::Stream;

our $VERSION = '0.017';    # VERSION

# ABSTRACT: The data from which contour lines are computed is set in `z`. Data in `z` must be a {2D array} of numbers. Say that `z` has N rows and M columns, then by default, these N rows correspond to N y coordinates (set in `y` or auto-generated) and the M columns correspond to M x coordinates (set in `x` or auto-generated). By setting `transpose` to *true*, the above behavior is flipped.

sub TO_JSON {
    my $self       = shift;
    my $extra_args = $self->extra_args // {};
    my $meta       = $self->meta;
    my %hash       = %$self;
    for my $name ( sort keys %hash ) {
        my $attr = $meta->get_attribute($name);
        if ( defined $attr ) {
            my $value = $hash{$name};
            my $type  = $attr->type_constraint;
            if ( $type && $type->equals('Bool') ) {
                $hash{$name} = $value ? \1 : \0;
            }
        }
    }
    %hash = ( %hash, %$extra_args );
    delete $hash{'extra_args'};
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

sub type {
    my @components = split( /::/, __PACKAGE__ );
    return lc( $components[-1] );
}

has autocolorscale => (
            is            => "rw",
            isa           => "Bool",
            documentation => "Determines whether or not the colorscale is picked using the sign of the input z values.",
);

has autocontour => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not the contour level attributes are picked by an algorithm. If *true*, the number of contour levels can be set in `ncontours`. If *false*, set the contour level attributes in `contours`.",
);

has colorbar => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Contour::Colorbar", );

has colorscale => (
    is => "rw",
    documentation =>
      "Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in z space, use zmin and zmax",
);

has connectgaps => (
        is            => "rw",
        isa           => "Bool",
        documentation => "Determines whether or not gaps (i.e. {nan} or missing values) in the `z` data are filled in.",
);

has contours => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Contour::Contours", );

has customdata => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements",
);

has customdatasrc => ( is            => "rw",
                       isa           => "Str",
                       documentation => "Sets the source reference on plot.ly for  customdata .",
);

has dx => ( is            => "rw",
            isa           => "Num",
            documentation => "Sets the x coordinate step. See `x0` for more info.",
);

has dy => ( is            => "rw",
            isa           => "Num",
            documentation => "Sets the y coordinate step. See `y0` for more info.",
);

has fillcolor => (
    is => "rw",
    documentation =>
      "Sets the fill color if `contours.type` is *constraint*. Defaults to a half-transparent variant of the line color, marker color, or marker line color, whichever is available.",
);

has hoverinfo => (
    is  => "rw",
    isa => "Maybe[ArrayRef]",
    documentation =>
      "Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.",
);

has hoverinfosrc => ( is            => "rw",
                      isa           => "Str",
                      documentation => "Sets the source reference on plot.ly for  hoverinfo .",
);

has hoverlabel => ( is  => "rw",
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Contour::Hoverlabel", );

has ids => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.",
);

has idssrc => ( is            => "rw",
                isa           => "Str",
                documentation => "Sets the source reference on plot.ly for  ids .",
);

has legendgroup => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Sets the legend group for this trace. Traces part of the same legend group hide/show at the same time when toggling legend items.",
);

has line => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Contour::Line", );

has name => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the trace name. The trace name appear as the legend item and on hover.",
);

has ncontours => (
    is  => "rw",
    isa => "Int",
    documentation =>
      "Sets the maximum number of contour levels. The actual number of contours will be chosen automatically to be less than or equal to the value of `ncontours`. Has an effect only if `autocontour` is *true* or if `contours.size` is missing.",
);

has opacity => ( is            => "rw",
                 isa           => "Num",
                 documentation => "Sets the opacity of the trace.",
);

has reversescale => ( is            => "rw",
                      isa           => "Bool",
                      documentation => "Reverses the colorscale.",
);

has selectedpoints => (
    is  => "rw",
    isa => "Any",
    documentation =>
      "Array containing integer indices of selected points. Has an effect only for traces that support selections. Note that an empty array means an empty selection where the `unselected` are turned on for all points, whereas, any other non-array values means no selection all where the `selected` and `unselected` styles have no effect.",
);

has showlegend => (
               is            => "rw",
               isa           => "Bool",
               documentation => "Determines whether or not an item corresponding to this trace is shown in the legend.",
);

has showscale => ( is            => "rw",
                   isa           => "Bool",
                   documentation => "Determines whether or not a colorbar is displayed for this trace.",
);

has stream => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Contour::Stream", );

has text => ( is            => "rw",
              isa           => "ArrayRef|PDL",
              documentation => "Sets the text elements associated with each z value.",
);

has textsrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on plot.ly for  text .",
);

has transpose => ( is            => "rw",
                   isa           => "Bool",
                   documentation => "Transposes the z data.",
);

has uid => ( is  => "rw",
             isa => "Str", );

has visible => (
    is => "rw",
    documentation =>
      "Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).",
);

has x => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the x coordinates.",
);

has x0 => (
    is  => "rw",
    isa => "Any",
    documentation =>
      "Alternate to `x`. Builds a linear space of x coordinates. Use with `dx` where `x0` is the starting coordinate and `dx` the step.",
);

has xaxis => (
    is => "rw",
    documentation =>
      "Sets a reference between this trace's x coordinates and a 2D cartesian x axis. If *x* (the default value), the x coordinates refer to `layout.xaxis`. If *x2*, the x coordinates refer to `layout.xaxis2`, and so on.",
);

has xcalendar => ( is  => "rw",
                   isa => enum(
                           [ "gregorian", "chinese", "coptic", "discworld", "ethiopian", "hebrew", "islamic", "julian",
                             "mayan", "nanakshahi", "nepali", "persian", "jalali", "taiwan", "thai", "ummalqura"
                           ]
                   ),
                   documentation => "Sets the calendar system to use with `x` date data.",
);

has xsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  x .",
);

has xtype => (
    is  => "rw",
    isa => enum( [ "array", "scaled" ] ),
    documentation =>
      "If *array*, the heatmap's x coordinates are given by *x* (the default behavior when `x` is provided). If *scaled*, the heatmap's x coordinates are given by *x0* and *dx* (the default behavior when `x` is not provided).",
);

has y => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the y coordinates.",
);

has y0 => (
    is  => "rw",
    isa => "Any",
    documentation =>
      "Alternate to `y`. Builds a linear space of y coordinates. Use with `dy` where `y0` is the starting coordinate and `dy` the step.",
);

has yaxis => (
    is => "rw",
    documentation =>
      "Sets a reference between this trace's y coordinates and a 2D cartesian y axis. If *y* (the default value), the y coordinates refer to `layout.yaxis`. If *y2*, the y coordinates refer to `layout.xaxis2`, and so on.",
);

has ycalendar => ( is  => "rw",
                   isa => enum(
                           [ "gregorian", "chinese", "coptic", "discworld", "ethiopian", "hebrew", "islamic", "julian",
                             "mayan", "nanakshahi", "nepali", "persian", "jalali", "taiwan", "thai", "ummalqura"
                           ]
                   ),
                   documentation => "Sets the calendar system to use with `y` date data.",
);

has ysrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  y .",
);

has ytype => (
    is  => "rw",
    isa => enum( [ "array", "scaled" ] ),
    documentation =>
      "If *array*, the heatmap's y coordinates are given by *y* (the default behavior when `y` is provided) If *scaled*, the heatmap's y coordinates are given by *y0* and *dy* (the default behavior when `y` is not provided)",
);

has z => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the z data.",
);

has zauto => (
          is            => "rw",
          isa           => "Bool",
          documentation => "Determines the whether or not the color domain is computed with respect to the input data.",
);

has zhoverformat => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Sets the hover text formatting rule using d3 formatting mini-languages which are very similar to those in Python. See: https://github.com/d3/d3-format/blob/master/README.md#locale_format",
);

has zmax => ( is            => "rw",
              isa           => "Num",
              documentation => "Sets the upper bound of color domain.",
);

has zmin => ( is            => "rw",
              isa           => "Num",
              documentation => "Sets the lower bound of color domain.",
);

has zsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  z .",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Contour - The data from which contour lines are computed is set in `z`. Data in `z` must be a {2D array} of numbers. Say that `z` has N rows and M columns, then by default, these N rows correspond to N y coordinates (set in `y` or auto-generated) and the M columns correspond to M x coordinates (set in `x` or auto-generated). By setting `transpose` to *true*, the above behavior is flipped.

=head1 VERSION

version 0.017

=head1 SYNOPSIS

 use Chart::Plotly qw(show_plot);
 use Chart::Plotly::Trace::Contour;
 use English qw(-no_match_vars);
 
 my $contour = Chart::Plotly::Trace::Contour->new(
     x => [ 0 .. 10 ],
     y => [ 0 .. 10 ],
     z => [
         map {
             my $y = $ARG;
             [ map { $ARG * $ARG + $y * $y } ( 0 .. 10 ) ]
         } ( 0 .. 10 )
     ]
 );
 
 show_plot( [$contour] );

=head1 DESCRIPTION

The data from which contour lines are computed is set in `z`. Data in `z` must be a {2D array} of numbers. Say that `z` has N rows and M columns, then by default, these N rows correspond to N y coordinates (set in `y` or auto-generated) and the M columns correspond to M x coordinates (set in `x` or auto-generated). By setting `transpose` to *true*, the above behavior is flipped.

Screenshot of the above example:

=for HTML <p>
<img src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/contour.png" alt="Screenshot of the above example">
</p>

=for markdown ![Screenshot of the above example](https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/contour.png)

=for HTML <p>
<iframe src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/contour.html" style="border:none;" width="80%" height="520"></iframe>
</p>

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#contour>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head2 type

Trace type.

=head1 ATTRIBUTES

=over

=item * autocolorscale

Determines whether or not the colorscale is picked using the sign of the input z values.

=item * autocontour

Determines whether or not the contour level attributes are picked by an algorithm. If *true*, the number of contour levels can be set in `ncontours`. If *false*, set the contour level attributes in `contours`.

=item * colorbar

=item * colorscale

Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in z space, use zmin and zmax

=item * connectgaps

Determines whether or not gaps (i.e. {nan} or missing values) in the `z` data are filled in.

=item * contours

=item * customdata

Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements

=item * customdatasrc

Sets the source reference on plot.ly for  customdata .

=item * dx

Sets the x coordinate step. See `x0` for more info.

=item * dy

Sets the y coordinate step. See `y0` for more info.

=item * fillcolor

Sets the fill color if `contours.type` is *constraint*. Defaults to a half-transparent variant of the line color, marker color, or marker line color, whichever is available.

=item * hoverinfo

Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.

=item * hoverinfosrc

Sets the source reference on plot.ly for  hoverinfo .

=item * hoverlabel

=item * ids

Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.

=item * idssrc

Sets the source reference on plot.ly for  ids .

=item * legendgroup

Sets the legend group for this trace. Traces part of the same legend group hide/show at the same time when toggling legend items.

=item * line

=item * name

Sets the trace name. The trace name appear as the legend item and on hover.

=item * ncontours

Sets the maximum number of contour levels. The actual number of contours will be chosen automatically to be less than or equal to the value of `ncontours`. Has an effect only if `autocontour` is *true* or if `contours.size` is missing.

=item * opacity

Sets the opacity of the trace.

=item * reversescale

Reverses the colorscale.

=item * selectedpoints

Array containing integer indices of selected points. Has an effect only for traces that support selections. Note that an empty array means an empty selection where the `unselected` are turned on for all points, whereas, any other non-array values means no selection all where the `selected` and `unselected` styles have no effect.

=item * showlegend

Determines whether or not an item corresponding to this trace is shown in the legend.

=item * showscale

Determines whether or not a colorbar is displayed for this trace.

=item * stream

=item * text

Sets the text elements associated with each z value.

=item * textsrc

Sets the source reference on plot.ly for  text .

=item * transpose

Transposes the z data.

=item * uid

=item * visible

Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).

=item * x

Sets the x coordinates.

=item * x0

Alternate to `x`. Builds a linear space of x coordinates. Use with `dx` where `x0` is the starting coordinate and `dx` the step.

=item * xaxis

Sets a reference between this trace's x coordinates and a 2D cartesian x axis. If *x* (the default value), the x coordinates refer to `layout.xaxis`. If *x2*, the x coordinates refer to `layout.xaxis2`, and so on.

=item * xcalendar

Sets the calendar system to use with `x` date data.

=item * xsrc

Sets the source reference on plot.ly for  x .

=item * xtype

If *array*, the heatmap's x coordinates are given by *x* (the default behavior when `x` is provided). If *scaled*, the heatmap's x coordinates are given by *x0* and *dx* (the default behavior when `x` is not provided).

=item * y

Sets the y coordinates.

=item * y0

Alternate to `y`. Builds a linear space of y coordinates. Use with `dy` where `y0` is the starting coordinate and `dy` the step.

=item * yaxis

Sets a reference between this trace's y coordinates and a 2D cartesian y axis. If *y* (the default value), the y coordinates refer to `layout.yaxis`. If *y2*, the y coordinates refer to `layout.xaxis2`, and so on.

=item * ycalendar

Sets the calendar system to use with `y` date data.

=item * ysrc

Sets the source reference on plot.ly for  y .

=item * ytype

If *array*, the heatmap's y coordinates are given by *y* (the default behavior when `y` is provided) If *scaled*, the heatmap's y coordinates are given by *y0* and *dy* (the default behavior when `y` is not provided)

=item * z

Sets the z data.

=item * zauto

Determines the whether or not the color domain is computed with respect to the input data.

=item * zhoverformat

Sets the hover text formatting rule using d3 formatting mini-languages which are very similar to those in Python. See: https://github.com/d3/d3-format/blob/master/README.md#locale_format

=item * zmax

Sets the upper bound of color domain.

=item * zmin

Sets the lower bound of color domain.

=item * zsrc

Sets the source reference on plot.ly for  z .

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
