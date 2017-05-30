package Chart::Plotly::Trace::Contour;
use Moose;
use MooseX::ExtraArgs;

use Chart::Plotly::Trace::Attribute::Colorbar;
use Chart::Plotly::Trace::Attribute::Contours;
use Chart::Plotly::Trace::Attribute::Line;

our $VERSION = '0.013';    # VERSION

sub TO_JSON {
    my $self       = shift;
    my $extra_args = $self->extra_args // {};
    my %hash       = ( %$self, %$extra_args );
    delete $hash{'extra_args'};
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

has autocolorscale => (
            is            => 'rw',
            isa           => "Bool",
            documentation => "Determines whether or not the colorscale is picked using the sign of the input z values.",
);

has autocontour => (
    is  => 'rw',
    isa => "Bool",
    documentation =>
      "Determines whether or not the contour level attributes are picked by an algorithm. If *true*, the number of contour levels can be set in `ncontours`. If *false*, set the contour level attributes in `contours`.",
);

has colorbar => ( is  => 'rw',
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Colorbar" );

has colorscale => (
    is => 'rw',
    documentation =>
      "Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in z space, use zmin and zmax",
);

has connectgaps => (
        is            => 'rw',
        isa           => "Bool",
        documentation => "Determines whether or not gaps (i.e. {nan} or missing values) in the `z` data are filled in.",
);

has contours => ( is  => 'rw',
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Contours" );

has dx => ( is            => 'rw',
            isa           => "Num",
            documentation => "Sets the x coordinate step. See `x0` for more info.",
);

has dy => ( is            => 'rw',
            isa           => "Num",
            documentation => "Sets the y coordinate step. See `y0` for more info.",
);

has line => ( is  => 'rw',
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Line" );

has ncontours => (
    is => 'rw',
    documentation =>
      "Sets the maximum number of contour levels. The actual number of contours will be chosen automatically to be less than or equal to the value of `ncontours`. Has an effect only if `autocontour` is *true*.",
);

has reversescale => ( is            => 'rw',
                      isa           => "Bool",
                      documentation => "Reverses the colorscale.",
);

has showscale => ( is            => 'rw',
                   isa           => "Bool",
                   documentation => "Determines whether or not a colorbar is displayed for this trace.",
);

has text => ( is            => 'rw',
              documentation => "Sets the text elements associated with each z value.", );

has transpose => ( is            => 'rw',
                   isa           => "Bool",
                   documentation => "Transposes the z data.",
);

has x => ( is            => 'rw',
           documentation => "Sets the x coordinates.", );

has x0 => (
    is  => 'rw',
    isa => "Any",
    documentation =>
      "Alternate to `x`. Builds a linear space of x coordinates. Use with `dx` where `x0` is the starting coordinate and `dx` the step.",
);

has xtype => (
    is => 'rw',
    documentation =>
      "If *array*, the heatmap's x coordinates are given by *x* (the default behavior when `x` is provided). If *scaled*, the heatmap's x coordinates are given by *x0* and *dx* (the default behavior when `x` is not provided).",
);

has y => ( is            => 'rw',
           documentation => "Sets the y coordinates.", );

has y0 => (
    is  => 'rw',
    isa => "Any",
    documentation =>
      "Alternate to `y`. Builds a linear space of y coordinates. Use with `dy` where `y0` is the starting coordinate and `dy` the step.",
);

has ytype => (
    is => 'rw',
    documentation =>
      "If *array*, the heatmap's y coordinates are given by *y* (the default behavior when `y` is provided) If *scaled*, the heatmap's y coordinates are given by *y0* and *dy* (the default behavior when `y` is not provided)",
);

has z => ( is            => 'rw',
           documentation => "Sets the z data.", );

has zauto => (
          is            => 'rw',
          isa           => "Bool",
          documentation => "Determines the whether or not the color domain is computed with respect to the input data.",
);

has zmax => ( is            => 'rw',
              isa           => "Num",
              documentation => "Sets the upper bound of color domain.",
);

has zmin => ( is            => 'rw',
              isa           => "Num",
              documentation => "Sets the lower bound of color domain.",
);

has name => ( is            => 'rw',
              isa           => "Str",
              documentation => "Sets the trace name",
);

sub type {
    my @components = split( /::/, __PACKAGE__ );
    return lc( $components[-1] );
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Contour

=head1 VERSION

version 0.013

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

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#contour>

=head1 NAME 

Chart::Plotly::Trace::Contour

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

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

=item * dx

Sets the x coordinate step. See `x0` for more info.

=item * dy

Sets the y coordinate step. See `y0` for more info.

=item * line

=item * ncontours

Sets the maximum number of contour levels. The actual number of contours will be chosen automatically to be less than or equal to the value of `ncontours`. Has an effect only if `autocontour` is *true*.

=item * reversescale

Reverses the colorscale.

=item * showscale

Determines whether or not a colorbar is displayed for this trace.

=item * text

Sets the text elements associated with each z value.

=item * transpose

Transposes the z data.

=item * x

Sets the x coordinates.

=item * x0

Alternate to `x`. Builds a linear space of x coordinates. Use with `dx` where `x0` is the starting coordinate and `dx` the step.

=item * xtype

If *array*, the heatmap's x coordinates are given by *x* (the default behavior when `x` is provided). If *scaled*, the heatmap's x coordinates are given by *x0* and *dx* (the default behavior when `x` is not provided).

=item * y

Sets the y coordinates.

=item * y0

Alternate to `y`. Builds a linear space of y coordinates. Use with `dy` where `y0` is the starting coordinate and `dy` the step.

=item * ytype

If *array*, the heatmap's y coordinates are given by *y* (the default behavior when `y` is provided) If *scaled*, the heatmap's y coordinates are given by *y0* and *dy* (the default behavior when `y` is not provided)

=item * z

Sets the z data.

=item * zauto

Determines the whether or not the color domain is computed with respect to the input data.

=item * zmax

Sets the upper bound of color domain.

=item * zmin

Sets the lower bound of color domain.

=item * name

Sets the trace name

=back

=head2 type

Trace type.

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
