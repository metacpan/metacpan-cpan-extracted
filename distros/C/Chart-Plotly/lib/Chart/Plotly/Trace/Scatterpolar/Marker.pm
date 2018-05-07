package Chart::Plotly::Trace::Scatterpolar::Marker;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Scatterpolar::Marker::Colorbar;
use Chart::Plotly::Trace::Scatterpolar::Marker::Gradient;
use Chart::Plotly::Trace::Scatterpolar::Marker::Line;

our $VERSION = '0.019';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace scatterpolar.

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
      "Has an effect only if `marker.color` is set to a numerical array. Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `marker.colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.",
);

has cauto => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Has an effect only if `marker.color` is set to a numerical array and `cmin`, `cmax` are set by the user. In this case, it controls whether the range of colors in `colorscale` is mapped to the range of values in the `color` array (`cauto: true`), or the `cmin`/`cmax` values (`cauto: false`). Defaults to `false` when `cmin`, `cmax` are set by the user.",
);

has cmax => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Has an effect only if `marker.color` is set to a numerical array. Sets the upper bound of the color domain. Value should be associated to the `marker.color` array index, and if set, `marker.cmin` must be set as well.",
);

has cmin => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Has an effect only if `marker.color` is set to a numerical array. Sets the lower bound of the color domain. Value should be associated to the `marker.color` array index, and if set, `marker.cmax` must be set as well.",
);

has color => (
    is  => "rw",
    isa => "Maybe[ArrayRef]",
    documentation =>
      "Sets the marker color. It accepts either a specific color or an array of numbers that are mapped to the colorscale relative to the max and min values of the array or relative to `cmin` and `cmax` if set.",
);

has colorbar => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Scatterpolar::Marker::Colorbar", );

has colorscale => (
    is => "rw",
    documentation =>
      "Sets the colorscale and only has an effect if `marker.color` is set to a numerical array. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use `marker.cmin` and `marker.cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys, YlGnBu, Greens, YlOrRd, Bluered, RdBu, Reds, Blues, Picnic, Rainbow, Portland, Jet, Hot, Blackbody, Earth, Electric, Viridis, Cividis",
);

has colorsrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on plot.ly for  color .",
);

has gradient => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Scatterpolar::Marker::Gradient", );

has line => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Scatterpolar::Marker::Line", );

has maxdisplayed => (
              is            => "rw",
              isa           => "Num",
              documentation => "Sets a maximum number of points to be drawn on the graph. *0* corresponds to no limit.",
);

has opacity => ( is            => "rw",
                 isa           => "Num|ArrayRef[Num]",
                 documentation => "Sets the marker opacity.",
);

has opacitysrc => ( is            => "rw",
                    isa           => "Str",
                    documentation => "Sets the source reference on plot.ly for  opacity .",
);

has reversescale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Has an effect only if `marker.color` is set to a numerical array. Reverses the color mapping if true (`cmin` will correspond to the last color in the array and `cmax` will correspond to the first color).",
);

has showscale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Has an effect only if `marker.color` is set to a numerical array. Determines whether or not a colorbar is displayed.",
);

has size => ( is            => "rw",
              isa           => "Num|ArrayRef[Num]",
              documentation => "Sets the marker size (in px).",
);

has sizemin => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Has an effect only if `marker.size` is set to a numerical array. Sets the minimum size (in px) of the rendered marker points.",
);

has sizemode => (
    is  => "rw",
    isa => enum( [ "diameter", "area" ] ),
    documentation =>
      "Has an effect only if `marker.size` is set to a numerical array. Sets the rule for which the data in `size` is converted to pixels.",
);

has sizeref => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Has an effect only if `marker.size` is set to a numerical array. Sets the scale factor used to determine the rendered size of marker points. Use with `sizemin` and `sizemode`.",
);

has sizesrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on plot.ly for  size .",
);

has symbol => (
    is  => "rw",
    isa => "Maybe[ArrayRef]",
    documentation =>
      "Sets the marker symbol type. Adding 100 is equivalent to appending *-open* to a symbol name. Adding 200 is equivalent to appending *-dot* to a symbol name. Adding 300 is equivalent to appending *-open-dot* or *dot-open* to a symbol name.",
);

has symbolsrc => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the source reference on plot.ly for  symbol .",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Scatterpolar::Marker - This attribute is one of the possible options for the trace scatterpolar.

=head1 VERSION

version 0.019

=head1 SYNOPSIS

 use Chart::Plotly qw(show_plot);
 use Chart::Plotly::Trace::Scatterpolar;
 # Example data from: https://plot.ly/javascript/polar-chart/#area-polar-chart
 my $scatterpolar1 = Chart::Plotly::Trace::Scatterpolar->new(
     mode      => "lines",
     r         => [ 0, 1.5, 1.5, 0, 2.5, 2.5, 0 ],
     theta     => [ 0, 10, 25, 0, 205, 215, 0 ],
     fill      => "toself",
     fillcolor => '#709BFF',
     line      => {
         color => 'black'
     }
 );
 my $scatterpolar2 = Chart::Plotly::Trace::Scatterpolar->new(
     mode      => "lines",
     r         => [ 0, 3.5, 3.5, 0 ],
     theta     => [ 0, 55, 75, 0 ],
     fill      => "toself",
     fillcolor => '#E4FF87',
     line      => {
         color => 'black'
     }
 );
 
 show_plot([ $scatterpolar1, $scatterpolar2 ]);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace scatterpolar.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#scatterpolar>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * autocolorscale

Has an effect only if `marker.color` is set to a numerical array. Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `marker.colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.

=item * cauto

Has an effect only if `marker.color` is set to a numerical array and `cmin`, `cmax` are set by the user. In this case, it controls whether the range of colors in `colorscale` is mapped to the range of values in the `color` array (`cauto: true`), or the `cmin`/`cmax` values (`cauto: false`). Defaults to `false` when `cmin`, `cmax` are set by the user.

=item * cmax

Has an effect only if `marker.color` is set to a numerical array. Sets the upper bound of the color domain. Value should be associated to the `marker.color` array index, and if set, `marker.cmin` must be set as well.

=item * cmin

Has an effect only if `marker.color` is set to a numerical array. Sets the lower bound of the color domain. Value should be associated to the `marker.color` array index, and if set, `marker.cmax` must be set as well.

=item * color

Sets the marker color. It accepts either a specific color or an array of numbers that are mapped to the colorscale relative to the max and min values of the array or relative to `cmin` and `cmax` if set.

=item * colorbar

=item * colorscale

Sets the colorscale and only has an effect if `marker.color` is set to a numerical array. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use `marker.cmin` and `marker.cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys, YlGnBu, Greens, YlOrRd, Bluered, RdBu, Reds, Blues, Picnic, Rainbow, Portland, Jet, Hot, Blackbody, Earth, Electric, Viridis, Cividis

=item * colorsrc

Sets the source reference on plot.ly for  color .

=item * gradient

=item * line

=item * maxdisplayed

Sets a maximum number of points to be drawn on the graph. *0* corresponds to no limit.

=item * opacity

Sets the marker opacity.

=item * opacitysrc

Sets the source reference on plot.ly for  opacity .

=item * reversescale

Has an effect only if `marker.color` is set to a numerical array. Reverses the color mapping if true (`cmin` will correspond to the last color in the array and `cmax` will correspond to the first color).

=item * showscale

Has an effect only if `marker.color` is set to a numerical array. Determines whether or not a colorbar is displayed.

=item * size

Sets the marker size (in px).

=item * sizemin

Has an effect only if `marker.size` is set to a numerical array. Sets the minimum size (in px) of the rendered marker points.

=item * sizemode

Has an effect only if `marker.size` is set to a numerical array. Sets the rule for which the data in `size` is converted to pixels.

=item * sizeref

Has an effect only if `marker.size` is set to a numerical array. Sets the scale factor used to determine the rendered size of marker points. Use with `sizemin` and `sizemode`.

=item * sizesrc

Sets the source reference on plot.ly for  size .

=item * symbol

Sets the marker symbol type. Adding 100 is equivalent to appending *-open* to a symbol name. Adding 200 is equivalent to appending *-dot* to a symbol name. Adding 300 is equivalent to appending *-open-dot* or *dot-open* to a symbol name.

=item * symbolsrc

Sets the source reference on plot.ly for  symbol .

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
