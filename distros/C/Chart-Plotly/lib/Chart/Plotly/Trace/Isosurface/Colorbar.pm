package Chart::Plotly::Trace::Isosurface::Colorbar;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Isosurface::Colorbar::Tickfont;
use Chart::Plotly::Trace::Isosurface::Colorbar::Tickformatstop;
use Chart::Plotly::Trace::Isosurface::Colorbar::Title;

our $VERSION = '0.042';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace isosurface.

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
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Colorbar::Tickfont", );

has tickformat => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "Sets the tick label formatting rule using d3 formatting mini-languages which are very similar to those in Python. For numbers, see: https://github.com/d3/d3-format/tree/v1.4.5#d3-format. And for dates see: https://github.com/d3/d3-time-format/tree/v2.2.3#locale_format. We add two items to d3's date formatter: *%h* for half of the year as a decimal number as well as *%{n}f* for fractional seconds with n digits. For example, *2016-10-13 09:15:23.456* with tickformat *%H~%M~%S.%2f* would display *09~15~23.46*",
);

has tickformatstops => ( is  => "rw",
                         isa => "ArrayRef|ArrayRef[Chart::Plotly::Trace::Isosurface::Colorbar::Tickformatstop]", );

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
               isa => "Maybe[HashRef]|Chart::Plotly::Trace::Isosurface::Colorbar::Title", );

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

Chart::Plotly::Trace::Isosurface::Colorbar - This attribute is one of the possible options for the trace isosurface.

=head1 VERSION

version 0.042

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

This attribute is part of the possible options for the trace isosurface.

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
