package Chart::Plotly::Trace::Scattercarpet::Marker;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Scattercarpet::Marker::Colorbar;
use Chart::Plotly::Trace::Scattercarpet::Marker::Gradient;
use Chart::Plotly::Trace::Scattercarpet::Marker::Line;

our $VERSION = '0.027';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace scattercarpet.

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
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Scattercarpet::Marker::Colorbar", );

has colorscale => (
    is => "rw",
    documentation =>
      "Sets the colorscale. Has an effect only if in `marker.color`is set to a numerical array. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use`marker.cmin` and `marker.cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys,YlGnBu,Greens,YlOrRd,Bluered,RdBu,Reds,Blues,Picnic,Rainbow,Portland,Jet,Hot,Blackbody,Earth,Electric,Viridis,Cividis.",
);

has colorsrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on plot.ly for  color .",
);

has gradient => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Scattercarpet::Marker::Gradient", );

has line => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Scattercarpet::Marker::Line", );

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
      "Reverses the color mapping if true. Has an effect only if in `marker.color`is set to a numerical array. If true, `marker.cmin` will correspond to the last color in the array and `marker.cmax` will correspond to the first color.",
);

has showscale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not a colorbar is displayed for this trace. Has an effect only if in `marker.color`is set to a numerical array.",
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

Chart::Plotly::Trace::Scattercarpet::Marker - This attribute is one of the possible options for the trace scattercarpet.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use Chart::Plotly qw(show_plot);
 use Chart::Plotly::Trace::Carpet;
 use Chart::Plotly::Trace::Scattercarpet;
 # Example data from: https://plot.ly/javascript/carpet-scatter/#add-carpet-scatter-trace
 my $scattercarpet = Chart::Plotly::Trace::Scattercarpet->new(
     a    => [ map {$_ * 1e-6} 4, 4.5, 5, 6 ],
     b    => [ map {$_ * 1e-6} 1.5, 2.5, 1.5, 2.5 ],
     line => { shape => 'spline', smoothing => 1 }
 );
 
 my $carpet = Chart::Plotly::Trace::Carpet->new(
     a     => [ map {$_ * 1e-6} 4, 4, 4, 4.5, 4.5, 4.5, 5, 5, 5, 6, 6, 6 ],
     b     => [ map {$_ * 1e-6} 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3 ],
     y     => [ 2, 3.5, 4, 3, 4.5, 5, 5.5, 6.5, 7.5, 8, 8.5, 10 ],
     aaxis => {
         tickprefix     => 'a = ',
         ticksuffix     => 'm',
         smoothing      => 1,
         minorgridcount => 9,
     },
     baxis => {
         tickprefix     => 'b = ',
         ticksuffix     => 'Pa',
         smoothing      => 1,
         minorgridcount => 9,
     }
 );
 
 show_plot([ $carpet, $scattercarpet ]);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace scattercarpet.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#scattercarpet>

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

=item * gradient

=item * line

=item * maxdisplayed

Sets a maximum number of points to be drawn on the graph. *0* corresponds to no limit.

=item * opacity

Sets the marker opacity.

=item * opacitysrc

Sets the source reference on plot.ly for  opacity .

=item * reversescale

Reverses the color mapping if true. Has an effect only if in `marker.color`is set to a numerical array. If true, `marker.cmin` will correspond to the last color in the array and `marker.cmax` will correspond to the first color.

=item * showscale

Determines whether or not a colorbar is displayed for this trace. Has an effect only if in `marker.color`is set to a numerical array.

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

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
