package Chart::Plotly::Trace::Cone;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Cone::Colorbar;
use Chart::Plotly::Trace::Cone::Hoverlabel;
use Chart::Plotly::Trace::Cone::Lighting;
use Chart::Plotly::Trace::Cone::Lightposition;
use Chart::Plotly::Trace::Cone::Stream;
use Chart::Plotly::Trace::Cone::Transform;

our $VERSION = '0.020';    # VERSION

# ABSTRACT: Use cone traces to visualize vector fields.  Specify a vector field using 6 1D arrays, 3 position arrays `x`, `y` and `z` and 3 vector component arrays `u`, `v`, `w`. The cones are drawn exactly at the positions given by `x`, `y` and `z`.

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

has anchor => (
    is  => "rw",
    isa => enum( [ "tip", "tail", "cm", "center" ] ),
    documentation =>
      "Sets the cones' anchor with respect to their x/y/z positions. Note that *cm* denote the cone's center of mass which corresponds to 1/4 from the tail to tip.",
);

has autocolorscale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Has an effect only if `color` is set to a numerical array. Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.",
);

has cauto => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Has an effect only if `color` is set to a numerical array and `cmin`, `cmax` are set by the user. In this case, it controls whether the range of colors in `colorscale` is mapped to the range of values in the `color` array (`cauto: true`), or the `cmin`/`cmax` values (`cauto: false`). Defaults to `false` when `cmin`, `cmax` are set by the user.",
);

has cmax => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Has an effect only if `color` is set to a numerical array. Sets the upper bound of the color domain. Value should be associated to the `color` array index, and if set, `cmin` must be set as well.",
);

has cmin => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Has an effect only if `color` is set to a numerical array. Sets the lower bound of the color domain. Value should be associated to the `color` array index, and if set, `cmax` must be set as well.",
);

has colorbar => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Cone::Colorbar", );

has colorscale => (
    is => "rw",
    documentation =>
      "Sets the colorscale and only has an effect if `color` is set to a numerical array. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use `cmin` and `cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys, YlGnBu, Greens, YlOrRd, Bluered, RdBu, Reds, Blues, Picnic, Rainbow, Portland, Jet, Hot, Blackbody, Earth, Electric, Viridis, Cividis",
);

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
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Cone::Hoverlabel", );

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

has lighting => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Cone::Lighting", );

has lightposition => ( is  => "rw",
                       isa => "Maybe[HashRef]|Chart::Plotly::Trace::Cone::Lightposition", );

has name => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the trace name. The trace name appear as the legend item and on hover.",
);

has opacity => ( is            => "rw",
                 isa           => "Num",
                 documentation => "Sets the opacity of the surface.",
);

has reversescale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Has an effect only if `color` is set to a numerical array. Reverses the color mapping if true (`cmin` will correspond to the last color in the array and `cmax` will correspond to the first color).",
);

has scene => (
    is => "rw",
    documentation =>
      "Sets a reference between this trace's 3D coordinate system and a 3D scene. If *scene* (the default value), the (x,y,z) coordinates refer to `layout.scene`. If *scene2*, the (x,y,z) coordinates refer to `layout.scene2`, and so on.",
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

has sizemode => (
    is  => "rw",
    isa => enum( [ "scaled", "absolute" ] ),
    documentation =>
      "Sets the mode by which the cones are sized. If *scaled*, `sizeref` scales such that the reference cone size for the maximum vector magnitude is 1. If *absolute*, `sizeref` scales such that the reference cone size for vector magnitude 1 is one grid unit.",
);

has sizeref => ( is            => "rw",
                 isa           => "Num",
                 documentation => "Sets the cone size reference value.",
);

has stream => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Cone::Stream", );

has text => (
    is  => "rw",
    isa => "Str|ArrayRef[Str]",
    documentation =>
      "Sets the text elements associated with the cones. If trace `hoverinfo` contains a *text* flag and *hovertext* is not set, these elements will be seen in the hover labels.",
);

has textsrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on plot.ly for  text .",
);

has transforms => ( is  => "rw",
                    isa => "ArrayRef|ArrayRef[Chart::Plotly::Trace::Cone::Transform]", );

has u => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the x components of the vector field.",
);

has uid => ( is  => "rw",
             isa => "Str", );

has usrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  u .",
);

has v => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the y components of the vector field.",
);

has visible => (
    is => "rw",
    documentation =>
      "Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).",
);

has vsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  v .",
);

has w => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the z components of the vector field.",
);

has wsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  w .",
);

has x => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the x coordinates of the vector field and of the displayed cones.",
);

has xsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  x .",
);

has y => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the y coordinates of the vector field and of the displayed cones.",
);

has ysrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  y .",
);

has z => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the z coordinates of the vector field and of the displayed cones.",
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

Chart::Plotly::Trace::Cone - Use cone traces to visualize vector fields.  Specify a vector field using 6 1D arrays, 3 position arrays `x`, `y` and `z` and 3 vector component arrays `u`, `v`, `w`. The cones are drawn exactly at the positions given by `x`, `y` and `z`.

=head1 VERSION

version 0.020

=head1 SYNOPSIS

 use Chart::Plotly qw(show_plot);
 use Chart::Plotly::Trace::Cone;
 
 my $cone = Chart::Plotly::Trace::Cone->new(
                 x => [1, 2],
                 y => [1, 2],
                 z => [1, 2],
                 u => [1, 2],
                 v => [1, 2],
                 w => [1, 2]
 );
 
 show_plot([ $cone ]);

=head1 DESCRIPTION

Use cone traces to visualize vector fields.  Specify a vector field using 6 1D arrays, 3 position arrays `x`, `y` and `z` and 3 vector component arrays `u`, `v`, `w`. The cones are drawn exactly at the positions given by `x`, `y` and `z`.

Screenshot of the above example:

=for HTML <p>
<img src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/cone.png" alt="Screenshot of the above example">
</p>

=for markdown ![Screenshot of the above example](https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/cone.png)

=for HTML <p>
<iframe src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/cone.html" style="border:none;" width="80%" height="520"></iframe>
</p>

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#cone>

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

=item * anchor

Sets the cones' anchor with respect to their x/y/z positions. Note that *cm* denote the cone's center of mass which corresponds to 1/4 from the tail to tip.

=item * autocolorscale

Has an effect only if `color` is set to a numerical array. Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.

=item * cauto

Has an effect only if `color` is set to a numerical array and `cmin`, `cmax` are set by the user. In this case, it controls whether the range of colors in `colorscale` is mapped to the range of values in the `color` array (`cauto: true`), or the `cmin`/`cmax` values (`cauto: false`). Defaults to `false` when `cmin`, `cmax` are set by the user.

=item * cmax

Has an effect only if `color` is set to a numerical array. Sets the upper bound of the color domain. Value should be associated to the `color` array index, and if set, `cmin` must be set as well.

=item * cmin

Has an effect only if `color` is set to a numerical array. Sets the lower bound of the color domain. Value should be associated to the `color` array index, and if set, `cmax` must be set as well.

=item * colorbar

=item * colorscale

Sets the colorscale and only has an effect if `color` is set to a numerical array. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use `cmin` and `cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys, YlGnBu, Greens, YlOrRd, Bluered, RdBu, Reds, Blues, Picnic, Rainbow, Portland, Jet, Hot, Blackbody, Earth, Electric, Viridis, Cividis

=item * customdata

Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements

=item * customdatasrc

Sets the source reference on plot.ly for  customdata .

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

=item * lighting

=item * lightposition

=item * name

Sets the trace name. The trace name appear as the legend item and on hover.

=item * opacity

Sets the opacity of the surface.

=item * reversescale

Has an effect only if `color` is set to a numerical array. Reverses the color mapping if true (`cmin` will correspond to the last color in the array and `cmax` will correspond to the first color).

=item * scene

Sets a reference between this trace's 3D coordinate system and a 3D scene. If *scene* (the default value), the (x,y,z) coordinates refer to `layout.scene`. If *scene2*, the (x,y,z) coordinates refer to `layout.scene2`, and so on.

=item * selectedpoints

Array containing integer indices of selected points. Has an effect only for traces that support selections. Note that an empty array means an empty selection where the `unselected` are turned on for all points, whereas, any other non-array values means no selection all where the `selected` and `unselected` styles have no effect.

=item * showlegend

Determines whether or not an item corresponding to this trace is shown in the legend.

=item * showscale

Determines whether or not a colorbar is displayed for this trace.

=item * sizemode

Sets the mode by which the cones are sized. If *scaled*, `sizeref` scales such that the reference cone size for the maximum vector magnitude is 1. If *absolute*, `sizeref` scales such that the reference cone size for vector magnitude 1 is one grid unit.

=item * sizeref

Sets the cone size reference value.

=item * stream

=item * text

Sets the text elements associated with the cones. If trace `hoverinfo` contains a *text* flag and *hovertext* is not set, these elements will be seen in the hover labels.

=item * textsrc

Sets the source reference on plot.ly for  text .

=item * transforms

=item * u

Sets the x components of the vector field.

=item * uid

=item * usrc

Sets the source reference on plot.ly for  u .

=item * v

Sets the y components of the vector field.

=item * visible

Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).

=item * vsrc

Sets the source reference on plot.ly for  v .

=item * w

Sets the z components of the vector field.

=item * wsrc

Sets the source reference on plot.ly for  w .

=item * x

Sets the x coordinates of the vector field and of the displayed cones.

=item * xsrc

Sets the source reference on plot.ly for  x .

=item * y

Sets the y coordinates of the vector field and of the displayed cones.

=item * ysrc

Sets the source reference on plot.ly for  y .

=item * z

Sets the z coordinates of the vector field and of the displayed cones.

=item * zsrc

Sets the source reference on plot.ly for  z .

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
