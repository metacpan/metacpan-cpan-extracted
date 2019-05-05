package Chart::GGPlot::Stat::Functions;

# ABSTRACT: Function interface for stats

use Chart::GGPlot::Setup;

our $VERSION = '0.0003'; # VERSION

use Module::Load;

use Chart::GGPlot::Util qw(collect_functions_from_package);

use parent qw(Exporter::Tiny);

my @export_ggplot;

our @sub_namespaces = qw(Bin Boxplot Count Identity);

for my $name (@sub_namespaces) {
    my $package = "Chart::GGPlot::Stat::$name";
    my @func_names = collect_functions_from_package($package);
    push @export_ggplot, @func_names;
}

our @EXPORT_OK   = @export_ggplot;
our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => \@export_ggplot,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Stat::Functions - Function interface for stats

=head1 VERSION

version 0.0003

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 stat_bin

    stat_bin(:$mapping=undef, :$data=undef,
             :$geom="bar", :$position="stack",
             :$binwidth=undef, :$bins=undef,
             :$center=undef, :$boundary=undef, :$breaks=undef,
             :$pad=false,
             :$na_rm=false, :$show_legend='auto', :$inherit_aes=true,
             %rest)

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

=head2 stat_boxplot

    stat_boxplot(:$mapping=undef, :$data=undef,
                 :$geom='boxplot', :$position='dodge2',
                 :$coef=1.5,
                 :$na_rm=false, :$show_legend='auto', :$inherit_aes=true,
                 %rest)

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

=item * $coef

Length of the whiskers as multiple of IQR. Defaults to 1.5.

=back

=head2 stat_count

    stat_count(:$mapping=undef, :$data=undef,
               :$geom='bar', :$position='stack', 
               :$width=undef,
               :$na_rm=false, :$show_legend=undef, :$inherit_aes=true,
               %rest)

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

=head2 stat_identity

    stat_identity(:$mapping=undef, :$data=undef,
                  :$geom="point", :$position="identity",
                  :$show_legend=undef, :$inherit_aes=true,
                  %rest)

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

L<Chart::GGPlot::Stat>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
