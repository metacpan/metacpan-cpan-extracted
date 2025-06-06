package Chart::Plotly::Trace::Parcats::Line::Colorbar;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Parcats::Line::Colorbar::Tickfont;
use Chart::Plotly::Trace::Parcats::Line::Colorbar::Tickformatstop;
use Chart::Plotly::Trace::Parcats::Line::Colorbar::Title;

our $VERSION = '0.042';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace parcats.

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

has bgcolor => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the color of padded area.",
);

has bordercolor => ( is            => "rw",
                     isa           => "Str",
                     documentation => "Sets the axis line color.",
);

has borderwidth => ( is            => "rw",
                     isa           => "Num",
                     documentation => "Sets the width (in px) or the border enclosing this color bar.",
);

has dtick => (
    is            => "rw",
    isa           => "Any",
    documentation =>
      "Sets the step in-between ticks on this axis. Use with `tick0`. Must be a positive number, or special strings available to *log* and *date* axes. If the axis `type` is *log*, then ticks are set every 10^(n*dtick) where n is the tick number. For example, to set a tick mark at 1, 10, 100, 1000, ... set dtick to 1. To set tick marks at 1, 100, 10000, ... set dtick to 2. To set tick marks at 1, 5, 25, 125, 625, 3125, ... set dtick to log_10(5), or 0.69897000433. *log* has several special values; *L<f>*, where `f` is a positive number, gives ticks linearly spaced in value (but not position). For example `tick0` = 0.1, `dtick` = *L0.5* will put ticks at 0.1, 0.6, 1.1, 1.6 etc. To show powers of 10 plus small digits between, use *D1* (all digits) or *D2* (only 2 and 5). `tick0` is ignored for *D1* and *D2*. If the axis `type` is *date*, then you must convert the time to milliseconds. For example, to set the interval between ticks to one day, set `dtick` to 86400000.0. *date* also has special values *n* gives ticks spaced by a number of months. `n` must be a positive integer. To set ticks on the 15th of every third month, set `tick0` to *2000-01-15* and `dtick` to *M3*. To set ticks every 4 years, set `dtick` to *M48*",
);

has exponentformat => (
    is            => "rw",
    isa           => enum( [ "none", "e", "E", "power", "SI", "B" ] ),
    documentation =>
      "Determines a formatting rule for the tick exponents. For example, consider the number 1,000,000,000. If *none*, it appears as 1,000,000,000. If *e*, 1e+9. If *E*, 1E+9. If *power*, 1x10^9 (with 9 in a super script). If *SI*, 1G. If *B*, 1B.",
);

has len => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the length of the color bar This measure excludes the padding of both ends. That is, the color bar length is this length minus the padding on both ends.",
);

has lenmode => (
    is            => "rw",
    isa           => enum( [ "fraction", "pixels" ] ),
    documentation =>
      "Determines whether this color bar's length (i.e. the measure in the color variation direction) is set in units of plot *fraction* or in *pixels. Use `len` to set the value.",
);

has minexponent => (
     is            => "rw",
     isa           => "Num",
     documentation =>
       "Hide SI prefix for 10^n if |n| is below this number. This only has an effect when `tickformat` is *SI* or *B*.",
);

has nticks => (
    is            => "rw",
    isa           => "Int",
    documentation =>
      "Specifies the maximum number of ticks for the particular axis. The actual number of ticks will be chosen automatically to be less than or equal to `nticks`. Has an effect only if `tickmode` is set to *auto*.",
);

has orientation => ( is            => "rw",
                     isa           => enum( [ "h", "v" ] ),
                     documentation => "Sets the orientation of the colorbar.",
);

has outlinecolor => ( is            => "rw",
                      isa           => "Str",
                      documentation => "Sets the axis line color.",
);

has outlinewidth => ( is            => "rw",
                      isa           => "Num",
                      documentation => "Sets the width (in px) of the axis line.",
);

has separatethousands => ( is            => "rw",
                           isa           => "Bool",
                           documentation => "If \"true\", even 4-digit integers are separated",
);

has showexponent => (
    is            => "rw",
    isa           => enum( [ "all", "first", "last", "none" ] ),
    documentation =>
      "If *all*, all exponents are shown besides their significands. If *first*, only the exponent of the first tick is shown. If *last*, only the exponent of the last tick is shown. If *none*, no exponents appear.",
);

has showticklabels => ( is            => "rw",
                        isa           => "Bool",
                        documentation => "Determines whether or not the tick labels are drawn.",
);

has showtickprefix => (
    is            => "rw",
    isa           => enum( [ "all", "first", "last", "none" ] ),
    documentation =>
      "If *all*, all tick labels are displayed with a prefix. If *first*, only the first tick is displayed with a prefix. If *last*, only the last tick is displayed with a suffix. If *none*, tick prefixes are hidden.",
);

has showticksuffix => ( is            => "rw",
                        isa           => enum( [ "all", "first", "last", "none" ] ),
                        documentation => "Same as `showtickprefix` but for tick suffixes.",
);

has thickness => (
               is            => "rw",
               isa           => "Num",
               documentation =>
                 "Sets the thickness of the color bar This measure excludes the size of the padding, ticks and labels.",
);

has thicknessmode => (
    is            => "rw",
    isa           => enum( [ "fraction", "pixels" ] ),
    documentation =>
      "Determines whether this color bar's thickness (i.e. the measure in the constant color direction) is set in units of plot *fraction* or in *pixels*. Use `thickness` to set the value.",
);

has tick0 => (
    is            => "rw",
    isa           => "Any",
    documentation =>
      "Sets the placement of the first tick on this axis. Use with `dtick`. If the axis `type` is *log*, then you must take the log of your starting tick (e.g. to set the starting tick to 100, set the `tick0` to 2) except when `dtick`=*L<f>* (see `dtick` for more info). If the axis `type` is *date*, it should be a date string, like date data. If the axis `type` is *category*, it should be a number, using the scale where each category is assigned a serial number from zero in the order it appears.",
);

has tickangle => (
    is            => "rw",
    documentation =>
      "Sets the angle of the tick labels with respect to the horizontal. For example, a `tickangle` of -90 draws the tick labels vertically.",
);

has tickcolor => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the tick color.",
);

has tickfont => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Parcats::Line::Colorbar::Tickfont", );

has tickformat => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "Sets the tick label formatting rule using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format. And for dates see: https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format. We add two items to d3's date formatter: *%h* for half of the year as a decimal number as well as *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*",
);

has tickformatstops => ( is  => "rw",
                         isa => "ArrayRef|ArrayRef[Chart::Plotly::Trace::Parcats::Line::Colorbar::Tickformatstop]", );

has ticklabeloverflow => (
    is            => "rw",
    isa           => enum( [ "allow", "hide past div", "hide past domain" ] ),
    documentation =>
      "Determines how we handle tick labels that would overflow either the graph div or the domain of the axis. The default value for inside tick labels is *hide past domain*. In other cases the default is *hide past div*.",
);

has ticklabelposition => (
    is  => "rw",
    isa => enum(
                 [ "outside",
                   "inside",
                   "outside top",
                   "inside top",
                   "outside left",
                   "inside left",
                   "outside right",
                   "inside right",
                   "outside bottom",
                   "inside bottom"
                 ]
    ),
    documentation =>
      "Determines where tick labels are drawn relative to the ticks. Left and right options are used when `orientation` is *h*, top and bottom when `orientation` is *v*.",
);

has ticklabelstep => (
    is            => "rw",
    isa           => "Int",
    documentation =>
      "Sets the spacing between tick labels as compared to the spacing between ticks. A value of 1 (default) means each tick gets a label. A value of 2 means shows every 2nd label. A larger value n means only every nth tick is labeled. `tick0` determines which labels are shown. Not implemented for axes with `type` *log* or *multicategory*, or when `tickmode` is *array*.",
);

has ticklen => ( is            => "rw",
                 isa           => "Num",
                 documentation => "Sets the tick length (in px).",
);

has tickmode => (
    is            => "rw",
    isa           => enum( [ "auto", "linear", "array" ] ),
    documentation =>
      "Sets the tick mode for this axis. If *auto*, the number of ticks is set via `nticks`. If *linear*, the placement of the ticks is determined by a starting position `tick0` and a tick step `dtick` (*linear* is the default value if `tick0` and `dtick` are provided). If *array*, the placement of the ticks is set via `tickvals` and the tick text is `ticktext`. (*array* is the default value if `tickvals` is provided).",
);

has tickprefix => ( is            => "rw",
                    isa           => "Str",
                    documentation => "Sets a tick label prefix.",
);

has ticks => (
    is            => "rw",
    isa           => enum( [ "outside", "inside", "" ] ),
    documentation =>
      "Determines whether ticks are drawn or not. If **, this axis' ticks are not drawn. If *outside* (*inside*), this axis' are drawn outside (inside) the axis lines.",
);

has ticksuffix => ( is            => "rw",
                    isa           => "Str",
                    documentation => "Sets a tick label suffix.",
);

has ticktext => (
    is            => "rw",
    isa           => "ArrayRef|PDL",
    documentation =>
      "Sets the text displayed at the ticks position via `tickvals`. Only has an effect if `tickmode` is set to *array*. Used with `tickvals`.",
);

has ticktextsrc => ( is            => "rw",
                     isa           => "Str",
                     documentation => "Sets the source reference on Chart Studio Cloud for `ticktext`.",
);

has tickvals => (
    is            => "rw",
    isa           => "ArrayRef|PDL",
    documentation =>
      "Sets the values at which ticks on this axis appear. Only has an effect if `tickmode` is set to *array*. Used with `ticktext`.",
);

has tickvalssrc => ( is            => "rw",
                     isa           => "Str",
                     documentation => "Sets the source reference on Chart Studio Cloud for `tickvals`.",
);

has tickwidth => ( is            => "rw",
                   isa           => "Num",
                   documentation => "Sets the tick width (in px).",
);

has title => ( is  => "rw",
               isa => "Maybe[HashRef]|Chart::Plotly::Trace::Parcats::Line::Colorbar::Title", );

has x => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the x position of the color bar (in plot fraction). Defaults to 1.02 when `orientation` is *v* and 0.5 when `orientation` is *h*.",
);

has xanchor => (
    is            => "rw",
    isa           => enum( [ "left", "center", "right" ] ),
    documentation =>
      "Sets this color bar's horizontal position anchor. This anchor binds the `x` position to the *left*, *center* or *right* of the color bar. Defaults to *left* when `orientation` is *v* and *center* when `orientation` is *h*.",
);

has xpad => ( is            => "rw",
              isa           => "Num",
              documentation => "Sets the amount of padding (in px) along the x direction.",
);

has y => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the y position of the color bar (in plot fraction). Defaults to 0.5 when `orientation` is *v* and 1.02 when `orientation` is *h*.",
);

has yanchor => (
    is            => "rw",
    isa           => enum( [ "top", "middle", "bottom" ] ),
    documentation =>
      "Sets this color bar's vertical position anchor This anchor binds the `y` position to the *top*, *middle* or *bottom* of the color bar. Defaults to *middle* when `orientation` is *v* and *bottom* when `orientation` is *h*.",
);

has ypad => ( is            => "rw",
              isa           => "Num",
              documentation => "Sets the amount of padding (in px) along the y direction.",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Parcats::Line::Colorbar - This attribute is one of the possible options for the trace parcats.

=head1 VERSION

version 0.042

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Trace::Parcats;
 use Chart::Plotly::Plot;
 
 # Example from https://github.com/plotly/plotly.js/blob/7b751009fc9804272316f0bb539ed0386c0858bd/test/image/mocks/parcats_bundled.json
 
 my $trace = Chart::Plotly::Trace::Parcats->new( bundlecolors => 1,
                                                 dimensions   => [
                                                            { label  => 'One',
                                                              values => [ (1) x 2, 2, 1, 2, (1) x 2, 2, 1 ]
                                                            },
                                                            { label  => 'Two',
                                                              values => [ 'A', 'B', 'A', 'B', ('C') x 2, 'A', 'B', 'C' ]
                                                            },
                                                            { label  => 'Three',
                                                              values => [ (11) x 9 ]
                                                            }
                                                 ],
                                                 domain => { x => [ 0.125, 0.625 ],
                                                             y => [ 0.25,  0.75 ]
                                                 },
                                                 line => { color => [ (0) x 2, (1) x 2, 0, 1, (0) x 3 ] }
 );
 
 my $plot = Chart::Plotly::Plot->new( traces => [$trace],
                                      layout => { height => 602,
                                                  margin => { b => 40,
                                                              l => 40,
                                                              r => 40,
                                                              t => 50
                                                  },
                                                  width => 592
                                      }
 );
 
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace parcats.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#parcats>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * bgcolor

Sets the color of padded area.

=item * bordercolor

Sets the axis line color.

=item * borderwidth

Sets the width (in px) or the border enclosing this color bar.

=item * dtick

Sets the step in-between ticks on this axis. Use with `tick0`. Must be a positive number, or special strings available to *log* and *date* axes. If the axis `type` is *log*, then ticks are set every 10^(n*dtick) where n is the tick number. For example, to set a tick mark at 1, 10, 100, 1000, ... set dtick to 1. To set tick marks at 1, 100, 10000, ... set dtick to 2. To set tick marks at 1, 5, 25, 125, 625, 3125, ... set dtick to log_10(5), or 0.69897000433. *log* has several special values; *L<f>*, where `f` is a positive number, gives ticks linearly spaced in value (but not position). For example `tick0` = 0.1, `dtick` = *L0.5* will put ticks at 0.1, 0.6, 1.1, 1.6 etc. To show powers of 10 plus small digits between, use *D1* (all digits) or *D2* (only 2 and 5). `tick0` is ignored for *D1* and *D2*. If the axis `type` is *date*, then you must convert the time to milliseconds. For example, to set the interval between ticks to one day, set `dtick` to 86400000.0. *date* also has special values *n* gives ticks spaced by a number of months. `n` must be a positive integer. To set ticks on the 15th of every third month, set `tick0` to *2000-01-15* and `dtick` to *M3*. To set ticks every 4 years, set `dtick` to *M48*

=item * exponentformat

Determines a formatting rule for the tick exponents. For example, consider the number 1,000,000,000. If *none*, it appears as 1,000,000,000. If *e*, 1e+9. If *E*, 1E+9. If *power*, 1x10^9 (with 9 in a super script). If *SI*, 1G. If *B*, 1B.

=item * len

Sets the length of the color bar This measure excludes the padding of both ends. That is, the color bar length is this length minus the padding on both ends.

=item * lenmode

Determines whether this color bar's length (i.e. the measure in the color variation direction) is set in units of plot *fraction* or in *pixels. Use `len` to set the value.

=item * minexponent

Hide SI prefix for 10^n if |n| is below this number. This only has an effect when `tickformat` is *SI* or *B*.

=item * nticks

Specifies the maximum number of ticks for the particular axis. The actual number of ticks will be chosen automatically to be less than or equal to `nticks`. Has an effect only if `tickmode` is set to *auto*.

=item * orientation

Sets the orientation of the colorbar.

=item * outlinecolor

Sets the axis line color.

=item * outlinewidth

Sets the width (in px) of the axis line.

=item * separatethousands

If "true", even 4-digit integers are separated

=item * showexponent

If *all*, all exponents are shown besides their significands. If *first*, only the exponent of the first tick is shown. If *last*, only the exponent of the last tick is shown. If *none*, no exponents appear.

=item * showticklabels

Determines whether or not the tick labels are drawn.

=item * showtickprefix

If *all*, all tick labels are displayed with a prefix. If *first*, only the first tick is displayed with a prefix. If *last*, only the last tick is displayed with a suffix. If *none*, tick prefixes are hidden.

=item * showticksuffix

Same as `showtickprefix` but for tick suffixes.

=item * thickness

Sets the thickness of the color bar This measure excludes the size of the padding, ticks and labels.

=item * thicknessmode

Determines whether this color bar's thickness (i.e. the measure in the constant color direction) is set in units of plot *fraction* or in *pixels*. Use `thickness` to set the value.

=item * tick0

Sets the placement of the first tick on this axis. Use with `dtick`. If the axis `type` is *log*, then you must take the log of your starting tick (e.g. to set the starting tick to 100, set the `tick0` to 2) except when `dtick`=*L<f>* (see `dtick` for more info). If the axis `type` is *date*, it should be a date string, like date data. If the axis `type` is *category*, it should be a number, using the scale where each category is assigned a serial number from zero in the order it appears.

=item * tickangle

Sets the angle of the tick labels with respect to the horizontal. For example, a `tickangle` of -90 draws the tick labels vertically.

=item * tickcolor

Sets the tick color.

=item * tickfont

=item * tickformat

Sets the tick label formatting rule using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format. And for dates see: https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format. We add two items to d3's date formatter: *%h* for half of the year as a decimal number as well as *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*

=item * tickformatstops

=item * ticklabeloverflow

Determines how we handle tick labels that would overflow either the graph div or the domain of the axis. The default value for inside tick labels is *hide past domain*. In other cases the default is *hide past div*.

=item * ticklabelposition

Determines where tick labels are drawn relative to the ticks. Left and right options are used when `orientation` is *h*, top and bottom when `orientation` is *v*.

=item * ticklabelstep

Sets the spacing between tick labels as compared to the spacing between ticks. A value of 1 (default) means each tick gets a label. A value of 2 means shows every 2nd label. A larger value n means only every nth tick is labeled. `tick0` determines which labels are shown. Not implemented for axes with `type` *log* or *multicategory*, or when `tickmode` is *array*.

=item * ticklen

Sets the tick length (in px).

=item * tickmode

Sets the tick mode for this axis. If *auto*, the number of ticks is set via `nticks`. If *linear*, the placement of the ticks is determined by a starting position `tick0` and a tick step `dtick` (*linear* is the default value if `tick0` and `dtick` are provided). If *array*, the placement of the ticks is set via `tickvals` and the tick text is `ticktext`. (*array* is the default value if `tickvals` is provided).

=item * tickprefix

Sets a tick label prefix.

=item * ticks

Determines whether ticks are drawn or not. If **, this axis' ticks are not drawn. If *outside* (*inside*), this axis' are drawn outside (inside) the axis lines.

=item * ticksuffix

Sets a tick label suffix.

=item * ticktext

Sets the text displayed at the ticks position via `tickvals`. Only has an effect if `tickmode` is set to *array*. Used with `tickvals`.

=item * ticktextsrc

Sets the source reference on Chart Studio Cloud for `ticktext`.

=item * tickvals

Sets the values at which ticks on this axis appear. Only has an effect if `tickmode` is set to *array*. Used with `ticktext`.

=item * tickvalssrc

Sets the source reference on Chart Studio Cloud for `tickvals`.

=item * tickwidth

Sets the tick width (in px).

=item * title

=item * x

Sets the x position of the color bar (in plot fraction). Defaults to 1.02 when `orientation` is *v* and 0.5 when `orientation` is *h*.

=item * xanchor

Sets this color bar's horizontal position anchor. This anchor binds the `x` position to the *left*, *center* or *right* of the color bar. Defaults to *left* when `orientation` is *v* and *center* when `orientation` is *h*.

=item * xpad

Sets the amount of padding (in px) along the x direction.

=item * y

Sets the y position of the color bar (in plot fraction). Defaults to 0.5 when `orientation` is *v* and 1.02 when `orientation` is *h*.

=item * yanchor

Sets this color bar's vertical position anchor This anchor binds the `y` position to the *top*, *middle* or *bottom* of the color bar. Defaults to *middle* when `orientation` is *v* and *bottom* when `orientation` is *h*.

=item * ypad

Sets the amount of padding (in px) along the y direction.

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
