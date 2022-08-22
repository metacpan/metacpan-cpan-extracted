package Chart::Plotly::Trace::Surface;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Surface::Colorbar;
use Chart::Plotly::Trace::Surface::Contours;
use Chart::Plotly::Trace::Surface::Hoverlabel;
use Chart::Plotly::Trace::Surface::Legendgrouptitle;
use Chart::Plotly::Trace::Surface::Lighting;
use Chart::Plotly::Trace::Surface::Lightposition;
use Chart::Plotly::Trace::Surface::Stream;

our $VERSION = '0.042';    # VERSION

# ABSTRACT: The data the describes the coordinates of the surface is set in `z`. Data in `z` should be a {2D array}. Coordinates in `x` and `y` can either be 1D {arrays} or {2D arrays} (e.g. to graph parametric surfaces). If not provided in `x` and `y`, the x and y coordinates are assumed to be linear starting at 0 with a unit step. The color scale corresponds to the `z` values by default. For custom color scales, use `surfacecolor` which should be a {2D array}, where its bounds can be controlled using `cmin` and `cmax`.

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
    is            => "rw",
    isa           => "Bool",
    documentation =>
      "Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.",
);

has cauto => (
    is            => "rw",
    isa           => "Bool",
    documentation =>
      "Determines whether or not the color domain is computed with respect to the input data (here z or surfacecolor) or the bounds set in `cmin` and `cmax` Defaults to `false` when `cmin` and `cmax` are set by the user.",
);

has cmax => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the upper bound of the color domain. Value should have the same units as z or surfacecolor and if set, `cmin` must be set as well.",
);

has cmid => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the mid-point of the color domain by scaling `cmin` and/or `cmax` to be equidistant to this point. Value should have the same units as z or surfacecolor. Has no effect when `cauto` is `false`.",
);

has cmin => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the lower bound of the color domain. Value should have the same units as z or surfacecolor and if set, `cmax` must be set as well.",
);

has coloraxis => (
    is            => "rw",
    documentation =>
      "Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.",
);

has colorbar => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Surface::Colorbar", );

has colorscale => (
    is            => "rw",
    documentation =>
      "Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)'], [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use `cmin` and `cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Blackbody,Bluered,Blues,Cividis,Earth,Electric,Greens,Greys,Hot,Jet,Picnic,Portland,Rainbow,RdBu,Reds,Viridis,YlGnBu,YlOrRd.",
);

has connectgaps => (
        is            => "rw",
        isa           => "Bool",
        documentation => "Determines whether or not gaps (i.e. {nan} or missing values) in the `z` data are filled in.",
);

has contours => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Surface::Contours", );

has customdata => (
    is            => "rw",
    isa           => "ArrayRef|PDL",
    documentation =>
      "Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements",
);

has customdatasrc => ( is            => "rw",
                       isa           => "Str",
                       documentation => "Sets the source reference on Chart Studio Cloud for `customdata`.",
);

has hidesurface => (
    is            => "rw",
    isa           => "Bool",
    documentation =>
      "Determines whether or not a surface is drawn. For example, set `hidesurface` to *false* `contours.x.show` to *true* and `contours.y.show` to *true* to draw a wire frame plot.",
);

has hoverinfo => (
    is            => "rw",
    isa           => "Str|ArrayRef[Str]",
    documentation =>
      "Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.",
);

has hoverinfosrc => ( is            => "rw",
                      isa           => "Str",
                      documentation => "Sets the source reference on Chart Studio Cloud for `hoverinfo`.",
);

has hoverlabel => ( is  => "rw",
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Surface::Hoverlabel", );

has hovertemplate => (
    is            => "rw",
    isa           => "Str|ArrayRef[Str]",
    documentation =>
      "Template string used for rendering the information that appear on hover box. Note that this will override `hoverinfo`. Variables are inserted using %{variable}, for example \"y: %{y}\" as well as %{xother}, {%_xother}, {%_xother_}, {%xother_}. When showing info for several points, *xother* will be added to those with different x positions from the first point. An underscore before or after *(x|y)other* will add a space on that side, only when this field is shown. Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example \"Price: %{y:\$.2f}\". https://github.com/d3/d3-format/tree/v1.4.5#d3-format for details on the formatting syntax. Dates are formatted using d3-time-format's syntax %{variable|d3-time-format}, for example \"Day: %{2019-01-01|%A}\". https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format for details on the date formatting syntax. The variables available in `hovertemplate` are the ones emitted as event data described at this link https://plotly.com/javascript/plotlyjs-events/#event-data. Additionally, every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available.  Anything contained in tag `<extra>` is displayed in the secondary box, for example \"<extra>{fullData.name}</extra>\". To hide the secondary box completely, use an empty tag `<extra></extra>`.",
);

has hovertemplatesrc => ( is            => "rw",
                          isa           => "Str",
                          documentation => "Sets the source reference on Chart Studio Cloud for `hovertemplate`.",
);

has hovertext => ( is            => "rw",
                   isa           => "Str|ArrayRef[Str]",
                   documentation => "Same as `text`.",
);

has hovertextsrc => ( is            => "rw",
                      isa           => "Str",
                      documentation => "Sets the source reference on Chart Studio Cloud for `hovertext`.",
);

has ids => (
    is            => "rw",
    isa           => "ArrayRef|PDL",
    documentation =>
      "Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.",
);

has idssrc => ( is            => "rw",
                isa           => "Str",
                documentation => "Sets the source reference on Chart Studio Cloud for `ids`.",
);

has legendgroup => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "Sets the legend group for this trace. Traces part of the same legend group hide/show at the same time when toggling legend items.",
);

has legendgrouptitle => ( is  => "rw",
                          isa => "Maybe[HashRef]|Chart::Plotly::Trace::Surface::Legendgrouptitle", );

has legendrank => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the legend rank for this trace. Items and groups with smaller ranks are presented on top/left side while with `*reversed* `legend.traceorder` they are on bottom/right side. The default legendrank is 1000, so that you can use ranks less than 1000 to place certain items before all unranked items, and ranks greater than 1000 to go after all unranked items.",
);

has lighting => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Surface::Lighting", );

has lightposition => ( is  => "rw",
                       isa => "Maybe[HashRef]|Chart::Plotly::Trace::Surface::Lightposition", );

has pmeta => (
    is            => "rw",
    isa           => "Any|ArrayRef[Any]",
    documentation =>
      "Assigns extra meta information associated with this trace that can be used in various text attributes. Attributes such as trace `name`, graph, axis and colorbar `title.text`, annotation `text` `rangeselector`, `updatemenues` and `sliders` `label` text all support `meta`. To access the trace `meta` values in an attribute in the same trace, simply use `%{meta[i]}` where `i` is the index or key of the `meta` item in question. To access trace `meta` in layout attributes, use `%{data[n[.meta[i]}` where `i` is the index or key of the `meta` and `n` is the trace index.",
);

has metasrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on Chart Studio Cloud for `meta`.",
);

has name => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the trace name. The trace name appear as the legend item and on hover.",
);

has opacity => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the opacity of the surface. Please note that in the case of using high `opacity` values for example a value greater than or equal to 0.5 on two surfaces (and 0.25 with four surfaces), an overlay of multiple transparent surfaces may not perfectly be sorted in depth by the webgl API. This behavior may be improved in the near future and is subject to change.",
);

has opacityscale => (
    is            => "rw",
    isa           => "Any",
    documentation =>
      "Sets the opacityscale. The opacityscale must be an array containing arrays mapping a normalized value to an opacity value. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 1], [0.5, 0.2], [1, 1]]` means that higher/lower values would have higher opacity values and those in the middle would be more transparent Alternatively, `opacityscale` may be a palette name string of the following list: 'min', 'max', 'extremes' and 'uniform'. The default is 'uniform'.",
);

has reversescale => (
    is            => "rw",
    isa           => "Bool",
    documentation =>
      "Reverses the color mapping if true. If true, `cmin` will correspond to the last color in the array and `cmax` will correspond to the first color.",
);

has scene => (
    is            => "rw",
    documentation =>
      "Sets a reference between this trace's 3D coordinate system and a 3D scene. If *scene* (the default value), the (x,y,z) coordinates refer to `layout.scene`. If *scene2*, the (x,y,z) coordinates refer to `layout.scene2`, and so on.",
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
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Surface::Stream", );

has surfacecolor => (
                   is            => "rw",
                   isa           => "ArrayRef|PDL",
                   documentation => "Sets the surface color values, used for setting a color scale independent of `z`.",
);

has surfacecolorsrc => ( is            => "rw",
                         isa           => "Str",
                         documentation => "Sets the source reference on Chart Studio Cloud for `surfacecolor`.",
);

has text => (
    is            => "rw",
    isa           => "Str|ArrayRef[Str]",
    documentation =>
      "Sets the text elements associated with each z value. If trace `hoverinfo` contains a *text* flag and *hovertext* is not set, these elements will be seen in the hover labels.",
);

has textsrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on Chart Studio Cloud for `text`.",
);

has uid => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "Assign an id to this trace, Use this to provide object constancy between traces during animations and transitions.",
);

has uirevision => (
    is            => "rw",
    isa           => "Any",
    documentation =>
      "Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.",
);

has visible => (
    is            => "rw",
    documentation =>
      "Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).",
);

has x => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the x coordinates.",
);

has xcalendar => ( is  => "rw",
                   isa => enum(
                           [ "chinese", "coptic", "discworld",  "ethiopian", "gregorian", "hebrew", "islamic", "jalali",
                             "julian",  "mayan",  "nanakshahi", "nepali",    "persian",   "taiwan", "thai", "ummalqura"
                           ]
                   ),
                   documentation => "Sets the calendar system to use with `x` date data.",
);

has xhoverformat => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "Sets the hover text formatting rulefor `x`  using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format. And for dates see: https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format. We add two items to d3's date formatter: *%h* for half of the year as a decimal number as well as *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*By default the values are formatted using `xaxis.hoverformat`.",
);

has xsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on Chart Studio Cloud for `x`.",
);

has y => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the y coordinates.",
);

has ycalendar => ( is  => "rw",
                   isa => enum(
                           [ "chinese", "coptic", "discworld",  "ethiopian", "gregorian", "hebrew", "islamic", "jalali",
                             "julian",  "mayan",  "nanakshahi", "nepali",    "persian",   "taiwan", "thai", "ummalqura"
                           ]
                   ),
                   documentation => "Sets the calendar system to use with `y` date data.",
);

has yhoverformat => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "Sets the hover text formatting rulefor `y`  using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format. And for dates see: https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format. We add two items to d3's date formatter: *%h* for half of the year as a decimal number as well as *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*By default the values are formatted using `yaxis.hoverformat`.",
);

has ysrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on Chart Studio Cloud for `y`.",
);

has z => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the z coordinates.",
);

has zcalendar => ( is  => "rw",
                   isa => enum(
                           [ "chinese", "coptic", "discworld",  "ethiopian", "gregorian", "hebrew", "islamic", "jalali",
                             "julian",  "mayan",  "nanakshahi", "nepali",    "persian",   "taiwan", "thai", "ummalqura"
                           ]
                   ),
                   documentation => "Sets the calendar system to use with `z` date data.",
);

has zhoverformat => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "Sets the hover text formatting rulefor `z`  using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format. And for dates see: https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format. We add two items to d3's date formatter: *%h* for half of the year as a decimal number as well as *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*By default the values are formatted using `zaxis.hoverformat`.",
);

has zsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on Chart Studio Cloud for `z`.",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Surface - The data the describes the coordinates of the surface is set in `z`. Data in `z` should be a {2D array}. Coordinates in `x` and `y` can either be 1D {arrays} or {2D arrays} (e.g. to graph parametric surfaces). If not provided in `x` and `y`, the x and y coordinates are assumed to be linear starting at 0 with a unit step. The color scale corresponds to the `z` values by default. For custom color scales, use `surfacecolor` which should be a {2D array}, where its bounds can be controlled using `cmin` and `cmax`.

=head1 VERSION

version 0.042

=head1 SYNOPSIS

 use Chart::Plotly qw(show_plot);
 use Chart::Plotly::Trace::Surface;
 use English qw(-no_match_vars);
 
 my $surface = Chart::Plotly::Trace::Surface->new(
     x => [ 0 .. 10 ],
     y => [ 0 .. 10 ],
     z => [
         map {
             my $y = $ARG;
             [ map { $ARG - $y * $y } ( 0 .. 10 ) ]
         } ( 0 .. 10 )
     ]
 );
 
 show_plot( [$surface] );

=head1 DESCRIPTION

The data the describes the coordinates of the surface is set in `z`. Data in `z` should be a {2D array}. Coordinates in `x` and `y` can either be 1D {arrays} or {2D arrays} (e.g. to graph parametric surfaces). If not provided in `x` and `y`, the x and y coordinates are assumed to be linear starting at 0 with a unit step. The color scale corresponds to the `z` values by default. For custom color scales, use `surfacecolor` which should be a {2D array}, where its bounds can be controlled using `cmin` and `cmax`.

Screenshot of the above example:

=for HTML <p>
<img src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/surface.png" alt="Screenshot of the above example">
</p>

=for markdown ![Screenshot of the above example](https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/surface.png)

=for HTML <p>
<iframe src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/surface.html" style="border:none;" width="80%" height="520"></iframe>
</p>

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#surface>

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

Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.

=item * cauto

Determines whether or not the color domain is computed with respect to the input data (here z or surfacecolor) or the bounds set in `cmin` and `cmax` Defaults to `false` when `cmin` and `cmax` are set by the user.

=item * cmax

Sets the upper bound of the color domain. Value should have the same units as z or surfacecolor and if set, `cmin` must be set as well.

=item * cmid

Sets the mid-point of the color domain by scaling `cmin` and/or `cmax` to be equidistant to this point. Value should have the same units as z or surfacecolor. Has no effect when `cauto` is `false`.

=item * cmin

Sets the lower bound of the color domain. Value should have the same units as z or surfacecolor and if set, `cmax` must be set as well.

=item * coloraxis

Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.

=item * colorbar

=item * colorscale

Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)'], [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use `cmin` and `cmax`. Alternatively, `colorscale` may be a palette name string of the following list: Blackbody,Bluered,Blues,Cividis,Earth,Electric,Greens,Greys,Hot,Jet,Picnic,Portland,Rainbow,RdBu,Reds,Viridis,YlGnBu,YlOrRd.

=item * connectgaps

Determines whether or not gaps (i.e. {nan} or missing values) in the `z` data are filled in.

=item * contours

=item * customdata

Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements

=item * customdatasrc

Sets the source reference on Chart Studio Cloud for `customdata`.

=item * hidesurface

Determines whether or not a surface is drawn. For example, set `hidesurface` to *false* `contours.x.show` to *true* and `contours.y.show` to *true* to draw a wire frame plot.

=item * hoverinfo

Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.

=item * hoverinfosrc

Sets the source reference on Chart Studio Cloud for `hoverinfo`.

=item * hoverlabel

=item * hovertemplate

Template string used for rendering the information that appear on hover box. Note that this will override `hoverinfo`. Variables are inserted using %{variable}, for example "y: %{y}" as well as %{xother}, {%_xother}, {%_xother_}, {%xother_}. When showing info for several points, *xother* will be added to those with different x positions from the first point. An underscore before or after *(x|y)other* will add a space on that side, only when this field is shown. Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example "Price: %{y:$.2f}". https://github.com/d3/d3-format/tree/v1.4.5#d3-format for details on the formatting syntax. Dates are formatted using d3-time-format's syntax %{variable|d3-time-format}, for example "Day: %{2019-01-01|%A}". https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format for details on the date formatting syntax. The variables available in `hovertemplate` are the ones emitted as event data described at this link https://plotly.com/javascript/plotlyjs-events/#event-data. Additionally, every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available.  Anything contained in tag `<extra>` is displayed in the secondary box, for example "<extra>{fullData.name}</extra>". To hide the secondary box completely, use an empty tag `<extra></extra>`.

=item * hovertemplatesrc

Sets the source reference on Chart Studio Cloud for `hovertemplate`.

=item * hovertext

Same as `text`.

=item * hovertextsrc

Sets the source reference on Chart Studio Cloud for `hovertext`.

=item * ids

Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.

=item * idssrc

Sets the source reference on Chart Studio Cloud for `ids`.

=item * legendgroup

Sets the legend group for this trace. Traces part of the same legend group hide/show at the same time when toggling legend items.

=item * legendgrouptitle

=item * legendrank

Sets the legend rank for this trace. Items and groups with smaller ranks are presented on top/left side while with `*reversed* `legend.traceorder` they are on bottom/right side. The default legendrank is 1000, so that you can use ranks less than 1000 to place certain items before all unranked items, and ranks greater than 1000 to go after all unranked items.

=item * lighting

=item * lightposition

=item * pmeta

Assigns extra meta information associated with this trace that can be used in various text attributes. Attributes such as trace `name`, graph, axis and colorbar `title.text`, annotation `text` `rangeselector`, `updatemenues` and `sliders` `label` text all support `meta`. To access the trace `meta` values in an attribute in the same trace, simply use `%{meta[i]}` where `i` is the index or key of the `meta` item in question. To access trace `meta` in layout attributes, use `%{data[n[.meta[i]}` where `i` is the index or key of the `meta` and `n` is the trace index.

=item * metasrc

Sets the source reference on Chart Studio Cloud for `meta`.

=item * name

Sets the trace name. The trace name appear as the legend item and on hover.

=item * opacity

Sets the opacity of the surface. Please note that in the case of using high `opacity` values for example a value greater than or equal to 0.5 on two surfaces (and 0.25 with four surfaces), an overlay of multiple transparent surfaces may not perfectly be sorted in depth by the webgl API. This behavior may be improved in the near future and is subject to change.

=item * opacityscale

Sets the opacityscale. The opacityscale must be an array containing arrays mapping a normalized value to an opacity value. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 1], [0.5, 0.2], [1, 1]]` means that higher/lower values would have higher opacity values and those in the middle would be more transparent Alternatively, `opacityscale` may be a palette name string of the following list: 'min', 'max', 'extremes' and 'uniform'. The default is 'uniform'.

=item * reversescale

Reverses the color mapping if true. If true, `cmin` will correspond to the last color in the array and `cmax` will correspond to the first color.

=item * scene

Sets a reference between this trace's 3D coordinate system and a 3D scene. If *scene* (the default value), the (x,y,z) coordinates refer to `layout.scene`. If *scene2*, the (x,y,z) coordinates refer to `layout.scene2`, and so on.

=item * showlegend

Determines whether or not an item corresponding to this trace is shown in the legend.

=item * showscale

Determines whether or not a colorbar is displayed for this trace.

=item * stream

=item * surfacecolor

Sets the surface color values, used for setting a color scale independent of `z`.

=item * surfacecolorsrc

Sets the source reference on Chart Studio Cloud for `surfacecolor`.

=item * text

Sets the text elements associated with each z value. If trace `hoverinfo` contains a *text* flag and *hovertext* is not set, these elements will be seen in the hover labels.

=item * textsrc

Sets the source reference on Chart Studio Cloud for `text`.

=item * uid

Assign an id to this trace, Use this to provide object constancy between traces during animations and transitions.

=item * uirevision

Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.

=item * visible

Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).

=item * x

Sets the x coordinates.

=item * xcalendar

Sets the calendar system to use with `x` date data.

=item * xhoverformat

Sets the hover text formatting rulefor `x`  using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format. And for dates see: https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format. We add two items to d3's date formatter: *%h* for half of the year as a decimal number as well as *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*By default the values are formatted using `xaxis.hoverformat`.

=item * xsrc

Sets the source reference on Chart Studio Cloud for `x`.

=item * y

Sets the y coordinates.

=item * ycalendar

Sets the calendar system to use with `y` date data.

=item * yhoverformat

Sets the hover text formatting rulefor `y`  using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format. And for dates see: https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format. We add two items to d3's date formatter: *%h* for half of the year as a decimal number as well as *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*By default the values are formatted using `yaxis.hoverformat`.

=item * ysrc

Sets the source reference on Chart Studio Cloud for `y`.

=item * z

Sets the z coordinates.

=item * zcalendar

Sets the calendar system to use with `z` date data.

=item * zhoverformat

Sets the hover text formatting rulefor `z`  using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format. And for dates see: https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format. We add two items to d3's date formatter: *%h* for half of the year as a decimal number as well as *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*By default the values are formatted using `zaxis.hoverformat`.

=item * zsrc

Sets the source reference on Chart Studio Cloud for `z`.

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
