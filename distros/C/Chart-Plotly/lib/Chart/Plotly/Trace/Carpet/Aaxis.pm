package Chart::Plotly::Trace::Carpet::Aaxis;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Carpet::Aaxis::Tickfont;
use Chart::Plotly::Trace::Carpet::Aaxis::Tickformatstop;
use Chart::Plotly::Trace::Carpet::Aaxis::Title;

our $VERSION = '0.027';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace carpet.

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

has arraydtick => ( is            => "rw",
                    isa           => "Int",
                    documentation => "The stride between grid lines along the axis",
);

has arraytick0 => ( is            => "rw",
                    isa           => "Int",
                    documentation => "The starting index of grid lines along the axis",
);

has autorange => (
    is => "rw",
    documentation =>
      "Determines whether or not the range of this axis is computed in relation to the input data. See `rangemode` for more info. If `range` is provided, then `autorange` is set to *false*.",
);

has categoryarray => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Sets the order in which categories on this axis appear. Only has an effect if `categoryorder` is set to *array*. Used with `categoryorder`.",
);

has categoryarraysrc => ( is            => "rw",
                          isa           => "Str",
                          documentation => "Sets the source reference on plot.ly for  categoryarray .",
);

has categoryorder => (
    is  => "rw",
    isa => enum( [ "trace", "category ascending", "category descending", "array" ] ),
    documentation =>
      "Specifies the ordering logic for the case of categorical variables. By default, plotly uses *trace*, which specifies the order that is present in the data supplied. Set `categoryorder` to *category ascending* or *category descending* if order should be determined by the alphanumerical order of the category names. Set `categoryorder` to *array* to derive the ordering from the attribute `categoryarray`. If a category is not found in the `categoryarray` array, the sorting behavior for that attribute will be identical to the *trace* mode. The unspecified categories will follow the categories in `categoryarray`.",
);

has cheatertype => ( is  => "rw",
                     isa => enum( [ "index", "value" ] ), );

has color => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Sets default for all colors associated with this axis all at once: line, font, tick, and grid colors. Grid color is lightened by blending this with the plot background Individual pieces can override this.",
);

has dtick => ( is            => "rw",
               isa           => "Num",
               documentation => "The stride between grid lines along the axis",
);

has endline => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not a line is drawn at along the final value of this axis. If *true*, the end line is drawn on top of the grid lines.",
);

has endlinecolor => ( is            => "rw",
                      isa           => "Str",
                      documentation => "Sets the line color of the end line.",
);

has endlinewidth => ( is            => "rw",
                      isa           => "Num",
                      documentation => "Sets the width (in px) of the end line.",
);

has exponentformat => (
    is  => "rw",
    isa => enum( [ "none", "e", "E", "power", "SI", "B" ] ),
    documentation =>
      "Determines a formatting rule for the tick exponents. For example, consider the number 1,000,000,000. If *none*, it appears as 1,000,000,000. If *e*, 1e+9. If *E*, 1E+9. If *power*, 1x10^9 (with 9 in a super script). If *SI*, 1G. If *B*, 1B.",
);

has fixedrange => (is            => "rw",
                   isa           => "Bool",
                   documentation => "Determines whether or not this axis is zoom-able. If true, then zoom is disabled.",
);

has gridcolor => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the axis line color.",
);

has gridwidth => ( is            => "rw",
                   isa           => "Num",
                   documentation => "Sets the width (in px) of the axis line.",
);

has labelpadding => ( is            => "rw",
                      isa           => "Int",
                      documentation => "Extra padding between label and the axis",
);

has labelprefix => ( is            => "rw",
                     isa           => "Str",
                     documentation => "Sets a axis label prefix.",
);

has labelsuffix => ( is            => "rw",
                     isa           => "Str",
                     documentation => "Sets a axis label suffix.",
);

has linecolor => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the axis line color.",
);

has linewidth => ( is            => "rw",
                   isa           => "Num",
                   documentation => "Sets the width (in px) of the axis line.",
);

has minorgridcolor => ( is            => "rw",
                        isa           => "Str",
                        documentation => "Sets the color of the grid lines.",
);

has minorgridcount => ( is            => "rw",
                        isa           => "Int",
                        documentation => "Sets the number of minor grid ticks per major grid tick",
);

has minorgridwidth => ( is            => "rw",
                        isa           => "Num",
                        documentation => "Sets the width (in px) of the grid lines.",
);

has nticks => (
    is  => "rw",
    isa => "Int",
    documentation =>
      "Specifies the maximum number of ticks for the particular axis. The actual number of ticks will be chosen automatically to be less than or equal to `nticks`. Has an effect only if `tickmode` is set to *auto*.",
);

has range => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Sets the range of this axis. If the axis `type` is *log*, then you must take the log of your desired range (e.g. to set the range from 1 to 100, set the range from 0 to 2). If the axis `type` is *date*, it should be date strings, like date data, though Date objects and unix milliseconds will be accepted and converted to strings. If the axis `type` is *category*, it should be numbers, using the scale where each category is assigned a serial number from zero in the order it appears.",
);

has rangemode => (
    is  => "rw",
    isa => enum( [ "normal", "tozero", "nonnegative" ] ),
    documentation =>
      "If *normal*, the range is computed in relation to the extrema of the input data. If *tozero*`, the range extends to 0, regardless of the input data If *nonnegative*, the range is non-negative, regardless of the input data.",
);

has separatethousands => ( is            => "rw",
                           isa           => "Bool",
                           documentation => "If \"true\", even 4-digit integers are separated",
);

has showexponent => (
    is  => "rw",
    isa => enum( [ "all", "first", "last", "none" ] ),
    documentation =>
      "If *all*, all exponents are shown besides their significands. If *first*, only the exponent of the first tick is shown. If *last*, only the exponent of the last tick is shown. If *none*, no exponents appear.",
);

has showgrid => (
            is  => "rw",
            isa => "Bool",
            documentation =>
              "Determines whether or not grid lines are drawn. If *true*, the grid lines are drawn at every tick mark.",
);

has showline => ( is            => "rw",
                  isa           => "Bool",
                  documentation => "Determines whether or not a line bounding this axis is drawn.",
);

has showticklabels => (
        is  => "rw",
        isa => enum( [ "start", "end", "both", "none" ] ),
        documentation =>
          "Determines whether axis labels are drawn on the low side, the high side, both, or neither side of the axis.",
);

has showtickprefix => (
    is  => "rw",
    isa => enum( [ "all", "first", "last", "none" ] ),
    documentation =>
      "If *all*, all tick labels are displayed with a prefix. If *first*, only the first tick is displayed with a prefix. If *last*, only the last tick is displayed with a suffix. If *none*, tick prefixes are hidden.",
);

has showticksuffix => ( is            => "rw",
                        isa           => enum( [ "all", "first", "last", "none" ] ),
                        documentation => "Same as `showtickprefix` but for tick suffixes.",
);

has smoothing => ( is  => "rw",
                   isa => "Num", );

has startline => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not a line is drawn at along the starting value of this axis. If *true*, the start line is drawn on top of the grid lines.",
);

has startlinecolor => ( is            => "rw",
                        isa           => "Str",
                        documentation => "Sets the line color of the start line.",
);

has startlinewidth => ( is            => "rw",
                        isa           => "Num",
                        documentation => "Sets the width (in px) of the start line.",
);

has tick0 => ( is            => "rw",
               isa           => "Num",
               documentation => "The starting index of grid lines along the axis",
);

has tickangle => (
    is => "rw",
    documentation =>
      "Sets the angle of the tick labels with respect to the horizontal. For example, a `tickangle` of -90 draws the tick labels vertically.",
);

has tickfont => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Carpet::Aaxis::Tickfont", );

has tickformat => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Sets the tick label formatting rule using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/blob/master/README.md#locale_format And for dates see: https://github.com/d3/d3-time-format/blob/master/README.md#locale_format We add one item to d3's date formatter: *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*",
);

has tickformatstops => ( is  => "rw",
                         isa => "ArrayRef|ArrayRef[Chart::Plotly::Trace::Carpet::Aaxis::Tickformatstop]", );

has tickmode => ( is  => "rw",
                  isa => enum( [ "linear", "array" ] ), );

has tickprefix => ( is            => "rw",
                    isa           => "Str",
                    documentation => "Sets a tick label prefix.",
);

has ticksuffix => ( is            => "rw",
                    isa           => "Str",
                    documentation => "Sets a tick label suffix.",
);

has ticktext => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Sets the text displayed at the ticks position via `tickvals`. Only has an effect if `tickmode` is set to *array*. Used with `tickvals`.",
);

has ticktextsrc => ( is            => "rw",
                     isa           => "Str",
                     documentation => "Sets the source reference on plot.ly for  ticktext .",
);

has tickvals => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Sets the values at which ticks on this axis appear. Only has an effect if `tickmode` is set to *array*. Used with `ticktext`.",
);

has tickvalssrc => ( is            => "rw",
                     isa           => "Str",
                     documentation => "Sets the source reference on plot.ly for  tickvals .",
);

has title => ( is  => "rw",
               isa => "Maybe[HashRef]|Chart::Plotly::Trace::Carpet::Aaxis::Title", );

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Carpet::Aaxis - This attribute is one of the possible options for the trace carpet.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use Chart::Plotly qw(show_plot);
 use Chart::Plotly::Trace::Carpet;
 # Example data from: https://plot.ly/javascript/carpet-plot/#add-parameter-values
 my $carpet = Chart::Plotly::Trace::Carpet->new(
     a => [ 4, 4, 4, 4.5, 4.5, 4.5, 5, 5, 5, 6, 6, 6 ],
     b => [ 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3 ],
     y => [ 2, 3.5, 4, 3, 4.5, 5, 5.5, 6.5, 7.5, 8, 8.5, 10 ]);
 
 show_plot([ $carpet ]);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace carpet.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#carpet>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * arraydtick

The stride between grid lines along the axis

=item * arraytick0

The starting index of grid lines along the axis

=item * autorange

Determines whether or not the range of this axis is computed in relation to the input data. See `rangemode` for more info. If `range` is provided, then `autorange` is set to *false*.

=item * categoryarray

Sets the order in which categories on this axis appear. Only has an effect if `categoryorder` is set to *array*. Used with `categoryorder`.

=item * categoryarraysrc

Sets the source reference on plot.ly for  categoryarray .

=item * categoryorder

Specifies the ordering logic for the case of categorical variables. By default, plotly uses *trace*, which specifies the order that is present in the data supplied. Set `categoryorder` to *category ascending* or *category descending* if order should be determined by the alphanumerical order of the category names. Set `categoryorder` to *array* to derive the ordering from the attribute `categoryarray`. If a category is not found in the `categoryarray` array, the sorting behavior for that attribute will be identical to the *trace* mode. The unspecified categories will follow the categories in `categoryarray`.

=item * cheatertype

=item * color

Sets default for all colors associated with this axis all at once: line, font, tick, and grid colors. Grid color is lightened by blending this with the plot background Individual pieces can override this.

=item * dtick

The stride between grid lines along the axis

=item * endline

Determines whether or not a line is drawn at along the final value of this axis. If *true*, the end line is drawn on top of the grid lines.

=item * endlinecolor

Sets the line color of the end line.

=item * endlinewidth

Sets the width (in px) of the end line.

=item * exponentformat

Determines a formatting rule for the tick exponents. For example, consider the number 1,000,000,000. If *none*, it appears as 1,000,000,000. If *e*, 1e+9. If *E*, 1E+9. If *power*, 1x10^9 (with 9 in a super script). If *SI*, 1G. If *B*, 1B.

=item * fixedrange

Determines whether or not this axis is zoom-able. If true, then zoom is disabled.

=item * gridcolor

Sets the axis line color.

=item * gridwidth

Sets the width (in px) of the axis line.

=item * labelpadding

Extra padding between label and the axis

=item * labelprefix

Sets a axis label prefix.

=item * labelsuffix

Sets a axis label suffix.

=item * linecolor

Sets the axis line color.

=item * linewidth

Sets the width (in px) of the axis line.

=item * minorgridcolor

Sets the color of the grid lines.

=item * minorgridcount

Sets the number of minor grid ticks per major grid tick

=item * minorgridwidth

Sets the width (in px) of the grid lines.

=item * nticks

Specifies the maximum number of ticks for the particular axis. The actual number of ticks will be chosen automatically to be less than or equal to `nticks`. Has an effect only if `tickmode` is set to *auto*.

=item * range

Sets the range of this axis. If the axis `type` is *log*, then you must take the log of your desired range (e.g. to set the range from 1 to 100, set the range from 0 to 2). If the axis `type` is *date*, it should be date strings, like date data, though Date objects and unix milliseconds will be accepted and converted to strings. If the axis `type` is *category*, it should be numbers, using the scale where each category is assigned a serial number from zero in the order it appears.

=item * rangemode

If *normal*, the range is computed in relation to the extrema of the input data. If *tozero*`, the range extends to 0, regardless of the input data If *nonnegative*, the range is non-negative, regardless of the input data.

=item * separatethousands

If "true", even 4-digit integers are separated

=item * showexponent

If *all*, all exponents are shown besides their significands. If *first*, only the exponent of the first tick is shown. If *last*, only the exponent of the last tick is shown. If *none*, no exponents appear.

=item * showgrid

Determines whether or not grid lines are drawn. If *true*, the grid lines are drawn at every tick mark.

=item * showline

Determines whether or not a line bounding this axis is drawn.

=item * showticklabels

Determines whether axis labels are drawn on the low side, the high side, both, or neither side of the axis.

=item * showtickprefix

If *all*, all tick labels are displayed with a prefix. If *first*, only the first tick is displayed with a prefix. If *last*, only the last tick is displayed with a suffix. If *none*, tick prefixes are hidden.

=item * showticksuffix

Same as `showtickprefix` but for tick suffixes.

=item * smoothing

=item * startline

Determines whether or not a line is drawn at along the starting value of this axis. If *true*, the start line is drawn on top of the grid lines.

=item * startlinecolor

Sets the line color of the start line.

=item * startlinewidth

Sets the width (in px) of the start line.

=item * tick0

The starting index of grid lines along the axis

=item * tickangle

Sets the angle of the tick labels with respect to the horizontal. For example, a `tickangle` of -90 draws the tick labels vertically.

=item * tickfont

=item * tickformat

Sets the tick label formatting rule using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/blob/master/README.md#locale_format And for dates see: https://github.com/d3/d3-time-format/blob/master/README.md#locale_format We add one item to d3's date formatter: *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*

=item * tickformatstops

=item * tickmode

=item * tickprefix

Sets a tick label prefix.

=item * ticksuffix

Sets a tick label suffix.

=item * ticktext

Sets the text displayed at the ticks position via `tickvals`. Only has an effect if `tickmode` is set to *array*. Used with `tickvals`.

=item * ticktextsrc

Sets the source reference on plot.ly for  ticktext .

=item * tickvals

Sets the values at which ticks on this axis appear. Only has an effect if `tickmode` is set to *array*. Used with `ticktext`.

=item * tickvalssrc

Sets the source reference on plot.ly for  tickvals .

=item * title

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
