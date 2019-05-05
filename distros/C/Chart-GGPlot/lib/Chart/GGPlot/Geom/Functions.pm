package Chart::GGPlot::Geom::Functions;

# ABSTRACT: Function interface for Chart::GGPlot::Geom

use Chart::GGPlot::Setup;

our $VERSION = '0.0003'; # VERSION

use Chart::GGPlot::Util qw(collect_functions_from_package);

use parent qw(Exporter::Tiny);

my @export_ggplot;

our @sub_namespaces = qw(
  Blank
  Bar Boxplot
  Path Point Line
);

for my $name (@sub_namespaces) {
    my $package = "Chart::GGPlot::Geom::$name";
    my @func_names = collect_functions_from_package($package);
    push @export_ggplot, @func_names;
}

our @EXPORT_OK = (
    @export_ggplot,
);

our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => \@export_ggplot,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Functions - Function interface for Chart::GGPlot::Geom

=head1 VERSION

version 0.0003

=head1 DESCRIPTION

This module provides the C<geom_*> functions supported by this Chart-GGPlot
library.  When used standalone, each C<geom_*> function generates a
L<Chart::GGPlot::Layer> object. Also the functions can be used as
L<Chart::GGPlot::Plot> methods, to add layers into the plot object.

=head1 FUNCTIONS

=head2 geom_blank

=head2 geom_bar

    geom_bar(:$mapping=undef, :$data=undef, :$stat='count',
             :$position='stack', :$width=undef,
             :$na_rm=false, :$show_legend='auto', :$inherit_aes=true,
             %rest)

The "bar" geom makes the height bar proportional to the number of cases in each group (or if the C<weight> aesthetic is supplied, the sum of the
C<weights>). 
It uses C<stat_count()> by default: it counts the number of cases at each x
position. 

Arguments:

=over 4

=item * $mapping

Set of aesthetic mappings created by C<aes()>. If specified and
C<$inherit_aes> is true (the default), it is combined with the default
mapping at the top level of the plot.
You must supply mapping if there is no plot mapping.

=item * $data

The data to be displayed in this layer.
If C<undef>, the default, the data is inherited from the plot data as
specified in the call to C<ggplot()>.

=item * $stat

The statistical transformation to use on the data for this layer, as a
string.

=item * $position

Position adjustment, either as a string, or the result of a call to a
position adjustment function.

=item * $na_rm

If false, the default, missing values are removed with a warning.
If true, missing values are silently removed.

=item * $show_legend

Should this layer be included in the legends?
'auto', the default, includes if any aesthetics are mapped.
false never includes, and false always includes.

=item * $inherit_aes

If false, overrides the default aesthetics, rather than combining with them.
This is most useful for helper functions that define both data and
aesthetics and shouldn't inherit behaviour from the default plot
specification.

=item * %rest

Other arguments passed to C<Chart::GGPlot::Layer-E<gt>new()>.
These are often aesthetics, used to set an aesthetic to a fixed value,
like C<color =E<gt> "red", size =E<gt> 3>.
They may also be parameters to the paired geom/stat.

=item * $width

Bar width. By default, set to 90% of the resolution of the data.

=back

See also L<Chart::GGPlot::Stat::Functions/stat_count>.

=head2 geom_histogram

    geom_histogram(:$mapping=undef, :$data=undef, :$stat="bin",
                   :$position="stack", :$binwidth=undef, :$bins=undef,
                   :$na_rm=false, :$show_legend='auto', :$inherit_aes=true,
                   %rest)

Visualise the distribution of a single continuous variable by dividing the 
x axis into bins and counting the number of observations in each bin.
This "histogram" geom displays the counts with bars.

=over 4

=item * $mapping

Set of aesthetic mappings created by C<aes()>. If specified and
C<$inherit_aes> is true (the default), it is combined with the default
mapping at the top level of the plot.
You must supply mapping if there is no plot mapping.

=item * $data

The data to be displayed in this layer.
If C<undef>, the default, the data is inherited from the plot data as
specified in the call to C<ggplot()>.

=item * $stat

The statistical transformation to use on the data for this layer, as a
string.

=item * $position

Position adjustment, either as a string, or the result of a call to a
position adjustment function.

=item * $na_rm

If false, the default, missing values are removed with a warning.
If true, missing values are silently removed.

=item * $show_legend

Should this layer be included in the legends?
'auto', the default, includes if any aesthetics are mapped.
false never includes, and false always includes.

=item * $inherit_aes

If false, overrides the default aesthetics, rather than combining with them.
This is most useful for helper functions that define both data and
aesthetics and shouldn't inherit behaviour from the default plot
specification.

=item * %rest

Other arguments passed to C<Chart::GGPlot::Layer-E<gt>new()>.
These are often aesthetics, used to set an aesthetic to a fixed value,
like C<color =E<gt> "red", size =E<gt> 3>.
They may also be parameters to the paired geom/stat.

=item * $binwidth

The width of the bins.
Can be specified as a numeric value, or a function that calculates width
from x. The default is to use C<$bins> bins that cover the range of the
data.

=item * $bins

Number of bins. Overridden by C<$binwidth>. Defaults to 30.

You should always override this C<$bins> or C<$binwidth>, exploring
multiple widths to find the best to illustrate the stories in your data.

=back

See also L<Chart::GGPlot::Stat::Functions/stat_bin>.

=head2 geom_boxplot

    geom_boxplot(:$mapping=undef, :$data=undef, 
                 :$stat='boxplot', :$position='dodge2',
                 :$outlier_color=undef, :$outlier_colour=undef,
                 :$outlier_fill=undef, :$outlier_shape=undef,
                 :$outlier_size=1.5, :$outlier_stroke=undef,
                 :$outlier_alpha=undef,
                 :$notch=false, :$notchwidth=0.25,
                 :$varwidth=false, :$na_rm=false,
                 :$show_legend='auto', :$inherit_aes=true,
                 %rest)

The boxplot compactly displays the distribution of a continuous variable. It
visualises five summary statistics (the median, two hinges and two whiskers),
and all "outlying" points individually.

Arguments:

=over 4

=item * $mapping

Set of aesthetic mappings created by C<aes()>. If specified and
C<$inherit_aes> is true (the default), it is combined with the default
mapping at the top level of the plot.
You must supply mapping if there is no plot mapping.

=item * $data

The data to be displayed in this layer.
If C<undef>, the default, the data is inherited from the plot data as
specified in the call to C<ggplot()>.

=item * $stat

The statistical transformation to use on the data for this layer, as a
string.

=item * $position

Position adjustment, either as a string, or the result of a call to a
position adjustment function.

=item * $na_rm

If false, the default, missing values are removed with a warning.
If true, missing values are silently removed.

=item * $show_legend

Should this layer be included in the legends?
'auto', the default, includes if any aesthetics are mapped.
false never includes, and false always includes.

=item * $inherit_aes

If false, overrides the default aesthetics, rather than combining with them.
This is most useful for helper functions that define both data and
aesthetics and shouldn't inherit behaviour from the default plot
specification.

=item * %rest

Other arguments passed to C<Chart::GGPlot::Layer-E<gt>new()>.
These are often aesthetics, used to set an aesthetic to a fixed value,
like C<color =E<gt> "red", size =E<gt> 3>.
They may also be parameters to the paired geom/stat.

=item * $outlier_color, $outlier_fill, $outlier_size, $outlier_stroke,
$outlier_alpha

Default aesthetics for outliers. Set to C<undef> to inherit from the
aesthetics used for the box.

Sometimes it can be useful to hide the outliers, for example when overlaying
the raw data points on top of the boxplot. Hiding the outliers can be
achieved by setting C<outlier_shape =E<gt> ''>.
Importantly, this does not remove the outliers, it only hides them, so the
range calculated for the y-axis will be the same with outliers shown and
outliers hidden.

=item * $notch

If false (default) make a standard box plot. If true, make a notched box
plot. Notches are used to compare groups; if the notches of two boxes do not
overlap, this suggests that the medians are significantly different.

=item * $notchwidth

For a notched box plot, width of the notch relative to the body. 

=back

See also L<Chart::GGPlot::Stat::Functions/stat_boxplot>.

=head2 geom_path

    geom_path(:$mapping=undef, :$data=undef, :$stat='identity',
              :$position='identity', :$na_rm=false, :$show_legend='auto',
              :$inherit_aes=true, 
              %rest)

The "path" geom connects the observations in the order in which they appear
in the data.

=over 4

=item * $mapping

Set of aesthetic mappings created by C<aes()>. If specified and
C<$inherit_aes> is true (the default), it is combined with the default
mapping at the top level of the plot.
You must supply mapping if there is no plot mapping.

=item * $data

The data to be displayed in this layer.
If C<undef>, the default, the data is inherited from the plot data as
specified in the call to C<ggplot()>.

=item * $stat

The statistical transformation to use on the data for this layer, as a
string.

=item * $position

Position adjustment, either as a string, or the result of a call to a
position adjustment function.

=item * $na_rm

If false, the default, missing values are removed with a warning.
If true, missing values are silently removed.

=item * $show_legend

Should this layer be included in the legends?
'auto', the default, includes if any aesthetics are mapped.
false never includes, and false always includes.

=item * $inherit_aes

If false, overrides the default aesthetics, rather than combining with them.
This is most useful for helper functions that define both data and
aesthetics and shouldn't inherit behaviour from the default plot
specification.

=item * %rest

Other arguments passed to C<Chart::GGPlot::Layer-E<gt>new()>.
These are often aesthetics, used to set an aesthetic to a fixed value,
like C<color =E<gt> "red", size =E<gt> 3>.
They may also be parameters to the paired geom/stat.

=back

=head2 geom_point

    geom_point(:$mapping=undef, :$data=undef, :$stat='identity',
               :$position='identity',
               :$na_rm=false, :$show_legend='auto', :$inherit_aes=true,
               %rest)

The "point" geom is used to create scatterplots.
The scatterplot is most useful for displaying the relationship between two
continuous variables.
A bubblechart is a scatterplot with a third variable mapped to the size of
points.

Arguments:

=over 4

=item * $mapping

Set of aesthetic mappings created by C<aes()>. If specified and
C<$inherit_aes> is true (the default), it is combined with the default
mapping at the top level of the plot.
You must supply mapping if there is no plot mapping.

=item * $data

The data to be displayed in this layer.
If C<undef>, the default, the data is inherited from the plot data as
specified in the call to C<ggplot()>.

=item * $stat

The statistical transformation to use on the data for this layer, as a
string.

=item * $position

Position adjustment, either as a string, or the result of a call to a
position adjustment function.

=item * $na_rm

If false, the default, missing values are removed with a warning.
If true, missing values are silently removed.

=item * $show_legend

Should this layer be included in the legends?
'auto', the default, includes if any aesthetics are mapped.
false never includes, and false always includes.

=item * $inherit_aes

If false, overrides the default aesthetics, rather than combining with them.
This is most useful for helper functions that define both data and
aesthetics and shouldn't inherit behaviour from the default plot
specification.

=item * %rest

Other arguments passed to C<Chart::GGPlot::Layer-E<gt>new()>.
These are often aesthetics, used to set an aesthetic to a fixed value,
like C<color =E<gt> "red", size =E<gt> 3>.
They may also be parameters to the paired geom/stat.

=back

=head2 geom_line

    geom_line(:$mapping=undef, :$data=undef, :$stat='identity',
              :$position='identity', :$na_rm=false, :$show_legend='auto',
              :$inherit_aes=true, 
              %rest)

The "line" geom connects the observations in the order of the variable on
the x axis.

Arguments:

=over 4

=item * $mapping

Set of aesthetic mappings created by C<aes()>. If specified and
C<$inherit_aes> is true (the default), it is combined with the default
mapping at the top level of the plot.
You must supply mapping if there is no plot mapping.

=item * $data

The data to be displayed in this layer.
If C<undef>, the default, the data is inherited from the plot data as
specified in the call to C<ggplot()>.

=item * $stat

The statistical transformation to use on the data for this layer, as a
string.

=item * $position

Position adjustment, either as a string, or the result of a call to a
position adjustment function.

=item * $na_rm

If false, the default, missing values are removed with a warning.
If true, missing values are silently removed.

=item * $show_legend

Should this layer be included in the legends?
'auto', the default, includes if any aesthetics are mapped.
false never includes, and false always includes.

=item * $inherit_aes

If false, overrides the default aesthetics, rather than combining with them.
This is most useful for helper functions that define both data and
aesthetics and shouldn't inherit behaviour from the default plot
specification.

=item * %rest

Other arguments passed to C<Chart::GGPlot::Layer-E<gt>new()>.
These are often aesthetics, used to set an aesthetic to a fixed value,
like C<color =E<gt> "red", size =E<gt> 3>.
They may also be parameters to the paired geom/stat.

=back

=head1 SEE ALSO

L<Chart::GGPlot::Layer>,
L<Chart::GGPlot::Plot>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
