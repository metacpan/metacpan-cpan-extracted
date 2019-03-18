package Chart::GGPlot::Geom::Functions;

# ABSTRACT: Function interface for Chart::GGPlot::Geom

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.0001'; # VERSION

use Chart::GGPlot::Layer::Functions qw(layer);
use Chart::GGPlot::Types;
use Chart::GGPlot::Util qw(:all);

use parent qw(Exporter::Tiny);

my @export_ggplot = qw(
  geom_blank
  geom_point
  geom_path geom_line
  geom_bar geom_histogram
);

our @EXPORT_OK = (
    @export_ggplot,
);

our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => \@export_ggplot,
);

fun geom_blank (:$mapping = undef, :$data = undef,
                :$stat = "identity", :$position = "identity",
                :$show_legend = 'auto', :$inherit_aes = true,
                %rest) {
    return layer(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        check_aes   => false,
        geom        => 'blank',
        params      => \%rest,
    );
}


fun geom_path (:$mapping = undef, :$data = undef, 
               :$stat = 'identity', :$position = 'identity', 
               :$na_rm = false,
               :$show_legend = 'auto', :$inherit_aes = true, 
               %rest) {
    return layer(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        geom        => 'path',
        params      => { na_rm => $na_rm, %rest },
    );
}


fun geom_line (:$mapping = undef, :$data = undef, 
               :$stat = 'identity', :$position = 'identity', 
               :$na_rm = false,
               :$show_legend = 'auto', :$inherit_aes = true, 
               %rest) {
    return layer(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        geom        => 'line',
        params      => { na_rm => $na_rm, %rest },
    );
}


fun geom_point (:$mapping = undef, :$data = undef,
                :$stat = 'identity', :$position = 'identity',
                :$na_rm = false,
                :$show_legend = 'auto', :$inherit_aes = true, 
                %rest) {
    return layer(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        geom        => 'point',
        params      => { na_rm => $na_rm, %rest },
    );
}


fun geom_bar(:$mapping = undef, :$data = undef,
             :$stat = 'count', :$position = 'stack', 
             :$width = undef, :$na_rm = false,
             :$show_legend = 'auto', :$inherit_aes = true,
             %rest) {
    return layer(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        geom        => 'bar',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => {
            width => $width,
            na_rm => $na_rm,
            %rest,
        },
    );
}


fun geom_histogram (:$data = undef, :$mapping = undef,
                    :$stat = "bin", :$position = "stack",
                    :$binwidth = undef, :$bins = undef,
                    :$na_rm = false,
                    :$show_legend = 'auto', :$inherit_aes = true,
                    %rest) {
    return layer(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        geom        => 'bar',
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        params      => {
            binwidth => $binwidth,
            bins     => $bins,
            na_rm    => $na_rm,
            pad      => false,
            %rest
        },
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Functions - Function interface for Chart::GGPlot::Geom

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This module provides the C<geom_*> functions supported by this Chart-GGPlot
library.  When used standalone, each C<geom_*> function generates a
L<Chart::GGPlot::Layer> object. Also the functions can be used as
L<Chart::GGPlot::Plot> methods, to add layers into the plot object.

=head1 FUNCTIONS

=head2 geom_path

    geom_path(:$mapping = undef, :$data = undef, :$stat = 'identity',
        :$position = 'identity', :$na_rm = false, :$show_legend = 'auto',
        :$inherit_aes = true, 
        %rest)

The "path" geom connects the observations in the order in which they appear
in the data. 

=head2 geom_line

    geom_line(:$mapping = undef, :$data = undef, :$stat = 'identity',
        :$position = 'identity', :$na_rm = false, :$show_legend = 'auto',           :$inherit_aes = true, 
        %rest)

The "line" geom connects the observations in the order of the variable on
the x axis. 

=head2 geom_point

    geom_point(:$mapping = undef, :$data = undef, :$stat = 'identity',
        :$position = 'identity', :$na_rm = false, :$show_legend = 'auto',
        :$inherit_aes = true, %rest)

The "point" geom is used to create scatterplots.
The scatterplot is most useful for displaying the relationship between two
continuous variables.
A bubblechart is a scatterplot with a third variable mapped to the size of
points.

=head2 geom_bar

    geom_bar(:$mapping = undef, :$data = undef, :$stat = 'count',
        :$position = 'stack', :$width = undef,
        :$na_rm = false, :$show_legend = 'auto', :$inherit_aes = true,
        %rest)

The "bar" geom makes the height bar proportional to the number of cases in each group (or if the C<weight> aesthetic is supplied, the sum of the
C<weights>). 
It uses C<stat_count()> by default: it counts the number of cases at each x
position. 

=head2 geom_histogram

    geom_histogram(:$data = undef, :$mapping = undef, :$stat = "bin",
        :$position = "stack", :$binwidth = undef, :$bins = undef,
        :$na_rm = false, :$show_legend = 'auto', :$inherit_aes = true,
        %rest)

Visualise the distribution of a single continuous variable by dividing the
x axis into bins and counting the number of observations in each bin.
This "histogram" geom displays the counts with bars.

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
