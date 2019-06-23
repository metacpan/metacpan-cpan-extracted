package Chart::Plotly::Trace::Funnel;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Funnel::Connector;
use Chart::Plotly::Trace::Funnel::Hoverlabel;
use Chart::Plotly::Trace::Funnel::Insidetextfont;
use Chart::Plotly::Trace::Funnel::Marker;
use Chart::Plotly::Trace::Funnel::Outsidetextfont;
use Chart::Plotly::Trace::Funnel::Stream;
use Chart::Plotly::Trace::Funnel::Textfont;
use Chart::Plotly::Trace::Funnel::Transform;

our $VERSION = '0.027';    # VERSION

# ABSTRACT: Visualize stages in a process using length-encoded bars. This trace can be used to show data in either a part-to-whole representation wherein each item appears in a single stage, or in a "drop-off" representation wherein each item appears in each stage it traversed. See also the "funnelarea" trace type for a different approach to visualizing funnel data.

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

has alignmentgroup => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Set several traces linked to the same position axis or matching axes to the same alignmentgroup. This controls whether bars compute their positional range dependently or independently.",
);

has cliponaxis => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether the text nodes are clipped about the subplot axes. To show the text nodes above axis lines and tick labels, make sure to set `xaxis.layer` and `yaxis.layer` to *below traces*.",
);

has connector => ( is  => "rw",
                   isa => "Maybe[HashRef]|Chart::Plotly::Trace::Funnel::Connector", );

has constraintext => (
             is            => "rw",
             isa           => enum( [ "inside", "outside", "both", "none" ] ),
             documentation => "Constrain the size of text inside or outside a bar to be no larger than the bar itself.",
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

has dx => ( is            => "rw",
            isa           => "Num",
            documentation => "Sets the x coordinate step. See `x0` for more info.",
);

has dy => ( is            => "rw",
            isa           => "Num",
            documentation => "Sets the y coordinate step. See `y0` for more info.",
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
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Funnel::Hoverlabel", );

has hovertemplate => (
    is  => "rw",
    isa => "Str|ArrayRef[Str]",
    documentation =>
      "Template string used for rendering the information that appear on hover box. Note that this will override `hoverinfo`. Variables are inserted using %{variable}, for example \"y: %{y}\". Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example \"Price: %{y:\$.2f}\". See https://github.com/d3/d3-format/blob/master/README.md#locale_format for details on the formatting syntax. The variables available in `hovertemplate` are the ones emitted as event data described at this link https://plot.ly/javascript/plotlyjs-events/#event-data. Additionally, every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available. variables `percentInitial`, `percentPrevious` and `percentTotal`. Anything contained in tag `<extra>` is displayed in the secondary box, for example \"<extra>{fullData.name}</extra>\". To hide the secondary box completely, use an empty tag `<extra></extra>`.",
);

has hovertemplatesrc => ( is            => "rw",
                          isa           => "Str",
                          documentation => "Sets the source reference on plot.ly for  hovertemplate .",
);

has hovertext => (
    is  => "rw",
    isa => "Str|ArrayRef[Str]",
    documentation =>
      "Sets hover text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (x,y) coordinates. To be seen, trace `hoverinfo` must contain a *text* flag.",
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

has insidetextanchor => (
         is            => "rw",
         isa           => enum( [ "end", "middle", "start" ] ),
         documentation => "Determines if texts are kept at center or start/end points in `textposition` *inside* mode.",
);

has insidetextfont => ( is  => "rw",
                        isa => "Maybe[HashRef]|Chart::Plotly::Trace::Funnel::Insidetextfont", );

has legendgroup => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Sets the legend group for this trace. Traces part of the same legend group hide/show at the same time when toggling legend items.",
);

has marker => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Funnel::Marker", );

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

has offset => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Shifts the position where the bar is drawn (in position axis units). In *group* barmode, traces that set *offset* will be excluded and drawn in *overlay* mode instead.",
);

has offsetgroup => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Set several traces linked to the same position axis or matching axes to the same offsetgroup where bars of the same position coordinate will line up.",
);

has opacity => ( is            => "rw",
                 isa           => "Num",
                 documentation => "Sets the opacity of the trace.",
);

has orientation => (
    is  => "rw",
    isa => enum( [ "v", "h" ] ),
    documentation =>
      "Sets the orientation of the funnels. With *v* (*h*), the value of the each bar spans along the vertical (horizontal). By default funnels are tend to be oriented horizontally; unless only *y* array is presented or orientation is set to *v*. Also regarding graphs including only 'horizontal' funnels, *autorange* on the *y-axis* are set to *reversed*.",
);

has outsidetextfont => ( is  => "rw",
                         isa => "Maybe[HashRef]|Chart::Plotly::Trace::Funnel::Outsidetextfont", );

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

has stream => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Funnel::Stream", );

has text => (
    is  => "rw",
    isa => "Str|ArrayRef[Str]",
    documentation =>
      "Sets text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (x,y) coordinates. If trace `hoverinfo` contains a *text* flag and *hovertext* is not set, these elements will be seen in the hover labels.",
);

has textangle => (
    is => "rw",
    documentation =>
      "Sets the angle of the tick labels with respect to the bar. For example, a `tickangle` of -90 draws the tick labels vertically. With *auto* the texts may automatically be rotated to fit with the maximum size in bars.",
);

has textfont => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Funnel::Textfont", );

has textinfo => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Determines which trace information appear on the graph. In the case of having multiple funnels, percentages & totals are computed separately (per trace).",
);

has textposition => (
    is  => "rw",
    isa => union( [ enum( [ "inside", "outside", "auto", "none" ] ), "ArrayRef" ] ),
    documentation =>
      "Specifies the location of the `text`. *inside* positions `text` inside, next to the bar end (rotated and scaled if needed). *outside* positions `text` outside, next to the bar end (scaled if needed), unless there is another bar stacked on this one, then the text gets pushed inside. *auto* tries to position `text` inside the bar, but if the bar is too small and no bar is stacked on this one the text is moved outside.",
);

has textpositionsrc => ( is            => "rw",
                         isa           => "Str",
                         documentation => "Sets the source reference on plot.ly for  textposition .",
);

has textsrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on plot.ly for  text .",
);

has transforms => ( is  => "rw",
                    isa => "ArrayRef|ArrayRef[Chart::Plotly::Trace::Funnel::Transform]", );

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

has visible => (
    is => "rw",
    documentation =>
      "Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).",
);

has width => ( is            => "rw",
               isa           => "Num",
               documentation => "Sets the bar width (in position axis units).",
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

has xsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  x .",
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
      "Sets a reference between this trace's y coordinates and a 2D cartesian y axis. If *y* (the default value), the y coordinates refer to `layout.yaxis`. If *y2*, the y coordinates refer to `layout.yaxis2`, and so on.",
);

has ysrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  y .",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Funnel - Visualize stages in a process using length-encoded bars. This trace can be used to show data in either a part-to-whole representation wherein each item appears in a single stage, or in a "drop-off" representation wherein each item appears in each stage it traversed. See also the "funnelarea" trace type for a different approach to visualizing funnel data.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Plot;
 use JSON;
 use Chart::Plotly::Trace::Funnel;
 
 # Example from https://github.com/plotly/plotly.js/blob/b93e3a5a83b6561ac6258a59f274b5fc87630c3e/test/image/mocks/funnel_11.json
 my $trace1 = Chart::Plotly::Trace::Funnel->new({'orientation' => 'v', 'marker' => {'color' => 'rgb(255, 102, 97)', }, 'y' => [13.23, 22.7, 26.06, ], 'x' => ['Half Dose', 'Full Dose', 'Double Dose', ], 'name' => 'Orange Juice', });
 
 my $trace2 = Chart::Plotly::Trace::Funnel->new({'name' => 'Vitamin C', 'marker' => {'color' => 'rgb(0, 196, 200)', }, 'y' => [7.98, 16.77, 26.14, ], 'x' => ['Half Dose', 'Full Dose', 'Double Dose', ], 'orientation' => 'v', });
 
 my $trace3 = Chart::Plotly::Trace::Funnel->new({'name' => 'Std Dev - OJ', 'x' => ['Half Dose', 'Full Dose', 'Double Dose', ], 'y' => [1.4102837, 1.236752, 0.8396031, ], 'visible' => JSON::false, 'orientation' => 'v', });
 
 my $trace4 = Chart::Plotly::Trace::Funnel->new({'y' => [0.868562, 0.7954104, 1.5171757, ], 'x' => ['Half Dose', 'Full Dose', 'Double Dose', ], 'name' => 'Std Dev - VC', 'orientation' => 'v', 'visible' => JSON::false, });
 
 
 my $plot = Chart::Plotly::Plot->new(
     traces => [$trace1, $trace2, $trace3, $trace4, ],
     layout => 
         {'autosize' => JSON::false, 'hidesources' => JSON::false, 'plot_bgcolor' => 'rgb(217, 217, 217)', 'font' => {'color' => '#000', 'size' => 12, 'family' => 'Arial, sans-serif', }, 'width' => 600, 'separators' => '.,', 'legend' => {'xanchor' => 'left', 'font' => {'size' => 16, 'family' => '', 'color' => 'rgb(0, 0, 0)', }, 'bgcolor' => 'rgba(255, 255, 255, 0)', 'bordercolor' => 'rgba(0, 0, 0, 0)', 'yanchor' => 'auto', 'x' => 1.02, 'y' => 0.931907250442406, 'borderwidth' => 1, 'traceorder' => 'normal', }, 'funnelgroupgap' => 0, 'funnelgap' => 0.2, 'annotations' => [{'tag' => '', 'yatype' => 'linear', 'showarrow' => JSON::false, 'xanchor' => 'auto', 'bgcolor' => 'rgba(0,0,0,0)', 'arrowhead' => 1, 'yref' => 'paper', 'ax' => -10, 'align' => 'center', 'yanchor' => 'auto', 'xatype' => 'category', 'bordercolor' => '', 'ref' => 'paper', 'text' => '<b>Supplement</b>', 'x' => 1.3479735318445, 'y' => 0.998214285714286, 'opacity' => 1, 'arrowwidth' => 0, 'font' => {'size' => 18, 'family' => '', 'color' => '', }, 'ay' => -26.7109375, 'arrowcolor' => '', 'borderpad' => 1, 'borderwidth' => 1, 'xref' => 'paper', 'arrowsize' => 1, }, ], 'height' => 440, 'dragmode' => 'zoom', 'hovermode' => 'x', 'paper_bgcolor' => '#fff', 'boxmode' => 'overlay', 'showlegend' => JSON::true, 'titlefont' => {'family' => '', 'size' => 16, 'color' => '', }, 'title' => 'Grouped Funnel Chart', 'margin' => {'r' => 0, 't' => 80, 'b' => 80, 'l' => 80, 'autoexpand' => JSON::true, 'pad' => 2, }, 'yaxis' => {'gridcolor' => 'rgb(255, 255, 255)', 'autotick' => JSON::true, 'ticks' => '', 'tickfont' => {'color' => '', 'size' => 16, 'family' => '', }, 'mirror' => JSON::true, 'tickangle' => 0, 'domain' => [0, 1, ], 'anchor' => 'x', 'showgrid' => JSON::true, 'exponentformat' => 'e', 'tick0' => 0, 'showticklabels' => JSON::true, 'nticks' => 0, 'zerolinewidth' => 1, 'zeroline' => JSON::false, 'position' => 0, 'range' => [0, 29.1128165263158, ], 'dtick' => 5, 'showexponent' => 'all', 'showline' => JSON::false, 'linecolor' => '#000', 'type' => 'linear', 'linewidth' => 0.1, 'overlaying' => JSON::false, 'ticklen' => 5, 'rangemode' => 'normal', 'tickwidth' => 1, 'tickcolor' => '#000', 'title' => 'Length', 'autorange' => JSON::true, 'titlefont' => {'size' => 16, 'family' => '', 'color' => '', }, 'zerolinecolor' => '#000', 'gridwidth' => 1.9, }, 'funnelmode' => 'group', 'xaxis' => {'ticks' => '', 'autotick' => JSON::true, 'gridcolor' => 'rgb(255, 255, 255)', 'tickfont' => {'color' => '', 'family' => '', 'size' => 16, }, 'mirror' => JSON::true, 'anchor' => 'y', 'tickangle' => 0, 'domain' => [0, 1, ], 'showgrid' => JSON::true, 'exponentformat' => 'e', 'tick0' => 0, 'showticklabels' => JSON::true, 'range' => [-0.5, 2.5, ], 'nticks' => 0, 'zerolinewidth' => 1, 'zeroline' => JSON::false, 'position' => 0, 'showexponent' => 'all', 'dtick' => 1, 'showline' => JSON::false, 'type' => 'category', 'linecolor' => '#000', 'overlaying' => JSON::false, 'linewidth' => 0.1, 'ticklen' => 5, 'rangemode' => 'normal', 'titlefont' => {'size' => 16, 'family' => '', 'color' => '', }, 'autorange' => JSON::true, 'title' => 'Dose (mg)', 'tickwidth' => 1, 'tickcolor' => '#000', 'gridwidth' => 1.9, 'zerolinecolor' => '#000', }, }
 ); 
 
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

Visualize stages in a process using length-encoded bars. This trace can be used to show data in either a part-to-whole representation wherein each item appears in a single stage, or in a "drop-off" representation wherein each item appears in each stage it traversed. See also the "funnelarea" trace type for a different approach to visualizing funnel data.

Screenshot of the above example:

=for HTML <p>
<img src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/funnel.png" alt="Screenshot of the above example">
</p>

=for markdown ![Screenshot of the above example](https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/funnel.png)

=for HTML <p>
<iframe src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/funnel.html" style="border:none;" width="80%" height="520"></iframe>
</p>

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#funnel>

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

=item * alignmentgroup

Set several traces linked to the same position axis or matching axes to the same alignmentgroup. This controls whether bars compute their positional range dependently or independently.

=item * cliponaxis

Determines whether the text nodes are clipped about the subplot axes. To show the text nodes above axis lines and tick labels, make sure to set `xaxis.layer` and `yaxis.layer` to *below traces*.

=item * connector

=item * constraintext

Constrain the size of text inside or outside a bar to be no larger than the bar itself.

=item * customdata

Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements

=item * customdatasrc

Sets the source reference on plot.ly for  customdata .

=item * dx

Sets the x coordinate step. See `x0` for more info.

=item * dy

Sets the y coordinate step. See `y0` for more info.

=item * hoverinfo

Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.

=item * hoverinfosrc

Sets the source reference on plot.ly for  hoverinfo .

=item * hoverlabel

=item * hovertemplate

Template string used for rendering the information that appear on hover box. Note that this will override `hoverinfo`. Variables are inserted using %{variable}, for example "y: %{y}". Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example "Price: %{y:$.2f}". See https://github.com/d3/d3-format/blob/master/README.md#locale_format for details on the formatting syntax. The variables available in `hovertemplate` are the ones emitted as event data described at this link https://plot.ly/javascript/plotlyjs-events/#event-data. Additionally, every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available. variables `percentInitial`, `percentPrevious` and `percentTotal`. Anything contained in tag `<extra>` is displayed in the secondary box, for example "<extra>{fullData.name}</extra>". To hide the secondary box completely, use an empty tag `<extra></extra>`.

=item * hovertemplatesrc

Sets the source reference on plot.ly for  hovertemplate .

=item * hovertext

Sets hover text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (x,y) coordinates. To be seen, trace `hoverinfo` must contain a *text* flag.

=item * hovertextsrc

Sets the source reference on plot.ly for  hovertext .

=item * ids

Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.

=item * idssrc

Sets the source reference on plot.ly for  ids .

=item * insidetextanchor

Determines if texts are kept at center or start/end points in `textposition` *inside* mode.

=item * insidetextfont

=item * legendgroup

Sets the legend group for this trace. Traces part of the same legend group hide/show at the same time when toggling legend items.

=item * marker

=item * pmeta

Assigns extra meta information associated with this trace that can be used in various text attributes. Attributes such as trace `name`, graph, axis and colorbar `title.text`, annotation `text` `rangeselector`, `updatemenues` and `sliders` `label` text all support `meta`. To access the trace `meta` values in an attribute in the same trace, simply use `%{meta[i]}` where `i` is the index or key of the `meta` item in question. To access trace `meta` in layout attributes, use `%{data[n[.meta[i]}` where `i` is the index or key of the `meta` and `n` is the trace index.

=item * metasrc

Sets the source reference on plot.ly for  meta .

=item * name

Sets the trace name. The trace name appear as the legend item and on hover.

=item * offset

Shifts the position where the bar is drawn (in position axis units). In *group* barmode, traces that set *offset* will be excluded and drawn in *overlay* mode instead.

=item * offsetgroup

Set several traces linked to the same position axis or matching axes to the same offsetgroup where bars of the same position coordinate will line up.

=item * opacity

Sets the opacity of the trace.

=item * orientation

Sets the orientation of the funnels. With *v* (*h*), the value of the each bar spans along the vertical (horizontal). By default funnels are tend to be oriented horizontally; unless only *y* array is presented or orientation is set to *v*. Also regarding graphs including only 'horizontal' funnels, *autorange* on the *y-axis* are set to *reversed*.

=item * outsidetextfont

=item * selectedpoints

Array containing integer indices of selected points. Has an effect only for traces that support selections. Note that an empty array means an empty selection where the `unselected` are turned on for all points, whereas, any other non-array values means no selection all where the `selected` and `unselected` styles have no effect.

=item * showlegend

Determines whether or not an item corresponding to this trace is shown in the legend.

=item * stream

=item * text

Sets text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (x,y) coordinates. If trace `hoverinfo` contains a *text* flag and *hovertext* is not set, these elements will be seen in the hover labels.

=item * textangle

Sets the angle of the tick labels with respect to the bar. For example, a `tickangle` of -90 draws the tick labels vertically. With *auto* the texts may automatically be rotated to fit with the maximum size in bars.

=item * textfont

=item * textinfo

Determines which trace information appear on the graph. In the case of having multiple funnels, percentages & totals are computed separately (per trace).

=item * textposition

Specifies the location of the `text`. *inside* positions `text` inside, next to the bar end (rotated and scaled if needed). *outside* positions `text` outside, next to the bar end (scaled if needed), unless there is another bar stacked on this one, then the text gets pushed inside. *auto* tries to position `text` inside the bar, but if the bar is too small and no bar is stacked on this one the text is moved outside.

=item * textpositionsrc

Sets the source reference on plot.ly for  textposition .

=item * textsrc

Sets the source reference on plot.ly for  text .

=item * transforms

=item * uid

Assign an id to this trace, Use this to provide object constancy between traces during animations and transitions.

=item * uirevision

Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.

=item * visible

Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).

=item * width

Sets the bar width (in position axis units).

=item * x

Sets the x coordinates.

=item * x0

Alternate to `x`. Builds a linear space of x coordinates. Use with `dx` where `x0` is the starting coordinate and `dx` the step.

=item * xaxis

Sets a reference between this trace's x coordinates and a 2D cartesian x axis. If *x* (the default value), the x coordinates refer to `layout.xaxis`. If *x2*, the x coordinates refer to `layout.xaxis2`, and so on.

=item * xsrc

Sets the source reference on plot.ly for  x .

=item * y

Sets the y coordinates.

=item * y0

Alternate to `y`. Builds a linear space of y coordinates. Use with `dy` where `y0` is the starting coordinate and `dy` the step.

=item * yaxis

Sets a reference between this trace's y coordinates and a 2D cartesian y axis. If *y* (the default value), the y coordinates refer to `layout.yaxis`. If *y2*, the y coordinates refer to `layout.yaxis2`, and so on.

=item * ysrc

Sets the source reference on plot.ly for  y .

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
