package Chart::Plotly::Trace::Streamtube;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Streamtube::Colorbar;
use Chart::Plotly::Trace::Streamtube::Hoverlabel;
use Chart::Plotly::Trace::Streamtube::Lighting;
use Chart::Plotly::Trace::Streamtube::Lightposition;
use Chart::Plotly::Trace::Streamtube::Starts;
use Chart::Plotly::Trace::Streamtube::Stream;

our $VERSION = '0.022';    # VERSION

# ABSTRACT: Use a streamtube trace to visualize flow in a vector field.  Specify a vector field using 6 1D arrays of equal length, 3 position arrays `x`, `y` and `z` and 3 vector component arrays `u`, `v`, and `w`.  By default, the tubes' starting positions will be cut from the vector field's x-z plane at its minimum y value. To specify your own starting position, use attributes `starts.x`, `starts.y` and `starts.z`.

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
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.",
);

has cauto => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not the color domain is computed with respect to the input data (here u/v/w norm) or the bounds set in `cmin` and `cmax`  Defaults to `false` when `cmin` and `cmax` are set by the user.",
);

has cmax => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the upper bound of the color domain. Value should have the same units as u/v/w norm and if set, `cmin` must be set as well.",
);

has cmin => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the lower bound of the color domain. Value should have the same units as u/v/w norm and if set, `cmax` must be set as well.",
);

has colorbar => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Streamtube::Colorbar", );

has colorscale => (
    is => "rw",
    documentation =>
      "Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use`cmin` and `cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys,YlGnBu,Greens,YlOrRd,Bluered,RdBu,Reds,Blues,Picnic,Rainbow,Portland,Jet,Hot,Blackbody,Earth,Electric,Viridis,Cividis.",
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
    isa => "Str|ArrayRef[Str]",
    documentation =>
      "Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.",
);

has hoverinfosrc => ( is            => "rw",
                      isa           => "Str",
                      documentation => "Sets the source reference on plot.ly for  hoverinfo .",
);

has hoverlabel => ( is  => "rw",
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Streamtube::Hoverlabel", );

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
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Streamtube::Lighting", );

has lightposition => ( is  => "rw",
                       isa => "Maybe[HashRef]|Chart::Plotly::Trace::Streamtube::Lightposition", );

has maxdisplayed => ( is            => "rw",
                      isa           => "Int",
                      documentation => "The maximum number of displayed segments in a streamtube.",
);

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
      "Reverses the color mapping if true. If true, `cmin` will correspond to the last color in the array and `cmax` will correspond to the first color.",
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

has sizeref => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "The scaling factor for the streamtubes. The default is 1, which avoids two max divergence tubes from touching at adjacent starting positions.",
);

has starts => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Streamtube::Starts", );

has stream => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Streamtube::Stream", );

has text => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Sets a text element associated with this trace. If trace `hoverinfo` contains a *text* flag, this text element will be seen in all hover labels. Note that streamtube traces do not support array `text` values.",
);

has u => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the x components of the vector field.",
);

has uid => ( is  => "rw",
             isa => "Str", );

has uirevision => (
    is  => "rw",
    isa => "Any",
    documentation =>
      "Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.",
);

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
           documentation => "Sets the x coordinates of the vector field.",
);

has xsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  x .",
);

has y => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the y coordinates of the vector field.",
);

has ysrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  y .",
);

has z => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the z coordinates of the vector field.",
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

Chart::Plotly::Trace::Streamtube - Use a streamtube trace to visualize flow in a vector field.  Specify a vector field using 6 1D arrays of equal length, 3 position arrays `x`, `y` and `z` and 3 vector component arrays `u`, `v`, and `w`.  By default, the tubes' starting positions will be cut from the vector field's x-z plane at its minimum y value. To specify your own starting position, use attributes `starts.x`, `starts.y` and `starts.z`.

=head1 VERSION

version 0.022

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Trace::Streamtube;
 use Chart::Plotly::Plot;
 
 # Example from https://github.com/plotly/plotly.js/blob/273292dcb24170f775dbc7ebb285c9b6a80b10f4/test/image/mocks/gl3d_streamtube-simple.json
 
 my $trace = Chart::Plotly::Trace::Streamtube->new(
     cmax    => 3,
     cmin    => 0,
     sizeref => 0.5,
     type    => 'streamtube',
     u       => [ (1) x 9, (1.8414709848079) x 9, (1.90929742682568) x 9 ],
     v       => [
            (1) x 3,
            (0.54030230586814) x 3,
            (-0.416146836547142) x 3,
            (1) x 3,
            (0.54030230586814) x 3,
            (-0.416146836547142) x 3,
            (1) x 3,
            (0.54030230586814) x 3,
            (-0.416146836547142) x 3
     ],
     w => [ 0,                  0.0886560619984019, 0.169392742018511,  0,
            0.0886560619984019, 0.169392742018511,  0,                  0.0886560619984019,
            0.169392742018511,  0,                  0.0886560619984019, 0.169392742018511,
            0,                  0.0886560619984019, 0.169392742018511,  0,
            0.0886560619984019, 0.169392742018511,  0,                  0.0886560619984019,
            0.169392742018511,  0,                  0.0886560619984019, 0.169392742018511,
            0,                  0.0886560619984019, 0.169392742018511
     ],
     x => [ (0) x 9, (1) x 9, (2) x 9 ],
     y => [ (0) x 3, (1) x 3, (2) x 3, (0) x 3, (1) x 3, (2) x 3, (0) x 3, (1) x 3, (2) x 3 ],
     z => [ 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2 ]
 
 );
 
 my $plot = Chart::Plotly::Plot->new( traces => [$trace],
                                      layout => {
                                                  scene => {
                                                             camera => {
                                                                         eye => { x => -0.724361245886518,
                                                                                  y => 1.9269804254718,
                                                                                  z => 0.670482829986172
                                                                         }
                                                             }
                                                  }
                                      }
 );
 
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

Use a streamtube trace to visualize flow in a vector field.  Specify a vector field using 6 1D arrays of equal length, 3 position arrays `x`, `y` and `z` and 3 vector component arrays `u`, `v`, and `w`.  By default, the tubes' starting positions will be cut from the vector field's x-z plane at its minimum y value. To specify your own starting position, use attributes `starts.x`, `starts.y` and `starts.z`.

Screenshot of the above example:

=for HTML <p>
<img src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/streamtube.png" alt="Screenshot of the above example">
</p>

=for markdown ![Screenshot of the above example](https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/streamtube.png)

=for HTML <p>
<iframe src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/streamtube.html" style="border:none;" width="80%" height="520"></iframe>
</p>

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#streamtube>

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

Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.

=item * cauto

Determines whether or not the color domain is computed with respect to the input data (here u/v/w norm) or the bounds set in `cmin` and `cmax`  Defaults to `false` when `cmin` and `cmax` are set by the user.

=item * cmax

Sets the upper bound of the color domain. Value should have the same units as u/v/w norm and if set, `cmin` must be set as well.

=item * cmin

Sets the lower bound of the color domain. Value should have the same units as u/v/w norm and if set, `cmax` must be set as well.

=item * colorbar

=item * colorscale

Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use`cmin` and `cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys,YlGnBu,Greens,YlOrRd,Bluered,RdBu,Reds,Blues,Picnic,Rainbow,Portland,Jet,Hot,Blackbody,Earth,Electric,Viridis,Cividis.

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

=item * maxdisplayed

The maximum number of displayed segments in a streamtube.

=item * name

Sets the trace name. The trace name appear as the legend item and on hover.

=item * opacity

Sets the opacity of the surface.

=item * reversescale

Reverses the color mapping if true. If true, `cmin` will correspond to the last color in the array and `cmax` will correspond to the first color.

=item * scene

Sets a reference between this trace's 3D coordinate system and a 3D scene. If *scene* (the default value), the (x,y,z) coordinates refer to `layout.scene`. If *scene2*, the (x,y,z) coordinates refer to `layout.scene2`, and so on.

=item * selectedpoints

Array containing integer indices of selected points. Has an effect only for traces that support selections. Note that an empty array means an empty selection where the `unselected` are turned on for all points, whereas, any other non-array values means no selection all where the `selected` and `unselected` styles have no effect.

=item * showlegend

Determines whether or not an item corresponding to this trace is shown in the legend.

=item * showscale

Determines whether or not a colorbar is displayed for this trace.

=item * sizeref

The scaling factor for the streamtubes. The default is 1, which avoids two max divergence tubes from touching at adjacent starting positions.

=item * starts

=item * stream

=item * text

Sets a text element associated with this trace. If trace `hoverinfo` contains a *text* flag, this text element will be seen in all hover labels. Note that streamtube traces do not support array `text` values.

=item * u

Sets the x components of the vector field.

=item * uid

=item * uirevision

Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.

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

Sets the x coordinates of the vector field.

=item * xsrc

Sets the source reference on plot.ly for  x .

=item * y

Sets the y coordinates of the vector field.

=item * ysrc

Sets the source reference on plot.ly for  y .

=item * z

Sets the z coordinates of the vector field.

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
