package Chart::Plotly::Trace::Histogram2dcontour;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Histogram2dcontour::Colorbar;
use Chart::Plotly::Trace::Histogram2dcontour::Contours;
use Chart::Plotly::Trace::Histogram2dcontour::Hoverlabel;
use Chart::Plotly::Trace::Histogram2dcontour::Legendgrouptitle;
use Chart::Plotly::Trace::Histogram2dcontour::Line;
use Chart::Plotly::Trace::Histogram2dcontour::Marker;
use Chart::Plotly::Trace::Histogram2dcontour::Stream;
use Chart::Plotly::Trace::Histogram2dcontour::Textfont;
use Chart::Plotly::Trace::Histogram2dcontour::Transform;
use Chart::Plotly::Trace::Histogram2dcontour::Xbins;
use Chart::Plotly::Trace::Histogram2dcontour::Ybins;

our $VERSION = '0.042';    # VERSION

# ABSTRACT: The sample data from which statistics are computed is set in `x` and `y` (where `x` and `y` represent marginal distributions, binning is set in `xbins` and `ybins` in this case) or `z` (where `z` represent the 2D distribution and binning set, binning is set by `x` and `y` in this case). The resulting distribution is visualized as a contour plot.

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

has autobinx => (
    is            => "rw",
    isa           => "Bool",
    documentation =>
      "Obsolete: since v1.42 each bin attribute is auto-determined separately and `autobinx` is not needed. However, we accept `autobinx: true` or `false` and will update `xbins` accordingly before deleting `autobinx` from the trace.",
);

has autobiny => (
    is            => "rw",
    isa           => "Bool",
    documentation =>
      "Obsolete: since v1.42 each bin attribute is auto-determined separately and `autobiny` is not needed. However, we accept `autobiny: true` or `false` and will update `ybins` accordingly before deleting `autobiny` from the trace.",
);

has autocolorscale => (
    is            => "rw",
    isa           => "Bool",
    documentation =>
      "Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.",
);

has autocontour => (
    is            => "rw",
    isa           => "Bool",
    documentation =>
      "Determines whether or not the contour level attributes are picked by an algorithm. If *true*, the number of contour levels can be set in `ncontours`. If *false*, set the contour level attributes in `contours`.",
);

has bingroup => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "Set the `xbingroup` and `ybingroup` default prefix For example, setting a `bingroup` of *1* on two histogram2d traces will make them their x-bins and y-bins match separately.",
);

has coloraxis => (
    is            => "rw",
    documentation =>
      "Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.",
);

has colorbar => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Histogram2dcontour::Colorbar", );

has colorscale => (
    is            => "rw",
    documentation =>
      "Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)'], [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use `zmin` and `zmax`. Alternatively, `colorscale` may be a palette name string of the following list: Blackbody,Bluered,Blues,Cividis,Earth,Electric,Greens,Greys,Hot,Jet,Picnic,Portland,Rainbow,RdBu,Reds,Viridis,YlGnBu,YlOrRd.",
);

has contours => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Histogram2dcontour::Contours", );

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

has histfunc => (
    is            => "rw",
    isa           => enum( [ "count", "sum", "avg", "min", "max" ] ),
    documentation =>
      "Specifies the binning function used for this histogram trace. If *count*, the histogram values are computed by counting the number of values lying inside each bin. If *sum*, *avg*, *min*, *max*, the histogram values are computed using the sum, the average, the minimum or the maximum of the values lying inside each bin respectively.",
);

has histnorm => (
    is            => "rw",
    isa           => enum( [ "", "percent", "probability", "density", "probability density" ] ),
    documentation =>
      "Specifies the type of normalization used for this histogram trace. If **, the span of each bar corresponds to the number of occurrences (i.e. the number of data points lying inside the bins). If *percent* / *probability*, the span of each bar corresponds to the percentage / fraction of occurrences with respect to the total number of sample points (here, the sum of all bin HEIGHTS equals 100% / 1). If *density*, the span of each bar corresponds to the number of occurrences in a bin divided by the size of the bin interval (here, the sum of all bin AREAS equals the total number of sample points). If *probability density*, the area of each bar corresponds to the probability that an event will fall into the corresponding bin (here, the sum of all bin AREAS equals 1).",
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
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Histogram2dcontour::Hoverlabel", );

has hovertemplate => (
    is            => "rw",
    isa           => "Str|ArrayRef[Str]",
    documentation =>
      "Template string used for rendering the information that appear on hover box. Note that this will override `hoverinfo`. Variables are inserted using %{variable}, for example \"y: %{y}\" as well as %{xother}, {%_xother}, {%_xother_}, {%xother_}. When showing info for several points, *xother* will be added to those with different x positions from the first point. An underscore before or after *(x|y)other* will add a space on that side, only when this field is shown. Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example \"Price: %{y:\$.2f}\". https://github.com/d3/d3-format/tree/v1.4.5#d3-format for details on the formatting syntax. Dates are formatted using d3-time-format's syntax %{variable|d3-time-format}, for example \"Day: %{2019-01-01|%A}\". https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format for details on the date formatting syntax. The variables available in `hovertemplate` are the ones emitted as event data described at this link https://plotly.com/javascript/plotlyjs-events/#event-data. Additionally, every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available. variable `z` Anything contained in tag `<extra>` is displayed in the secondary box, for example \"<extra>{fullData.name}</extra>\". To hide the secondary box completely, use an empty tag `<extra></extra>`.",
);

has hovertemplatesrc => ( is            => "rw",
                          isa           => "Str",
                          documentation => "Sets the source reference on Chart Studio Cloud for `hovertemplate`.",
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
                          isa => "Maybe[HashRef]|Chart::Plotly::Trace::Histogram2dcontour::Legendgrouptitle", );

has legendrank => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the legend rank for this trace. Items and groups with smaller ranks are presented on top/left side while with `*reversed* `legend.traceorder` they are on bottom/right side. The default legendrank is 1000, so that you can use ranks less than 1000 to place certain items before all unranked items, and ranks greater than 1000 to go after all unranked items.",
);

has line => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Histogram2dcontour::Line", );

has marker => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Histogram2dcontour::Marker", );

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

has nbinsx => (
    is            => "rw",
    isa           => "Int",
    documentation =>
      "Specifies the maximum number of desired bins. This value will be used in an algorithm that will decide the optimal bin size such that the histogram best visualizes the distribution of the data. Ignored if `xbins.size` is provided.",
);

has nbinsy => (
    is            => "rw",
    isa           => "Int",
    documentation =>
      "Specifies the maximum number of desired bins. This value will be used in an algorithm that will decide the optimal bin size such that the histogram best visualizes the distribution of the data. Ignored if `ybins.size` is provided.",
);

has ncontours => (
    is            => "rw",
    isa           => "Int",
    documentation =>
      "Sets the maximum number of contour levels. The actual number of contours will be chosen automatically to be less than or equal to the value of `ncontours`. Has an effect only if `autocontour` is *true* or if `contours.size` is missing.",
);

has opacity => ( is            => "rw",
                 isa           => "Num",
                 documentation => "Sets the opacity of the trace.",
);

has reversescale => (
    is            => "rw",
    isa           => "Bool",
    documentation =>
      "Reverses the color mapping if true. If true, `zmin` will correspond to the last color in the array and `zmax` will correspond to the first color.",
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
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Histogram2dcontour::Stream", );

has textfont => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Histogram2dcontour::Textfont", );

has texttemplate => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "For this trace it only has an effect if `coloring` is set to *heatmap*. Template string used for rendering the information text that appear on points. Note that this will override `textinfo`. Variables are inserted using %{variable}, for example \"y: %{y}\". Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example \"Price: %{y:\$.2f}\". https://github.com/d3/d3-format/tree/v1.4.5#d3-format for details on the formatting syntax. Dates are formatted using d3-time-format's syntax %{variable|d3-time-format}, for example \"Day: %{2019-01-01|%A}\". https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format for details on the date formatting syntax. Every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available. variables `x`, `y`, `z` and `text`.",
);

has transforms => ( is  => "rw",
                    isa => "ArrayRef|ArrayRef[Chart::Plotly::Trace::Histogram2dcontour::Transform]", );

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
           documentation => "Sets the sample data to be binned on the x axis.",
);

has xaxis => (
    is            => "rw",
    documentation =>
      "Sets a reference between this trace's x coordinates and a 2D cartesian x axis. If *x* (the default value), the x coordinates refer to `layout.xaxis`. If *x2*, the x coordinates refer to `layout.xaxis2`, and so on.",
);

has xbingroup => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "Set a group of histogram traces which will have compatible x-bin settings. Using `xbingroup`, histogram2d and histogram2dcontour traces  (on axes of the same axis type) can have compatible x-bin settings. Note that the same `xbingroup` value can be used to set (1D) histogram `bingroup`",
);

has xbins => ( is  => "rw",
               isa => "Maybe[HashRef]|Chart::Plotly::Trace::Histogram2dcontour::Xbins", );

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
           documentation => "Sets the sample data to be binned on the y axis.",
);

has yaxis => (
    is            => "rw",
    documentation =>
      "Sets a reference between this trace's y coordinates and a 2D cartesian y axis. If *y* (the default value), the y coordinates refer to `layout.yaxis`. If *y2*, the y coordinates refer to `layout.yaxis2`, and so on.",
);

has ybingroup => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "Set a group of histogram traces which will have compatible y-bin settings. Using `ybingroup`, histogram2d and histogram2dcontour traces  (on axes of the same axis type) can have compatible y-bin settings. Note that the same `ybingroup` value can be used to set (1D) histogram `bingroup`",
);

has ybins => ( is  => "rw",
               isa => "Maybe[HashRef]|Chart::Plotly::Trace::Histogram2dcontour::Ybins", );

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
           documentation => "Sets the aggregation data.",
);

has zauto => (
    is            => "rw",
    isa           => "Bool",
    documentation =>
      "Determines whether or not the color domain is computed with respect to the input data (here in `z`) or the bounds set in `zmin` and `zmax` Defaults to `false` when `zmin` and `zmax` are set by the user.",
);

has zhoverformat => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "Sets the hover text formatting rulefor `z`  using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format.By default the values are formatted using generic number format.",
);

has zmax => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the upper bound of the color domain. Value should have the same units as in `z` and if set, `zmin` must be set as well.",
);

has zmid => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the mid-point of the color domain by scaling `zmin` and/or `zmax` to be equidistant to this point. Value should have the same units as in `z`. Has no effect when `zauto` is `false`.",
);

has zmin => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the lower bound of the color domain. Value should have the same units as in `z` and if set, `zmax` must be set as well.",
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

Chart::Plotly::Trace::Histogram2dcontour - The sample data from which statistics are computed is set in `x` and `y` (where `x` and `y` represent marginal distributions, binning is set in `xbins` and `ybins` in this case) or `z` (where `z` represent the 2D distribution and binning set, binning is set by `x` and `y` in this case). The resulting distribution is visualized as a contour plot.

=head1 VERSION

version 0.042

=head1 SYNOPSIS

 use HTML::Show;
 use Chart::Plotly;
 use Chart::Plotly::Trace::Histogram2dcontour;
 my $histogram2dcontour =
   Chart::Plotly::Trace::Histogram2dcontour->new( x => [ map { int( 10 * rand() ) } ( 1 .. 500 ) ],
                                                  y => [ map { int( 10 * rand() ) } ( 1 .. 500 ) ] );
 
 HTML::Show::show( Chart::Plotly::render_full_html( data => [$histogram2dcontour] ) );

=head1 DESCRIPTION

The sample data from which statistics are computed is set in `x` and `y` (where `x` and `y` represent marginal distributions, binning is set in `xbins` and `ybins` in this case) or `z` (where `z` represent the 2D distribution and binning set, binning is set by `x` and `y` in this case). The resulting distribution is visualized as a contour plot.

Screenshot of the above example:

=for HTML <p>
<img src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/histogram2dcontour.png" alt="Screenshot of the above example">
</p>

=for markdown ![Screenshot of the above example](https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/histogram2dcontour.png)

=for HTML <p>
<iframe src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/histogram2dcontour.html" style="border:none;" width="80%" height="520"></iframe>
</p>

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#histogram2dcontour>

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

=item * autobinx

Obsolete: since v1.42 each bin attribute is auto-determined separately and `autobinx` is not needed. However, we accept `autobinx: true` or `false` and will update `xbins` accordingly before deleting `autobinx` from the trace.

=item * autobiny

Obsolete: since v1.42 each bin attribute is auto-determined separately and `autobiny` is not needed. However, we accept `autobiny: true` or `false` and will update `ybins` accordingly before deleting `autobiny` from the trace.

=item * autocolorscale

Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.

=item * autocontour

Determines whether or not the contour level attributes are picked by an algorithm. If *true*, the number of contour levels can be set in `ncontours`. If *false*, set the contour level attributes in `contours`.

=item * bingroup

Set the `xbingroup` and `ybingroup` default prefix For example, setting a `bingroup` of *1* on two histogram2d traces will make them their x-bins and y-bins match separately.

=item * coloraxis

Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.

=item * colorbar

=item * colorscale

Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)'], [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use `zmin` and `zmax`. Alternatively, `colorscale` may be a palette name string of the following list: Blackbody,Bluered,Blues,Cividis,Earth,Electric,Greens,Greys,Hot,Jet,Picnic,Portland,Rainbow,RdBu,Reds,Viridis,YlGnBu,YlOrRd.

=item * contours

=item * customdata

Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements

=item * customdatasrc

Sets the source reference on Chart Studio Cloud for `customdata`.

=item * histfunc

Specifies the binning function used for this histogram trace. If *count*, the histogram values are computed by counting the number of values lying inside each bin. If *sum*, *avg*, *min*, *max*, the histogram values are computed using the sum, the average, the minimum or the maximum of the values lying inside each bin respectively.

=item * histnorm

Specifies the type of normalization used for this histogram trace. If **, the span of each bar corresponds to the number of occurrences (i.e. the number of data points lying inside the bins). If *percent* / *probability*, the span of each bar corresponds to the percentage / fraction of occurrences with respect to the total number of sample points (here, the sum of all bin HEIGHTS equals 100% / 1). If *density*, the span of each bar corresponds to the number of occurrences in a bin divided by the size of the bin interval (here, the sum of all bin AREAS equals the total number of sample points). If *probability density*, the area of each bar corresponds to the probability that an event will fall into the corresponding bin (here, the sum of all bin AREAS equals 1).

=item * hoverinfo

Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.

=item * hoverinfosrc

Sets the source reference on Chart Studio Cloud for `hoverinfo`.

=item * hoverlabel

=item * hovertemplate

Template string used for rendering the information that appear on hover box. Note that this will override `hoverinfo`. Variables are inserted using %{variable}, for example "y: %{y}" as well as %{xother}, {%_xother}, {%_xother_}, {%xother_}. When showing info for several points, *xother* will be added to those with different x positions from the first point. An underscore before or after *(x|y)other* will add a space on that side, only when this field is shown. Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example "Price: %{y:$.2f}". https://github.com/d3/d3-format/tree/v1.4.5#d3-format for details on the formatting syntax. Dates are formatted using d3-time-format's syntax %{variable|d3-time-format}, for example "Day: %{2019-01-01|%A}". https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format for details on the date formatting syntax. The variables available in `hovertemplate` are the ones emitted as event data described at this link https://plotly.com/javascript/plotlyjs-events/#event-data. Additionally, every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available. variable `z` Anything contained in tag `<extra>` is displayed in the secondary box, for example "<extra>{fullData.name}</extra>". To hide the secondary box completely, use an empty tag `<extra></extra>`.

=item * hovertemplatesrc

Sets the source reference on Chart Studio Cloud for `hovertemplate`.

=item * ids

Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.

=item * idssrc

Sets the source reference on Chart Studio Cloud for `ids`.

=item * legendgroup

Sets the legend group for this trace. Traces part of the same legend group hide/show at the same time when toggling legend items.

=item * legendgrouptitle

=item * legendrank

Sets the legend rank for this trace. Items and groups with smaller ranks are presented on top/left side while with `*reversed* `legend.traceorder` they are on bottom/right side. The default legendrank is 1000, so that you can use ranks less than 1000 to place certain items before all unranked items, and ranks greater than 1000 to go after all unranked items.

=item * line

=item * marker

=item * pmeta

Assigns extra meta information associated with this trace that can be used in various text attributes. Attributes such as trace `name`, graph, axis and colorbar `title.text`, annotation `text` `rangeselector`, `updatemenues` and `sliders` `label` text all support `meta`. To access the trace `meta` values in an attribute in the same trace, simply use `%{meta[i]}` where `i` is the index or key of the `meta` item in question. To access trace `meta` in layout attributes, use `%{data[n[.meta[i]}` where `i` is the index or key of the `meta` and `n` is the trace index.

=item * metasrc

Sets the source reference on Chart Studio Cloud for `meta`.

=item * name

Sets the trace name. The trace name appear as the legend item and on hover.

=item * nbinsx

Specifies the maximum number of desired bins. This value will be used in an algorithm that will decide the optimal bin size such that the histogram best visualizes the distribution of the data. Ignored if `xbins.size` is provided.

=item * nbinsy

Specifies the maximum number of desired bins. This value will be used in an algorithm that will decide the optimal bin size such that the histogram best visualizes the distribution of the data. Ignored if `ybins.size` is provided.

=item * ncontours

Sets the maximum number of contour levels. The actual number of contours will be chosen automatically to be less than or equal to the value of `ncontours`. Has an effect only if `autocontour` is *true* or if `contours.size` is missing.

=item * opacity

Sets the opacity of the trace.

=item * reversescale

Reverses the color mapping if true. If true, `zmin` will correspond to the last color in the array and `zmax` will correspond to the first color.

=item * showlegend

Determines whether or not an item corresponding to this trace is shown in the legend.

=item * showscale

Determines whether or not a colorbar is displayed for this trace.

=item * stream

=item * textfont

=item * texttemplate

For this trace it only has an effect if `coloring` is set to *heatmap*. Template string used for rendering the information text that appear on points. Note that this will override `textinfo`. Variables are inserted using %{variable}, for example "y: %{y}". Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example "Price: %{y:$.2f}". https://github.com/d3/d3-format/tree/v1.4.5#d3-format for details on the formatting syntax. Dates are formatted using d3-time-format's syntax %{variable|d3-time-format}, for example "Day: %{2019-01-01|%A}". https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format for details on the date formatting syntax. Every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available. variables `x`, `y`, `z` and `text`.

=item * transforms

=item * uid

Assign an id to this trace, Use this to provide object constancy between traces during animations and transitions.

=item * uirevision

Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.

=item * visible

Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).

=item * x

Sets the sample data to be binned on the x axis.

=item * xaxis

Sets a reference between this trace's x coordinates and a 2D cartesian x axis. If *x* (the default value), the x coordinates refer to `layout.xaxis`. If *x2*, the x coordinates refer to `layout.xaxis2`, and so on.

=item * xbingroup

Set a group of histogram traces which will have compatible x-bin settings. Using `xbingroup`, histogram2d and histogram2dcontour traces  (on axes of the same axis type) can have compatible x-bin settings. Note that the same `xbingroup` value can be used to set (1D) histogram `bingroup`

=item * xbins

=item * xcalendar

Sets the calendar system to use with `x` date data.

=item * xhoverformat

Sets the hover text formatting rulefor `x`  using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format. And for dates see: https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format. We add two items to d3's date formatter: *%h* for half of the year as a decimal number as well as *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*By default the values are formatted using `xaxis.hoverformat`.

=item * xsrc

Sets the source reference on Chart Studio Cloud for `x`.

=item * y

Sets the sample data to be binned on the y axis.

=item * yaxis

Sets a reference between this trace's y coordinates and a 2D cartesian y axis. If *y* (the default value), the y coordinates refer to `layout.yaxis`. If *y2*, the y coordinates refer to `layout.yaxis2`, and so on.

=item * ybingroup

Set a group of histogram traces which will have compatible y-bin settings. Using `ybingroup`, histogram2d and histogram2dcontour traces  (on axes of the same axis type) can have compatible y-bin settings. Note that the same `ybingroup` value can be used to set (1D) histogram `bingroup`

=item * ybins

=item * ycalendar

Sets the calendar system to use with `y` date data.

=item * yhoverformat

Sets the hover text formatting rulefor `y`  using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format. And for dates see: https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format. We add two items to d3's date formatter: *%h* for half of the year as a decimal number as well as *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*By default the values are formatted using `yaxis.hoverformat`.

=item * ysrc

Sets the source reference on Chart Studio Cloud for `y`.

=item * z

Sets the aggregation data.

=item * zauto

Determines whether or not the color domain is computed with respect to the input data (here in `z`) or the bounds set in `zmin` and `zmax` Defaults to `false` when `zmin` and `zmax` are set by the user.

=item * zhoverformat

Sets the hover text formatting rulefor `z`  using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format.By default the values are formatted using generic number format.

=item * zmax

Sets the upper bound of the color domain. Value should have the same units as in `z` and if set, `zmin` must be set as well.

=item * zmid

Sets the mid-point of the color domain by scaling `zmin` and/or `zmax` to be equidistant to this point. Value should have the same units as in `z`. Has no effect when `zauto` is `false`.

=item * zmin

Sets the lower bound of the color domain. Value should have the same units as in `z` and if set, `zmax` must be set as well.

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
