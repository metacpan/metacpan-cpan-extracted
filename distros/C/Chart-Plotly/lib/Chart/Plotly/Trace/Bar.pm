package Chart::Plotly::Trace::Bar;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Bar::Error_x;
use Chart::Plotly::Trace::Bar::Error_y;
use Chart::Plotly::Trace::Bar::Hoverlabel;
use Chart::Plotly::Trace::Bar::Insidetextfont;
use Chart::Plotly::Trace::Bar::Marker;
use Chart::Plotly::Trace::Bar::Outsidetextfont;
use Chart::Plotly::Trace::Bar::Selected;
use Chart::Plotly::Trace::Bar::Stream;
use Chart::Plotly::Trace::Bar::Textfont;
use Chart::Plotly::Trace::Bar::Unselected;

our $VERSION = '0.018';    # VERSION

# ABSTRACT: The data visualized by the span of the bars is set in `y` if `orientation` is set th *v* (the default) and the labels are set in `x`. By setting `orientation` to *h*, the roles are interchanged.

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

has base => (
    is  => "rw",
    isa => "Any|ArrayRef[Any]",
    documentation =>
      "Sets where the bar base is drawn (in position axis units). In *stack* or *relative* barmode, traces that set *base* will be excluded and drawn in *overlay* mode instead.",
);

has basesrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on plot.ly for  base .",
);

has cliponaxis => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether the text nodes are clipped about the subplot axes. To show the text nodes above axis lines and tick labels, make sure to set `xaxis.layer` and `yaxis.layer` to *below traces*.",
);

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

has error_x => ( is  => "rw",
                 isa => "Maybe[HashRef]|Chart::Plotly::Trace::Bar::Error_x", );

has error_y => ( is  => "rw",
                 isa => "Maybe[HashRef]|Chart::Plotly::Trace::Bar::Error_y", );

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
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Bar::Hoverlabel", );

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

has insidetextfont => ( is  => "rw",
                        isa => "Maybe[HashRef]|Chart::Plotly::Trace::Bar::Insidetextfont", );

has legendgroup => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Sets the legend group for this trace. Traces part of the same legend group hide/show at the same time when toggling legend items.",
);

has marker => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Bar::Marker", );

has name => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the trace name. The trace name appear as the legend item and on hover.",
);

has offset => (
    is  => "rw",
    isa => "Num|ArrayRef[Num]",
    documentation =>
      "Shifts the position where the bar is drawn (in position axis units). In *group* barmode, traces that set *offset* will be excluded and drawn in *overlay* mode instead.",
);

has offsetsrc => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the source reference on plot.ly for  offset .",
);

has opacity => ( is            => "rw",
                 isa           => "Num",
                 documentation => "Sets the opacity of the trace.",
);

has orientation => (
    is  => "rw",
    isa => enum( [ "v", "h" ] ),
    documentation =>
      "Sets the orientation of the bars. With *v* (*h*), the value of the each bar spans along the vertical (horizontal).",
);

has outsidetextfont => ( is  => "rw",
                         isa => "Maybe[HashRef]|Chart::Plotly::Trace::Bar::Outsidetextfont", );

has r => ( is  => "rw",
           isa => "ArrayRef|PDL",
           documentation =>
             "For legacy polar chart only.Please switch to *scatterpolar* trace type.Sets the radial coordinates.",
);

has rsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  r .",
);

has selected => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Bar::Selected", );

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
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Bar::Stream", );

has t => ( is  => "rw",
           isa => "ArrayRef|PDL",
           documentation =>
             "For legacy polar chart only.Please switch to *scatterpolar* trace type.Sets the angular coordinates.",
);

has text => (
    is  => "rw",
    isa => "Str|ArrayRef[Str]",
    documentation =>
      "Sets text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (x,y) coordinates. If trace `hoverinfo` contains a *text* flag and *hovertext* is not set, these elements will be seen in the hover labels.",
);

has textfont => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Bar::Textfont", );

has textposition => (
    is  => "rw",
    isa => union( [ enum( [ "inside", "outside", "auto", "none" ] ), "ArrayRef" ] ),
    documentation =>
      "Specifies the location of the `text`. *inside* positions `text` inside, next to the bar end (rotated and scaled if needed). *outside* positions `text` outside, next to the bar end (scaled if needed). *auto* positions `text` inside or outside so that `text` size is maximized.",
);

has textpositionsrc => ( is            => "rw",
                         isa           => "Str",
                         documentation => "Sets the source reference on plot.ly for  textposition .",
);

has textsrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on plot.ly for  text .",
);

has tsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  t .",
);

has uid => ( is  => "rw",
             isa => "Str", );

has unselected => ( is  => "rw",
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Bar::Unselected", );

has visible => (
    is => "rw",
    documentation =>
      "Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).",
);

has width => ( is            => "rw",
               isa           => "Num|ArrayRef[Num]",
               documentation => "Sets the bar width (in position axis units).",
);

has widthsrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on plot.ly for  width .",
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

has xcalendar => ( is  => "rw",
                   isa => enum(
                           [ "gregorian", "chinese", "coptic", "discworld", "ethiopian", "hebrew", "islamic", "julian",
                             "mayan", "nanakshahi", "nepali", "persian", "jalali", "taiwan", "thai", "ummalqura"
                           ]
                   ),
                   documentation => "Sets the calendar system to use with `x` date data.",
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
      "Sets a reference between this trace's y coordinates and a 2D cartesian y axis. If *y* (the default value), the y coordinates refer to `layout.yaxis`. If *y2*, the y coordinates refer to `layout.xaxis2`, and so on.",
);

has ycalendar => ( is  => "rw",
                   isa => enum(
                           [ "gregorian", "chinese", "coptic", "discworld", "ethiopian", "hebrew", "islamic", "julian",
                             "mayan", "nanakshahi", "nepali", "persian", "jalali", "taiwan", "thai", "ummalqura"
                           ]
                   ),
                   documentation => "Sets the calendar system to use with `y` date data.",
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

Chart::Plotly::Trace::Bar - The data visualized by the span of the bars is set in `y` if `orientation` is set th *v* (the default) and the labels are set in `x`. By setting `orientation` to *h*, the roles are interchanged.

=head1 VERSION

version 0.018

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Trace::Bar;
 use Chart::Plotly::Plot;
 my $x = [ "apples", "bananas", "cherries" ];
 my $sample1 = Chart::Plotly::Trace::Bar->new( x    => $x,
                                               y    => [ map { int( rand() * 10 ) } ( 1 .. ( scalar(@$x) ) ) ],
                                               name => "sample1"
 );
 my $sample2 = Chart::Plotly::Trace::Bar->new( x    => $x,
                                               y    => [ map { int( rand() * 10 ) } ( 1 .. ( scalar(@$x) ) ) ],
                                               name => "sample2"
 );
 my $sample3 = Chart::Plotly::Trace::Bar->new( x    => $x,
                                               y    => [ map { int( rand() * 10 ) } ( 1 .. ( scalar(@$x) ) ) ],
                                               name => "sample3"
 );
 my $plot = Chart::Plotly::Plot->new( traces => [ $sample1, $sample2, $sample3 ], layout => { barmode => 'group' } );
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

The data visualized by the span of the bars is set in `y` if `orientation` is set th *v* (the default) and the labels are set in `x`. By setting `orientation` to *h*, the roles are interchanged.

Screenshot of the above example:

=for HTML <p>
<img src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/bar.png" alt="Screenshot of the above example">
</p>

=for markdown ![Screenshot of the above example](https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/bar.png)

=for HTML <p>
<iframe src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/bar.html" style="border:none;" width="80%" height="520"></iframe>
</p>

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#bar>

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

=item * base

Sets where the bar base is drawn (in position axis units). In *stack* or *relative* barmode, traces that set *base* will be excluded and drawn in *overlay* mode instead.

=item * basesrc

Sets the source reference on plot.ly for  base .

=item * cliponaxis

Determines whether the text nodes are clipped about the subplot axes. To show the text nodes above axis lines and tick labels, make sure to set `xaxis.layer` and `yaxis.layer` to *below traces*.

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

=item * error_x

=item * error_y

=item * hoverinfo

Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.

=item * hoverinfosrc

Sets the source reference on plot.ly for  hoverinfo .

=item * hoverlabel

=item * hovertext

Sets hover text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (x,y) coordinates. To be seen, trace `hoverinfo` must contain a *text* flag.

=item * hovertextsrc

Sets the source reference on plot.ly for  hovertext .

=item * ids

Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.

=item * idssrc

Sets the source reference on plot.ly for  ids .

=item * insidetextfont

=item * legendgroup

Sets the legend group for this trace. Traces part of the same legend group hide/show at the same time when toggling legend items.

=item * marker

=item * name

Sets the trace name. The trace name appear as the legend item and on hover.

=item * offset

Shifts the position where the bar is drawn (in position axis units). In *group* barmode, traces that set *offset* will be excluded and drawn in *overlay* mode instead.

=item * offsetsrc

Sets the source reference on plot.ly for  offset .

=item * opacity

Sets the opacity of the trace.

=item * orientation

Sets the orientation of the bars. With *v* (*h*), the value of the each bar spans along the vertical (horizontal).

=item * outsidetextfont

=item * r

For legacy polar chart only.Please switch to *scatterpolar* trace type.Sets the radial coordinates.

=item * rsrc

Sets the source reference on plot.ly for  r .

=item * selected

=item * selectedpoints

Array containing integer indices of selected points. Has an effect only for traces that support selections. Note that an empty array means an empty selection where the `unselected` are turned on for all points, whereas, any other non-array values means no selection all where the `selected` and `unselected` styles have no effect.

=item * showlegend

Determines whether or not an item corresponding to this trace is shown in the legend.

=item * stream

=item * t

For legacy polar chart only.Please switch to *scatterpolar* trace type.Sets the angular coordinates.

=item * text

Sets text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points. If an array of string, the items are mapped in order to the this trace's (x,y) coordinates. If trace `hoverinfo` contains a *text* flag and *hovertext* is not set, these elements will be seen in the hover labels.

=item * textfont

=item * textposition

Specifies the location of the `text`. *inside* positions `text` inside, next to the bar end (rotated and scaled if needed). *outside* positions `text` outside, next to the bar end (scaled if needed). *auto* positions `text` inside or outside so that `text` size is maximized.

=item * textpositionsrc

Sets the source reference on plot.ly for  textposition .

=item * textsrc

Sets the source reference on plot.ly for  text .

=item * tsrc

Sets the source reference on plot.ly for  t .

=item * uid

=item * unselected

=item * visible

Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).

=item * width

Sets the bar width (in position axis units).

=item * widthsrc

Sets the source reference on plot.ly for  width .

=item * x

Sets the x coordinates.

=item * x0

Alternate to `x`. Builds a linear space of x coordinates. Use with `dx` where `x0` is the starting coordinate and `dx` the step.

=item * xaxis

Sets a reference between this trace's x coordinates and a 2D cartesian x axis. If *x* (the default value), the x coordinates refer to `layout.xaxis`. If *x2*, the x coordinates refer to `layout.xaxis2`, and so on.

=item * xcalendar

Sets the calendar system to use with `x` date data.

=item * xsrc

Sets the source reference on plot.ly for  x .

=item * y

Sets the y coordinates.

=item * y0

Alternate to `y`. Builds a linear space of y coordinates. Use with `dy` where `y0` is the starting coordinate and `dy` the step.

=item * yaxis

Sets a reference between this trace's y coordinates and a 2D cartesian y axis. If *y* (the default value), the y coordinates refer to `layout.yaxis`. If *y2*, the y coordinates refer to `layout.xaxis2`, and so on.

=item * ycalendar

Sets the calendar system to use with `y` date data.

=item * ysrc

Sets the source reference on plot.ly for  y .

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
