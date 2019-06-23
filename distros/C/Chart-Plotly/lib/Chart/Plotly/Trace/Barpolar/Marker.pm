package Chart::Plotly::Trace::Barpolar::Marker;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Barpolar::Marker::Colorbar;
use Chart::Plotly::Trace::Barpolar::Marker::Line;

our $VERSION = '0.027';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace barpolar.

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

has autocolorscale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `marker.colorscale`. Has an effect only if in `marker.color`is set to a numerical array. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.",
);

has cauto => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not the color domain is computed with respect to the input data (here in `marker.color`) or the bounds set in `marker.cmin` and `marker.cmax`  Has an effect only if in `marker.color`is set to a numerical array. Defaults to `false` when `marker.cmin` and `marker.cmax` are set by the user.",
);

has cmax => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the upper bound of the color domain. Has an effect only if in `marker.color`is set to a numerical array. Value should have the same units as in `marker.color` and if set, `marker.cmin` must be set as well.",
);

has cmid => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the mid-point of the color domain by scaling `marker.cmin` and/or `marker.cmax` to be equidistant to this point. Has an effect only if in `marker.color`is set to a numerical array. Value should have the same units as in `marker.color`. Has no effect when `marker.cauto` is `false`.",
);

has cmin => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the lower bound of the color domain. Has an effect only if in `marker.color`is set to a numerical array. Value should have the same units as in `marker.color` and if set, `marker.cmax` must be set as well.",
);

has color => (
    is  => "rw",
    isa => "Str|ArrayRef[Str]",
    documentation =>
      "Sets themarkercolor. It accepts either a specific color or an array of numbers that are mapped to the colorscale relative to the max and min values of the array or relative to `marker.cmin` and `marker.cmax` if set.",
);

has coloraxis => (
    is => "rw",
    documentation =>
      "Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.",
);

has colorbar => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Barpolar::Marker::Colorbar", );

has colorscale => (
    is => "rw",
    documentation =>
      "Sets the colorscale. Has an effect only if in `marker.color`is set to a numerical array. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use`marker.cmin` and `marker.cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys,YlGnBu,Greens,YlOrRd,Bluered,RdBu,Reds,Blues,Picnic,Rainbow,Portland,Jet,Hot,Blackbody,Earth,Electric,Viridis,Cividis.",
);

has colorsrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on plot.ly for  color .",
);

has line => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Barpolar::Marker::Line", );

has opacity => ( is            => "rw",
                 isa           => "Num|ArrayRef[Num]",
                 documentation => "Sets the opacity of the bars.",
);

has opacitysrc => ( is            => "rw",
                    isa           => "Str",
                    documentation => "Sets the source reference on plot.ly for  opacity .",
);

has reversescale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Reverses the color mapping if true. Has an effect only if in `marker.color`is set to a numerical array. If true, `marker.cmin` will correspond to the last color in the array and `marker.cmax` will correspond to the first color.",
);

has showscale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not a colorbar is displayed for this trace. Has an effect only if in `marker.color`is set to a numerical array.",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Barpolar::Marker - This attribute is one of the possible options for the trace barpolar.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Trace::Barpolar;
 use Chart::Plotly::Plot;
 
 # Example from https://github.com/plotly/plotly.js/blob/235fe5b214a576d5749ab4c2aaf625dbf7138d63/test/image/mocks/polar_wind-rose.json
 my $trace1 = Chart::Plotly::Trace::Barpolar->new(
     r    => [ 77.5,    72.5,  70.0,   45.0,  22.5,    42.5,  40.0,   62.5 ],
     t    => [ 'North', 'N-E', 'East', 'S-E', 'South', 'S-W', 'West', 'N-W' ],
     name => '11-14 m/s',
     marker => { color => 'rgb(106,81,163)' },
 );
 
 my $trace2 = {
     r    => [ 57.5,    50.0,  45.0,   35.0,  20.0,    22.5,  37.5,   55.0 ],
     t    => [ 'North', 'N-E', 'East', 'S-E', 'South', 'S-W', 'West', 'N-W' ],
     name => '8-11 m/s',
     marker => { color => 'rgb(158,154,200)' },
     type   => 'barpolar'
 };
 
 my $trace3 = {
     r    => [ 40.0,    30.0,  30.0,   35.0,  7.5,     7.5,   32.5,   40.0 ],
     t    => [ 'North', 'N-E', 'East', 'S-E', 'South', 'S-W', 'West', 'N-W' ],
     name => '5-8 m/s',
     marker => { color => 'rgb(203,201,226)' },
     type   => 'barpolar'
 };
 
 my $trace4 = {
     r    => [ 20.0,    7.5,   15.0,   22.5,  2.5,     2.5,   12.5,   22.5 ],
     t    => [ 'North', 'N-E', 'East', 'S-E', 'South', 'S-W', 'West', 'N-W' ],
     name => '< 5 m/s',
     marker => { color => 'rgb(242,240,247)' },
     type   => 'barpolar'
 };
 
 my $plot = Chart::Plotly::Plot->new(
     traces => [ $trace1, $trace2, $trace3, $trace4 ],
     layout => {
         title  => 'Wind Speed Distribution in Laurel, NE',
         font   => { size => 16 },
         legend => { font => { size => 16 } },
         polar  => {
             radialaxis => { ticksuffix => '%', angle => 45, dtick => 20 },
             barmode    => "overlay",
             angularaxis => { direction => "clockwise" },
             bargap      => 0
         }
       }
 
 );
 
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace barpolar.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#barpolar>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * autocolorscale

Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `marker.colorscale`. Has an effect only if in `marker.color`is set to a numerical array. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.

=item * cauto

Determines whether or not the color domain is computed with respect to the input data (here in `marker.color`) or the bounds set in `marker.cmin` and `marker.cmax`  Has an effect only if in `marker.color`is set to a numerical array. Defaults to `false` when `marker.cmin` and `marker.cmax` are set by the user.

=item * cmax

Sets the upper bound of the color domain. Has an effect only if in `marker.color`is set to a numerical array. Value should have the same units as in `marker.color` and if set, `marker.cmin` must be set as well.

=item * cmid

Sets the mid-point of the color domain by scaling `marker.cmin` and/or `marker.cmax` to be equidistant to this point. Has an effect only if in `marker.color`is set to a numerical array. Value should have the same units as in `marker.color`. Has no effect when `marker.cauto` is `false`.

=item * cmin

Sets the lower bound of the color domain. Has an effect only if in `marker.color`is set to a numerical array. Value should have the same units as in `marker.color` and if set, `marker.cmax` must be set as well.

=item * color

Sets themarkercolor. It accepts either a specific color or an array of numbers that are mapped to the colorscale relative to the max and min values of the array or relative to `marker.cmin` and `marker.cmax` if set.

=item * coloraxis

Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.

=item * colorbar

=item * colorscale

Sets the colorscale. Has an effect only if in `marker.color`is set to a numerical array. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use`marker.cmin` and `marker.cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys,YlGnBu,Greens,YlOrRd,Bluered,RdBu,Reds,Blues,Picnic,Rainbow,Portland,Jet,Hot,Blackbody,Earth,Electric,Viridis,Cividis.

=item * colorsrc

Sets the source reference on plot.ly for  color .

=item * line

=item * opacity

Sets the opacity of the bars.

=item * opacitysrc

Sets the source reference on plot.ly for  opacity .

=item * reversescale

Reverses the color mapping if true. Has an effect only if in `marker.color`is set to a numerical array. If true, `marker.cmin` will correspond to the last color in the array and `marker.cmax` will correspond to the first color.

=item * showscale

Determines whether or not a colorbar is displayed for this trace. Has an effect only if in `marker.color`is set to a numerical array.

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
