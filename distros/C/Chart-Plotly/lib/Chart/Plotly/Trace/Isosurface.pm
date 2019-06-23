package Chart::Plotly::Trace::Isosurface;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Isosurface::Caps;
use Chart::Plotly::Trace::Isosurface::Colorbar;
use Chart::Plotly::Trace::Isosurface::Contour;
use Chart::Plotly::Trace::Isosurface::Hoverlabel;
use Chart::Plotly::Trace::Isosurface::Lighting;
use Chart::Plotly::Trace::Isosurface::Lightposition;
use Chart::Plotly::Trace::Isosurface::Slices;
use Chart::Plotly::Trace::Isosurface::Spaceframe;
use Chart::Plotly::Trace::Isosurface::Stream;
use Chart::Plotly::Trace::Isosurface::Surface;

our $VERSION = '0.027';    # VERSION

# ABSTRACT: Draws isosurfaces between iso-min and iso-max values with coordinates given by four 1-dimensional arrays containing the `value`, `x`, `y` and `z` of every vertex of a uniform or non-uniform 3-D grid. Horizontal or vertical slices, caps as well as spaceframe between iso-min and iso-max values could also be drawn using this trace.

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
    my $plotly_meta = delete $hash{'pmeta'};
    if ( defined $plotly_meta ) {
        $hash{'meta'} = $plotly_meta;
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

has caps => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Caps", );

has cauto => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not the color domain is computed with respect to the input data (here `value`) or the bounds set in `cmin` and `cmax`  Defaults to `false` when `cmin` and `cmax` are set by the user.",
);

has cmax => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the upper bound of the color domain. Value should have the same units as `value` and if set, `cmin` must be set as well.",
);

has cmid => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the mid-point of the color domain by scaling `cmin` and/or `cmax` to be equidistant to this point. Value should have the same units as `value`. Has no effect when `cauto` is `false`.",
);

has cmin => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the lower bound of the color domain. Value should have the same units as `value` and if set, `cmax` must be set as well.",
);

has coloraxis => (
    is => "rw",
    documentation =>
      "Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.",
);

has colorbar => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Colorbar", );

has colorscale => (
    is => "rw",
    documentation =>
      "Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use`cmin` and `cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys,YlGnBu,Greens,YlOrRd,Bluered,RdBu,Reds,Blues,Picnic,Rainbow,Portland,Jet,Hot,Blackbody,Earth,Electric,Viridis,Cividis.",
);

has contour => ( is  => "rw",
                 isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Contour", );

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

has flatshading => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not normal smoothing is applied to the meshes, creating meshes with an angular, low-poly look via flat reflections.",
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
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Hoverlabel", );

has hovertemplate => (
    is  => "rw",
    isa => "Str|ArrayRef[Str]",
    documentation =>
      "Template string used for rendering the information that appear on hover box. Note that this will override `hoverinfo`. Variables are inserted using %{variable}, for example \"y: %{y}\". Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example \"Price: %{y:\$.2f}\". See https://github.com/d3/d3-format/blob/master/README.md#locale_format for details on the formatting syntax. The variables available in `hovertemplate` are the ones emitted as event data described at this link https://plot.ly/javascript/plotlyjs-events/#event-data. Additionally, every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available.  Anything contained in tag `<extra>` is displayed in the secondary box, for example \"<extra>{fullData.name}</extra>\". To hide the secondary box completely, use an empty tag `<extra></extra>`.",
);

has hovertemplatesrc => ( is            => "rw",
                          isa           => "Str",
                          documentation => "Sets the source reference on plot.ly for  hovertemplate .",
);

has hovertext => ( is            => "rw",
                   isa           => "Str|ArrayRef[Str]",
                   documentation => "Same as `text`.",
);

has hovertextsrc => ( is            => "rw",
                      isa           => "Str",
                      documentation => "Sets the source reference on plot.ly for  hovertext .",
);

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

has isomax => ( is            => "rw",
                isa           => "Num",
                documentation => "Sets the maximum boundary for iso-surface plot.",
);

has isomin => ( is            => "rw",
                isa           => "Num",
                documentation => "Sets the minimum boundary for iso-surface plot.",
);

has lighting => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Lighting", );

has lightposition => ( is  => "rw",
                       isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Lightposition", );

has pmeta => (
    is  => "rw",
    isa => "Any|ArrayRef[Any]",
    documentation =>
      "Assigns extra meta information associated with this trace that can be used in various text attributes. Attributes such as trace `name`, graph, axis and colorbar `title.text`, annotation `text` `rangeselector`, `updatemenues` and `sliders` `label` text all support `meta`. To access the trace `meta` values in an attribute in the same trace, simply use `%{meta[i]}` where `i` is the index or key of the `meta` item in question. To access trace `meta` in layout attributes, use `%{data[n[.meta[i]}` where `i` is the index or key of the `meta` and `n` is the trace index.",
);

has metasrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on plot.ly for  meta .",
);

has name => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the trace name. The trace name appear as the legend item and on hover.",
);

has opacity => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the opacity of the surface. Please note that in the case of using high `opacity` values for example a value greater than or equal to 0.5 on two surfaces (and 0.25 with four surfaces), an overlay of multiple transparent surfaces may not perfectly be sorted in depth by the webgl API. This behavior may be improved in the near future and is subject to change.",
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

has showscale => ( is            => "rw",
                   isa           => "Bool",
                   documentation => "Determines whether or not a colorbar is displayed for this trace.",
);

has slices => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Slices", );

has spaceframe => ( is  => "rw",
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Spaceframe", );

has stream => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Stream", );

has surface => ( is  => "rw",
                 isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Surface", );

has text => (
    is  => "rw",
    isa => "Str|ArrayRef[Str]",
    documentation =>
      "Sets the text elements associated with the vertices. If trace `hoverinfo` contains a *text* flag and *hovertext* is not set, these elements will be seen in the hover labels.",
);

has textsrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on plot.ly for  text .",
);

has uid => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Assign an id to this trace, Use this to provide object constancy between traces during animations and transitions.",
);

has uirevision => (
    is  => "rw",
    isa => "Any",
    documentation =>
      "Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.",
);

has value => ( is            => "rw",
               isa           => "ArrayRef|PDL",
               documentation => "Sets the 4th dimension (value) of the vertices.",
);

has valuesrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on plot.ly for  value .",
);

has visible => (
    is => "rw",
    documentation =>
      "Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).",
);

has x => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the X coordinates of the vertices on X axis.",
);

has xsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  x .",
);

has y => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the Y coordinates of the vertices on Y axis.",
);

has ysrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  y .",
);

has z => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the Z coordinates of the vertices on Z axis.",
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

Chart::Plotly::Trace::Isosurface - Draws isosurfaces between iso-min and iso-max values with coordinates given by four 1-dimensional arrays containing the `value`, `x`, `y` and `z` of every vertex of a uniform or non-uniform 3-D grid. Horizontal or vertical slices, caps as well as spaceframe between iso-min and iso-max values could also be drawn using this trace.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Trace::Isosurface;
 use Chart::Plotly::Plot;
 
 # Example from https://github.com/plotly/plotly.js/blob/bc8334b93034d6d08155e03acc9774b1e0bbf8e5/test/image/mocks/gl3d_isosurface_multiple-traces.json
 
 my $trace1 = Chart::Plotly::Trace::Isosurface->new(
             "colorscale"=>"Reds",
             "reversescale"=>JSON::true,
             "surface"=>{ "show"=>JSON::true },
             "spaceframe"=>{ "show"=>JSON::false },
             "slices"=>{
                 "x"=>{ "show"=>JSON::false },
                 "y"=>{ "show"=>JSON::false },
                 "z"=>{ "show"=>JSON::false }
             },
             "caps"=>{
                 "x"=>{ "show"=>JSON::true },
                 "y"=>{ "show"=>JSON::true },
                 "z"=>{ "show"=>JSON::true }
             },
             "contour"=>{
                 "show"=>JSON::false,
                 "width"=>4
             },
             "isomin"=>150,
             "isomax"=>250,
             "value"=>[
 
                 0, 125, 250, 375, 500, 625, 750, 875, 1000,
                 -125, 0, 125, 250, 375, 500, 625, 750, 875,
                 -250, -125, 0, 125, 250, 375, 500, 625, 750,
                 -375, -250, -125, 0, 125, 250, 375, 500, 625,
                 -500, -375, -250, -125, 0, 125, 250, 375, 500,
                 -625, -500, -375, -250, -125, 0, 125, 250, 375,
                 -750, -625, -500, -375, -250, -125, 0, 125, 250,
                 -875, -750, -625, -500, -375, -250, -125, 0, 125,
                 -1000, -875, -750, -625, -500, -375, -250, -125, 0,
 
                 -125, 0, 125, 250, 375, 500, 625, 750, 875,
                 -250, -121, 8, 137, 266, 395, 523, 652, 781,
                 -375, -242, -109, 23, 156, 289, 422, 555, 688,
                 -500, -363, -227, -90, 47, 184, 320, 457, 594,
                 -625, -484, -344, -203, -63, 78, 219, 359, 500,
                 -750, -605, -461, -316, -172, -27, 117, 262, 406,
                 -875, -727, -578, -430, -281, -133, 16, 164, 313,
                 -1000, -848, -695, -543, -391, -238, -86, 66, 219,
                 -1125, -969, -813, -656, -500, -344, -188, -31, 125,
 
                 -250, -125, 0, 125, 250, 375, 500, 625, 750,
                 -375, -242, -109, 23, 156, 289, 422, 555, 688,
                 -500, -359, -219, -78, 63, 203, 344, 484, 625,
                 -625, -477, -328, -180, -31, 117, 266, 414, 563,
                 -750, -594, -438, -281, -125, 31, 188, 344, 500,
                 -875, -711, -547, -383, -219, -55, 109, 273, 438,
                 -1000, -828, -656, -484, -313, -141, 31, 203, 375,
                 -1125, -945, -766, -586, -406, -227, -47, 133, 313,
                 -1250, -1063, -875, -688, -500, -313, -125, 63, 250,
 
                 -375, -250, -125, 0, 125, 250, 375, 500, 625,
                 -500, -363, -227, -90, 47, 184, 320, 457, 594,
                 -625, -477, -328, -180, -31, 117, 266, 414, 563,
                 -750, -590, -430, -270, -109, 51, 211, 371, 531,
                 -875, -703, -531, -359, -188, -16, 156, 328, 500,
                 -1000, -816, -633, -449, -266, -82, 102, 285, 469,
                 -1125, -930, -734, -539, -344, -148, 47, 242, 438,
                 -1250, -1043, -836, -629, -422, -215, -8, 199, 406,
                 -1375, -1156, -938, -719, -500, -281, -63, 156, 375,
 
                 -500, -375, -250, -125, 0, 125, 250, 375, 500,
                 -625, -484, -344, -203, -63, 78, 219, 359, 500,
                 -750, -594, -438, -281, -125, 31, 188, 344, 500,
                 -875, -703, -531, -359, -188, -16, 156, 328, 500,
                 -1000, -813, -625, -438, -250, -63, 125, 313, 500,
                 -1125, -922, -719, -516, -313, -109, 94, 297, 500,
                 -1250, -1031, -813, -594, -375, -156, 63, 281, 500,
                 -1375, -1141, -906, -672, -438, -203, 31, 266, 500,
                 -1500, -1250, -1000, -750, -500, -250, 0, 250, 500,
 
                 -625, -500, -375, -250, -125, 0, 125, 250, 375,
                 -750, -605, -461, -316, -172, -27, 117, 262, 406,
                 -875, -711, -547, -383, -219, -55, 109, 273, 438,
                 -1000, -816, -633, -449, -266, -82, 102, 285, 469,
                 -1125, -922, -719, -516, -313, -109, 94, 297, 500,
                 -1250, -1027, -805, -582, -359, -137, 86, 309, 531,
                 -1375, -1133, -891, -648, -406, -164, 78, 320, 563,
                 -1500, -1238, -977, -715, -453, -191, 70, 332, 594,
                 -1625, -1344, -1063, -781, -500, -219, 63, 344, 625,
 
                 -750, -625, -500, -375, -250, -125, 0, 125, 250,
                 -875, -727, -578, -430, -281, -133, 16, 164, 313,
                 -1000, -828, -656, -484, -313, -141, 31, 203, 375,
                 -1125, -930, -734, -539, -344, -148, 47, 242, 438,
                 -1250, -1031, -813, -594, -375, -156, 63, 281, 500,
                 -1375, -1133, -891, -648, -406, -164, 78, 320, 563,
                 -1500, -1234, -969, -703, -438, -172, 94, 359, 625,
                 -1625, -1336, -1047, -758, -469, -180, 109, 398, 688,
                 -1750, -1438, -1125, -813, -500, -188, 125, 438, 750,
 
                 -875, -750, -625, -500, -375, -250, -125, 0, 125,
                 -1000, -848, -695, -543, -391, -238, -86, 66, 219,
                 -1125, -945, -766, -586, -406, -227, -47, 133, 313,
                 -1250, -1043, -836, -629, -422, -215, -8, 199, 406,
                 -1375, -1141, -906, -672, -438, -203, 31, 266, 500,
                 -1500, -1238, -977, -715, -453, -191, 70, 332, 594,
                 -1625, -1336, -1047, -758, -469, -180, 109, 398, 688,
                 -1750, -1434, -1117, -801, -484, -168, 148, 465, 781,
                 -1875, -1531, -1188, -844, -500, -156, 188, 531, 875,
 
                 -1000, -875, -750, -625, -500, -375, -250, -125, 0,
                 -1125, -969, -813, -656, -500, -344, -188, -31, 125,
                 -1250, -1063, -875, -688, -500, -313, -125, 63, 250,
                 -1375, -1156, -938, -719, -500, -281, -63, 156, 375,
                 -1500, -1250, -1000, -750, -500, -250, 0, 250, 500,
                 -1625, -1344, -1063, -781, -500, -219, 63, 344, 625,
                 -1750, -1438, -1125, -813, -500, -188, 125, 438, 750,
                 -1875, -1531, -1188, -844, -500, -156, 188, 531, 875,
                 -2000, -1625, -1250, -875, -500, -125, 250, 625, 1000
             ],
             "x"=>[
 
                 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000,
                 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000,
                 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000,
                 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000,
                 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000,
                 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000,
                 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000,
                 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000,
                 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000,
 
                 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875,
                 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875,
                 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875,
                 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875,
                 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875,
                 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875,
                 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875,
                 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875,
                 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875, 1.875,
 
                 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750,
                 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750,
                 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750,
                 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750,
                 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750,
                 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750,
                 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750,
                 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750,
                 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750, 1.750,
 
                 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625,
                 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625,
                 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625,
                 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625,
                 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625,
                 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625,
                 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625,
                 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625,
                 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625, 1.625,
 
                 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500,
                 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500,
                 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500,
                 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500,
                 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500,
                 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500,
                 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500,
                 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500,
                 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500,
 
                 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375,
                 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375,
                 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375,
                 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375,
                 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375,
                 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375,
                 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375,
                 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375,
                 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375, 1.375,
 
                 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250,
                 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250,
                 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250,
                 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250,
                 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250,
                 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250,
                 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250,
                 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250,
                 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250, 1.250,
 
                 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125,
                 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125,
                 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125,
                 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125,
                 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125,
                 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125,
                 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125,
                 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125,
                 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125, 1.125,
 
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000
             ],
             "y"=>[
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000
             ],
             "z"=>[
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000
             ]
         );
         
         
 my $trace2 = Chart::Plotly::Trace::Isosurface->new(
             "colorscale"=>"Reds",
             "reversescale"=>JSON::true,
             "surface"=>{ "show"=>JSON::true },
             "spaceframe"=>{ "show"=>JSON::false },
             "slices"=>{
                 "x"=>{ "show"=>JSON::false },
                 "y"=>{ "show"=>JSON::false },
                 "z"=>{ "show"=>JSON::false }
             },
             "caps"=>{
                 "x"=>{ "show"=>JSON::true },
                 "y"=>{ "show"=>JSON::true },
                 "z"=>{ "show"=>JSON::true }
             },
             "contour"=>{
                 "show"=>JSON::false,
                 "width"=>4
             },
             "isomin"=>150,
             "isomax"=>250,
             "value"=>[
 
                 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 16, 31, 47, 63, 78, 94, 109, 125,
                 0, 31, 63, 94, 125, 156, 188, 219, 250,
                 0, 47, 94, 141, 188, 234, 281, 328, 375,
                 0, 63, 125, 188, 250, 313, 375, 438, 500,
                 0, 78, 156, 234, 313, 391, 469, 547, 625,
                 0, 94, 188, 281, 375, 469, 563, 656, 750,
                 0, 109, 219, 328, 438, 547, 656, 766, 875,
                 0, 125, 250, 375, 500, 625, 750, 875, 1000,
 
                 0, 16, 31, 47, 63, 78, 94, 109, 125,
                 16, 47, 78, 109, 141, 172, 203, 234, 266,
                 31, 78, 125, 172, 219, 266, 313, 359, 406,
                 47, 109, 172, 234, 297, 359, 422, 484, 547,
                 63, 141, 219, 297, 375, 453, 531, 609, 688,
                 78, 172, 266, 359, 453, 547, 641, 734, 828,
                 94, 203, 313, 422, 531, 641, 750, 859, 969,
                 109, 234, 359, 484, 609, 734, 859, 984, 1109,
                 125, 266, 406, 547, 688, 828, 969, 1109, 1250,
 
                 0, 31, 63, 94, 125, 156, 188, 219, 250,
                 31, 78, 125, 172, 219, 266, 313, 359, 406,
                 63, 125, 188, 250, 313, 375, 438, 500, 563,
                 94, 172, 250, 328, 406, 484, 563, 641, 719,
                 125, 219, 313, 406, 500, 594, 688, 781, 875,
                 156, 266, 375, 484, 594, 703, 813, 922, 1031,
                 188, 313, 438, 563, 688, 813, 938, 1063, 1188,
                 219, 359, 500, 641, 781, 922, 1063, 1203, 1344,
                 250, 406, 563, 719, 875, 1031, 1188, 1344, 1500,
 
                 0, 47, 94, 141, 188, 234, 281, 328, 375,
                 47, 109, 172, 234, 297, 359, 422, 484, 547,
                 94, 172, 250, 328, 406, 484, 563, 641, 719,
                 141, 234, 328, 422, 516, 609, 703, 797, 891,
                 188, 297, 406, 516, 625, 734, 844, 953, 1063,
                 234, 359, 484, 609, 734, 859, 984, 1109, 1234,
                 281, 422, 563, 703, 844, 984, 1125, 1266, 1406,
                 328, 484, 641, 797, 953, 1109, 1266, 1422, 1578,
                 375, 547, 719, 891, 1063, 1234, 1406, 1578, 1750,
 
                 0, 63, 125, 188, 250, 313, 375, 438, 500,
                 63, 141, 219, 297, 375, 453, 531, 609, 688,
                 125, 219, 313, 406, 500, 594, 688, 781, 875,
                 188, 297, 406, 516, 625, 734, 844, 953, 1063,
                 250, 375, 500, 625, 750, 875, 1000, 1125, 1250,
                 313, 453, 594, 734, 875, 1016, 1156, 1297, 1438,
                 375, 531, 688, 844, 1000, 1156, 1313, 1469, 1625,
                 438, 609, 781, 953, 1125, 1297, 1469, 1641, 1813,
                 500, 688, 875, 1063, 1250, 1438, 1625, 1813, 2000,
 
                 0, 78, 156, 234, 313, 391, 469, 547, 625,
                 78, 172, 266, 359, 453, 547, 641, 734, 828,
                 156, 266, 375, 484, 594, 703, 813, 922, 1031,
                 234, 359, 484, 609, 734, 859, 984, 1109, 1234,
                 313, 453, 594, 734, 875, 1016, 1156, 1297, 1438,
                 391, 547, 703, 859, 1016, 1172, 1328, 1484, 1641,
                 469, 641, 813, 984, 1156, 1328, 1500, 1672, 1844,
                 547, 734, 922, 1109, 1297, 1484, 1672, 1859, 2047,
                 625, 828, 1031, 1234, 1438, 1641, 1844, 2047, 2250,
 
                 0, 94, 188, 281, 375, 469, 563, 656, 750,
                 94, 203, 313, 422, 531, 641, 750, 859, 969,
                 188, 313, 438, 563, 688, 813, 938, 1063, 1188,
                 281, 422, 563, 703, 844, 984, 1125, 1266, 1406,
                 375, 531, 688, 844, 1000, 1156, 1313, 1469, 1625,
                 469, 641, 813, 984, 1156, 1328, 1500, 1672, 1844,
                 563, 750, 938, 1125, 1313, 1500, 1688, 1875, 2063,
                 656, 859, 1063, 1266, 1469, 1672, 1875, 2078, 2281,
                 750, 969, 1188, 1406, 1625, 1844, 2063, 2281, 2500,
 
                 0, 109, 219, 328, 438, 547, 656, 766, 875,
                 109, 234, 359, 484, 609, 734, 859, 984, 1109,
                 219, 359, 500, 641, 781, 922, 1063, 1203, 1344,
                 328, 484, 641, 797, 953, 1109, 1266, 1422, 1578,
                 438, 609, 781, 953, 1125, 1297, 1469, 1641, 1813,
                 547, 734, 922, 1109, 1297, 1484, 1672, 1859, 2047,
                 656, 859, 1063, 1266, 1469, 1672, 1875, 2078, 2281,
                 766, 984, 1203, 1422, 1641, 1859, 2078, 2297, 2516,
                 875, 1109, 1344, 1578, 1813, 2047, 2281, 2516, 2750,
 
                 0, 125, 250, 375, 500, 625, 750, 875, 1000,
                 125, 266, 406, 547, 688, 828, 969, 1109, 1250,
                 250, 406, 563, 719, 875, 1031, 1188, 1344, 1500,
                 375, 547, 719, 891, 1063, 1234, 1406, 1578, 1750,
                 500, 688, 875, 1063, 1250, 1438, 1625, 1813, 2000,
                 625, 828, 1031, 1234, 1438, 1641, 1844, 2047, 2250,
                 750, 969, 1188, 1406, 1625, 1844, 2063, 2281, 2500,
                 875, 1109, 1344, 1578, 1813, 2047, 2281, 2516, 2750,
                 1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000
             ],
             "x"=>[
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
 
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
 
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
 
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
 
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
 
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
 
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
 
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
 
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000
             ],
             "y"=>[
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
 
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125,
                 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250, 0.250,
                 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375, 0.375,
                 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500, 0.500,
                 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625, 0.625,
                 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750, 0.750,
                 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875, 0.875,
                 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000
             ],
             "z"=>[
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
 
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000,
                 0.000, 0.125, 0.250, 0.375, 0.500, 0.625, 0.750, 0.875, 1.000
             ]
         );
 
 my $plot = Chart::Plotly::Plot->new(
     traces => [ $trace1, $trace2 ],
     layout => {
         "title"=>{
             "text"=>"scene with multiple isosurface traces"
         },
         "width"=>1200,
         "height"=>900,
         "scene"=>{
             "aspectratio"=>{
                 "x"=>2,
                 "y"=>1,
                 "z"=>1
             },
             "xaxis"=>{ "nticks"=>10 },
             "yaxis"=>{ "nticks"=>10 },
             "zaxis"=>{ "nticks"=>10 },
             "camera"=>{
                 "eye"=>{
                     "x"=>1,
                     "y"=>2,
                     "z"=>0.5
                 }
             }
         }
       }
 
 );
 
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

Draws isosurfaces between iso-min and iso-max values with coordinates given by four 1-dimensional arrays containing the `value`, `x`, `y` and `z` of every vertex of a uniform or non-uniform 3-D grid. Horizontal or vertical slices, caps as well as spaceframe between iso-min and iso-max values could also be drawn using this trace.

Screenshot of the above example:

=for HTML <p>
<img src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/isosurface.png" alt="Screenshot of the above example">
</p>

=for markdown ![Screenshot of the above example](https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/isosurface.png)

=for HTML <p>
<iframe src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/isosurface.html" style="border:none;" width="80%" height="520"></iframe>
</p>

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#isosurface>

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

=item * caps

=item * cauto

Determines whether or not the color domain is computed with respect to the input data (here `value`) or the bounds set in `cmin` and `cmax`  Defaults to `false` when `cmin` and `cmax` are set by the user.

=item * cmax

Sets the upper bound of the color domain. Value should have the same units as `value` and if set, `cmin` must be set as well.

=item * cmid

Sets the mid-point of the color domain by scaling `cmin` and/or `cmax` to be equidistant to this point. Value should have the same units as `value`. Has no effect when `cauto` is `false`.

=item * cmin

Sets the lower bound of the color domain. Value should have the same units as `value` and if set, `cmax` must be set as well.

=item * coloraxis

Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.

=item * colorbar

=item * colorscale

Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use`cmin` and `cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys,YlGnBu,Greens,YlOrRd,Bluered,RdBu,Reds,Blues,Picnic,Rainbow,Portland,Jet,Hot,Blackbody,Earth,Electric,Viridis,Cividis.

=item * contour

=item * customdata

Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements

=item * customdatasrc

Sets the source reference on plot.ly for  customdata .

=item * flatshading

Determines whether or not normal smoothing is applied to the meshes, creating meshes with an angular, low-poly look via flat reflections.

=item * hoverinfo

Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.

=item * hoverinfosrc

Sets the source reference on plot.ly for  hoverinfo .

=item * hoverlabel

=item * hovertemplate

Template string used for rendering the information that appear on hover box. Note that this will override `hoverinfo`. Variables are inserted using %{variable}, for example "y: %{y}". Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example "Price: %{y:$.2f}". See https://github.com/d3/d3-format/blob/master/README.md#locale_format for details on the formatting syntax. The variables available in `hovertemplate` are the ones emitted as event data described at this link https://plot.ly/javascript/plotlyjs-events/#event-data. Additionally, every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available.  Anything contained in tag `<extra>` is displayed in the secondary box, for example "<extra>{fullData.name}</extra>". To hide the secondary box completely, use an empty tag `<extra></extra>`.

=item * hovertemplatesrc

Sets the source reference on plot.ly for  hovertemplate .

=item * hovertext

Same as `text`.

=item * hovertextsrc

Sets the source reference on plot.ly for  hovertext .

=item * ids

Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.

=item * idssrc

Sets the source reference on plot.ly for  ids .

=item * isomax

Sets the maximum boundary for iso-surface plot.

=item * isomin

Sets the minimum boundary for iso-surface plot.

=item * lighting

=item * lightposition

=item * pmeta

Assigns extra meta information associated with this trace that can be used in various text attributes. Attributes such as trace `name`, graph, axis and colorbar `title.text`, annotation `text` `rangeselector`, `updatemenues` and `sliders` `label` text all support `meta`. To access the trace `meta` values in an attribute in the same trace, simply use `%{meta[i]}` where `i` is the index or key of the `meta` item in question. To access trace `meta` in layout attributes, use `%{data[n[.meta[i]}` where `i` is the index or key of the `meta` and `n` is the trace index.

=item * metasrc

Sets the source reference on plot.ly for  meta .

=item * name

Sets the trace name. The trace name appear as the legend item and on hover.

=item * opacity

Sets the opacity of the surface. Please note that in the case of using high `opacity` values for example a value greater than or equal to 0.5 on two surfaces (and 0.25 with four surfaces), an overlay of multiple transparent surfaces may not perfectly be sorted in depth by the webgl API. This behavior may be improved in the near future and is subject to change.

=item * reversescale

Reverses the color mapping if true. If true, `cmin` will correspond to the last color in the array and `cmax` will correspond to the first color.

=item * scene

Sets a reference between this trace's 3D coordinate system and a 3D scene. If *scene* (the default value), the (x,y,z) coordinates refer to `layout.scene`. If *scene2*, the (x,y,z) coordinates refer to `layout.scene2`, and so on.

=item * showscale

Determines whether or not a colorbar is displayed for this trace.

=item * slices

=item * spaceframe

=item * stream

=item * surface

=item * text

Sets the text elements associated with the vertices. If trace `hoverinfo` contains a *text* flag and *hovertext* is not set, these elements will be seen in the hover labels.

=item * textsrc

Sets the source reference on plot.ly for  text .

=item * uid

Assign an id to this trace, Use this to provide object constancy between traces during animations and transitions.

=item * uirevision

Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.

=item * value

Sets the 4th dimension (value) of the vertices.

=item * valuesrc

Sets the source reference on plot.ly for  value .

=item * visible

Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).

=item * x

Sets the X coordinates of the vertices on X axis.

=item * xsrc

Sets the source reference on plot.ly for  x .

=item * y

Sets the Y coordinates of the vertices on Y axis.

=item * ysrc

Sets the source reference on plot.ly for  y .

=item * z

Sets the Z coordinates of the vertices on Z axis.

=item * zsrc

Sets the source reference on plot.ly for  z .

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
